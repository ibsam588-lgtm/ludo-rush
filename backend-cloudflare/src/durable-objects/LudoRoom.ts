import { DurableObject } from "cloudflare:workers";
import { ECONOMY } from "../economy";
import {
  TURN_DURATION_MS,
  applyMove,
  applyRoll,
  chooseBotMove,
  computeFinishRanks,
  createInitialSnapshot,
  fillBotSeats,
  getCurrentSeat,
  isBotTurn,
  markDisconnected,
  resignPlayer,
  rollDice,
  timeoutTurn,
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
const BOT_CONTINUE_DELAY_MS = 250;
const TURN_TIMEOUT_GRACE_MS = 1_000;
const MAX_REACTION_LENGTH = 120;

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

    try {
      if (parsed.type === "join") {
        await this.handleJoin(ws, parsed.playerId, parsed.displayName);
        return;
      }

      if (parsed.type === "roll_dice") {
        await this.handleRoll(ws, this.requireActor(ws, parsed.playerId));
        return;
      }

      if (parsed.type === "move_piece") {
        await this.handleMove(ws, this.requireActor(ws, parsed.playerId), parsed.pieceId);
        return;
      }

      if (parsed.type === "fill_bots") {
        await this.handleFillBots(ws);
        return;
      }

      if (parsed.type === "resign") {
        await this.handleResign(this.requireActor(ws, parsed.playerId));
        return;
      }

      if (parsed.type === "reaction") {
        await this.handleReaction(ws, parsed.text, parsed.isEmoji !== false);
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

    let snapshot: RoomSnapshot;
    try {
      snapshot = await this.getSnapshot();
    } catch {
      return;
    }

    const updated = markDisconnected(snapshot, attachment.playerId);
    await this.saveSnapshot(updated);
    this.broadcast({ type: "snapshot", snapshot: updated });
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
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);

    const url = new URL(request.url);
    const playerId = url.searchParams.get("playerId") ?? undefined;
    const displayName = url.searchParams.get("displayName") ?? undefined;

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

  private async handleJoin(ws: WebSocket, playerId: string, displayName: string): Promise<void> {
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    if (attachment?.playerId && attachment.playerId !== playerId) {
      throw new Error("This connection already belongs to another player.");
    }

    const before = await this.getSnapshot();
    const updated = upsertSeat(before, { playerId, displayName });

    ws.serializeAttachment({
      playerId,
      displayName,
      joinedAt: Date.now()
    } satisfies ConnectionAttachment);

    await this.saveSnapshot(updated);
    await this.persistMatchStartIfNeeded(before, updated);
    this.broadcast({ type: "snapshot", snapshot: updated });
    await this.playBotsIfNeeded();
  }

  private requireActor(ws: WebSocket, claimedPlayerId: string): string {
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    const actor = attachment?.playerId;
    if (!actor) {
      throw new Error("Join the room before playing.");
    }

    if (claimedPlayerId && claimedPlayerId !== actor) {
      throw new Error("You can only act as yourself.");
    }

    return actor;
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

    this.broadcast({
      type: "move_accepted",
      playerId,
      pieceId,
      capturedPieceIds: result.capturedPieceIds,
      snapshot: result.snapshot
    });
    await this.playBotsIfNeeded();
  }

  private async handleFillBots(ws: WebSocket): Promise<void> {
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    const before = await this.getSnapshot();
    if (!attachment?.playerId || !before.seats.some((seat) => seat.playerId === attachment.playerId)) {
      throw new Error("Join the room before adding bots.");
    }

    const updated = fillBotSeats(before);

    await this.saveSnapshot(updated);
    await this.persistMatchStartIfNeeded(before, updated);
    this.broadcast({ type: "bots_filled", snapshot: updated });
    await this.playBotsIfNeeded();
  }

  private async handleReaction(ws: WebSocket, rawText: string, isEmoji: boolean): Promise<void> {
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    const actor = attachment?.playerId;
    if (!actor) {
      throw new Error("Join the room before sending reactions.");
    }

    const snapshot = await this.getSnapshot();
    const seat = snapshot.seats.find((roomSeat) => roomSeat.playerId === actor);
    if (!seat) {
      throw new Error("Only seated players can send reactions.");
    }

    if (!isEmoji) {
      const profile = await this.env.DB.prepare("SELECT age FROM users WHERE id = ?")
        .bind(actor)
        .first<{ age: number }>();
      if ((profile?.age ?? 0) < 13) {
        throw new Error("Table chat is only available to players age 13 or older.");
      }
    }

    const text = (rawText ?? "").trim().slice(0, MAX_REACTION_LENGTH);
    if (!text) {
      return;
    }

    this.broadcast({ type: "reaction", playerId: actor, displayName: seat.displayName, text, isEmoji });
  }

  private async handleResign(playerId: string): Promise<void> {
    const snapshot = await this.getSnapshot();
    const updated = resignPlayer(snapshot, playerId);

    await this.saveSnapshot(updated);
    if (updated.status === "finished" && snapshot.status !== "finished" && updated.winnerPlayerId) {
      await this.persistMatchFinishedIfNeeded(updated);
      this.broadcast({ type: "match_finished", winnerPlayerId: updated.winnerPlayerId, snapshot: updated });
      return;
    }

    this.broadcast({ type: "snapshot", snapshot: updated });
    await this.playBotsIfNeeded();
  }

  async alarm(): Promise<void> {
    let snapshot: RoomSnapshot;
    try {
      snapshot = await this.getSnapshot();
    } catch {
      return;
    }

    if (snapshot.status !== "playing") {
      return;
    }

    if (isBotTurn(snapshot)) {
      // A bot chain hit MAX_BOT_ACTIONS_PER_TICK (or a resigned seat gained the
      // turn with no client message in flight) — continue it here.
      await this.playBotsIfNeeded();
      return;
    }

    const deadline = snapshot.turnDeadlineAt;
    const now = Date.now();
    if (deadline === undefined || now < deadline) {
      await this.scheduleTurnAlarm(snapshot);
      return;
    }

    const timedOutSeat = getCurrentSeat(snapshot);
    const result = timeoutTurn(snapshot, now);
    if (!result.timedOut) {
      await this.scheduleTurnAlarm(snapshot);
      return;
    }

    await this.saveSnapshot(result.snapshot);

    if (result.snapshot.status === "finished" && result.snapshot.winnerPlayerId) {
      await this.persistMatchFinishedIfNeeded(result.snapshot);
      this.broadcast({
        type: "match_finished",
        winnerPlayerId: result.snapshot.winnerPlayerId,
        snapshot: result.snapshot
      });
      return;
    }

    if (result.movedPieceId && timedOutSeat) {
      this.broadcast({
        type: "move_accepted",
        playerId: timedOutSeat.playerId,
        pieceId: result.movedPieceId,
        capturedPieceIds: result.capturedPieceIds ?? [],
        snapshot: result.snapshot
      });
    } else {
      this.broadcast({
        type: "turn_skipped",
        playerId: timedOutSeat?.playerId ?? "",
        reason: "turn_timeout",
        snapshot: result.snapshot
      });
    }

    await this.playBotsIfNeeded();
  }

  private async scheduleTurnAlarm(snapshot: RoomSnapshot): Promise<void> {
    if (snapshot.status !== "playing") {
      await this.ctx.storage.deleteAlarm();
      return;
    }

    const now = Date.now();
    const target = isBotTurn(snapshot)
      ? now + BOT_CONTINUE_DELAY_MS
      : (snapshot.turnDeadlineAt ?? now + TURN_DURATION_MS[snapshot.mode]) + TURN_TIMEOUT_GRACE_MS;
    await this.ctx.storage.setAlarm(target);
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

      this.broadcast({
        type: "move_accepted",
        playerId: botSeat.playerId,
        pieceId,
        capturedPieceIds: moveResult.capturedPieceIds,
        snapshot: moveResult.snapshot
      });
      snapshot = moveResult.snapshot;
      actions += 1;
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
    const winnerSeat = snapshot.seats.find((seat) => seat.playerId === snapshot.winnerPlayerId);
    // A bot can be broadcast as the on-screen winner (e.g. the last human
    // resigned), but bot ids must never be persisted as winning users.
    const winnerUserId = winnerSeat && isHumanSeat(winnerSeat) ? winnerSeat.playerId : null;
    const ranks = computeFinishRanks(snapshot);

    const statements = [
      this.env.DB.prepare("UPDATE matches SET status = ?, winner_user_id = ?, ended_at = ? WHERE id = ?")
        .bind("finished", winnerUserId, snapshot.updatedAt, snapshot.roomId)
    ];

    for (const seat of humanSeats) {
      const won = seat.playerId === snapshot.winnerPlayerId;
      const coinsDelta = won
        ? ECONOMY.onlineWinCoins
        : ECONOMY.onlineFinishCoins;
      const clubContribution = won
        ? ECONOMY.clubWinContribution
        : ECONOMY.clubFinishContribution;
      const ratingDelta = won ? 12 : -6;
      const finishRank = seat.finishRank ?? ranks.get(seat.playerId) ?? (won ? 1 : snapshot.seats.length);

      statements.push(
        this.env.DB.prepare(
          "UPDATE match_players SET finish_rank = ?, rating_delta = ?, coins_delta = ? WHERE match_id = ? AND user_id = ?"
        ).bind(finishRank, ratingDelta, coinsDelta, snapshot.roomId, seat.playerId),
        this.env.DB.prepare(
          "INSERT INTO wallets (user_id, coins, updated_at) VALUES (?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET coins = coins + ?, updated_at = ?"
        ).bind(seat.playerId, coinsDelta, snapshot.updatedAt, coinsDelta, snapshot.updatedAt),
        this.env.DB.prepare("UPDATE users SET rating = rating + ?, last_seen_at = ? WHERE id = ?")
          .bind(ratingDelta, snapshot.updatedAt, seat.playerId),
        this.env.DB.prepare(
          "UPDATE club_members SET contribution = contribution + ? WHERE user_id = ?"
        ).bind(clubContribution, seat.playerId)
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
    await this.scheduleTurnAlarm(snapshot);
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
  // Seats filled by fillBotSeats always carry a "bot_" playerId. A human whose
  // seat was handed to a bot (resign or repeated turn timeouts) keeps their own
  // playerId and must still receive result/reward persistence.
  return !seat.playerId.startsWith("bot_");
}
