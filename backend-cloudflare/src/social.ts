import type { Env } from "./types";
import { authenticatedPlayerId } from "./auth";
import { badRequest, json, notFound, readJson, unauthorized } from "./utils/http";
import { createId } from "./utils/id";

interface SocialBody {
  playerId?: string;
  targetPlayerId?: string;
  giftId?: string;
  message?: string;
  displayName?: string;
  countryCode?: string;
  avatarKey?: string;
  age?: number;
}

interface UserRow {
  id: string;
  display_name: string;
  rating: number;
  age: number;
}

interface FriendshipRow {
  user_a: string;
  user_b: string;
  requested_by: string;
  status: "pending" | "accepted";
}

const COIN_GIFTS: Record<string, number> = {
  lucky_dice: 25,
  coin_ship: 50,
  crown_chest: 125
};

export async function routeSocialRequest(
  request: Request,
  env: Env,
  url: URL
): Promise<Response> {
  const playerId = await authenticatedPlayerId(request, env);
  if (!playerId) return unauthorized();
  if (request.method === "GET" && url.pathname === "/api/v1/social/overview") {
    return socialOverview(env, playerId);
  }
  if (request.method === "POST" && url.pathname === "/api/v1/social/profile") {
    return updateProfile(request, env, playerId);
  }
  if (request.method === "POST" && url.pathname === "/api/v1/social/friends/request") {
    return requestFriend(request, env, playerId);
  }
  if (request.method === "POST" && url.pathname === "/api/v1/social/friends/accept") {
    return acceptFriend(request, env, playerId);
  }
  if (request.method === "POST" && url.pathname === "/api/v1/social/friends/remove") {
    return removeFriend(request, env, playerId);
  }
  if (request.method === "POST" && url.pathname === "/api/v1/social/gifts") {
    return sendGift(request, env, playerId);
  }
  if (request.method === "GET" && url.pathname === "/api/v1/social/messages") {
    return getMessages(env, playerId);
  }
  if (request.method === "POST" && url.pathname === "/api/v1/social/messages") {
    return sendMessage(request, env, playerId);
  }
  if (request.method === "POST" && url.pathname === "/api/v1/social/rewards/daily") {
    return claimDailyReward(env, playerId);
  }
  if (request.method === "POST" && url.pathname === "/api/v1/social/rewards/gold-chest") {
    return claimGoldChest(env, playerId);
  }
  return notFound();
}

async function socialOverview(env: Env, playerId: string): Promise<Response> {
  if (!playerId) return badRequest("playerId is required.");

  const [friends, incoming, outgoing, recent, gifts, wallet, stats, chestClaims] = await Promise.all([
    socialUsers(env, playerId, "accepted"),
    socialUsers(env, playerId, "pending", "incoming"),
    socialUsers(env, playerId, "pending", "outgoing"),
    recentOpponents(env, playerId),
    env.DB.prepare(
      `SELECT g.id, g.gift_id AS giftId, g.created_at AS createdAt,
              u.id AS senderId, u.display_name AS senderName
       FROM friend_gifts g
       JOIN users u ON u.id = g.sender_user_id
       WHERE g.recipient_user_id = ?
       ORDER BY g.created_at DESC
       LIMIT 12`
    ).bind(playerId).all(),
    env.DB.prepare("SELECT coins FROM wallets WHERE user_id = ?").bind(playerId).first<{ coins: number }>(),
    env.DB.prepare(
      `SELECT COUNT(*) AS gamesPlayed,
              SUM(CASE WHEN m.winner_user_id = ? THEN 1 ELSE 0 END) AS wins
       FROM match_players mp
       JOIN matches m ON m.id = mp.match_id AND m.status = 'finished'
       WHERE mp.user_id = ?`
    ).bind(playerId, playerId).first<{ gamesPlayed: number; wins: number }>(),
    env.DB.prepare(
      "SELECT COUNT(*) AS claimed FROM reward_claims WHERE user_id = ? AND reward_id = 'gold_chest'"
    ).bind(playerId).first<{ claimed: number }>()
  ]);

  const onlineWins = stats?.wins ?? 0;
  const earnedGoldChests = 1 + Math.floor(onlineWins / 3);

  return json({
    friends,
    incomingRequests: incoming,
    outgoingRequests: outgoing,
    recentOpponents: recent,
    receivedGifts: gifts.results ?? [],
    coins: wallet?.coins ?? 0,
    gamesPlayed: stats?.gamesPlayed ?? 0,
    wins: onlineWins,
    availableGoldChests: Math.max(0, earnedGoldChests - (chestClaims?.claimed ?? 0))
  });
}

async function claimDailyReward(env: Env, playerId: string): Promise<Response> {
  const periodKey = new Date().toISOString().slice(0, 10);
  const claim = await env.DB.prepare(
    "INSERT OR IGNORE INTO reward_claims (user_id, reward_id, period_key, claimed_at) VALUES (?, 'daily_coins', ?, ?)"
  ).bind(playerId, periodKey, Date.now()).run();
  if (claim.meta.changes === 1) {
    await env.DB.prepare(
      "UPDATE wallets SET coins = coins + 150, updated_at = ? WHERE user_id = ?"
    ).bind(Date.now(), playerId).run();
  }
  const wallet = await env.DB.prepare("SELECT coins FROM wallets WHERE user_id = ?")
    .bind(playerId).first<{ coins: number }>();
  return json({
    claimed: claim.meta.changes === 1,
    periodKey,
    coins: wallet?.coins ?? 0
  });
}

async function claimGoldChest(env: Env, playerId: string): Promise<Response> {
  const [stats, claimed] = await Promise.all([
    env.DB.prepare(
      `SELECT SUM(CASE WHEN m.winner_user_id = ? THEN 1 ELSE 0 END) AS wins
       FROM match_players mp
       JOIN matches m ON m.id = mp.match_id AND m.status = 'finished'
       WHERE mp.user_id = ?`
    ).bind(playerId, playerId).first<{ wins: number }>(),
    env.DB.prepare(
      "SELECT COUNT(*) AS count FROM reward_claims WHERE user_id = ? AND reward_id = 'gold_chest'"
    ).bind(playerId).first<{ count: number }>()
  ]);
  const available = 1 + Math.floor((stats?.wins ?? 0) / 3) - (claimed?.count ?? 0);
  if (available <= 0) {
    return json({ error: "No Gold Chest is ready. Earn one every 3 online wins." }, { status: 409 });
  }
  const ordinal = (claimed?.count ?? 0) + 1;
  const claim = await env.DB.prepare(
    "INSERT OR IGNORE INTO reward_claims (user_id, reward_id, period_key, claimed_at) VALUES (?, 'gold_chest', ?, ?)"
  ).bind(playerId, `chest_${ordinal}`, Date.now()).run();
  if (claim.meta.changes !== 1) {
    return json({ error: "This Gold Chest was already claimed." }, { status: 409 });
  }
  await env.DB.prepare(
    "UPDATE wallets SET coins = coins + 500, updated_at = ? WHERE user_id = ?"
  ).bind(Date.now(), playerId).run();
  const wallet = await env.DB.prepare("SELECT coins FROM wallets WHERE user_id = ?")
    .bind(playerId).first<{ coins: number }>();
  return json({
    claimed: true,
    coins: wallet?.coins ?? 0,
    availableGoldChests: available - 1
  });
}

async function updateProfile(request: Request, env: Env, playerId: string): Promise<Response> {
  const body = await readJson<SocialBody>(request);
  body.playerId = playerId;
  const displayName = cleanName(body.displayName);
  const age = clampInt(body.age, 0, 120);
  const countryCode = (body.countryCode ?? "US").trim().toUpperCase().slice(0, 2) || "US";
  const avatarKey = (body.avatarKey ?? "").trim().slice(0, 80) || null;
  const now = Date.now();

  await env.DB.batch([
    env.DB.prepare(
      `INSERT INTO users (id, display_name, region, rating, created_at, last_seen_at, age, country_code, avatar_key)
       VALUES (?, ?, 'auto', 1000, ?, ?, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
         display_name = excluded.display_name,
         age = excluded.age,
         country_code = excluded.country_code,
         avatar_key = excluded.avatar_key,
         last_seen_at = excluded.last_seen_at`
    ).bind(body.playerId, displayName, now, now, age, countryCode, avatarKey),
    env.DB.prepare(
      "INSERT INTO wallets (user_id, coins, updated_at) VALUES (?, 500, ?) ON CONFLICT(user_id) DO NOTHING"
    ).bind(body.playerId, now)
  ]);

  return json({ ok: true });
}

async function requestFriend(request: Request, env: Env, authenticatedId: string): Promise<Response> {
  const body = await readJson<SocialBody>(request);
  body.playerId = authenticatedId;
  const ids = validatePair(body);
  if (ids instanceof Response) return ids;
  const [playerId, targetPlayerId] = ids;
  if (!(await userExists(env, targetPlayerId))) return notFound();
  if (!(await havePlayedTogether(env, playerId, targetPlayerId))) {
    return json({ error: "Only recent opponents can receive a friend request." }, { status: 403 });
  }

  const [userA, userB] = orderedPair(playerId, targetPlayerId);
  const existing = await friendship(env, userA, userB);
  const now = Date.now();
  if (existing?.status === "accepted") return json({ status: "accepted" });

  const status = existing?.requested_by === targetPlayerId ? "accepted" : "pending";
  await env.DB.prepare(
    `INSERT INTO friendships (user_a, user_b, requested_by, status, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?)
     ON CONFLICT(user_a, user_b) DO UPDATE SET
       requested_by = excluded.requested_by,
       status = excluded.status,
       updated_at = excluded.updated_at`
  ).bind(userA, userB, playerId, status, now, now).run();
  return json({ status });
}

async function acceptFriend(request: Request, env: Env, authenticatedId: string): Promise<Response> {
  const body = await readJson<SocialBody>(request);
  body.playerId = authenticatedId;
  const ids = validatePair(body);
  if (ids instanceof Response) return ids;
  const [playerId, targetPlayerId] = ids;
  const [userA, userB] = orderedPair(playerId, targetPlayerId);
  const existing = await friendship(env, userA, userB);
  if (!existing || existing.status !== "pending" || existing.requested_by !== targetPlayerId) {
    return json({ error: "No incoming request from that player." }, { status: 409 });
  }
  await env.DB.prepare(
    "UPDATE friendships SET status = 'accepted', updated_at = ? WHERE user_a = ? AND user_b = ?"
  ).bind(Date.now(), userA, userB).run();
  return json({ status: "accepted" });
}

async function removeFriend(request: Request, env: Env, authenticatedId: string): Promise<Response> {
  const body = await readJson<SocialBody>(request);
  body.playerId = authenticatedId;
  const ids = validatePair(body);
  if (ids instanceof Response) return ids;
  const [userA, userB] = orderedPair(ids[0], ids[1]);
  await env.DB.prepare("DELETE FROM friendships WHERE user_a = ? AND user_b = ?")
    .bind(userA, userB).run();
  return json({ status: "removed" });
}

async function sendGift(request: Request, env: Env, authenticatedId: string): Promise<Response> {
  const body = await readJson<SocialBody>(request);
  body.playerId = authenticatedId;
  const ids = validatePair(body);
  if (ids instanceof Response) return ids;
  const [playerId, targetPlayerId] = ids;
  const giftId = (body.giftId ?? "").trim();
  const coinCost = COIN_GIFTS[giftId];
  if (coinCost === undefined) {
    return json({ error: "Premium gifts require a verified Google Play purchase." }, { status: 402 });
  }
  if (!(await areFriends(env, playerId, targetPlayerId))) {
    return json({ error: "Gifts can only be sent to accepted friends." }, { status: 403 });
  }

  const debit = await env.DB.prepare(
    "UPDATE wallets SET coins = coins - ?, updated_at = ? WHERE user_id = ? AND coins >= ?"
  ).bind(coinCost, Date.now(), playerId, coinCost).run();
  if (debit.meta.changes !== 1) {
    return json({ error: "Not enough coins for this gift." }, { status: 409 });
  }

  await env.DB.prepare(
    "INSERT INTO friend_gifts (id, sender_user_id, recipient_user_id, gift_id, coin_cost, created_at) VALUES (?, ?, ?, ?, ?, ?)"
  ).bind(createId("gift"), playerId, targetPlayerId, giftId, coinCost, Date.now()).run();
  const wallet = await env.DB.prepare("SELECT coins FROM wallets WHERE user_id = ?")
    .bind(playerId).first<{ coins: number }>();
  return json({ status: "sent", coins: wallet?.coins ?? 0 });
}

async function getMessages(env: Env, playerId: string): Promise<Response> {
  if (!playerId) return badRequest("playerId is required.");
  if (!(await chatAllowed(env, playerId))) {
    return json({ error: "Friends chat is only available to players age 13 or older." }, { status: 403 });
  }
  const messages = await env.DB.prepare(
    `SELECT m.id, m.message, m.created_at AS createdAt,
            u.id AS senderId, u.display_name AS senderName
     FROM friend_messages m
     JOIN users u ON u.id = m.sender_user_id
     WHERE m.sender_user_id = ?
        OR EXISTS (
          SELECT 1 FROM friendships f
          WHERE f.status = 'accepted'
            AND ((f.user_a = ? AND f.user_b = m.sender_user_id)
              OR (f.user_b = ? AND f.user_a = m.sender_user_id))
        )
     ORDER BY m.created_at DESC
     LIMIT 60`
  ).bind(playerId, playerId, playerId).all();
  return json({ messages: (messages.results ?? []).reverse() });
}

async function sendMessage(request: Request, env: Env, playerId: string): Promise<Response> {
  const body = await readJson<SocialBody>(request);
  body.playerId = playerId;
  if (!(await chatAllowed(env, body.playerId))) {
    return json({ error: "Friends chat is only available to players age 13 or older." }, { status: 403 });
  }
  const message = (body.message ?? "").trim().replace(/\s+/g, " ").slice(0, 160);
  if (!message) return badRequest("message is required.");
  const id = createId("msg");
  const createdAt = Date.now();
  await env.DB.prepare(
    "INSERT INTO friend_messages (id, sender_user_id, message, created_at) VALUES (?, ?, ?, ?)"
  ).bind(id, body.playerId, message, createdAt).run();
  return json({ id, message, createdAt });
}

async function socialUsers(
  env: Env,
  playerId: string,
  status: "pending" | "accepted",
  direction?: "incoming" | "outgoing"
): Promise<unknown[]> {
  const rows = await env.DB.prepare(
    `SELECT f.user_a, f.user_b, f.requested_by, f.status,
            u.id, u.display_name AS displayName, u.rating
     FROM friendships f
     JOIN users u ON u.id = CASE WHEN f.user_a = ? THEN f.user_b ELSE f.user_a END
     WHERE (f.user_a = ? OR f.user_b = ?) AND f.status = ?
     ORDER BY f.updated_at DESC`
  ).bind(playerId, playerId, playerId, status).all<FriendshipRow & UserRow & { displayName: string }>();
  return (rows.results ?? [])
    .filter((row) => direction !== "incoming" || row.requested_by !== playerId)
    .filter((row) => direction !== "outgoing" || row.requested_by === playerId)
    .map((row) => ({ id: row.id, displayName: row.displayName, rating: row.rating }));
}

async function recentOpponents(env: Env, playerId: string): Promise<unknown[]> {
  const rows = await env.DB.prepare(
    `SELECT u.id, u.display_name AS displayName, u.rating,
            MAX(m.ended_at) AS lastPlayedAt
     FROM match_players mine
     JOIN match_players other ON other.match_id = mine.match_id AND other.user_id <> mine.user_id
     JOIN matches m ON m.id = mine.match_id AND m.status = 'finished'
     JOIN users u ON u.id = other.user_id
     WHERE mine.user_id = ?
       AND NOT EXISTS (
         SELECT 1 FROM friendships f
         WHERE (f.user_a = ? AND f.user_b = u.id)
            OR (f.user_b = ? AND f.user_a = u.id)
       )
     GROUP BY u.id, u.display_name, u.rating
     ORDER BY lastPlayedAt DESC
     LIMIT 12`
  ).bind(playerId, playerId, playerId).all();
  return rows.results ?? [];
}

async function havePlayedTogether(env: Env, playerId: string, targetPlayerId: string): Promise<boolean> {
  const row = await env.DB.prepare(
    `SELECT 1 AS found
     FROM match_players a
     JOIN match_players b ON b.match_id = a.match_id
     JOIN matches m ON m.id = a.match_id AND m.status = 'finished'
     WHERE a.user_id = ? AND b.user_id = ?
     LIMIT 1`
  ).bind(playerId, targetPlayerId).first();
  return row !== null;
}

async function areFriends(env: Env, playerId: string, targetPlayerId: string): Promise<boolean> {
  const [userA, userB] = orderedPair(playerId, targetPlayerId);
  const row = await friendship(env, userA, userB);
  return row?.status === "accepted";
}

async function friendship(env: Env, userA: string, userB: string): Promise<FriendshipRow | null> {
  return env.DB.prepare(
    "SELECT user_a, user_b, requested_by, status FROM friendships WHERE user_a = ? AND user_b = ?"
  ).bind(userA, userB).first<FriendshipRow>();
}

async function chatAllowed(env: Env, playerId: string): Promise<boolean> {
  const user = await env.DB.prepare("SELECT age FROM users WHERE id = ?")
    .bind(playerId).first<{ age: number }>();
  return (user?.age ?? 0) >= 13;
}

async function userExists(env: Env, playerId: string): Promise<boolean> {
  return (await env.DB.prepare("SELECT id FROM users WHERE id = ?").bind(playerId).first()) !== null;
}

function validatePair(body: SocialBody): [string, string] | Response {
  const playerId = (body.playerId ?? "").trim();
  const targetPlayerId = (body.targetPlayerId ?? "").trim();
  if (!playerId || !targetPlayerId) return badRequest("playerId and targetPlayerId are required.");
  if (playerId === targetPlayerId) return badRequest("You cannot select your own profile.");
  return [playerId, targetPlayerId];
}

function orderedPair(first: string, second: string): [string, string] {
  return first < second ? [first, second] : [second, first];
}

function cleanName(value?: string): string {
  const clean = (value ?? "").trim().replace(/\s+/g, " ").slice(0, 24);
  return clean.length >= 2 ? clean : "Guest";
}

function clampInt(value: number | undefined, min: number, max: number): number {
  if (!Number.isFinite(value)) return min;
  return Math.min(max, Math.max(min, Math.trunc(value!)));
}
