import 'dart:math' as math;
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import '../models/game_snapshot.dart';

enum TravelKind { hop, climb, slide, capture }

class TravelLeg {
  final int from;
  final int to;
  final TravelKind kind;
  final int milliseconds;
  const TravelLeg(this.from, this.to, this.kind, this.milliseconds);
}

/// A visual itinerary only. Authoritative snapshots remain untouched.
class PieceJourney {
  final PieceState before;
  final PieceState after;
  final List<TravelLeg> legs;
  const PieceJourney(this.before, this.after, this.legs);
  int get milliseconds => legs.fold(0, (sum, leg) => sum + leg.milliseconds);

  static PieceJourney? between(PieceState before, PieceState after,
      {required bool snakes, required int dice}) {
    if (before.progress == after.progress && before.state == after.state)
      return null;
    final legs = <TravelLeg>[];
    final start = before.progress;
    final end = after.progress;
    if (!snakes && end < 0) {
      legs.add(TravelLeg(start, end, TravelKind.capture, 420));
    } else {
      // A snake/ladder turn first lands on its trigger square, then travels.
      final rolledLanding = start + dice;
      final transport = snakes &&
          dice >= 1 &&
          dice <= 6 &&
          (ladders[rolledLanding] == end || drops[rolledLanding] == end);
      final landing = transport ? rolledLanding : end;
      if (landing > start &&
          landing - start <= 6 &&
          start >= (snakes ? 1 : 0)) {
        for (var square = start; square < landing; square++) {
          legs.add(TravelLeg(square, square + 1, TravelKind.hop, 90));
        }
      } else {
        legs.add(TravelLeg(start, landing, TravelKind.hop, 220));
      }
      if (transport) {
        legs.add(TravelLeg(landing, end,
            end > landing ? TravelKind.climb : TravelKind.slide, 620));
      }
    }
    return PieceJourney(before, after, legs);
  }

  TravelSample sample(double value) {
    var elapsed = value.clamp(0.0, 1.0) * milliseconds;
    for (final leg in legs) {
      if (elapsed <= leg.milliseconds || identical(leg, legs.last)) {
        return TravelSample(
            this, leg, (elapsed / leg.milliseconds).clamp(0.0, 1.0));
      }
      elapsed -= leg.milliseconds;
    }
    return TravelSample(this, legs.last, 1);
  }

  static const ladders = {6: 26, 23: 37, 48: 68, 65: 85, 79: 99};
  static const drops = {47: 13, 57: 35, 84: 64, 93: 68};
}

class TravelSample {
  final PieceJourney journey;
  final TravelLeg leg;
  final double t;
  const TravelSample(this.journey, this.leg, this.t);
  double get fraction => leg.kind == TravelKind.slide
      ? Curves.easeInOutCubic.transform(t)
      : Curves.easeInOut.transform(t);
  double get lift =>
      leg.kind == TravelKind.hop ? math.sin(t * math.pi) * .28 : 0;
  PieceState at(int progress) => PieceState(
      pieceId: journey.after.pieceId,
      seat: journey.after.seat,
      state: progress < 0
          ? 'yard'
          : progress >= 57
              ? 'finished'
              : progress >= 52
                  ? 'home'
                  : 'track',
      progress: progress,
      trackIndex: -1);
}

/// Independent clocks keep an opponent's next move from interrupting a climb.
class BoardMotion extends ChangeNotifier {
  final TickerProvider vsync;
  final Map<String, (PieceJourney, AnimationController)> _moving = {};
  BoardMotion(this.vsync);
  int revision = 0;
  void _changed() {
    revision++;
    notifyListeners();
  }

  bool get isMoving => _moving.values.any((entry) => entry.$2.isAnimating);
  TravelSample? sample(String id) {
    final entry = _moving[id];
    if (entry == null || !entry.$2.isAnimating) return null;
    return entry.$1.sample(entry.$2.value);
  }

  void update(GameSnapshot? before, GameSnapshot? after,
      {required bool animate}) {
    if (!animate ||
        before == null ||
        after == null ||
        before.mode != after.mode ||
        before.status == 'finished' ||
        before.seats.map((s) => s.playerId).join('|') !=
            after.seats.map((s) => s.playerId).join('|')) {
      clear();
      return;
    }
    final old = {for (final piece in before.pieces) piece.pieceId: piece};
    for (final piece in after.pieces) {
      final previous = old[piece.pieceId];
      if (previous == null) continue;
      final journey = PieceJourney.between(previous, piece,
          snakes: after.mode == 'snakes_ladders', dice: before.diceValue);
      if (journey == null) continue;
      _moving.remove(piece.pieceId)?.$2.dispose();
      final controller = AnimationController(
          vsync: vsync, duration: Duration(milliseconds: journey.milliseconds));
      _moving[piece.pieceId] = (journey, controller);
      controller.addListener(_changed);
      controller.addStatusListener((_) => _changed());
      controller.forward();
    }
  }

  void clear() {
    revision++;
    for (final entry in _moving.values) {
      entry.$2.dispose();
    }
    _moving.clear();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
