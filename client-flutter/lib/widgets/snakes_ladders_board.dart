import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_snapshot.dart';
import '../theme/app_theme.dart';

class SnakesLaddersBoard extends StatefulWidget {
  final GameSnapshot? snapshot;
  final int? mySeat;
  final void Function(String pieceId) onPieceTap;

  const SnakesLaddersBoard({
    super.key,
    required this.snapshot,
    required this.mySeat,
    required this.onPieceTap,
  });

  @override
  State<SnakesLaddersBoard> createState() => _SnakesLaddersBoardState();
}

class _SnakesLaddersBoardState extends State<SnakesLaddersBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final List<_SnakeHit> _hits = [];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _handleTap(Offset pos) {
    _SnakeHit? best;
    var bestDistance = double.infinity;
    for (final hit in _hits) {
      if (!hit.legal) continue;
      final distance = (hit.center - pos).distance;
      if (distance < hit.radius * 2.7 && distance < bestDistance) {
        best = hit;
        bestDistance = distance;
      }
    }
    if (best != null) widget.onPieceTap(best.pieceId);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handleTap(details.localPosition),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => CustomPaint(
          painter: _SnakesLaddersPainter(
            snapshot: widget.snapshot,
            mySeat: widget.mySeat,
            pulse: _pulse.value,
            hits: _hits,
          ),
        ),
      ),
    );
  }
}

class _SnakeHit {
  final String pieceId;
  final Offset center;
  final double radius;
  final bool legal;

  const _SnakeHit(this.pieceId, this.center, this.radius, this.legal);
}

class _PieceDraw {
  final PieceState piece;
  final Offset center;
  final int index;
  final int total;

  const _PieceDraw({
    required this.piece,
    required this.center,
    required this.index,
    required this.total,
  });
}

class _SnakesLaddersPainter extends CustomPainter {
  static const Map<int, int> ladders = {
    4: 14,
    9: 31,
    20: 38,
    28: 84,
    40: 59,
    51: 67,
    63: 81,
    71: 91,
  };

  static const Map<int, int> snakes = {
    17: 7,
    54: 34,
    62: 19,
    64: 60,
    87: 24,
    93: 73,
    95: 75,
    99: 78,
  };

  static const List<Color> _seatColors = [
    boardRed,
    boardBlue,
    boardGreen,
    boardYellow,
  ];

  final GameSnapshot? snapshot;
  final int? mySeat;
  final double pulse;
  final List<_SnakeHit> hits;

  _SnakesLaddersPainter({
    required this.snapshot,
    required this.mySeat,
    required this.pulse,
    required this.hits,
  });

  @override
  void paint(Canvas canvas, Size size) {
    hits.clear();
    final side = math.min(size.width, size.height);
    final boardRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side * 0.96,
      height: side * 0.96,
    );
    final playRect = boardRect.deflate(10);
    final cell = playRect.width / 10;
    _drawShell(canvas, boardRect);

    canvas.save();
    canvas.clipRRect(RRect.fromRectXY(playRect, 18, 18));
    _drawTiles(canvas, playRect, cell);
    _drawLadders(canvas, playRect, cell);
    _drawSnakes(canvas, playRect, cell);
    _drawNumbers(canvas, playRect, cell);
    canvas.restore();

    _drawPieces(canvas, playRect, cell);
    _drawTitle(canvas, boardRect);
  }

  void _drawShell(Canvas canvas, Rect rect) {
    final p = Paint()..isAntiAlias = true;
    final shadow = Rect.fromCenter(
      center: rect.center.translate(0, rect.height * 0.035),
      width: rect.width * 1.02,
      height: rect.height * 1.01,
    );
    p.color = const Color(0x99000000);
    canvas.drawRRect(RRect.fromRectXY(shadow, 28, 28), p);

    p.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF7A6), Color(0xFFFFB61C), Color(0xFF713100)],
    ).createShader(rect);
    canvas.drawRRect(RRect.fromRectXY(rect, 24, 24), p);
    p.shader = null;

    final inner = rect.deflate(10);
    p.color = const Color(0xFFFFF1C4);
    canvas.drawRRect(RRect.fromRectXY(inner, 18, 18), p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFFFFF2A8);
    canvas.drawRRect(RRect.fromRectXY(rect.deflate(4), 22, 22), p);
    p.style = PaintingStyle.fill;
  }

  void _drawTiles(Canvas canvas, Rect rect, double cell) {
    final p = Paint()..isAntiAlias = true;
    for (var n = 1; n <= 100; n++) {
      final r = _cellRect(rect, cell, n);
      final isGoal = n == 100;
      final isStart = n == 1;
      final ladderStart = ladders.containsKey(n);
      final snakeHead = snakes.containsKey(n);
      final checkpoint = n % 10 == 0 || n == 25 || n == 60;
      Color fill;
      if (isGoal) {
        fill = boardRed;
      } else if (isStart) {
        fill = const Color(0xFF24A45D);
      } else if (ladderStart) {
        fill = const Color(0xFF285DCA);
      } else if (snakeHead) {
        fill = const Color(0xFFD6384B);
      } else if (checkpoint) {
        fill = const Color(0xFF8E35D9);
      } else {
        fill = (n + (n ~/ 10)).isEven
            ? const Color(0xFFFFF6DC)
            : const Color(0xFFFFEDBE);
      }
      p.color = fill;
      canvas.drawRect(r, p);
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..color = const Color(0xCC9A6B10);
      canvas.drawRect(r, p);
      p.style = PaintingStyle.fill;

      if (checkpoint || ladderStart || snakeHead || isGoal) {
        _drawStar(
          canvas,
          r.center.translate(r.width * 0.22, -r.height * 0.22),
          r.width * 0.15,
          Colors.white.withAlpha(230),
        );
      }
    }
  }

  void _drawLadders(Canvas canvas, Rect rect, double cell) {
    for (final entry in ladders.entries) {
      _drawLadder(
        canvas,
        _cellCenter(rect, cell, entry.key),
        _cellCenter(rect, cell, entry.value),
        cell,
      );
    }
  }

  void _drawLadder(Canvas canvas, Offset from, Offset to, double cell) {
    final p = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;
    final dir = (to - from);
    final len = dir.distance;
    if (len <= 0) return;
    final unit = dir / len;
    final normal = Offset(-unit.dy, unit.dx) * cell * 0.16;
    final a1 = from + normal;
    final a2 = to + normal;
    final b1 = from - normal;
    final b2 = to - normal;

    p
      ..strokeWidth = cell * 0.15
      ..color = const Color(0x66000000);
    canvas.drawLine(a1.translate(2, 3), a2.translate(2, 3), p);
    canvas.drawLine(b1.translate(2, 3), b2.translate(2, 3), p);

    p
      ..strokeWidth = cell * 0.10
      ..color = const Color(0xFFFFCC3A);
    canvas.drawLine(a1, a2, p);
    canvas.drawLine(b1, b2, p);
    p
      ..strokeWidth = cell * 0.035
      ..color = const Color(0xFFFFF2A0);
    canvas.drawLine(a1, a2, p);
    canvas.drawLine(b1, b2, p);

    final rungCount = math.max(3, (len / (cell * 0.55)).round());
    for (var i = 1; i < rungCount; i++) {
      final t = i / rungCount;
      final c = Offset.lerp(from, to, t)!;
      p
        ..strokeWidth = cell * 0.075
        ..color = const Color(0xFFFFB11B);
      canvas.drawLine(c - normal * 1.05, c + normal * 1.05, p);
      p
        ..strokeWidth = cell * 0.026
        ..color = const Color(0xFFFFF0A6);
      canvas.drawLine(c - normal * 0.88, c + normal * 0.88, p);
    }
  }

  void _drawSnakes(Canvas canvas, Rect rect, double cell) {
    final colors = [
      boardGreen,
      boardBlue,
      boardPurple,
      boardRed,
      const Color(0xFFFF7A16),
      const Color(0xFF18B89D),
      const Color(0xFFD946EF),
      const Color(0xFF79B000),
    ];
    var i = 0;
    for (final entry in snakes.entries) {
      _drawSnake(
        canvas,
        _cellCenter(rect, cell, entry.key),
        _cellCenter(rect, cell, entry.value),
        cell,
        colors[i % colors.length],
      );
      i++;
    }
  }

  void _drawSnake(
    Canvas canvas,
    Offset head,
    Offset tail,
    double cell,
    Color color,
  ) {
    final p = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dir = tail - head;
    final len = dir.distance;
    if (len <= 0) return;
    final unit = dir / len;
    final normal = Offset(-unit.dy, unit.dx);
    final wave = normal * cell * 0.62;
    final c1 = head + dir * 0.33 + wave;
    final c2 = head + dir * 0.66 - wave;
    final path = Path()
      ..moveTo(head.dx, head.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, tail.dx, tail.dy);

    p
      ..strokeWidth = cell * 0.40
      ..color = const Color(0x55000000);
    canvas.drawPath(path.shift(const Offset(2, 4)), p);

    p
      ..strokeWidth = cell * 0.32
      ..color = color;
    canvas.drawPath(path, p);
    p
      ..strokeWidth = cell * 0.15
      ..color = Color.lerp(color, Colors.white, 0.35)!;
    canvas.drawPath(path, p);

    final fill = Paint()..isAntiAlias = true;
    fill.shader = RadialGradient(
      center: const Alignment(-0.25, -0.35),
      colors: [
        Color.lerp(color, Colors.white, 0.55)!,
        color,
        Color.lerp(color, Colors.black, 0.32)!,
      ],
    ).createShader(Rect.fromCircle(center: head, radius: cell * 0.31));
    canvas.drawCircle(head, cell * 0.28, fill);
    fill.shader = null;
    fill.color = Colors.white;
    canvas.drawCircle(
        head + normal * cell * 0.08 - unit * cell * 0.04, cell * 0.055, fill);
    fill.color = const Color(0xFF1C1122);
    canvas.drawCircle(
        head + normal * cell * 0.08 - unit * cell * 0.04, cell * 0.026, fill);
  }

  void _drawNumbers(Canvas canvas, Rect rect, double cell) {
    for (var n = 1; n <= 100; n++) {
      final r = _cellRect(rect, cell, n);
      final bright = n == 100 ||
          n == 1 ||
          ladders.containsKey(n) ||
          snakes.containsKey(n) ||
          n % 10 == 0 ||
          n == 25 ||
          n == 60;
      _drawText(
        canvas,
        n.toString(),
        r.topLeft + Offset(cell * 0.16, cell * 0.16),
        bright ? Colors.white : const Color(0xFF694616),
        cell * 0.23,
        weight: FontWeight.w900,
        align: TextAlign.left,
        anchorMode: _TextAnchor.topLeft,
      );
    }
  }

  void _drawPieces(Canvas canvas, Rect rect, double cell) {
    final snap = snapshot;
    final pieces = snap?.pieces ?? const <PieceState>[];
    final legal = snap?.availableMoves.toSet() ?? const <String>{};
    if (pieces.isEmpty) {
      final previewCells = [1, 8, 15, 22];
      for (var i = 0; i < previewCells.length; i++) {
        _drawToken(
          canvas,
          _cellCenter(rect, cell, previewCells[i]),
          cell * 0.28,
          _seatColor(i),
          false,
          false,
        );
      }
      return;
    }

    final groups = <int, List<PieceState>>{};
    for (final piece in pieces) {
      groups.putIfAbsent(piece.progress.clamp(1, 100), () => []).add(piece);
    }

    final draws = <_PieceDraw>[];
    for (final entry in groups.entries) {
      final center = _cellCenter(rect, cell, entry.key);
      final total = entry.value.length;
      for (var i = 0; i < total; i++) {
        draws.add(_PieceDraw(
          piece: entry.value[i],
          center: center,
          index: i,
          total: total,
        ));
      }
    }

    for (final draw in draws) {
      final pos = _stackedPosition(draw.center, draw.index, draw.total, cell);
      final radius = cell * (draw.total > 2 ? 0.165 : 0.19);
      final isLegal = legal.contains(draw.piece.pieceId);
      hits.add(_SnakeHit(draw.piece.pieceId, pos, radius, isLegal));
      _drawToken(
        canvas,
        pos,
        radius,
        _seatColor(draw.piece.seat),
        isLegal,
        snap?.currentTurnSeat == draw.piece.seat,
      );
    }
  }

  void _drawToken(
    Canvas canvas,
    Offset c,
    double r,
    Color color,
    bool legal,
    bool active,
  ) {
    final p = Paint()..isAntiAlias = true;
    if (legal || active) {
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * (legal ? 0.30 : 0.18)
        ..color = goldColor.withAlpha(
          legal ? (105 + pulse * 120).round() : (60 + pulse * 70).round(),
        );
      canvas.drawCircle(c, r * (legal ? 1.78 : 1.48), p);
      p.style = PaintingStyle.fill;
    }
    p.color = const Color(0x66000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, r * 0.55),
        width: r * 1.95,
        height: r * 0.42,
      ),
      p,
    );
    p.shader = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      colors: [
        Color.lerp(color, Colors.white, 0.58)!,
        color,
        Color.lerp(color, Colors.black, 0.40)!,
      ],
    ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, r * 0.08)
      ..color = Color.lerp(color, Colors.black, 0.55)!;
    canvas.drawCircle(c, r, p);
    p.style = PaintingStyle.fill;
    p.color = Colors.white.withAlpha(170);
    canvas.drawCircle(c.translate(-r * 0.30, -r * 0.32), r * 0.16, p);
  }

  void _drawTitle(Canvas canvas, Rect boardRect) {
    final p = Paint()..isAntiAlias = true;
    final rect = Rect.fromCenter(
      center:
          Offset(boardRect.center.dx, boardRect.top + boardRect.height * 0.034),
      width: boardRect.width * 0.46,
      height: boardRect.height * 0.048,
    );
    p.shader = const LinearGradient(
      colors: [Color(0xEE551066), Color(0xEE17051F)],
    ).createShader(rect);
    canvas.drawRRect(RRect.fromRectXY(rect, 999, 999), p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = goldColor;
    canvas.drawRRect(RRect.fromRectXY(rect, 999, 999), p);
    p.style = PaintingStyle.fill;
    _drawText(
      canvas,
      'Snakes & Ladders',
      rect.center,
      Colors.white,
      boardRect.width * 0.030,
      weight: FontWeight.w900,
    );
  }

  Rect _cellRect(Rect inner, double cell, int number) {
    final rowFromBottom = (number - 1) ~/ 10;
    final colInRow = (number - 1) % 10;
    final col = rowFromBottom.isEven ? colInRow : 9 - colInRow;
    final row = 9 - rowFromBottom;
    return Rect.fromLTWH(
        inner.left + col * cell, inner.top + row * cell, cell, cell);
  }

  Offset _cellCenter(Rect inner, double cell, int number) =>
      _cellRect(inner, cell, number).center;

  Offset _stackedPosition(Offset center, int index, int total, double cell) {
    if (total <= 1) return center;
    final d = cell * 0.145;
    final offsets = switch (total) {
      2 => [Offset(-d, 0), Offset(d, 0)],
      3 => [Offset(0, -d), Offset(-d, d), Offset(d, d)],
      _ => [Offset(-d, -d), Offset(d, -d), Offset(-d, d), Offset(d, d)],
    };
    return center + offsets[index.clamp(0, offsets.length - 1)];
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final p = Paint()..isAntiAlias = true;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.42;
      final point = center + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    p.color = const Color(0x66000000);
    canvas.drawPath(path.shift(Offset(r * 0.08, r * 0.12)), p);
    p.color = color;
    canvas.drawPath(path, p);
  }

  Color _seatColor(int seat) =>
      _seatColors[seat.clamp(0, _seatColors.length - 1)];

  void _drawText(
    Canvas canvas,
    String text,
    Offset anchor,
    Color color,
    double size, {
    FontWeight weight = FontWeight.w800,
    TextAlign align = TextAlign.center,
    _TextAnchor anchorMode = _TextAnchor.center,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          height: 1,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = switch (anchorMode) {
      _TextAnchor.center =>
        anchor - Offset(painter.width / 2, painter.height / 2),
      _TextAnchor.topLeft => anchor,
    };
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SnakesLaddersPainter oldDelegate) {
    return oldDelegate.snapshot != snapshot ||
        oldDelegate.mySeat != mySeat ||
        oldDelegate.pulse != pulse;
  }
}

enum _TextAnchor { center, topLeft }
