import { MAX_PLAYERS_BY_MODE } from './game/rules';
import type { GameMode, Region } from './types';
import { createId } from './utils/id';

export const MATCH_TICKET_TTL_MS = 45_000;
export interface TicketRow {
  id: string;
  player_id: string;
  display_name: string;
  mode: GameMode;
  region: Region;
  rating: number;
  latency_ms: number | null;
  status: 'waiting' | 'preparing' | 'matched' | 'cancelled' | 'expired';
  room_id: string | null;
  requested_at: number;
  updated_at: number;
  expires_at: number;
}
type CreateMatchedRoom = (roomId: string, players: TicketRow[]) => Promise<void>;

export async function enqueueMatch(db: D1Database, input: {
  playerId: string; displayName: string; mode: GameMode; region: Region; rating: number; latencyMs?: number;
}, createRoom: CreateMatchedRoom, now = Date.now()): Promise<TicketRow> {
  const id = createId('ticket');
  await db.batch([
    db.prepare("UPDATE matchmaking_tickets SET status = 'expired', updated_at = ? WHERE status IN ('waiting','preparing') AND expires_at <= ?").bind(now, now),
    db.prepare("UPDATE matchmaking_tickets SET status = 'cancelled', updated_at = ? WHERE player_id = ? AND status IN ('waiting','preparing') AND (mode <> ? OR region <> ?)").bind(now, input.playerId, input.mode, input.region),
    // Enqueue before looking for opponents. INSERT ... SELECT is atomic, so
    // simultaneous requests from the same player cannot make duplicate tickets.
    db.prepare(`INSERT INTO matchmaking_tickets
      (id,player_id,display_name,mode,region,rating,latency_ms,status,room_id,requested_at,updated_at,expires_at)
      SELECT ?,?,?,?,?,?,?,'waiting',NULL,?,?,? WHERE NOT EXISTS
      (SELECT 1 FROM matchmaking_tickets WHERE player_id = ? AND status IN ('waiting','preparing') AND expires_at > ?)`)
      .bind(id, input.playerId, input.displayName, input.mode, input.region, input.rating, input.latencyMs ?? null,
        now, now, now + MATCH_TICKET_TTL_MS, input.playerId, now),
  ]);
  const ticket = await db.prepare(`SELECT * FROM matchmaking_tickets WHERE player_id = ? AND expires_at > ?
    AND status IN ('waiting','preparing','matched') ORDER BY CASE WHEN status = 'matched' THEN 1 ELSE 0 END, requested_at DESC, id DESC LIMIT 1`)
    .bind(input.playerId, now).first<TicketRow>();
  if (!ticket) throw new Error('Unable to enter the matchmaking queue. Please retry.');
  return matchWaitingTicket(db, ticket, createRoom, now);
}

export async function matchWaitingTicket(db: D1Database, ticket: TicketRow, createRoom: CreateMatchedRoom,
  now = Date.now()): Promise<TicketRow> {
  if (ticket.status !== 'waiting' || ticket.expires_at <= now) return ticket;
  const count = MAX_PLAYERS_BY_MODE[ticket.mode];
  const waiting = await db.prepare(`SELECT * FROM matchmaking_tickets WHERE status = 'waiting'
    AND mode = ? AND region = ? AND player_id <> ? AND expires_at > ? ORDER BY requested_at, id LIMIT 100`)
    .bind(ticket.mode, ticket.region, ticket.player_id, now).all<TicketRow>();
  const players = [ticket];
  const seen = new Set([ticket.player_id]);
  for (const candidate of waiting.results) {
    if (seen.has(candidate.player_id)) continue;
    seen.add(candidate.player_id);
    players.push(candidate);
    if (players.length === count) break;
  }
  if (players.length !== count) return ticket;
  const roomId = createId('room');
  const ids = players.map(p => p.id);
  const placeholders = ids.map(() => '?').join(',');
  // Claim the whole group in one statement, including the caller. Partial
  // claims used to allow a player to be paired into more than one room.
  const claimed = await db.prepare(`UPDATE matchmaking_tickets SET status = 'preparing', room_id = ?, updated_at = ?
    WHERE id IN (${placeholders}) AND status = 'waiting'
    AND (SELECT COUNT(DISTINCT player_id) FROM matchmaking_tickets
      WHERE id IN (${placeholders}) AND status = 'waiting' AND expires_at > ?) = ?`)
    .bind(roomId, now, ...ids, ...ids, now, count).run();
  if (claimed.meta.changes === count) {
    try {
      await createRoom(roomId, players);
      // Never publish a socket URL before room creation succeeds. A cancelled
      // member during setup releases the other members to the queue.
      const ready = await db.prepare(`UPDATE matchmaking_tickets SET status = 'matched', updated_at = ?
        WHERE room_id = ? AND status = 'preparing'
        AND (SELECT COUNT(*) FROM matchmaking_tickets WHERE room_id = ? AND status = 'preparing') = ?`)
        .bind(Date.now(), roomId, roomId, count).run();
      if (ready.meta.changes !== count) throw new Error('Match setup was cancelled.');
    } catch {
      await db.prepare("UPDATE matchmaking_tickets SET status = 'waiting', room_id = NULL, updated_at = ? WHERE room_id = ? AND status = 'preparing'")
        .bind(Date.now(), roomId).run();
    }
  }
  return (await db.prepare('SELECT * FROM matchmaking_tickets WHERE id = ?').bind(ticket.id).first<TicketRow>()) ?? ticket;
}
