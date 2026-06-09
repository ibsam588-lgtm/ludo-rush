import { DurableObject } from "cloudflare:workers";
import {
  advanceTurn,
  applyMove,
  applyRoll,
  chooseBotMove,
  convertSeatToBot,
  createInitialSnapshot,
  fillBotSeats,
  getCurrentSeat,
  isBotTurn,
  markDisconnected,
  resignPlayer,
  rollDice,
  upsertSeat
} from "../game/rules";
import type { ClientRoomMessage, Env, GameMode, Region, RoomSnapshot, RoomSeat, ServerRoomMessage } from "../types";

interface ConnectionAttachment {
  playerId?: string;
  displayName?: string;
  joinedAt: number;
}

interface CreateRoomRequest {
  roomId: string;
  code?: string;
  mode: GameMode;
  region: Region;
}

const SNAPSHOT_KEY = "snapshot";
const MATCH_STARTED_KEY = "match_started";
const MATCH_FINISHED_KEY = "match_finished";
const MAX_BOT_ACTIONS_PER_TICK = 24;
const BOT_CONTINUATION_DELAY_MS = 1_000;

export class LudoRoom extends DurableObject<Env> {
  private snapshot?: RoomSnapshot;

  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "POST" && url.pathname.endsWith("/create")) {
      return this.createRoom(request);
    }

    if (request.headers.get("upgrade") === "websocket") {
      return this.acceptClient(request);
    }

    if (request.method === "GET") {
      const snapshot = await this.getSnapshot();
      return Response.json(snapshot);
    }

    return Response.json({ error: "Unsupported room request" }, { status: 405 });
  }

  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer): Promise<void> {
    if (typeof message !== "string") {
      this.send(ws, { type: "error", code: "binary_not_supported", message: "Binary messages are not supported yet." });
      return;
    }

    let parsed: ClientRoomMessage;
    try {
      parsed = JSON.parse(message) as ClientRoomMessage;
    } catch {
      this.send(ws, { type: "error", code: "invalid_json", message: "Message must be valid JSON." });
      return;
    }

    // Never trust the playerId inside the message body — use the identity
    // that was authenticated when the socket was accepted.
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    const playerId = attachment?.playerId;
    if (!playerId) {
      this.send(ws, { type: "error", code: "not_authenticated", message: "Connection is not authenticated." });
      return;
    }

    try {
      if (parsed.type === "join") {
        await this.handleJoin(ws, playerId, attachment?.displayName ?? parsed.displayName);
        return;
      }

      if (parsed.type === "roll_dice") {
        await this.handleRoll(ws, playerId);
        return;
      }

      if (parsed.type === "move_piece") {
        await this.handleMove(ws, playerId, parsed.pieceId);
        return;
      }

      if (parsed.type === "fill_bots") {
        await this.handleFillBots();
        return;
      }

      if (parsed.type === "resign") {
        await this.handleResign(playerId);
        return;
      }

      if (parsed.type === "heartbeat") {
        this.send(ws, { type: "snapshot", snapshot: await this.getSnapshot() });
      }
    } catch (error) {
      this.send(ws, {
        type: "error",
        code: "room_error",
        message: error instanceof Error ? error.message : "Unknown room error."
      });
    }
  }

  async webSocketClose(ws: WebSocket): Promise<void> {
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    if (!attachment?.playerId) {
      return;
    }

    const snapshot = await this.getSnapshot().catch(() => undefined);
    if (!snapshot || snapshot.status === "finished") {
      return;
    }

    let updated = markDisconnected(snapshot, attachment.playerId);

    if (updated.status === "playing") {
      // Hand the seat to the bot AI so the remaining players are not stalled.
      updated = convertSeatToBot(updated, attachment.playerId);

      const humansRemain = updated.seats.some((seat) => !seat.isBot && seat.connected);
      if (!humansRemain) {
        updated = { ...updated, status: "finished", updatedAt: Date.now() };
        await this.saveSnapshot(updated);
        await this.env.DB.prepare("UPDATE matches SET status = ?, ended_at = ? WHERE id = ? AND status = ?")
          .bind("abandoned", Date.now(), updated.roomId, "playing")
          .run();
        return;
      }
    }

    await this.saveSnapshot(updated);
    this.broadcast({ type: "snapshot", snapshot: updated });
    await this.playBotsIfNeeded();
  }

  async alarm(): Promise<void> {
    const snapshot = await this.getSnapshot().catch(() => undefined);
    if (!snapshot || snapshot.status !== "playing") {
      return;
    }

    const now = Date.now();
    if (snapshot.turnDeadlineAt !== undefined && snapshot.turnDeadlineAt <= now) {
      const timedOutSeat = getCurrentSeat(snapshot);
      const skipped = advanceTurn(snapshot, now);
      await this.saveSnapshot(skipped);
      this.broadcast({
        type: "turn_skipped",
        playerId: timedOutSeat?.playerId ?? "",
        reason: "turn_timeout",
        snapshot: skipped
      });
    }

    await this.playBotsIfNeeded();
  }

  private async createRoom(request: Request): Promise<Response> {
    const body = (await request.json()) as CreateRoomRequest;
    const existing = await this.ctx.storage.get<RoomSnapshot>(SNAPSHOT_KEY);

    if (existing) {
      return Response.json(existing);
    }

    const snapshot = createInitialSnapshot({
      roomId: body.roomId,
      code: body.code,
      mode: body.mode,
      region: body.region,
      now: Date.now()
    });

    await this.saveSnapshot(snapshot);
    return Response.json(snapshot, { status: 201 });
  }

  private async acceptClient(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const playerId = url.searchParams.get("playerId") ?? undefined;
    const displayName = url.searchParams.get("displayName") ?? undefined;
    const token = url.searchParams.get("token") ?? undefined;

    if (!playerId || !token || !(await this.isValidToken(playerId, token))) {
      return Response.json({ error: "Invalid player credentials." }, { status: 401 });
    }

    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);

    this.ctx.acceptWebSocket(server);
    server.serializeAttachment({
      playerId,
      displayName,
      joinedAt: Date.now()
    } satisfies ConnectionAttachment);

    this.send(server, { type: "snapshot", snapshot: await this.getSnapshot() });

    return new Response(null, {
      status: 101,
      webSocket: client
    });
  }

  private async isValidToken(playerId: string, token: string): Promise<boolean> {
    const row = await this.env.DB.prepare("SELECT auth_token FROM users WHERE id = ?")
      .bind(playerId)
      .first<{ auth_token: string | null }>();
    return row?.auth_token != null && row.auth_token === token;
  }

  private async handleJoin(ws: WebSocket, playerId: string, displayName?: string): Promise<void> {
    const before = await this.getSnapshot();
    const updated = upsertSeat(before, { playerId, displayName: displayName ?? "Player" });

    await this.saveSnapshot(updated);
    await this.persistMatchStartIfNeeded(before, updated);
    this.broadcast({ type: "snapshot", snapshot: updated });
    await this.playBotsIfNeeded();
  }

  private async handleRoll(ws: WebSocket, playerId: string): Promise<void> {
    const snapshot = await this.getSnapshot();
    const value = rollDice();
    const result = applyRoll(snapshot, playerId, value);

    await this.saveSnapshot(result.snapshot);
    this.broadcast({ type: "dice_rolled", playerId, value, snapshot: result.snapshot });

    if (result.skipped) {
      this.broadcast({ type: "turn_skipped", playerId, reason: "no_legal_moves", snapshot: result.snapshot });
      await this.playBotsIfNeeded();
    }
  }

  private async handleMove(ws: WebSocket, playerId: string, pieceId: string): Promise<void> {
    const snapshot = await this.getSnapshot();
    const result = applyMove(snapshot, playerId, pieceId);

    await this.saveSnapshot(result.snapshot);

    if (result.finished && result.snapshot.winnerPlayerId) {
      await this.persistMatchFinishedIfNeeded(result.snapshot);
      this.broadcast({ type: "match_finished", winnerPlayerId: result.snapshot.winnerPlayerId, snapshot: result.snapshot });
      return;
    }

    this.broadcast({ type: "move_accepted", playerId, pieceId, snapshot: result.snapshot });
    await this.playBotsIfNeeded();
  }

  private async handleFillBots(): Promise<void> {
    const before = await this.getSnapshot();
    const updated = fillBotSeats(before);

    await this.saveSnapshot(updated);
    await this.persistMatchStartIfNeeded(before, updated);
    this.broadcast({ type: "bots_filled", snapshot: updated });
    await this.playBotsIfNeeded();
  }

  private async handleResign(playerId: string): Promise<void> {
    const snapshot = await this.getSnapshot();
    if (snapshot.status !== "playing") {
      return;
    }

    const updated = resignPlayer(snapshot, playerId);

    await this.saveSnapshot(updated);
    if (updated.status === "finished" && updated.winnerPlayerId) {
      await this.persistMatchFinishedIfNeeded(updated);
      this.broadcast({ type: "match_finished", winnerPlayerId: updated.winnerPlayerId, snapshot: updated });
      return;
    }

    this.broadcast({ type: "snapshot", snapshot: updated });
    await this.playBotsIfNeeded();
  }

  private async playBotsIfNeeded(): Promise<void> {
    let snapshot = await this.getSnapshot();
    let actions = 0;

    while (isBotTurn(snapshot) && snapshot.status === "playing" && actions < MAX_BOT_ACTIONS_PER_TICK) {
      const botSeat = getCurrentSeat(snapshot);
      if (!botSeat) {
        return;
      }

      const value = rollDice();
      const rollResult = applyRoll(snapshot, botSeat.playerId, value);
      await this.saveSnapshot(rollResult.snapshot);
      this.broadcast({ type: "dice_rolled", playerId: botSeat.playerId, value, snapshot: rollResult.snapshot });
      actions += 1;

      if (rollResult.skipped) {
        this.broadcast({ type: "turn_skipped", playerId: botSeat.playerId, reason: "no_legal_moves", snapshot: rollResult.snapshot });
        snapshot = rollResult.snapshot;
        continue;
      }

      const pieceId = chooseBotMove(rollResult.snapshot);
      if (!pieceId) {
        snapshot = rollResult.snapshot;
        break;
      }

      const moveResult = applyMove(rollResult.snapshot, botSeat.playerId, pieceId);
      await this.saveSnapshot(moveResult.snapshot);

      if (moveResult.finished && moveResult.snapshot.winnerPlayerId) {
        await this.persistMatchFinishedIfNeeded(moveResult.snapshot);
        this.broadcast({
          type: "match_finished",
          winnerPlayerId: moveResult.snapshot.winnerPlayerId,
          snapshot: moveResult.snapshot
        });
        return;
      }

      this.broadcast({ type: "move_accepted", playerId: botSeat.playerId, pieceId, snapshot: moveResult.snapshot });
      snapshot = moveResult.snapshot;
      actions += 1;
    }

    // If we hit the per-tick action cap with a bot still to move (e.g. an
    // all-bot room after every human disconnected), schedule a continuation
    // so the match always progresses to completion.
    if (isBotTurn(snapshot) && snapshot.status === "playing") {
      await this.ctx.storage.setAlarm(Date.now() + BOT_CONTINUATION_DELAY_MS);
    }
  }

  private async persistMatchStartIfNeeded(before: RoomSnapshot, after: RoomSnapshot): Promise<void> {
    if (before.status === "playing" || after.status !== "playing") {
      return;
    }

    const alreadyStarted = await this.ctx.storage.get<boolean>(MATCH_STARTED_KEY);
    if (alreadyStarted) {
      return;
    }

    await this.env.DB.batch([
      this.env.DB.prepare(
        "INSERT OR IGNORE INTO matches (id, mode, region, status, started_at) VALUES (?, ?, ?, ?, ?)"
      ).bind(after.roomId, after.mode, after.region, "playing", after.updatedAt),
      ...after.seats.filter(isHumanSeat).map((seat) =>
        this.env.DB.prepare("INSERT OR IGNORE INTO match_players (match_id, user_id, seat) VALUES (?, ?, ?)")
          .bind(after.roomId, seat.playerId, seat.seat)
      )
    ]);

    await this.ctx.storage.put(MATCH_STARTED_KEY, true);
  }

  private async persistMatchFinishedIfNeeded(snapshot: RoomSnapshot): Promise<void> {
    const alreadyFinished = await this.ctx.storage.get<boolean>(MATCH_FINISHED_KEY);
    if (alreadyFinished || !snapshot.winnerPlayerId) {
      return;
    }

    const humanSeats = snapshot.seats.filter(isHumanSeat);
    const statements = [
      this.env.DB.prepare("UPDATE matches SET status = ?, winner_user_id = ?, ended_at = ? WHERE id = ?")
        .bind("finished", snapshot.winnerPlayerId, snapshot.updatedAt, snapshot.roomId)
    ];

    for (const seat of humanSeats) {
      const won = seat.playerId === snapshot.winnerPlayerId;
      const coinsDelta = won ? 100 : 15;
      const ratingDelta = won ? 12 : -6;

      statements.push(
        this.env.DB.prepare(
          "UPDATE match_players SET finish_rank = ?, rating_delta = ?, coins_delta = ? WHERE match_id = ? AND user_id = ?"
        ).bind(won ? 1 : 2, ratingDelta, coinsDelta, snapshot.roomId, seat.playerId),
        this.env.DB.prepare(
          "INSERT INTO wallets (user_id, coins, updated_at) VALUES (?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET coins = coins + ?, updated_at = ?"
        ).bind(seat.playerId, coinsDelta, snapshot.updatedAt, coinsDelta, snapshot.updatedAt),
        this.env.DB.prepare("UPDATE users SET rating = MAX(0, rating + ?), last_seen_at = ? WHERE id = ?")
          .bind(ratingDelta, snapshot.updatedAt, seat.playerId)
      );
    }

    await this.env.DB.batch(statements);
    await this.ctx.storage.put(MATCH_FINISHED_KEY, true);
    await this.env.BACKGROUND_QUEUE.send({ type: "settle_match", matchId: snapshot.roomId });
  }

  private async getSnapshot(): Promise<RoomSnapshot> {
    if (this.snapshot) {
      return this.snapshot;
    }

    const stored = await this.ctx.storage.get<RoomSnapshot>(SNAPSHOT_KEY);
    if (!stored) {
      throw new Error("Room has not been created.");
    }

    this.snapshot = stored;
    return stored;
  }

  private async saveSnapshot(snapshot: RoomSnapshot): Promise<void> {
    this.snapshot = snapshot;
    await this.ctx.storage.put(SNAPSHOT_KEY, snapshot);

    // Keep an alarm armed for the turn deadline so AFK or disconnected
    // players can never stall a live match.
    if (snapshot.status === "playing" && snapshot.turnDeadlineAt !== undefined) {
      await this.ctx.storage.setAlarm(snapshot.turnDeadlineAt);
    } else if (snapshot.status === "finished") {
      await this.ctx.storage.deleteAlarm();
    }
  }

  private broadcast(message: ServerRoomMessage): void {
    const payload = JSON.stringify(message);
    for (const ws of this.ctx.getWebSockets()) {
      ws.send(payload);
    }
  }

  private send(ws: WebSocket, message: ServerRoomMessage): void {
    ws.send(JSON.stringify(message));
  }
}

function isHumanSeat(seat: RoomSeat): boolean {
  return !seat.isBot && !seat.playerId.startsWith("bot_");
}
