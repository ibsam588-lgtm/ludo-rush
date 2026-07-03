import { describe, expect, it } from "vitest";
import {
  MAX_MISSED_TURNS,
  applyMove,
  applyRoll,
  computeFinishRanks,
  createInitialSnapshot,
  fillBotSeats,
  getTrackIndex,
  resignPlayer,
  rollDice,
  timeoutTurn,
  upsertSeat
} from "../src/game/rules";
import type { RoomSnapshot } from "../src/types";

function playingSnapshot(playerIds: string[], mode: "classic_2p" | "classic_3p" | "classic_4p" = "classic_2p"): RoomSnapshot {
  let snapshot = createInitialSnapshot({
    roomId: "room_1",
    mode,
    region: "us-east",
    now: 1
  });

  for (const [index, playerId] of playerIds.entries()) {
    snapshot = upsertSeat(snapshot, { playerId, displayName: `Player ${index}` });
  }

  return snapshot;
}

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

  it("always rolls a value between 1 and 6", () => {
    for (let i = 0; i < 500; i += 1) {
      const value = rollDice();
      expect(value).toBeGreaterThanOrEqual(1);
      expect(value).toBeLessThanOrEqual(6);
    }
  });
});

describe("resign", () => {
  it("keeps the current player's turn and dice when someone else resigns", () => {
    let snapshot = playingSnapshot(["p1", "p2", "p3"], "classic_3p");
    snapshot = applyRoll(snapshot, "p1", 6, 2).snapshot;
    expect(snapshot.diceValue).toBe(6);

    const resigned = resignPlayer(snapshot, "p3", 3);

    expect(resigned.status).toBe("playing");
    expect(resigned.currentTurnSeat).toBe(0);
    expect(resigned.diceValue).toBe(6);
    expect(resigned.availableMoves.length).toBeGreaterThan(0);
    const seat = resigned.seats.find((roomSeat) => roomSeat.playerId === "p3");
    expect(seat?.isBot).toBe(true);
    expect(seat?.resigned).toBe(true);
  });

  it("advances the turn when the current player resigns", () => {
    const snapshot = playingSnapshot(["p1", "p2", "p3"], "classic_3p");
    const resigned = resignPlayer(snapshot, "p1", 3);

    expect(resigned.status).toBe("playing");
    expect(resigned.currentTurnSeat).toBe(1);
    expect(resigned.diceValue).toBeUndefined();
  });

  it("frees the seat when leaving a waiting room", () => {
    let snapshot = createInitialSnapshot({ roomId: "room_1", mode: "classic_2p", region: "us-east", now: 1 });
    snapshot = upsertSeat(snapshot, { playerId: "p1", displayName: "One" });

    const left = resignPlayer(snapshot, "p1", 2);

    expect(left.status).toBe("waiting");
    expect(left.seats).toHaveLength(0);
  });

  it("finishes the match for the last remaining human", () => {
    const snapshot = playingSnapshot(["p1", "p2"]);
    const resigned = resignPlayer(snapshot, "p1", 3);

    expect(resigned.status).toBe("finished");
    expect(resigned.winnerPlayerId).toBe("p2");
    expect(resigned.finishOrder).toEqual(["p2"]);
    const loser = resigned.seats.find((roomSeat) => roomSeat.playerId === "p1");
    expect(loser?.resigned).toBe(true);
  });
});

describe("turn timeouts", () => {
  it("skips the current player's turn when they never rolled", () => {
    const snapshot = playingSnapshot(["p1", "p2"]);
    const result = timeoutTurn(snapshot, 5);

    expect(result.timedOut).toBe(true);
    expect(result.timedOutPlayerId).toBe("p1");
    expect(result.snapshot.currentTurnSeat).toBe(1);
    expect(result.snapshot.diceValue).toBeUndefined();
    const seat = result.snapshot.seats.find((roomSeat) => roomSeat.playerId === "p1");
    expect(seat?.missedTurns).toBe(1);
    expect(seat?.isBot).toBe(false);
  });

  it("auto-moves when the player rolled but never moved", () => {
    let snapshot = playingSnapshot(["p1", "p2"]);
    snapshot = applyRoll(snapshot, "p1", 6, 2).snapshot;

    const result = timeoutTurn(snapshot, 5);

    expect(result.timedOut).toBe(true);
    expect(result.movedPieceId).toBeDefined();
    const piece = result.snapshot.pieces.find((candidate) => candidate.pieceId === result.movedPieceId);
    expect(piece?.state).toBe("track");
  });

  it("hands the seat to a bot after too many consecutive missed turns", () => {
    let snapshot = playingSnapshot(["p1", "p2"]);

    for (let i = 0; i < MAX_MISSED_TURNS; i += 1) {
      snapshot = timeoutTurn(snapshot, 5 + i).snapshot;
      // Skip p2's turn back to p1 by simulating p2 rolling with no legal move.
      if (i < MAX_MISSED_TURNS - 1) {
        snapshot = applyRoll(snapshot, "p2", 3, 6 + i).snapshot;
      }
    }

    const seat = snapshot.seats.find((roomSeat) => roomSeat.playerId === "p1");
    expect(seat?.missedTurns).toBe(MAX_MISSED_TURNS);
    expect(seat?.isBot).toBe(true);
    expect(seat?.resigned).toBeUndefined();
  });

  it("restores control when a timed-out player rejoins", () => {
    let snapshot = playingSnapshot(["p1", "p2"]);
    for (let i = 0; i < MAX_MISSED_TURNS; i += 1) {
      snapshot = timeoutTurn(snapshot, 5 + i).snapshot;
      if (i < MAX_MISSED_TURNS - 1) {
        snapshot = applyRoll(snapshot, "p2", 3, 6 + i).snapshot;
      }
    }
    expect(snapshot.seats.find((roomSeat) => roomSeat.playerId === "p1")?.isBot).toBe(true);

    const rejoined = upsertSeat(snapshot, { playerId: "p1", displayName: "One" });
    const seat = rejoined.seats.find((roomSeat) => roomSeat.playerId === "p1");
    expect(seat?.isBot).toBe(false);
    expect(seat?.missedTurns).toBe(0);
  });

  it("resets the missed-turn counter when the player rolls", () => {
    let snapshot = playingSnapshot(["p1", "p2"]);
    snapshot = timeoutTurn(snapshot, 5).snapshot;
    snapshot = applyRoll(snapshot, "p2", 3, 6).snapshot; // p2 has no legal move; back to p1
    expect(snapshot.currentTurnSeat).toBe(0);

    snapshot = applyRoll(snapshot, "p1", 6, 7).snapshot;

    const seat = snapshot.seats.find((roomSeat) => roomSeat.playerId === "p1");
    expect(seat?.missedTurns).toBe(0);
  });

  it("does not time out finished or waiting rooms", () => {
    const waiting = createInitialSnapshot({ roomId: "room_1", mode: "classic_2p", region: "us-east", now: 1 });
    expect(timeoutTurn(waiting, 5).timedOut).toBe(false);
  });
});

describe("finish ranks", () => {
  it("ranks the winner first and orders the rest by board progress", () => {
    let snapshot = playingSnapshot(["p1", "p2"], "classic_2p");
    snapshot = fillBotSeats(snapshot);
    snapshot = {
      ...snapshot,
      finishOrder: ["p1"],
      winnerPlayerId: "p1",
      status: "finished",
      pieces: snapshot.pieces.map((piece) =>
        piece.seat === 1 ? { ...piece, progress: 10, state: "track" as const } : piece
      )
    };

    const ranks = computeFinishRanks(snapshot);
    expect(ranks.get("p1")).toBe(1);
    expect(ranks.get("p2")).toBe(2);
  });
});
