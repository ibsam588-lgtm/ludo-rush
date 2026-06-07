import { describe, expect, it } from "vitest";
import {
  applyMove,
  applyRoll,
  createInitialSnapshot,
  getTrackIndex,
  upsertSeat
} from "../src/game/rules";

describe("room rules", () => {
  it("starts a 2-player room when the second player joins", () => {
    let snapshot = createInitialSnapshot({
      roomId: "room_1",
      mode: "classic_2p",
      region: "us-east",
      now: 1
    });

    snapshot = upsertSeat(snapshot, { playerId: "p1", displayName: "One" });
    expect(snapshot.status).toBe("waiting");

    snapshot = upsertSeat(snapshot, { playerId: "p2", displayName: "Two" });
    expect(snapshot.status).toBe("playing");
    expect(snapshot.seats).toHaveLength(2);
    expect(snapshot.pieces).toHaveLength(8);
  });

  it("skips a player when the dice creates no legal moves", () => {
    let snapshot = createInitialSnapshot({
      roomId: "room_1",
      mode: "classic_2p",
      region: "us-east",
      now: 1
    });

    snapshot = upsertSeat(snapshot, { playerId: "p1", displayName: "One" });
    snapshot = upsertSeat(snapshot, { playerId: "p2", displayName: "Two" });
    const result = applyRoll(snapshot, "p1", 3, 2);

    expect(result.skipped).toBe(true);
    expect(result.snapshot.currentTurnSeat).toBe(1);
    expect(result.snapshot.diceValue).toBeUndefined();
  });

  it("lets a player enter from yard only on six", () => {
    let snapshot = createInitialSnapshot({
      roomId: "room_1",
      mode: "classic_2p",
      region: "us-east",
      now: 1
    });

    snapshot = upsertSeat(snapshot, { playerId: "p1", displayName: "One" });
    snapshot = upsertSeat(snapshot, { playerId: "p2", displayName: "Two" });
    const rolled = applyRoll(snapshot, "p1", 6, 2).snapshot;
    const moved = applyMove(rolled, "p1", "s0_p0", 3).snapshot;
    const piece = moved.pieces.find((candidate) => candidate.pieceId === "s0_p0");

    expect(piece?.progress).toBe(0);
    expect(piece?.state).toBe("track");
    expect(piece?.trackIndex).toBe(0);
  });

  it("captures an opponent on an unsafe shared track tile", () => {
    let snapshot = createInitialSnapshot({
      roomId: "room_1",
      mode: "classic_2p",
      region: "us-east",
      now: 1
    });

    snapshot = upsertSeat(snapshot, { playerId: "p1", displayName: "One" });
    snapshot = upsertSeat(snapshot, { playerId: "p2", displayName: "Two" });
    const targetTrackIndex = getTrackIndex(0, 3);
    snapshot = {
      ...snapshot,
      diceValue: 3,
      availableMoves: ["s0_p0"],
      pieces: snapshot.pieces.map((piece) => {
        if (piece.pieceId === "s0_p0") {
          return { ...piece, progress: 0, state: "track", trackIndex: getTrackIndex(0, 0) };
        }

        if (piece.pieceId === "s1_p0") {
          return { ...piece, progress: 42, state: "track", trackIndex: targetTrackIndex };
        }

        return piece;
      })
    };

    const result = applyMove(snapshot, "p1", "s0_p0", 3);
    const captured = result.snapshot.pieces.find((piece) => piece.pieceId === "s1_p0");

    expect(result.capturedPieceIds).toContain("s1_p0");
    expect(captured?.state).toBe("yard");
    expect(captured?.progress).toBe(-1);
  });
});
