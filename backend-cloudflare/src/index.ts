import { buildAppConfig, parsePositiveInt } from "./app-config";
import { authenticatedPlayerId, issueSession } from "./auth";
import { ECONOMY } from "./economy";
import { LudoRoom } from "./durable-objects/LudoRoom";
import { MAX_PLAYERS_BY_MODE } from "./game/rules";
import type { BackgroundJob, Env, GameMode, Region } from "./types";
import { badRequest, json, notFound, readJson, unauthorized } from "./utils/http";
import { createId, createRoomCode } from "./utils/id";
import { routeSocialRequest } from "./social";

export { LudoRoom };

interface GuestAuthRequest {
  displayName?: string;
  region?: Region;
  countryCode?: string;
  avatarKey?: string;
  age?: number;
}

interface MatchmakingRequest {
  playerId: string;
  displayName: string;
  mode: GameMode;
  region?: Region;
  latencyMs?: number;
  difficulty?: "easy" | "medium" | "hard" | "repeat";
}

interface CreatePrivateRoomRequest {
  playerId: string;
  displayName: string;
  mode: GameMode;
  region?: Region;
}

interface JoinPrivateRoomRequest {
  playerId: string;
  displayName: string;
  code: string;
}

interface TicketRow {
  id: string;
  player_id: string;
  display_name: string;
  mode: GameMode;
  region: Region;
  rating: number;
  latency_ms: number | null;
  status: "waiting" | "matched" | "cancelled" | "expired";
  room_id: string | null;
  requested_at: number;
  updated_at: number;
  expires_at: number;
}

interface PrivateRoomRow {
  code: string;
  room_id: string;
  mode: GameMode;
  region: Region;
  created_by: string;
  created_at: number;
  expires_at: number;
}

interface AppReleaseConfigRow {
  minimum_build_number: number;
  latest_build_number: number;
  latest_version_name: string;
  force_latest: number;
  update_url: string;
  message: string;
}

const DEFAULT_REGION: Region = "auto";
const MATCH_TICKET_TTL_MS = 45_000;
const PRIVATE_ROOM_TTL_MS = 30 * 60_000;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "access-control-allow-origin": "*",
          "access-control-allow-methods": "GET,POST,OPTIONS",
          "access-control-allow-headers": "content-type,authorization"
        }
      });
    }

    if (request.method === "GET" && url.pathname === "/health") {
      return json({ ok: true, service: "ludo-rush-backend" });
    }

    try {
      if (request.method === "GET" && url.pathname === "/api/v1/app/config") {
        return getAppConfig(env, url);
      }

      if (request.method === "POST" && url.pathname === "/api/v1/auth/guest") {
        return createGuest(request, env);
      }

      if (request.method === "POST" && url.pathname === "/api/v1/matchmaking/quick") {
        return quickMatch(request, env);
      }

      if (request.method === "POST" && url.pathname === "/api/v1/matchmaking/bots") {
        return createBotMatch(request, env);
      }

      if (request.method === "GET" && url.pathname.startsWith("/api/v1/matchmaking/tickets/")) {
        return getMatchTicket(request, env, url);
      }

      if (request.method === "POST" && url.pathname.endsWith("/cancel") && url.pathname.startsWith("/api/v1/matchmaking/tickets/")) {
        return cancelMatchTicket(request, env, url);
      }

      if (request.method === "POST" && url.pathname === "/api/v1/rooms/private") {
        return createPrivateRoom(request, env);
      }

      if (request.method === "POST" && url.pathname === "/api/v1/rooms/private/join") {
        return joinPrivateRoom(request, env);
      }

      if (url.pathname.startsWith("/api/v1/social/")) {
        return routeSocialRequest(request, env, url);
      }

      if (url.pathname.startsWith("/api/v1/rooms/")) {
        return routeRoomRequest(request, env, url);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unexpected server error";
      return json({ error: message }, { status: 500 });
    }

    return notFound();
  },

  async queue(batch: MessageBatch<BackgroundJob>, env: Env): Promise<void> {
    for (const message of batch.messages) {
      if (message.body.type === "settle_match") {
        await env.DB.prepare("UPDATE matches SET reward_settled_at = ? WHERE id = ? AND reward_settled_at IS NULL")
          .bind(Date.now(), message.body.matchId)
          .run();
      }

      message.ack();
    }
  }
};

async function getAppConfig(env: Env, url: URL): Promise<Response> {
  const platform = (url.searchParams.get("platform") ?? "android").toLowerCase();
  const installedBuild = parsePositiveInt(url.searchParams.get("build"), 0);
  let release: AppReleaseConfigRow | null = null;

  try {
    release = await env.DB.prepare(
      `SELECT minimum_build_number, latest_build_number, latest_version_name,
              force_latest, update_url, message
       FROM app_release_config
       WHERE platform = ?`
    ).bind(platform).first<AppReleaseConfigRow>();
  } catch {
    // Keep the environment fallback available during the first migration/deploy.
  }

  return json(buildAppConfig(env, platform, installedBuild, release
    ? {
        minimumBuildNumber: release.minimum_build_number,
        latestBuildNumber: release.latest_build_number,
        latestVersionName: release.latest_version_name,
        forceLatestBuild: release.force_latest === 1,
        updateUrl: release.update_url,
        message: release.message
      }
    : undefined));
}

async function createGuest(request: Request, env: Env): Promise<Response> {
  const body = await readJson<GuestAuthRequest>(request);
  const now = Date.now();
  const userId = createId("usr");
  const displayName = cleanDisplayName(body.displayName);
  const region = body.region ?? DEFAULT_REGION;
  const age = Number.isFinite(body.age) ? Math.min(120, Math.max(0, Math.trunc(body.age!))) : 0;
  const countryCode = (body.countryCode ?? "US").trim().toUpperCase().slice(0, 2) || "US";
  const avatarMatch = /^preset_([0-3])$/.exec((body.avatarKey ?? "").trim());
  const avatarKey = avatarMatch?.[0] ?? "preset_0";

  await env.DB.batch([
    env.DB.prepare(
      `INSERT INTO users (id, display_name, region, rating, created_at, last_seen_at, age, country_code, avatar_key)
       VALUES (?, ?, ?, 1000, ?, ?, ?, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
         display_name = excluded.display_name,
         region = excluded.region,
         age = excluded.age,
         country_code = excluded.country_code,
         avatar_key = excluded.avatar_key,
         last_seen_at = excluded.last_seen_at`
    ).bind(userId, displayName, region, now, now, age, countryCode, avatarKey),
    env.DB.prepare(
      "INSERT INTO wallets (user_id, coins, updated_at) VALUES (?, ?, ?) ON CONFLICT(user_id) DO NOTHING"
    ).bind(userId, ECONOMY.startingCoins, now)
  ]);

  const [user, wallet, token] = await Promise.all([
    env.DB.prepare("SELECT display_name, region, rating FROM users WHERE id = ?")
      .bind(userId).first<{ display_name: string; region: Region; rating: number }>(),
    env.DB.prepare("SELECT coins FROM wallets WHERE user_id = ?")
      .bind(userId).first<{ coins: number }>(),
    issueSession(env, userId)
  ]);

  return json(
    {
      token,
      player: {
        id: userId,
        displayName: user?.display_name ?? displayName,
        region: user?.region ?? region,
        rating: user?.rating ?? 1000,
        coins: wallet?.coins ?? ECONOMY.startingCoins
      }
    },
    { status: 201 }
  );
}

async function quickMatch(request: Request, env: Env): Promise<Response> {
  const body = await readJson<MatchmakingRequest>(request);
  const authenticated = await requireClaimedPlayer(request, env, body.playerId);
  if (authenticated instanceof Response) return authenticated;
  body.playerId = authenticated;
  if (!body.displayName || !isGameMode(body.mode)) {
    return badRequest("playerId, displayName, and mode are required.");
  }

  const now = Date.now();
  const region = body.region ?? DEFAULT_REGION;
  const rating = await ensureMatchmakingUser(env, body.playerId, body.displayName, region, now);
  await expireOldTickets(env, now);

  // A room only starts once MAX_PLAYERS_BY_MODE[mode] seats are filled, so the
  // caller must be paired with enough waiting opponents for the mode — pairing
  // exactly two players would leave 3p/4p rooms waiting forever.
  const neededOpponents = (MAX_PLAYERS_BY_MODE[body.mode] ?? 2) - 1;
  const waitingTickets = await env.DB.prepare(
    "SELECT * FROM matchmaking_tickets WHERE status = ? AND mode = ? AND region = ? AND player_id <> ? AND expires_at > ? ORDER BY requested_at ASC LIMIT ?"
  ).bind("waiting", body.mode, region, body.playerId, now, neededOpponents).all<TicketRow>();

  const candidates = dedupeByPlayer(waitingTickets.results ?? []);
  if (candidates.length >= neededOpponents) {
    const roomId = createId("room");
    const claimed: TicketRow[] = [];

    // Claim each ticket with a status guard so two concurrent quickMatch calls
    // cannot both pair against the same waiting ticket.
    for (const ticket of candidates) {
      const claim = await env.DB.prepare(
        "UPDATE matchmaking_tickets SET status = ?, room_id = ?, updated_at = ? WHERE id = ? AND status = ?"
      ).bind("matched", roomId, now, ticket.id, "waiting").run();

      if (claim.meta.changes === 1) {
        claimed.push(ticket);
      }
    }

    if (claimed.length === neededOpponents) {
      await createRoom(env, roomId, body.mode, region);
      await env.DB.prepare(
        "INSERT INTO matchmaking_tickets (id, player_id, display_name, mode, region, rating, latency_ms, status, room_id, requested_at, updated_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
      ).bind(createId("ticket"), body.playerId, body.displayName, body.mode, region, rating, body.latencyMs ?? null, "matched", roomId, now, now, now + MATCH_TICKET_TTL_MS).run();

      return json(matchReadyResponse(roomId, body.mode, region));
    }

    // Lost a race for at least one ticket: release the ones we claimed and
    // fall through to waiting like any other unpaired caller.
    for (const ticket of claimed) {
      await env.DB.prepare(
        "UPDATE matchmaking_tickets SET status = ?, room_id = NULL, updated_at = ? WHERE id = ? AND room_id = ?"
      ).bind("waiting", now, ticket.id, roomId).run();
    }
  }

  const activeTicket = await env.DB.prepare(
    "SELECT * FROM matchmaking_tickets WHERE player_id = ? AND status = ? AND expires_at > ? ORDER BY requested_at DESC LIMIT 1"
  ).bind(body.playerId, "waiting", now).first<TicketRow>();

  if (activeTicket) {
    return json(waitingResponse(activeTicket));
  }

  const ticketId = createId("ticket");
  const expiresAt = now + MATCH_TICKET_TTL_MS;
  await env.DB.prepare(
    "INSERT INTO matchmaking_tickets (id, player_id, display_name, mode, region, rating, latency_ms, status, room_id, requested_at, updated_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
  ).bind(ticketId, body.playerId, body.displayName, body.mode, region, rating, body.latencyMs ?? null, "waiting", null, now, now, expiresAt).run();

  return json({
    status: "waiting",
    ticketId,
    mode: body.mode,
    region,
    expiresAt
  });
}

async function createBotMatch(request: Request, env: Env): Promise<Response> {
  const body = await readJson<MatchmakingRequest>(request);
  const authenticated = await requireClaimedPlayer(request, env, body.playerId);
  if (authenticated instanceof Response) return authenticated;
  body.playerId = authenticated;
  if (!body.displayName || !isGameMode(body.mode)) {
    return badRequest("playerId, displayName, and mode are required.");
  }

  const region = body.region ?? DEFAULT_REGION;
  await ensureMatchmakingUser(env, body.playerId, body.displayName, region, Date.now());
  const roomId = createId("room");
  await createRoom(env, roomId, body.mode, region);

  return json(matchReadyResponse(roomId, body.mode, region));
}

async function getMatchTicket(request: Request, env: Env, url: URL): Promise<Response> {
  const authenticated = await authenticatedPlayerId(request, env);
  if (!authenticated) return unauthorized();
  const ticketId = url.pathname.split("/").at(-1);
  if (!ticketId) {
    return badRequest("Ticket id is required.");
  }

  const now = Date.now();
  const ticket = await env.DB.prepare("SELECT * FROM matchmaking_tickets WHERE id = ?").bind(ticketId).first<TicketRow>();
  if (!ticket) {
    return notFound();
  }
  if (ticket.player_id !== authenticated) return unauthorized();

  if (ticket.status === "waiting" && ticket.expires_at <= now) {
    await env.DB.prepare("UPDATE matchmaking_tickets SET status = ?, updated_at = ? WHERE id = ?")
      .bind("expired", now, ticket.id)
      .run();

    return json({
      status: "expired",
      ticketId: ticket.id,
      mode: ticket.mode,
      region: ticket.region
    });
  }

  if (ticket.status === "matched" && ticket.room_id) {
    return json(matchReadyResponse(ticket.room_id, ticket.mode, ticket.region, ticket.id));
  }

  return json(waitingResponse(ticket));
}

async function cancelMatchTicket(request: Request, env: Env, url: URL): Promise<Response> {
  const authenticated = await authenticatedPlayerId(request, env);
  if (!authenticated) return unauthorized();
  const parts = url.pathname.split("/");
  const ticketId = parts.at(-2);
  if (!ticketId) {
    return badRequest("Ticket id is required.");
  }

  await env.DB.prepare("UPDATE matchmaking_tickets SET status = ?, updated_at = ? WHERE id = ? AND player_id = ? AND status = ?")
    .bind("cancelled", Date.now(), ticketId, authenticated, "waiting")
    .run();

  return json({ status: "cancelled", ticketId });
}

async function createPrivateRoom(request: Request, env: Env): Promise<Response> {
  const body = await readJson<CreatePrivateRoomRequest>(request);
  const authenticated = await requireClaimedPlayer(request, env, body.playerId);
  if (authenticated instanceof Response) return authenticated;
  body.playerId = authenticated;
  if (!body.displayName || !isGameMode(body.mode)) {
    return badRequest("playerId, displayName, and mode are required.");
  }

  const roomId = createId("room");
  const code = await createUniqueRoomCode(env);
  const region = body.region ?? DEFAULT_REGION;
  await createRoom(env, roomId, body.mode, region, code);
  await env.DB.prepare(
    "INSERT INTO private_rooms (code, room_id, mode, region, created_by, created_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)"
  ).bind(code, roomId, body.mode, region, body.playerId, Date.now(), Date.now() + PRIVATE_ROOM_TTL_MS).run();

  return json(
    {
      status: "matched",
      roomId,
      code,
      mode: body.mode,
      region,
      socketUrl: `/api/v1/rooms/${roomId}/socket`
    },
    { status: 201 }
  );
}

async function joinPrivateRoom(request: Request, env: Env): Promise<Response> {
  const body = await readJson<JoinPrivateRoomRequest>(request);
  const authenticated = await requireClaimedPlayer(request, env, body.playerId);
  if (authenticated instanceof Response) return authenticated;
  body.playerId = authenticated;
  if (!body.displayName || !body.code) {
    return badRequest("playerId, displayName, and code are required.");
  }

  const code = body.code.trim();
  const room = await env.DB.prepare("SELECT * FROM private_rooms WHERE code = ?").bind(code).first<PrivateRoomRow>();
  if (!room || room.expires_at <= Date.now()) {
    return json({ error: "Room code was not found or has expired." }, { status: 404 });
  }

  return json(matchReadyResponse(room.room_id, room.mode, room.region));
}

async function routeRoomRequest(request: Request, env: Env, url: URL): Promise<Response> {
  const [, , , , roomId, action] = url.pathname.split("/");
  if (!roomId) {
    return badRequest("Room id is required.");
  }
  if (action === "socket") {
    const authenticated = await authenticatedPlayerId(request, env);
    const claimed = url.searchParams.get("playerId") ?? "";
    if (!authenticated || authenticated !== claimed) return unauthorized();
  }

  const id = env.LUDO_ROOMS.idFromName(roomId);
  const stub = env.LUDO_ROOMS.get(id);

  const roomUrl = new URL(request.url);
  roomUrl.pathname = action === "socket" ? "/socket" : "/";

  return stub.fetch(new Request(roomUrl, request));
}

async function createRoom(env: Env, roomId: string, mode: GameMode, region: Region, code?: string): Promise<void> {
  const id = env.LUDO_ROOMS.idFromName(roomId);
  const stub = env.LUDO_ROOMS.get(id);

  await stub.fetch("https://room/create", {
    method: "POST",
    body: JSON.stringify({ roomId, mode, region, code }),
    headers: { "content-type": "application/json" }
  });
}

async function ensureMatchmakingUser(
  env: Env,
  playerId: string,
  displayName: string,
  region: Region,
  now: number
): Promise<number> {
  const cleanName = cleanDisplayName(displayName);
  await env.DB.batch([
    env.DB.prepare(
      `INSERT INTO users (id, display_name, region, rating, created_at, last_seen_at)
       VALUES (?, ?, ?, 1000, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
         display_name = excluded.display_name,
         region = excluded.region,
         last_seen_at = excluded.last_seen_at`
    ).bind(playerId, cleanName, region, now, now),
    env.DB.prepare(
      "INSERT INTO wallets (user_id, coins, updated_at) VALUES (?, ?, ?) ON CONFLICT(user_id) DO NOTHING"
    ).bind(playerId, ECONOMY.startingCoins, now)
  ]);
  const user = await env.DB.prepare("SELECT rating FROM users WHERE id = ?")
    .bind(playerId).first<{ rating: number }>();
  return user?.rating ?? 1000;
}

function dedupeByPlayer(tickets: TicketRow[]): TicketRow[] {
  const seen = new Set<string>();
  return tickets.filter((ticket) => {
    if (seen.has(ticket.player_id)) {
      return false;
    }

    seen.add(ticket.player_id);
    return true;
  });
}

async function expireOldTickets(env: Env, now: number): Promise<void> {
  await env.DB.prepare("UPDATE matchmaking_tickets SET status = ?, updated_at = ? WHERE status = ? AND expires_at <= ?")
    .bind("expired", now, "waiting", now)
    .run();
}

async function createUniqueRoomCode(env: Env): Promise<string> {
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const code = createRoomCode();
    const existing = await env.DB.prepare("SELECT code FROM private_rooms WHERE code = ?").bind(code).first();
    if (!existing) {
      return code;
    }
  }

  return createId("code").slice(-6);
}

function matchReadyResponse(roomId: string, mode: GameMode, region: Region, ticketId?: string): Record<string, unknown> {
  return {
    status: "matched",
    ticketId,
    roomId,
    mode,
    region,
    socketUrl: `/api/v1/rooms/${roomId}/socket`
  };
}

function waitingResponse(ticket: TicketRow): Record<string, unknown> {
  return {
    status: "waiting",
    ticketId: ticket.id,
    mode: ticket.mode,
    region: ticket.region,
    expiresAt: ticket.expires_at
  };
}

function cleanDisplayName(displayName?: string): string {
  const cleaned = displayName?.trim().slice(0, 24);
  return cleaned && cleaned.length >= 2 ? cleaned : "Guest";
}

async function requireClaimedPlayer(
  request: Request,
  env: Env,
  claimedPlayerId?: string
): Promise<string | Response> {
  const authenticated = await authenticatedPlayerId(request, env);
  if (!authenticated) return unauthorized();
  if (claimedPlayerId && claimedPlayerId !== authenticated) {
    return unauthorized("The session does not match this player.");
  }
  return authenticated;
}

function isGameMode(value: unknown): value is GameMode {
  return typeof value === "string" && value in MAX_PLAYERS_BY_MODE;
}
