import type { RoomSnapshot } from "../types";
import { ECONOMY } from "../economy";
import { computeFinishRanks } from "./rules";

// Every statement is executed in one D1 batch transaction. finish_rank is the
// settlement marker, so retries after a Durable Object restart cannot pay twice.
export function matchRewardStatements(db: D1Database, snapshot: RoomSnapshot): D1PreparedStatement[] {
  const statements: D1PreparedStatement[] = [];
  const ranks = computeFinishRanks(snapshot);
  for (const seat of snapshot.seats.filter((seat) => !seat.playerId.startsWith("bot_"))) {
    const won = !seat.isBot && seat.playerId === snapshot.winnerPlayerId;
    const coins = seat.isBot ? 0 : won ? ECONOMY.onlineWinCoins : ECONOMY.onlineFinishCoins;
    const contribution = seat.isBot ? 0 : won ? ECONOMY.clubWinContribution : ECONOMY.clubFinishContribution;
    const rating = won ? 12 : -6;
    statements.push(
      db.prepare(`INSERT INTO wallets (user_id, coins, updated_at)
        SELECT ?, ?, ? WHERE EXISTS (SELECT 1 FROM match_players WHERE match_id = ? AND user_id = ? AND finish_rank IS NULL)
        ON CONFLICT(user_id) DO UPDATE SET coins = MIN(99999999, wallets.coins + excluded.coins), updated_at = excluded.updated_at`)
        .bind(seat.playerId, coins, snapshot.updatedAt, snapshot.roomId, seat.playerId),
      db.prepare(`UPDATE users SET rating = MAX(0, MIN(9999, rating + ?)), last_seen_at = ?
        WHERE id = ? AND EXISTS (SELECT 1 FROM match_players WHERE match_id = ? AND user_id = ? AND finish_rank IS NULL)`)
        .bind(rating, snapshot.updatedAt, seat.playerId, snapshot.roomId, seat.playerId),
      db.prepare(`UPDATE club_members SET contribution = contribution + ?
        WHERE user_id = ? AND EXISTS (SELECT 1 FROM match_players WHERE match_id = ? AND user_id = ? AND finish_rank IS NULL)`)
        .bind(contribution, seat.playerId, snapshot.roomId, seat.playerId),
      db.prepare(`UPDATE match_players SET finish_rank = ?, rating_delta = ?, coins_delta = ?
        WHERE match_id = ? AND user_id = ? AND finish_rank IS NULL`)
        .bind(seat.finishRank ?? ranks.get(seat.playerId) ?? (won ? 1 : snapshot.seats.length), rating, coins, snapshot.roomId, seat.playerId),
    );
  }
  return statements;
}
