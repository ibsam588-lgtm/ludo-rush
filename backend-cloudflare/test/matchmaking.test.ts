import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import { afterEach, describe, expect, it } from 'vitest';
import { enqueueMatch, matchWaitingTicket, type TicketRow } from '../src/matchmaking';
import { createInitialSnapshot, fillBotSeats, upsertSeat } from '../src/game/rules';
import type { GameMode } from '../src/types';

const databases: DatabaseSync[] = [];
afterEach(() => { for (const db of databases.splice(0)) db.close(); });
function harness() {
  const sqlite = new DatabaseSync(':memory:');
  databases.push(sqlite);
  for (const migration of ['0001_initial.sql','0002_internal_testing.sql']) {
    sqlite.exec(readFileSync(new URL(`../migrations/${migration}`,import.meta.url),'utf8'));
  }
  for (let i=0;i<12;i++) sqlite.prepare('INSERT INTO users VALUES (?,?,?,1000,1,1)').run(`p${i}`,`P${i}`,'auto');
  class Statement {
    constructor(readonly sql:string, readonly values:(string|number|null)[] = []) {}
    bind(...values:(string|number|null)[]) { return new Statement(this.sql,values); }
    async first() { return sqlite.prepare(this.sql).get(...this.values) ?? null; }
    async all() { return {results:sqlite.prepare(this.sql).all(...this.values)}; }
    execute() { const result=sqlite.prepare(this.sql).run(...this.values); return {meta:{changes:Number(result.changes)}}; }
    async run() { return this.execute(); }
  }
  const db = {prepare:(sql:string)=>new Statement(sql), batch:async(statements:Statement[])=>{
    sqlite.exec('BEGIN');
    try { const results=statements.map(s=>s.execute());sqlite.exec('COMMIT');return results; }
    catch(error) {sqlite.exec('ROLLBACK');throw error;}
  }} as unknown as D1Database;
  const rooms = new Map<string,TicketRow[]>();
  const create = async(id:string, players:TicketRow[]) => {rooms.set(id,players);};
  const input=(id:number,mode:GameMode='classic_2p')=>({playerId:`p${id}`,displayName:`P${id}`,region:'auto' as const,mode,rating:1000});
  return {db,sqlite,rooms,create,input};
}

describe('online matching',()=>{
  it.each([['classic_2p',2],['classic_3p',3],['classic_4p',4],['snakes_ladders',4]] as const)('waits for every human in %s',async(mode,count)=>{
    const {db,rooms,create,input,sqlite}=harness();
    for(let i=0;i<count-1;i++) expect((await enqueueMatch(db,input(i,mode),create,100+i)).status).toBe('waiting');
    expect(rooms.size).toBe(0);
    const final=await enqueueMatch(db,input(count-1,mode),create,110);
    expect(final.status).toBe('matched');
    expect(rooms.size).toBe(1);
    expect(new Set(rooms.get(final.room_id!)!.map(p=>p.player_id)).size).toBe(count);
    expect(sqlite.prepare("SELECT COUNT(*) AS n FROM matchmaking_tickets WHERE status='matched'").get()?.n).toBe(count);
  });
  it('pairs simultaneous arrivals exactly once without putting a player in two rooms',async()=>{
    const {db,rooms,create,input,sqlite}=harness();
    await Promise.all(Array.from({length:8},(_,i)=>enqueueMatch(db,input(i),create,100)));
    // Polling can form any group that lost a claim race, without a new arrival.
    for(const ticket of sqlite.prepare("SELECT * FROM matchmaking_tickets WHERE status='waiting'").all() as unknown as TicketRow[]) {
      await matchWaitingTicket(db,ticket,create,101);
    }
    expect(rooms.size).toBe(4);
    const players=[...rooms.values()].flat().map(p=>p.player_id);
    expect(players).toHaveLength(8);
    expect(new Set(players).size).toBe(8);
    expect(sqlite.prepare("SELECT COUNT(*) AS n FROM matchmaking_tickets WHERE status='waiting'").get()?.n).toBe(0);
  });
  it('deduplicates concurrent queue requests and replaces an old mode or region',async()=>{
    const {db,create,input,sqlite}=harness();
    const results=await Promise.all([enqueueMatch(db,input(0),create,100),enqueueMatch(db,input(0),create,100)]);
    expect(results[0].id).toBe(results[1].id);
    expect(sqlite.prepare('SELECT COUNT(*) AS n FROM matchmaking_tickets').get()?.n).toBe(1);
    const changed=await enqueueMatch(db,{...input(0,'classic_4p'),region:'us-east'},create,101);
    expect(changed.mode).toBe('classic_4p');
    expect(changed.region).toBe('us-east');
    expect(sqlite.prepare('SELECT status FROM matchmaking_tickets WHERE id=?').get(results[0].id)?.status).toBe('cancelled');
  });
  it('rolls failed room creation back and retries on polling',async()=>{
    const {db,create,input,rooms,sqlite}=harness();
    const first=await enqueueMatch(db,input(0),create,100);
    await enqueueMatch(db,input(1),async()=>{throw new Error('room unavailable');},101);
    expect(sqlite.prepare("SELECT COUNT(*) AS n FROM matchmaking_tickets WHERE status='waiting'").get()?.n).toBe(2);
    expect((await matchWaitingTicket(db,first,create,102)).status).toBe('matched');
    expect(rooms.size).toBe(1);
  });
  it('does not publish half-created rooms and releases peers when setup is cancelled',async()=>{
    const {db,create,input,sqlite}=harness();
    await enqueueMatch(db,input(0),create,100);
    await enqueueMatch(db,input(1),async(roomId)=>{
      const tickets=sqlite.prepare('SELECT * FROM matchmaking_tickets WHERE room_id=?').all(roomId);
      expect(tickets.map(t=>t.status)).toEqual(['preparing','preparing']);
      sqlite.prepare("UPDATE matchmaking_tickets SET status='cancelled' WHERE player_id='p0'").run();
    },101);
    expect(sqlite.prepare("SELECT status FROM matchmaking_tickets WHERE player_id='p1'").get()?.status).toBe('waiting');
    expect(sqlite.prepare("SELECT COUNT(*) AS n FROM matchmaking_tickets WHERE status='matched'").get()?.n).toBe(0);
  });
  it('reserves online seats for the matched players while slow players join',()=>{
    let room=createInitialSnapshot({roomId:'r',mode:'classic_2p',region:'auto',now:1,expectedPlayerIds:['a','b']});
    room=upsertSeat(room,{playerId:'a',displayName:'A'});
    room=fillBotSeats(room); // Older clients send this immediately after joining.
    expect(room.status).toBe('waiting');
    expect(room.seats).toHaveLength(1);
    expect(()=>upsertSeat(room,{playerId:'stranger',displayName:'X'})).toThrow('reserved');
    room=upsertSeat(room,{playerId:'b',displayName:'B'});
    expect(room.status).toBe('playing');
    expect(room.seats.every(s=>!s.isBot)).toBe(true);
  });
});
