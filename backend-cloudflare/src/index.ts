import { LudoRoom } from "./durable-objects/LudoRoom";
import type { BackgroundJob, Env, GameMode, Region } from "./types";
import { badRequest, json, notFound, readJson } from "./utils/http";
import { createId, createRoomCode } from "./utils/id";

export { LudoRoom };

interface GuestAuthRequest {
  displayName?: string;
  region?: Region;
}

interface MatchmakingRequest {
  playerId: string;
  displayName: string;
  mode: GameMode;
  region?: Region;
  latencyMs?: number;
  rating?: number;
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

const DEFAULT_REGION: Region = "auto";
const MATCH_TICKET_TTL_MS = 45_000;
const PRIVATE_ROOM_TTL_MS = 30 * 60_000;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return json({ ok: true, service: "ludo-rush-backend" });
    }

    try {
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
        return getMatchTicket(env, url);
      }

      if (request.method === "POST" && url.pathname.endsWith("/cancel") && url.pathname.startsWith("/api/v1/matchmaking/tickets/")) {
        return cancelMatchTicket(env, url);
      }

      if (request.method === "POST" && url.pathname === "/api/v1/rooms/private") {
        return createPrivateRoom(request, env);
      }

      if (request.method === "POST" && url.pathname === "/api/v1/rooms/private/join") {
        return joinPrivateRoom(request, env);
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

async function createGuest(request: Request, env: Env): Promise<Response> {
  const body = await readJson<GuestAuthRequest>(request);
  const now = Date.now();
  const userId = createId("usr");
  const displayName = cleanDisplayName(body.displayName);
  const region = body.region ?? DEFAULT_REGION;

  await env.DB.batch([
    env.DB.prepare(
      "INSERT INTO users (id, display_name, region, rating, created_at, last_seen_at) VALUES (?, ?, ?, ?, ?, ?)"
    ).bind(userId, displayName, region, 1000, now, now),
    env.DB.prepare("INSERT INTO wallets (user_id, coins, updated_at) VALUES (?, ?, ?)").bind(userId, 500, now)
  ]);

  return json(
    {
      player: {
        id: userId,
        displayName,
        region,
        rating: 1000,
        coins: 500
      }
    },
    { status: 201 }
  );
}

async function quickMatch(request: Request, env: Env): Promise<Response> {
  const body = await readJson<MatchmakingRequest>(request);
  if (!body.playerId || !body.displayName || !body.mode) {
    return badRequest("playerId, displayName, and mode are required.");
  }

  const now = Date.now();
  const region = body.region ?? DEFAULT_REGION;
  const rating = body.rating ?? 1000;
  await expireOldTickets(env, now);

  const existingTicket = await env.DB.prepare(
    "SELECT * FROM matchmaking_tickets WHERE status = ? AND mode = ? AND region = ? AND player_id <> ? ORDER BY requested_at ASC LIMIT 1"
  ).bind("waiting", body.mode, region, body.playerId).first<TicketRow>();

  if (existingTicket) {
    const roomId = createId("room");
    await createRoom(env, roomId, body.mode, region);
    await env.DB.batch([
      env.DB.prepare("UPDATE matchmaking_tickets SET status = ?, room_id = ?, updated_at = ? WHERE id = ?")
        .bind("matched", roomId, now, existingTicket.id),
      env.DB.prepare(
        "INSERT INTO matchmaking_tickets (id, player_id, display_name, mode, region, rating, latency_ms, status, room_id, requested_at, updated_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
      ).bind(createId("ticket"), body.playerId, body.displayName, body.mode, region, rating, body.latencyMs ?? null, "matched", roomId, now, now, now + MATCH_TICKET_TTL_MS)
    ]);

    return json(matchReadyResponse(roomId, body.mode, region));
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
  if (!body.playerId || !body.displayName || !body.mode) {
    return badRequest("playerId, displayName, and mode are required.");
  }

  const region = body.region ?? DEFAULT_REGION;
  const roomId = createId("room");
  await createRoom(env, roomId, body.mode, region);

  return json(matchReadyResponse(roomId, body.mode, region));
}

async function getMatchTicket(env: Env, url: URL): Promise<Response> {
  const ticketId = url.pathname.split("/").at(-1);
  if (!ticketId) {
    return badRequest("Ticket id is required.");
  }

  const now = Date.now();
  const ticket = await env.DB.prepare("SELECT * FROM matchmaking_tickets WHERE id = ?").bind(ticketId).first<TicketRow>();
  if (!ticket) {
    return notFound();
  }

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

async function cancelMatchTicket(env: Env, url: URL): Promise<Response> {
  const parts = url.pathname.split("/");
  const ticketId = parts.at(-2);
  if (!ticketId) {
    return badRequest("Ticket id is required.");
  }

  await env.DB.prepare("UPDATE matchmaking_tickets SET status = ?, updated_at = ? WHERE id = ? AND status = ?")
    .bind("cancelled", Date.now(), ticketId, "waiting")
    .run();

  return json({ status: "cancelled", ticketId });
}

async function createPrivateRoom(request: Request, env: Env): Promise<Response> {
  const body = await readJson<CreatePrivateRoomRequest>(request);
  if (!body.playerId || !body.displayName || !body.mode) {
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
  if (!body.playerId || !body.displayName || !body.code) {
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
