import 'game_snapshot.dart';

enum AvatarMood { idle, lucky, capture, climb, slide, winner }

class MatchMoment {
  final int seat;
  final AvatarMood mood;
  final String label;
  const MatchMoment(this.seat, this.mood, this.label);
  static MatchMoment? between(GameSnapshot? before, GameSnapshot after) {
    if (before == null ||
        before.mode != after.mode ||
        before.status != 'playing') return null;
    if (after.status == 'finished') {
      for (final seat in after.seats) {
        if (seat.playerId == after.winnerPlayerId)
          return MatchMoment(seat.seat, AvatarMood.winner, 'Victory!');
      }
    }
    final previous = {for (final piece in before.pieces) piece.pieceId: piece};
    if (after.mode == 'snakes_ladders') {
      for (final piece in after.pieces) {
        final old = previous[piece.pieceId];
        if (old == null || old.progress == piece.progress) continue;
        final landing = old.progress + before.diceValue;
        if (piece.progress > landing)
          return MatchMoment(piece.seat, AvatarMood.climb, 'What a climb!');
        if (piece.progress < old.progress)
          return MatchMoment(piece.seat, AvatarMood.slide, 'Back in the race!');
      }
    } else {
      for (final piece in after.pieces) {
        if (piece.progress < 0 &&
            (previous[piece.pieceId]?.progress ?? -1) >= 0) {
          return MatchMoment(
              before.currentTurnSeat, AvatarMood.capture, 'Nice capture!');
        }
      }
    }
    return null;
  }
}

String moodEmoji(AvatarMood mood) => switch (mood) {
      AvatarMood.lucky => '🎲',
      AvatarMood.capture => '😎',
      AvatarMood.climb => '🚀',
      AvatarMood.slide => '😮',
      AvatarMood.winner => '👑',
      AvatarMood.idle => '',
    };
