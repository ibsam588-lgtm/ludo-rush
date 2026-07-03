import 'dart:convert';

class PieceState {
  final String pieceId;
  final int seat;
  final String state; // "yard", "track", "home", "finished"
  final int progress; // -1=yard, 0-51=track, 52-56=home lane, >=57=finished
  final int trackIndex; // explicit PATH index (-1 if not set)

  const PieceState({
    required this.pieceId,
    required this.seat,
    required this.state,
    required this.progress,
    required this.trackIndex,
  });

  factory PieceState.fromJson(Map<String, dynamic> j) {
    return PieceState(
      pieceId:    j['pieceId']    as String? ?? '',
      seat:       j['seat']       as int?    ?? 0,
      state:      j['state']      as String? ?? 'yard',
      progress:   j['progress']   as int?    ?? -1,
      trackIndex: j['trackIndex'] as int?    ?? -1,
    );
  }
}

class SeatState {
  final int seat;
  final String playerId;
  final String displayName;
  final bool isBot;

  const SeatState({
    required this.seat,
    required this.playerId,
    required this.displayName,
    required this.isBot,
  });

  factory SeatState.fromJson(Map<String, dynamic> j) {
    return SeatState(
      seat:        j['seat']        as int?    ?? 0,
      playerId:    j['playerId']    as String? ?? '',
      displayName: j['displayName'] as String? ?? 'Player',
      isBot:       j['isBot']       as bool?   ?? false,
    );
  }
}

class GameSnapshot {
  final List<SeatState> seats;
  final List<PieceState> pieces;
  final int diceValue;
  final int currentTurnSeat;
  final String status; // "waiting", "playing", "finished"
  final List<String> availableMoves;
  final String winnerPlayerId;
  final String mode;

  const GameSnapshot({
    required this.seats,
    required this.pieces,
    required this.diceValue,
    required this.currentTurnSeat,
    required this.status,
    required this.availableMoves,
    required this.winnerPlayerId,
    required this.mode,
  });

  factory GameSnapshot.fromJson(Map<String, dynamic> j) {
    final seatsRaw  = j['seats']  as List<dynamic>? ?? [];
    final piecesRaw = j['pieces'] as List<dynamic>? ?? [];
    final movesRaw  = j['availableMoves'] as List<dynamic>? ?? [];

    return GameSnapshot(
      seats:           seatsRaw.map((s) => SeatState.fromJson(s as Map<String, dynamic>)).toList(),
      pieces:          piecesRaw.map((p) => PieceState.fromJson(p as Map<String, dynamic>)).toList(),
      diceValue:       j['diceValue']       as int?    ?? 0,
      currentTurnSeat: j['currentTurnSeat'] as int?    ?? -1,
      status:          j['status']          as String? ?? 'waiting',
      availableMoves:  movesRaw.map((m) => m.toString()).toList(),
      winnerPlayerId:  j['winnerPlayerId']  as String? ?? '',
      mode:            j['mode']            as String? ?? 'classic_2p',
    );
  }

  static GameSnapshot? tryParse(String text) {
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      return GameSnapshot.fromJson(j);
    } catch (_) {
      return null;
    }
  }
}
