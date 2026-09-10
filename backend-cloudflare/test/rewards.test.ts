import { DatabaseSync } from "node:sqlite";
import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { matchRewardStatements } from "../src/game/rewards";
import { createInitialSnapshot, upsertSeat } from "../src/game/rules";

describe("match settlement", () => {
  it.each([false, true])("settles once and excludes departed-player rewards (departed: %s)", (departed) => {
    const sqlite = new DatabaseSync(":memory:");
    sqlite.exec(readFileSync(new URL("../migrations/0001_initial.sql", import.meta.url), "utf8"));
    sqlite.exec("CREATE TABLE club_members(user_id TEXT PRIMARY KEY, contribution INTEGER NOT NULL DEFAULT 0)");
    sqlite.exec(`INSERT INTO club_members VALUES ('a',0),('b',0);
      INSERT INTO users VALUES ('a','A','us-east',1000,1,1),('b','B','us-east',2,1,1);
      INSERT INTO wallets VALUES ('a',500,1),('b',500,1);
      INSERT INTO matches (id,mode,region,status,started_at) VALUES ('room','classic_2p','us-east','playing',1);
      INSERT INTO match_players(match_id,user_id,seat) VALUES ('room','a',0),('room','b',1);`);
    let snapshot = createInitialSnapshot({ roomId: "room", mode: "classic_2p", region: "us-east", now: 1 });
    snapshot = upsertSeat(snapshot, { playerId: "a", displayName: "A" });
    snapshot = upsertSeat(snapshot, { playerId: "b", displayName: "B" });
    snapshot = { ...snapshot, status: "finished", winnerPlayerId: "a",
      seats: snapshot.seats.map((seat) => seat.playerId === "b" ? { ...seat, isBot: departed } : seat) };
    const db = { prepare: (sql: string) => ({ bind: (...values: (string | number)[]) => ({ sql, values }) }) } as unknown as D1Database;
    for (let retry = 0; retry < 3; retry++) {
      const statements = matchRewardStatements(db, snapshot) as unknown as { sql: string; values: (string | number)[] }[];
      sqlite.exec("BEGIN");
      for (const statement of statements) sqlite.prepare(statement.sql).run(...statement.values);
      sqlite.exec("COMMIT");
    }
    expect(sqlite.prepare("SELECT coins FROM wallets WHERE user_id='a'").get()?.coins).toBe(600);
    expect(sqlite.prepare("SELECT coins FROM wallets WHERE user_id='b'").get()?.coins).toBe(departed ? 500 : 515);
    expect(sqlite.prepare("SELECT rating FROM users WHERE id='a'").get()?.rating).toBe(1012);
    expect(sqlite.prepare("SELECT rating FROM users WHERE id='b'").get()?.rating).toBe(0);
    expect(matchRewardStatements(db, { ...snapshot, seats: snapshot.seats.map((seat) => ({ ...seat, playerId: `bot_${seat.playerId}`, isBot: true })) })).toHaveLength(0);
    expect(sqlite.prepare("SELECT contribution FROM club_members WHERE user_id='a'").get()?.contribution).toBe(10);
    expect(sqlite.prepare("SELECT contribution FROM club_members WHERE user_id='b'").get()?.contribution).toBe(departed ? 0 : 3);
    sqlite.close();
  });
});
