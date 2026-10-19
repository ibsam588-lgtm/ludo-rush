import { DurableObject } from "cloudflare:workers";
import { matchRewardStatements } from "../game/rewards";
import {
  TURN_DURATION_MS,
  applyMove,
  applyRoll,
  chooseBotMove,
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
  spectator?: boolean;
  voiceJoined?: boolean;
  joinedAt: number;
}

interface CreateRoomRequest {
  roomId: string;
  expectedPlayerIds?: string[];
  code?: string;
  mode: GameMode;
  region: Region;
}

const SNAPSHOT_KEY = "snapshot";
const MATCH_STARTED_KEY = "match_started";
const MATCH_FINISHED_KEY = "match_finished";
const BOT_ROLL_DELAY_MS = 850;
const BOT_MOVE_DELAY_MS = 700;
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
    if (message.length > 24_000) {
      this.send(ws, { type: "error", code: "message_too_large", message: "Room message is too large." });
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

      if (parsed.type === "spectate") {
        await this.handleSpectate(ws, parsed.playerId, parsed.displayName);
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
        this.handleVoiceLeave(ws);
        await this.handleResign(this.requireActor(ws, parsed.playerId));
        return;
      }

      if (parsed.type === "reaction") {
        await this.handleReaction(ws, parsed.text, parsed.isEmoji !== false);
        return;
      }

      if (parsed.type === "voice_join") {
        await this.handleVoiceJoin(ws);
        return;
      }

      if (parsed.type === "voice_leave") {
        this.handleVoiceLeave(ws);
        return;
      }

      if (parsed.type === "voice_signal") {
        await this.handleVoiceSignal(ws, parsed.toPlayerId, parsed.signal);
        return;
      }

      if (parsed.type === "heartbeat") {
        this.send(ws, { type: "snapshot", snapshot: await this.getSnapshot() });
      }
    } catch (error) {
      this.send(ws, {
        type: "error",
        code: parsed.type.startsWith("voice_") ? "voice_error" : "room_error",
        message: error instanceof Error ? error.message : "Unknown room error."
      });
    }
  }

  async webSocketClose(ws: WebSocket): Promise<void> {
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    if (!attachment?.playerId || attachment.spectator) {
      return;
    }

    // Closing an old socket must not disconnect a newer connection for the
    // same player (for example after a mobile network handoff).
    if (this.ctx.getWebSockets().some(other => other !== ws && other.readyState === 1 &&
        (other.deserializeAttachment() as ConnectionAttachment | undefined)?.playerId === attachment.playerId)) return;

    let snapshot: RoomSnapshot;
    try {
      snapshot = await this.getSnapshot();
    } catch {
      return;
    }

    if (attachment.voiceJoined) this.broadcastVoiceState(ws);

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
      expectedPlayerIds: body.expectedPlayerIds,
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
    const spectator = url.searchParams.get("spectator") === "1";

    this.ctx.acceptWebSocket(server);
    server.serializeAttachment({
      playerId,
      displayName,
      spectator,
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
    let updated = upsertSeat(before, { playerId, displayName });
    if (updated.status === "waiting" && !updated.code &&
      (!updated.expectedPlayerIds || updated.expectedPlayerIds.every(id =>
        updated.seats.some(seat => seat.playerId === id)))) {
      updated = fillBotSeats(updated);
    }

    ws.serializeAttachment({
      playerId,
      displayName,
      voiceJoined: attachment?.voiceJoined,
      joinedAt: Date.now()
    } satisfies ConnectionAttachment);

    await this.saveSnapshot(updated);
    await this.persistMatchStartIfNeeded(before, updated);
    this.broadcast({ type: "snapshot", snapshot: updated });
    await this.playBotsIfNeeded();
  }

  private async handleSpectate(ws: WebSocket, playerId: string, displayName: string): Promise<void> {
    ws.serializeAttachment({
      playerId,
      displayName,
      spectator: true,
      joinedAt: Date.now()
    } satisfies ConnectionAttachment);
    this.send(ws, { type: "snapshot", snapshot: await this.getSnapshot() });
  }

  private requireActor(ws: WebSocket, claimedPlayerId: string): string {
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    const actor = attachment?.playerId;
    if (!actor || attachment?.spectator) {
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
    if (before.code && (before.seats[0]?.playerId !== attachment.playerId ||
        before.seats.filter(seat => !seat.isBot).length < 2)) {
      throw new Error("The host can start a private table with bots after two players join.");
    }

    const updated = fillBotSeats(before, !!before.code);

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

  private async handleVoiceJoin(ws: WebSocket): Promise<void> {
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    const actor = attachment?.playerId;
    const snapshot = await this.getSnapshot();
    const seat = snapshot.seats.find(roomSeat => roomSeat.playerId === actor);
    if (!actor || attachment?.spectator || !seat || seat.isBot || !seat.connected || snapshot.status !== "playing") {
      throw new Error("Only active human players can join match voice chat.");
    }
    const profile = await this.env.DB.prepare("SELECT age FROM users WHERE id = ?")
      .bind(actor).first<{ age: number }>();
    if ((profile?.age ?? 0) < 13) throw new Error("Voice chat is available to players age 13 or older.");
    ws.serializeAttachment({ ...attachment, voiceJoined: true });
    this.broadcastVoiceState();
  }

  private handleVoiceLeave(ws: WebSocket): void {
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    if (!attachment?.voiceJoined) return;
    ws.serializeAttachment({ ...attachment, voiceJoined: false });
    this.broadcastVoiceState();
  }

  private async handleVoiceSignal(ws: WebSocket, toPlayerId: string,
    signal: { type: "offer" | "answer" | "candidate"; sdp?: string; candidate?: string; sdpMid?: string; sdpMLineIndex?: number }): Promise<void> {
    const attachment = ws.deserializeAttachment() as ConnectionAttachment | undefined;
    const actor = attachment?.playerId;
    const snapshot = await this.getSnapshot();
    if (!actor || !attachment?.voiceJoined || snapshot.status !== "playing" ||
      !snapshot.seats.some(seat => seat.playerId === actor && !seat.isBot)) return;
    if (!signal || !["offer", "answer", "candidate"].includes(signal.type) ||
      (signal.type === "candidate" ? typeof signal.candidate !== "string" || signal.candidate.length > 4_096 :
        typeof signal.sdp !== "string" || signal.sdp.length > 20_000)) return;
    if (!snapshot.seats.some(seat => seat.playerId === toPlayerId && !seat.isBot)) return;
    const recipient = this.ctx.getWebSockets().find(peer => peer.readyState === 1 &&
      (peer.deserializeAttachment() as ConnectionAttachment | undefined)?.playerId === toPlayerId &&
      (peer.deserializeAttachment() as ConnectionAttachment | undefined)?.voiceJoined);
    if (recipient) this.send(recipient, { type: "voice_signal", fromPlayerId: actor, signal });
  }

  private broadcastVoiceState(excluded?: WebSocket): void {
    const playerIds = [...new Set(this.ctx.getWebSockets()
      .filter(ws => ws !== excluded && ws.readyState === 1)
      .map(ws => ws.deserializeAttachment() as ConnectionAttachment | undefined)
      .filter((attachment): attachment is ConnectionAttachment => !!attachment?.voiceJoined && !attachment.spectator &&
        !!attachment.playerId && !!this.snapshot?.seats.some(seat => seat.playerId === attachment.playerId && !seat.isBot))
      .map(attachment => attachment.playerId!))];
    this.broadcast({ type: "voice_state", playerIds });
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
      await this.playBotAction(snapshot);
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

    if (timedOutSeat && !timedOutSeat.isBot &&
        result.snapshot.seats.some(seat => seat.playerId === timedOutSeat.playerId && seat.isBot)) {
      this.broadcastVoiceState();
    }

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
      ? now + (snapshot.diceValue === undefined ? BOT_ROLL_DELAY_MS : BOT_MOVE_DELAY_MS) + Math.floor(Math.random() * 450)
      : (snapshot.turnDeadlineAt ?? now + TURN_DURATION_MS[snapshot.mode]) + TURN_TIMEOUT_GRACE_MS;
    await this.ctx.storage.setAlarm(target);
  }

  private async playBotsIfNeeded(): Promise<void> {
    // The alarm drives one action at a time so rolls, choices, and moves are
    // visible to players instead of an entire bot turn flashing by at once.
    await this.scheduleTurnAlarm(await this.getSnapshot());
  }

  private async playBotAction(snapshot: RoomSnapshot): Promise<void> {
    const botSeat = getCurrentSeat(snapshot);
    if (!botSeat?.isBot) return;
    if (snapshot.diceValue === undefined) {
      const value = rollDice();
      const result = applyRoll(snapshot, botSeat.playerId, value);
      await this.saveSnapshot(result.snapshot);
      this.broadcast({ type: "dice_rolled", playerId: botSeat.playerId, value, snapshot: result.snapshot });
      if (result.skipped) this.broadcast({ type: "turn_skipped", playerId: botSeat.playerId,
        reason: "no_legal_moves", snapshot: result.snapshot });
      return;
    }
    const pieceId = chooseBotMove(snapshot);
    if (!pieceId) return;
    const result = applyMove(snapshot, botSeat.playerId, pieceId);
    await this.saveSnapshot(result.snapshot);
    if (result.finished && result.snapshot.winnerPlayerId) {
      await this.persistMatchFinishedIfNeeded(result.snapshot);
      this.broadcast({ type: "match_finished", winnerPlayerId: result.snapshot.winnerPlayerId, snapshot: result.snapshot });
      return;
    }
    this.broadcast({ type: "move_accepted", playerId: botSeat.playerId, pieceId,
      capturedPieceIds: result.capturedPieceIds, snapshot: result.snapshot });
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

    const winnerSeat = snapshot.seats.find((seat) => seat.playerId === snapshot.winnerPlayerId);
    // A bot can be broadcast as the on-screen winner (e.g. the last human
    // resigned), but bot ids must never be persisted as winning users.
    const winnerUserId = winnerSeat && isHumanSeat(winnerSeat) && !winnerSeat.isBot ? winnerSeat.playerId : null;

    const statements = [
      this.env.DB.prepare("UPDATE matches SET status = ?, winner_user_id = ?, ended_at = ? WHERE id = ?")
        .bind("finished", winnerUserId, snapshot.updatedAt, snapshot.roomId)
    ];

    statements.push(...matchRewardStatements(this.env.DB, snapshot));

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
