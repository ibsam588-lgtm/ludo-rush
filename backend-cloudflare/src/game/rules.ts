import type { GameMode, LudoPiece, RoomSeat, RoomSnapshot } from "../types";

export const MAX_PLAYERS_BY_MODE: Record<GameMode, number> = {
  classic_2p: 2,
  classic_3p: 3,
  classic_4p: 4,
  rush_2p: 2,
  rush_4p: 4
};

export const TURN_DURATION_MS: Record<GameMode, number> = {
  classic_2p: 30_000,
  classic_3p: 30_000,
  classic_4p: 30_000,
  rush_2p: 15_000,
  rush_4p: 15_000
};

export const TRACK_LENGTH = 52;
export const FINISH_PROGRESS = 57;
export const YARD_PROGRESS = -1;

const PIECES_PER_PLAYER = 4;
const START_OFFSETS = [0, 13, 26, 39];
const SAFE_TRACK_INDEXES = new Set([0, 8, 13, 21, 26, 34, 39, 47]);
const FALLBACK_PLAYER_NAMES = [
  "Maya",
  "Leo",
  "Ava",
  "Noah",
  "Zara",
  "Omar",
  "Mia",
  "Ethan"
];

export interface RollResult {
  snapshot: RoomSnapshot;
  skipped: boolean;
}

export interface MoveResult {
  snapshot: RoomSnapshot;
  capturedPieceIds: string[];
  finished: boolean;
}

export function createInitialSnapshot(input: {
  roomId: string;
  code?: string;
  mode: GameMode;
  region: RoomSnapshot["region"];
  now: number;
}): RoomSnapshot {
  return {
    roomId: input.roomId,
    code: input.code,
    mode: input.mode,
    region: input.region,
    status: "waiting",
    seats: [],
    pieces: [],
    currentTurnSeat: 0,
    availableMoves: [],
    finishOrder: [],
    createdAt: input.now,
    updatedAt: input.now
  };
}

export function upsertSeat(
  snapshot: RoomSnapshot,
  player: Omit<RoomSeat, "seat" | "connected" | "isBot" | "joinedAt">
): RoomSnapshot {
  const existing = snapshot.seats.find((seat) => seat.playerId === player.playerId);
  const now = Date.now();

  if (existing) {
    return {
      ...snapshot,
      seats: snapshot.seats.map((seat) =>
        seat.playerId === player.playerId
          ? {
              ...seat,
              displayName: player.displayName,
              connected: true,
              disconnectedAt: undefined,
              // A player converted to a bot by turn timeouts regains control on
              // rejoin; a resigned player stays a bot.
              isBot: seat.resigned ? seat.isBot : false,
              missedTurns: 0
            }
          : seat
      ),
      updatedAt: now
    };
  }

  assertCanSeat(snapshot);

  const maxPlayers = MAX_PLAYERS_BY_MODE[snapshot.mode];
  const nextSeat = firstAvailableSeat(snapshot.seats, maxPlayers);
  const seats = [
    ...snapshot.seats,
    {
      seat: nextSeat,
      playerId: player.playerId,
      displayName: player.displayName,
      connected: true,
      isBot: false,
      joinedAt: now
    }
  ].sort((a, b) => a.seat - b.seat);

  return startIfReady({
    ...snapshot,
    seats,
    updatedAt: now
  });
}

export function fillBotSeats(snapshot: RoomSnapshot): RoomSnapshot {
  if (snapshot.status !== "waiting") {
    return snapshot;
  }

  const now = Date.now();
  const maxPlayers = MAX_PLAYERS_BY_MODE[snapshot.mode];
  const seats = [...snapshot.seats];

  while (seats.length < maxPlayers) {
    const seat = firstAvailableSeat(seats, maxPlayers);
    seats.push({
      seat,
      playerId: `bot_${snapshot.roomId}_${seat}`,
      displayName: fallbackPlayerName(seat),
      connected: true,
      isBot: true,
      joinedAt: now
    });
  }

  return startIfReady({
    ...snapshot,
    seats: seats.sort((a, b) => a.seat - b.seat),
    updatedAt: now
  });
}

export function markDisconnected(snapshot: RoomSnapshot, playerId: string, now = Date.now()): RoomSnapshot {
  return {
    ...snapshot,
    seats: snapshot.seats.map((seat) =>
      seat.playerId === playerId ? { ...seat, connected: false, disconnectedAt: now } : seat
    ),
    updatedAt: now
  };
}

export function canAct(snapshot: RoomSnapshot, playerId: string): boolean {
  const playerSeat = snapshot.seats.find((seat) => seat.playerId === playerId);
  return snapshot.status === "playing" && playerSeat?.seat === snapshot.currentTurnSeat;
}

export function rollDice(): number {
  // Rejection sampling keeps every face equally likely (2^32 is not a
  // multiple of 6, so a bare modulo slightly favours faces 1-4).
  const limit = 4294967292; // largest multiple of 6 below 2^32
  let value = crypto.getRandomValues(new Uint32Array(1))[0];
  while (value >= limit) {
    value = crypto.getRandomValues(new Uint32Array(1))[0];
  }

  return (value % 6) + 1;
}

export function applyRoll(snapshot: RoomSnapshot, playerId: string, diceValue: number, now = Date.now()): RollResult {
  if (!canAct(snapshot, playerId)) {
    throw new Error("It is not your turn.");
  }

  if (snapshot.diceValue !== undefined) {
    throw new Error("Move a piece before rolling again.");
  }

  const seat = getSeatForPlayer(snapshot, playerId);
  const availableMoves = getLegalMoves(snapshot, seat.seat, diceValue);
  const rolled = {
    ...snapshot,
    seats: clearMissedTurns(snapshot.seats, seat.seat),
    diceValue,
    availableMoves,
    updatedAt: now
  };

  if (availableMoves.length === 0) {
    return {
      snapshot: advanceTurn(rolled, now),
      skipped: true
    };
  }

  return {
    snapshot: rolled,
    skipped: false
  };
}

export function applyMove(snapshot: RoomSnapshot, playerId: string, pieceId: string, now = Date.now()): MoveResult {
  if (!canAct(snapshot, playerId)) {
    throw new Error("It is not your turn.");
  }

  if (snapshot.diceValue === undefined) {
    throw new Error("Roll before moving a piece.");
  }

  const seat = getSeatForPlayer(snapshot, playerId);
  const legalMoves = getLegalMoves(snapshot, seat.seat, snapshot.diceValue);
  if (!legalMoves.includes(pieceId)) {
    throw new Error("That piece cannot move for this dice value.");
  }

  const moved = movePiece(snapshot.pieces, pieceId, snapshot.diceValue, seat.seat);
  const moverFinished = hasSeatFinished(moved.pieces, seat.seat);

  let seats = snapshot.seats;
  let finishOrder = snapshot.finishOrder;
  if (moverFinished && !snapshot.finishOrder.includes(playerId)) {
    const rank = snapshot.finishOrder.length + 1;
    seats = snapshot.seats.map((roomSeat) => (roomSeat.seat === seat.seat ? { ...roomSeat, finishRank: rank } : roomSeat));
    finishOrder = [...snapshot.finishOrder, playerId];
  }

  if (moverFinished) {
    const finishedSnapshot: RoomSnapshot = {
      ...snapshot,
      status: "finished",
      seats,
      pieces: moved.pieces,
      diceValue: undefined,
      availableMoves: [],
      winnerPlayerId: playerId,
      finishOrder,
      updatedAt: now
    };

    return {
      snapshot: finishedSnapshot,
      capturedPieceIds: moved.capturedPieceIds,
      finished: true
    };
  }

  const shouldKeepTurn = snapshot.diceValue === 6;
  const nextSnapshot: RoomSnapshot = shouldKeepTurn
    ? startTurn({
        ...snapshot,
        seats,
        pieces: moved.pieces,
        diceValue: undefined,
        availableMoves: [],
        finishOrder,
        updatedAt: now
      }, seat.seat, now)
    : advanceTurn({
        ...snapshot,
        seats,
        pieces: moved.pieces,
        diceValue: undefined,
        availableMoves: [],
        finishOrder,
        updatedAt: now
      }, now);

  return {
    snapshot: nextSnapshot,
    capturedPieceIds: moved.capturedPieceIds,
    finished: false
  };
}

export function resignPlayer(snapshot: RoomSnapshot, playerId: string, now = Date.now()): RoomSnapshot {
  const seat = getSeatForPlayer(snapshot, playerId);

  if (snapshot.status === "finished") {
    return snapshot;
  }

  if (snapshot.status === "waiting") {
    // Leaving before the match starts frees the seat for someone else.
    return {
      ...snapshot,
      seats: snapshot.seats.filter((roomSeat) => roomSeat.playerId !== playerId),
      updatedAt: now
    };
  }

  const remainingHumanSeats = snapshot.seats.filter((roomSeat) => roomSeat.playerId !== playerId && !roomSeat.isBot);

  if (remainingHumanSeats.length <= 1) {
    const winner = remainingHumanSeats.length === 1
      ? remainingHumanSeats[0]
      : snapshot.seats.find((roomSeat) => roomSeat.playerId !== playerId);

    const finishOrder = winner && !snapshot.finishOrder.includes(winner.playerId)
      ? [...snapshot.finishOrder, winner.playerId]
      : snapshot.finishOrder;

    return {
      ...snapshot,
      status: "finished",
      winnerPlayerId: winner?.playerId,
      finishOrder,
      seats: snapshot.seats.map((roomSeat) =>
        roomSeat.playerId === winner?.playerId
          ? { ...roomSeat, finishRank: 1 }
          : roomSeat.seat === seat.seat
            ? { ...roomSeat, connected: false, resigned: true, finishRank: snapshot.seats.length }
            : roomSeat
      ),
      diceValue: undefined,
      availableMoves: [],
      updatedAt: now
    };
  }

  const seats = snapshot.seats.map((roomSeat) =>
    roomSeat.seat === seat.seat
      ? { ...roomSeat, connected: false, isBot: true, resigned: true }
      : roomSeat
  );

  if (snapshot.currentTurnSeat !== seat.seat) {
    // Someone else holds the turn: leave their turn and any rolled dice intact.
    return { ...snapshot, seats, updatedAt: now };
  }

  return advanceTurn({
    ...snapshot,
    seats,
    diceValue: undefined,
    availableMoves: [],
    updatedAt: now
  }, now);
}

export const MAX_MISSED_TURNS = 3;

export interface TimeoutResult {
  snapshot: RoomSnapshot;
  timedOut: boolean;
  timedOutPlayerId?: string;
  movedPieceId?: string;
}

export function timeoutTurn(snapshot: RoomSnapshot, now = Date.now()): TimeoutResult {
  if (snapshot.status !== "playing") {
    return { snapshot, timedOut: false };
  }

  const seat = getCurrentSeat(snapshot);
  if (!seat) {
    return { snapshot, timedOut: false };
  }

  const missedTurns = (seat.missedTurns ?? 0) + 1;
  const seats = snapshot.seats.map((roomSeat) =>
    roomSeat.seat === seat.seat
      ? {
          ...roomSeat,
          missedTurns,
          // After too many consecutive missed turns a bot takes over so the
          // match keeps moving; rejoining restores control (see upsertSeat).
          isBot: roomSeat.isBot || missedTurns >= MAX_MISSED_TURNS
        }
      : roomSeat
  );

  const withSeats: RoomSnapshot = { ...snapshot, seats, updatedAt: now };

  if (withSeats.diceValue !== undefined) {
    const pieceId = chooseBotMove(withSeats);
    if (pieceId) {
      const moved = applyMove(withSeats, seat.playerId, pieceId, now);
      return {
        snapshot: moved.snapshot,
        timedOut: true,
        timedOutPlayerId: seat.playerId,
        movedPieceId: pieceId
      };
    }
  }

  return {
    snapshot: advanceTurn({ ...withSeats, diceValue: undefined, availableMoves: [] }, now),
    timedOut: true,
    timedOutPlayerId: seat.playerId
  };
}

export function computeFinishRanks(snapshot: RoomSnapshot): Map<string, number> {
  const ranks = new Map<string, number>();
  snapshot.finishOrder.forEach((finishedPlayerId, index) => {
    ranks.set(finishedPlayerId, index + 1);
  });

  const remaining = snapshot.seats
    .filter((seat) => !ranks.has(seat.playerId))
    .map((seat) => ({
      seat,
      progress: snapshot.pieces
        .filter((piece) => piece.seat === seat.seat)
        .reduce((total, piece) => total + Math.max(piece.progress, 0), 0)
    }))
    .sort((a, b) => b.progress - a.progress || a.seat.seat - b.seat.seat);

  let nextRank = ranks.size + 1;
  for (const entry of remaining) {
    ranks.set(entry.seat.playerId, nextRank);
    nextRank += 1;
  }

  return ranks;
}

function clearMissedTurns(seats: RoomSeat[], seat: number): RoomSeat[] {
  return seats.map((roomSeat) =>
    roomSeat.seat === seat && roomSeat.missedTurns ? { ...roomSeat, missedTurns: 0 } : roomSeat
  );
}

function fallbackPlayerName(seat: number): string {
  return FALLBACK_PLAYER_NAMES[seat % FALLBACK_PLAYER_NAMES.length];
}

export function getLegalMoves(snapshot: RoomSnapshot, seat: number, diceValue: number): string[] {
  return snapshot.pieces
    .filter((piece) => piece.seat === seat)
    .filter((piece) => canMovePiece(piece, diceValue))
    .map((piece) => piece.pieceId);
}

export function chooseBotMove(snapshot: RoomSnapshot): string | undefined {
  if (snapshot.availableMoves.length === 0) {
    return undefined;
  }

  const byPriority = [...snapshot.availableMoves].sort((a, b) => scoreBotMove(snapshot, b) - scoreBotMove(snapshot, a));
  return byPriority[0];
}

export function isBotTurn(snapshot: RoomSnapshot): boolean {
  return snapshot.status === "playing" && snapshot.seats.some((seat) => seat.seat === snapshot.currentTurnSeat && seat.isBot);
}

export function getCurrentSeat(snapshot: RoomSnapshot): RoomSeat | undefined {
  return snapshot.seats.find((seat) => seat.seat === snapshot.currentTurnSeat);
}

export function getTrackIndex(seat: number, progress: number): number | undefined {
  if (progress < 0 || progress > 51) {
    return undefined;
  }

  return (START_OFFSETS[seat] + progress) % TRACK_LENGTH;
}

export function isSafeTrack(trackIndex: number): boolean {
  return SAFE_TRACK_INDEXES.has(trackIndex);
}

export function startIfReady(snapshot: RoomSnapshot): RoomSnapshot {
  if (snapshot.status !== "waiting") {
    return snapshot;
  }

  const maxPlayers = MAX_PLAYERS_BY_MODE[snapshot.mode];
  if (snapshot.seats.length < maxPlayers) {
    return snapshot;
  }

  const now = Date.now();
  return startTurn(
    {
      ...snapshot,
      status: "playing",
      pieces: createPieces(snapshot.seats),
      currentTurnSeat: snapshot.seats[0].seat,
      updatedAt: now
    },
    snapshot.seats[0].seat,
    now
  );
}

export function advanceTurn(snapshot: RoomSnapshot, now = Date.now()): RoomSnapshot {
  if (snapshot.seats.length === 0 || snapshot.status !== "playing") {
    return snapshot;
  }

  const activeSeats = snapshot.seats
    .filter((seat) => !hasSeatFinished(snapshot.pieces, seat.seat))
    .map((seat) => seat.seat)
    .sort((a, b) => a - b);

  if (activeSeats.length === 0) {
    return snapshot;
  }

  const index = activeSeats.indexOf(snapshot.currentTurnSeat);
  const nextIndex = index === -1 ? 0 : (index + 1) % activeSeats.length;
  return startTurn(snapshot, activeSeats[nextIndex], now);
}

function startTurn(snapshot: RoomSnapshot, seat: number, now: number): RoomSnapshot {
  return {
    ...snapshot,
    currentTurnSeat: seat,
    diceValue: undefined,
    availableMoves: [],
    turnStartedAt: now,
    turnDeadlineAt: now + TURN_DURATION_MS[snapshot.mode],
    updatedAt: now
  };
}

function movePiece(pieces: LudoPiece[], pieceId: string, diceValue: number, moverSeat: number): {
  pieces: LudoPiece[];
  capturedPieceIds: string[];
} {
  const mover = pieces.find((piece) => piece.pieceId === pieceId);
  if (!mover) {
    throw new Error("Piece was not found.");
  }

  const nextProgress = mover.progress === YARD_PROGRESS ? 0 : mover.progress + diceValue;
  const nextTrackIndex = getTrackIndex(moverSeat, nextProgress);
  const capturedPieceIds: string[] = [];

  let nextPieces = pieces.map((piece) =>
    piece.pieceId === pieceId
      ? {
          ...piece,
          progress: nextProgress,
          state: stateForProgress(nextProgress),
          trackIndex: nextTrackIndex
        }
      : piece
  );

  if (nextTrackIndex !== undefined && !isSafeTrack(nextTrackIndex)) {
    nextPieces = nextPieces.map((piece) => {
      if (piece.seat === moverSeat || piece.trackIndex !== nextTrackIndex || piece.state !== "track") {
        return piece;
      }

      capturedPieceIds.push(piece.pieceId);
      return {
        ...piece,
        progress: YARD_PROGRESS,
        state: "yard",
        trackIndex: undefined
      };
    });
  }

  return { pieces: nextPieces, capturedPieceIds };
}

function canMovePiece(piece: LudoPiece, diceValue: number): boolean {
  if (piece.state === "finished") {
    return false;
  }

  if (piece.progress === YARD_PROGRESS) {
    return diceValue === 6;
  }

  return piece.progress + diceValue <= FINISH_PROGRESS;
}

function createPieces(seats: RoomSeat[]): LudoPiece[] {
  return seats.flatMap((seat) =>
    Array.from({ length: PIECES_PER_PLAYER }, (_, index) => ({
      pieceId: `s${seat.seat}_p${index}`,
      seat: seat.seat,
      progress: YARD_PROGRESS,
      state: "yard" as const
    }))
  );
}

function stateForProgress(progress: number): LudoPiece["state"] {
  if (progress === YARD_PROGRESS) {
    return "yard";
  }

  if (progress >= FINISH_PROGRESS) {
    return "finished";
  }

  if (progress > 51) {
    return "home";
  }

  return "track";
}

function hasSeatFinished(pieces: LudoPiece[], seat: number): boolean {
  const seatPieces = pieces.filter((piece) => piece.seat === seat);
  return seatPieces.length > 0 && seatPieces.every((piece) => piece.state === "finished");
}

function getSeatForPlayer(snapshot: RoomSnapshot, playerId: string): RoomSeat {
  const seat = snapshot.seats.find((roomSeat) => roomSeat.playerId === playerId);
  if (!seat) {
    throw new Error("Player is not seated in this room.");
  }

  return seat;
}

function scoreBotMove(snapshot: RoomSnapshot, pieceId: string): number {
  const piece = snapshot.pieces.find((candidate) => candidate.pieceId === pieceId);
  if (!piece || snapshot.diceValue === undefined) {
    return 0;
  }

  if (piece.progress === YARD_PROGRESS) {
    return 30;
  }

  const nextProgress = piece.progress + snapshot.diceValue;
  const trackIndex = getTrackIndex(piece.seat, nextProgress);
  const captures = trackIndex !== undefined && !isSafeTrack(trackIndex)
    ? snapshot.pieces.some((candidate) => candidate.seat !== piece.seat && candidate.trackIndex === trackIndex)
    : false;

  return nextProgress + (captures ? 100 : 0);
}

function assertCanSeat(snapshot: RoomSnapshot): void {
  if (snapshot.status !== "waiting") {
    throw new Error("Room has already started.");
  }

  const maxPlayers = MAX_PLAYERS_BY_MODE[snapshot.mode];
  if (snapshot.seats.length >= maxPlayers) {
    throw new Error("Room is full.");
  }
}

function firstAvailableSeat(seats: RoomSeat[], maxPlayers: number): number {
  const taken = new Set(seats.map((seat) => seat.seat));
  for (let seat = 0; seat < maxPlayers; seat += 1) {
    if (!taken.has(seat)) {
      return seat;
    }
  }

  throw new Error("No seats available.");
}
