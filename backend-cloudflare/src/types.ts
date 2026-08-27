export interface Env {
  DB: D1Database;
  LUDO_ROOMS: DurableObjectNamespace;
  BACKGROUND_QUEUE: Queue<BackgroundJob>;
  MIN_ANDROID_BUILD_NUMBER?: string;
  LATEST_ANDROID_BUILD_NUMBER?: string;
  LATEST_ANDROID_VERSION_NAME?: string;
  FORCE_LATEST_ANDROID_BUILD?: string;
  ANDROID_UPDATE_URL?: string;
  FORCE_UPDATE_MESSAGE?: string;
}

export type Region = "auto" | "us-east" | "us-west" | "europe" | "middle-east" | "south-asia" | "east-asia";

export type GameMode =
  | "classic_2p"
  | "classic_3p"
  | "classic_4p"
  | "rush_2p"
  | "rush_4p";

export interface PlayerProfile {
  id: string;
  displayName: string;
  region: Region;
  rating: number;
  coins: number;
}

export interface MatchTicket {
  id: string;
  playerId: string;
  displayName: string;
  mode: GameMode;
  region: Region;
  latencyMs?: number;
  rating: number;
  requestedAt: number;
  status: "waiting" | "matched" | "cancelled" | "expired";
  roomId?: string;
}

export interface RoomSeat {
  seat: number;
  playerId: string;
  displayName: string;
  connected: boolean;
  isBot: boolean;
  joinedAt: number;
  disconnectedAt?: number;
  finishRank?: number;
  missedTurns?: number;
  resigned?: boolean;
}

export interface LudoPiece {
  pieceId: string;
  seat: number;
  progress: number;
  state: "yard" | "track" | "home" | "finished";
  trackIndex?: number;
}

export interface RoomSnapshot {
  roomId: string;
  code?: string;
  mode: GameMode;
  region: Region;
  status: "waiting" | "playing" | "finished";
  seats: RoomSeat[];
  pieces: LudoPiece[];
  currentTurnSeat: number;
  diceValue?: number;
  availableMoves: string[];
  turnStartedAt?: number;
  turnDeadlineAt?: number;
  winnerPlayerId?: string;
  finishOrder: string[];
  createdAt: number;
  updatedAt: number;
}

export type ClientRoomMessage =
  | { type: "join"; playerId: string; displayName: string }
  | { type: "roll_dice"; playerId: string }
  | { type: "move_piece"; playerId: string; pieceId: string }
  | { type: "fill_bots"; playerId: string }
  | { type: "resign"; playerId: string }
  | { type: "reaction"; playerId: string; displayName?: string; text: string; isEmoji?: boolean }
  | { type: "heartbeat"; playerId: string };

export type ServerRoomMessage =
  | { type: "snapshot"; snapshot: RoomSnapshot }
  | { type: "dice_rolled"; playerId: string; value: number; snapshot: RoomSnapshot }
  | {
      type: "move_accepted";
      playerId: string;
      pieceId: string;
      capturedPieceIds: string[];
      snapshot: RoomSnapshot;
    }
  | { type: "turn_skipped"; playerId: string; reason: string; snapshot: RoomSnapshot }
  | { type: "bots_filled"; snapshot: RoomSnapshot }
  | { type: "match_finished"; winnerPlayerId: string; snapshot: RoomSnapshot }
  | { type: "reaction"; playerId: string; displayName?: string; text: string; isEmoji: boolean }
  | { type: "error"; code: string; message: string };

export type BackgroundJob =
  | { type: "settle_match"; matchId: string }
  | { type: "validate_purchase"; purchaseId: string };
