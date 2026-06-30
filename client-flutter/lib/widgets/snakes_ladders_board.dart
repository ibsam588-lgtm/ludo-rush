import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/game_snapshot.dart';
import '../theme/app_theme.dart';

const _snakesTitlePlaqueAsset =
    'assets/images/rush/rush_snakes_ladders_title_plaque_v2.png';

const _snakePieceAssets = [
  'assets/images/rush/rush_goti_red_v2.png',
  'assets/images/rush/rush_goti_blue_v2.png',
  'assets/images/rush/rush_goti_yellow_v2.png',
  'assets/images/rush/rush_goti_green_v2.png',
];

class SnakesLaddersBoard extends StatefulWidget {
  final GameSnapshot? snapshot;
  final int? mySeat;
  final String boardTheme;
  final void Function(String pieceId) onPieceTap;

  const SnakesLaddersBoard({
    super.key,
    required this.snapshot,
    required this.mySeat,
    this.boardTheme = 'carnival',
    required this.onPieceTap,
  });

  @override
  State<SnakesLaddersBoard> createState() => _SnakesLaddersBoardState();
}

class _SnakesLaddersBoardState extends State<SnakesLaddersBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final List<_SnakeHit> _hits = [];
  ui.Image? _titlePlaque;
  Map<int, ui.Image> _pieceImages = const {};

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..repeat(reverse: true);
    _loadAssets();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _titlePlaque?.dispose();
    for (final image in _pieceImages.values) {
      image.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAssets() async {
    final title = await _loadImage(_snakesTitlePlaqueAsset);
    final pieces = <int, ui.Image>{};
    for (var i = 0; i < _snakePieceAssets.length; i++) {
      final image = await _loadImage(_snakePieceAssets[i]);
      if (image != null) pieces[i] = image;
    }
    if (!mounted) {
      title?.dispose();
      for (final image in pieces.values) {
        image.dispose();
      }
      return;
    }
    setState(() {
      _titlePlaque?.dispose();
      for (final image in _pieceImages.values) {
        image.dispose();
      }
      _titlePlaque = title;
      _pieceImages = pieces;
    });
  }

  Future<ui.Image?> _loadImage(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
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
            titlePlaque: _titlePlaque,
            pieceImages: _pieceImages,
            boardTheme: widget.boardTheme,
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

class _SnakeSample {
  final Offset point;
  final Offset tangent;
  final Offset normal;
  final double radius;

  const _SnakeSample({
    required this.point,
    required this.tangent,
    required this.normal,
    required this.radius,
  });
}

class _SnakesLaddersPainter extends CustomPainter {
  static const Map<int, int> ladders = {
    6: 26,
    23: 37,
    48: 68,
    65: 85,
    79: 99,
  };

  static const Map<int, int> snakes = {
    47: 13,
    57: 35,
    84: 64,
    93: 68,
  };

  static const Map<int, Color> _coloredCells = {
    100: boardRed,
    97: boardBlue,
    94: boardGreen,
    90: boardRed,
    79: boardPurple,
    67: boardRed,
    60: boardBlue,
    49: boardPurple,
    36: boardGreen,
    25: boardBlue,
    20: boardRed,
    9: boardPurple,
  };

  static const Set<int> _starCells = {
    97,
    94,
    90,
    79,
    67,
    49,
    36,
    25,
    20,
    9,
  };

  static const List<Color> _seatColors = [
    boardRed,
    boardBlue,
    boardYellow,
    boardGreen,
  ];

  final GameSnapshot? snapshot;
  final int? mySeat;
  final double pulse;
  final List<_SnakeHit> hits;
  final ui.Image? titlePlaque;
  final Map<int, ui.Image> pieceImages;
  final String boardTheme;

  _SnakesLaddersPainter({
    required this.snapshot,
    required this.mySeat,
    required this.pulse,
    required this.hits,
    required this.titlePlaque,
    required this.pieceImages,
    required this.boardTheme,
  });

  String get _theme {
    final value = boardTheme.trim().toLowerCase();
    if (value == 'royal' || value == 'neon' || value == 'classic') {
      return value;
    }
    return 'carnival';
  }

  List<Color> get _shellColors {
    switch (_theme) {
      case 'royal':
        return const [Color(0xFFFFF8C9), Color(0xFFD69BFF), Color(0xFF4B1688)];
      case 'neon':
        return const [Color(0xFFB9FFFF), Color(0xFFFF4CE2), Color(0xFF160051)];
      case 'classic':
        return const [Color(0xFFFFF8D6), Color(0xFFFFC448), Color(0xFF7D430E)];
      case 'carnival':
      default:
        return const [Color(0xFFFFF7A6), Color(0xFFFFB61C), Color(0xFF713100)];
    }
  }

  Color get _innerShellColor {
    switch (_theme) {
      case 'royal':
        return const Color(0xFFFFECFF);
      case 'neon':
        return const Color(0xFFF2FBFF);
      case 'classic':
        return const Color(0xFFFFF5D6);
      case 'carnival':
      default:
        return const Color(0xFFFFF1C4);
    }
  }

  Color get _gridColor {
    switch (_theme) {
      case 'royal':
        return const Color(0xD18F58C9);
      case 'neon':
        return const Color(0xD129BFFF);
      case 'classic':
        return const Color(0xD6BE8A25);
      case 'carnival':
      default:
        return const Color(0xD9D8A115);
    }
  }

  Color get _outerGridColor {
    switch (_theme) {
      case 'royal':
        return const Color(0xFFE7B7FF);
      case 'neon':
        return const Color(0xFF15DFFF);
      case 'classic':
        return const Color(0xFFB77B1A);
      case 'carnival':
      default:
        return const Color(0xFFE5A716);
    }
  }

  List<Color> _plainCellColors(int number) {
    final even = (number + (number ~/ 10)).isEven;
    switch (_theme) {
      case 'royal':
        return even
            ? const [Color(0xFFFFF8FF), Color(0xFFF4DFFF)]
            : const [Color(0xFFFFF2F8), Color(0xFFEAD8FF)];
      case 'neon':
        return even
            ? const [Color(0xFFFFFFFF), Color(0xFFE1FBFF)]
            : const [Color(0xFFFFF5FF), Color(0xFFEAF8FF)];
      case 'classic':
        return even
            ? const [Color(0xFFFFFDF4), Color(0xFFFFE7B5)]
            : const [Color(0xFFFFF7E1), Color(0xFFFFE0A0)];
      case 'carnival':
      default:
        return even
            ? const [Color(0xFFFFFDF0), Color(0xFFFFF0C7)]
            : const [Color(0xFFFFF9E6), Color(0xFFFFEAB1)];
    }
  }

  List<Color> get _snakePalette {
    switch (_theme) {
      case 'royal':
        return const [
          Color(0xFFFF873D),
          Color(0xFFB85CFF),
          Color(0xFF54DD78),
          Color(0xFF33B9FF),
        ];
      case 'neon':
        return const [
          Color(0xFFFF7A00),
          Color(0xFFFF4CFF),
          Color(0xFF79FF35),
          Color(0xFF20F0FF),
        ];
      case 'classic':
        return const [
          Color(0xFFFF8122),
          Color(0xFFB15CE0),
          Color(0xFF53C846),
          Color(0xFF2AA8EA),
        ];
      case 'carnival':
      default:
        return const [
          boardOrange,
          boardPurple,
          Color(0xFF56D82D),
          Color(0xFF22B7FF),
        ];
    }
  }

  Color _themedCellColor(Color color) {
    switch (_theme) {
      case 'royal':
        return Color.lerp(color, const Color(0xFFD886FF), 0.10)!;
      case 'neon':
        return Color.lerp(color, const Color(0xFF39F6FF), 0.12)!;
      case 'classic':
        return Color.lerp(color, Colors.white, 0.04)!;
      case 'carnival':
      default:
        return color;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    hits.clear();
    final titleHeight = (size.height * 0.135).clamp(40.0, 78.0);
    final gap = (size.height * 0.012).clamp(4.0, 8.0);
    final maxBoardSide = size.height - titleHeight - gap;
    final boardSide = math.min(size.width * 0.965, maxBoardSide);
    final totalHeight = titleHeight + gap + boardSide;
    final top = math.max(0.0, (size.height - totalHeight) / 2);
    final boardRect = Rect.fromLTWH(
      (size.width - boardSide) / 2,
      top + titleHeight + gap,
      boardSide,
      boardSide,
    );
    final titleRect = Rect.fromCenter(
      center: Offset(size.width / 2, top + titleHeight / 2),
      width: math.min(size.width * 0.92, boardSide * 0.96),
      height: titleHeight,
    );
    final playRect = boardRect.deflate(boardSide * 0.025);
    final cell = playRect.width / 10;

    _drawTitle(canvas, titleRect);
    _drawShell(canvas, boardRect);

    canvas.save();
    canvas.clipRRect(RRect.fromRectXY(playRect, cell * 0.12, cell * 0.12));
    _drawTiles(canvas, playRect, cell);
    _drawLadders(canvas, playRect, cell);
    _drawSnakes(canvas, playRect, cell);
    _drawNumbers(canvas, playRect, cell);
    canvas.restore();

    _drawPieces(canvas, playRect, cell);
  }

  void _drawTitle(Canvas canvas, Rect rect) {
    final image = titlePlaque;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high,
      );
    } else {
      final p = Paint()..isAntiAlias = true;
      p.shader = const LinearGradient(
        colors: [Color(0xFFFFDA37), Color(0xFFFF8B00), Color(0xFF6D2500)],
      ).createShader(rect);
      canvas.drawRRect(RRect.fromRectXY(rect, 24, 24), p);
      p.shader = const LinearGradient(
        colors: [Color(0xFFFF36B8), Color(0xFF5B0B7F)],
      ).createShader(rect.deflate(6));
      canvas.drawRRect(RRect.fromRectXY(rect.deflate(6), 18, 18), p);
      p.shader = null;
    }
    _drawOutlinedText(
      canvas,
      'Snakes & Ladders',
      rect.center.translate(0, rect.height * 0.01),
      rect.height * 0.43,
      const Color(0xFFFFF34D),
      const Color(0xFF7C2600),
    );
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

    p.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _shellColors,
    ).createShader(rect);
    canvas.drawRRect(RRect.fromRectXY(rect, 24, 24), p);
    p.shader = null;

    final inner = rect.deflate(rect.width * 0.018);
    p.color = _innerShellColor;
    canvas.drawRRect(RRect.fromRectXY(inner, 18, 18), p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.006
      ..color = Color.lerp(_outerGridColor, Colors.white, 0.34)!;
    canvas.drawRRect(RRect.fromRectXY(rect.deflate(4), 22, 22), p);
    p.style = PaintingStyle.fill;
  }

  void _drawTiles(Canvas canvas, Rect rect, double cell) {
    final p = Paint()..isAntiAlias = true;
    for (var n = 1; n <= 100; n++) {
      final r = _cellRect(rect, cell, n);
      final cellColor = _coloredCells[n];
      if (cellColor != null) {
        final themedCellColor = _themedCellColor(cellColor);
        p.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(themedCellColor, Colors.white, 0.20)!,
            themedCellColor,
            Color.lerp(themedCellColor, Colors.black, 0.12)!,
          ],
        ).createShader(r);
        canvas.drawRect(r, p);
        p.shader = null;
      } else {
        p.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _plainCellColors(n),
        ).createShader(r);
        canvas.drawRect(r, p);
        p.shader = null;
      }

      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, cell * 0.025)
        ..color = _gridColor;
      canvas.drawRect(r, p);
      p.style = PaintingStyle.fill;

      if (_starCells.contains(n)) {
        _drawStar(
          canvas,
          r.center,
          cell * 0.30,
          Colors.white,
          _starOutlineFor(cellColor ?? goldColor),
        );
      }
    }

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, cell * 0.055)
      ..color = _outerGridColor;
    canvas.drawRect(rect, p);
    p.style = PaintingStyle.fill;
  }

  Color _starOutlineFor(Color color) {
    if (color == boardRed) return const Color(0xFFB91825);
    if (color == boardBlue) return const Color(0xFF126AC6);
    if (color == boardGreen) return const Color(0xFF1D8B39);
    if (color == boardPurple) return const Color(0xFF8B22B7);
    return const Color(0xFFB78000);
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
    final dir = to - from;
    final len = dir.distance;
    if (len <= 0) return;
    final unit = dir / len;
    final normal = Offset(-unit.dy, unit.dx) * cell * 0.15;
    final start = from + unit * cell * 0.13;
    final end = to - unit * cell * 0.13;
    final a1 = start + normal;
    final a2 = end + normal;
    final b1 = start - normal;
    final b2 = end - normal;

    p
      ..strokeWidth = cell * 0.14
      ..color = const Color(0x66000000);
    canvas.drawLine(a1.translate(2, 3), a2.translate(2, 3), p);
    canvas.drawLine(b1.translate(2, 3), b2.translate(2, 3), p);

    p
      ..strokeWidth = cell * 0.105
      ..color = const Color(0xFFFFB51C);
    canvas.drawLine(a1, a2, p);
    canvas.drawLine(b1, b2, p);
    p
      ..strokeWidth = cell * 0.045
      ..color = const Color(0xFFFFF0A1);
    canvas.drawLine(a1, a2, p);
    canvas.drawLine(b1, b2, p);

    final rungCount = math.max(4, (len / (cell * 0.42)).round());
    for (var i = 1; i < rungCount; i++) {
      final t = i / rungCount;
      final c = Offset.lerp(start, end, t)!;
      p
        ..strokeWidth = cell * 0.075
        ..color = const Color(0xFFFFAB15);
      canvas.drawLine(c - normal * 1.05, c + normal * 1.05, p);
      p
        ..strokeWidth = cell * 0.026
        ..color = const Color(0xFFFFF2A8);
      canvas.drawLine(c - normal * 0.84, c + normal * 0.84, p);
    }
  }

  void _drawSnakes(Canvas canvas, Rect rect, double cell) {
    final colors = _snakePalette;
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
    final dir = tail - head;
    final len = dir.distance;
    if (len <= 0) return;
    final unit = dir / len;
    final normal = Offset(-unit.dy, unit.dx);
    final wave = normal * cell * 0.76;
    final c1 = head + dir * 0.30 + wave;
    final c2 = head + dir * 0.68 - wave;
    final path = Path()
      ..moveTo(head.dx, head.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, tail.dx, tail.dy);

    final samples = <_SnakeSample>[];
    const sampleCount = 34;
    for (var i = 0; i <= sampleCount; i++) {
      final t = i / sampleCount;
      final point = _cubicPoint(head, c1, c2, tail, t);
      final tangent = _cubicTangent(head, c1, c2, tail, t);
      final side = Offset(-tangent.dy, tangent.dx);
      final taper = math.pow(1 - t, 0.72).toDouble();
      final pulseWidth = math.sin(t * math.pi) * 0.035;
      samples.add(_SnakeSample(
        point: point,
        tangent: tangent,
        normal: side,
        radius: cell * (0.115 + taper * 0.165 + pulseWidth),
      ));
    }

    final shadowPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0x60000000);
    for (var i = samples.length - 1; i >= 0; i--) {
      final s = samples[i];
      canvas.drawCircle(
        s.point.translate(cell * 0.055, cell * 0.075),
        s.radius * 1.17,
        shadowPaint,
      );
    }

    final outlinePaint = Paint()
      ..isAntiAlias = true
      ..color = Color.lerp(color, Colors.black, 0.48)!;
    for (var i = samples.length - 1; i >= 0; i--) {
      final s = samples[i];
      canvas.drawCircle(s.point, s.radius * 1.08, outlinePaint);
    }

    final fillPaint = Paint()..isAntiAlias = true;
    for (var i = samples.length - 1; i >= 0; i--) {
      final s = samples[i];
      final highlightCenter = s.point - s.normal * s.radius * 0.32;
      fillPaint.shader = RadialGradient(
        center: const Alignment(-0.38, -0.42),
        colors: [
          Color.lerp(color, Colors.white, 0.62)!,
          color,
          Color.lerp(color, Colors.black, 0.36)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(
        center: highlightCenter,
        radius: s.radius * 1.75,
      ));
      canvas.drawCircle(s.point, s.radius, fillPaint);
      fillPaint.shader = null;
    }

    final linePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    linePaint
      ..strokeWidth = cell * 0.065
      ..color = Colors.white.withAlpha(76);
    canvas.drawPath(path, linePaint);
    linePaint
      ..strokeWidth = cell * 0.026
      ..color = Color.lerp(color, Colors.black, 0.28)!.withAlpha(115);
    canvas.drawPath(path.shift(Offset(cell * 0.018, cell * 0.025)), linePaint);

    final detailPaint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;
    for (var i = 4; i < samples.length - 3; i += 4) {
      final s = samples[i];
      detailPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, cell * 0.030)
        ..color = Color.lerp(color, Colors.black, 0.30)!.withAlpha(95);
      canvas.drawLine(
        s.point - s.normal * s.radius * 0.58,
        s.point + s.normal * s.radius * 0.58,
        detailPaint,
      );
    }

    detailPaint.style = PaintingStyle.fill;
    for (var i = 5; i < samples.length - 6; i += 5) {
      final s = samples[i];
      final side = i.isEven ? 1.0 : -1.0;
      detailPaint.color = Color.lerp(color, Colors.white, 0.50)!.withAlpha(185);
      canvas.drawCircle(
        s.point + s.normal * side * s.radius * 0.45,
        s.radius * 0.18,
        detailPaint,
      );
    }

    final tailSample = samples.last;
    final tailPath = Path()
      ..moveTo(
        tailSample.point.dx - tailSample.normal.dx * tailSample.radius * 0.58,
        tailSample.point.dy - tailSample.normal.dy * tailSample.radius * 0.58,
      )
      ..lineTo(
        tailSample.point.dx + tailSample.tangent.dx * cell * 0.24,
        tailSample.point.dy + tailSample.tangent.dy * cell * 0.24,
      )
      ..lineTo(
        tailSample.point.dx + tailSample.normal.dx * tailSample.radius * 0.58,
        tailSample.point.dy + tailSample.normal.dy * tailSample.radius * 0.58,
      )
      ..close();
    detailPaint.color = Color.lerp(color, Colors.black, 0.26)!;
    canvas.drawPath(tailPath, detailPaint);

    _drawSnakeHead(
        canvas, head, _cubicTangent(head, c1, c2, tail, 0.035), cell, color);
  }

  void _drawSnakeHead(
    Canvas canvas,
    Offset head,
    Offset tangent,
    double cell,
    Color color,
  ) {
    final face = -tangent;
    final side = Offset(-face.dy, face.dx);
    final angle = math.atan2(face.dy, face.dx);
    final headCenter = head + face * cell * 0.045;
    final headPaint = Paint()..isAntiAlias = true;
    final headRadius = cell * 0.35;

    headPaint.color = const Color(0x66000000);
    _drawRotatedOval(
      canvas,
      headCenter.translate(cell * 0.035, cell * 0.055),
      angle,
      Size(headRadius * 1.85, headRadius * 1.25),
      headPaint,
    );

    headPaint.shader = RadialGradient(
      center: const Alignment(-0.32, -0.42),
      colors: [
        Color.lerp(color, Colors.white, 0.70)!,
        color,
        Color.lerp(color, Colors.black, 0.42)!,
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(
        Rect.fromCircle(center: headCenter, radius: headRadius * 1.3));
    _drawRotatedOval(
      canvas,
      headCenter,
      angle,
      Size(headRadius * 1.85, headRadius * 1.28),
      headPaint,
    );
    headPaint.shader = null;
    headPaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, cell * 0.035)
      ..color = Color.lerp(color, Colors.black, 0.50)!;
    _drawRotatedOval(
      canvas,
      headCenter,
      angle,
      Size(headRadius * 1.85, headRadius * 1.28),
      headPaint,
    );
    headPaint.style = PaintingStyle.fill;

    headPaint.color = Color.lerp(color, Colors.white, 0.45)!.withAlpha(135);
    _drawRotatedOval(
      canvas,
      headCenter - side * cell * 0.10 - face * cell * 0.03,
      angle,
      Size(headRadius * 0.48, headRadius * 0.22),
      headPaint,
    );

    final eyeA = headCenter + face * cell * 0.16 + side * cell * 0.115;
    final eyeB = headCenter + face * cell * 0.16 - side * cell * 0.115;
    headPaint.color = Colors.white;
    canvas.drawCircle(eyeA, cell * 0.070, headPaint);
    canvas.drawCircle(eyeB, cell * 0.070, headPaint);
    headPaint.color = const Color(0xFF130B17);
    canvas.drawCircle(eyeA + face * cell * 0.018, cell * 0.032, headPaint);
    canvas.drawCircle(eyeB + face * cell * 0.018, cell * 0.032, headPaint);
    headPaint.color = Colors.white.withAlpha(190);
    canvas.drawCircle(eyeA + face * cell * 0.030 - side * cell * 0.018,
        cell * 0.012, headPaint);
    canvas.drawCircle(eyeB + face * cell * 0.030 + side * cell * 0.018,
        cell * 0.012, headPaint);

    headPaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, cell * 0.018)
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5D171D).withAlpha(170);
    canvas.drawArc(
      Rect.fromCenter(
        center: headCenter + face * cell * 0.22,
        width: cell * 0.20,
        height: cell * 0.12,
      ),
      angle + 0.22,
      math.pi - 0.44,
      false,
      headPaint,
    );

    headPaint
      ..strokeWidth = math.max(1.0, cell * 0.024)
      ..color = const Color(0xFFE01648);
    final tongueStart = headCenter + face * cell * 0.34;
    final tongueEnd = headCenter + face * cell * 0.55;
    canvas.drawLine(tongueStart, tongueEnd, headPaint);
    canvas.drawLine(tongueEnd, tongueEnd + side * cell * 0.075, headPaint);
    canvas.drawLine(tongueEnd, tongueEnd - side * cell * 0.075, headPaint);
    headPaint.style = PaintingStyle.fill;
  }

  void _drawRotatedOval(
    Canvas canvas,
    Offset center,
    double angle,
    Size size,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero, width: size.width, height: size.height),
      paint,
    );
    canvas.restore();
  }

  Offset _cubicPoint(Offset a, Offset b, Offset c, Offset d, double t) {
    final mt = 1 - t;
    return a * (mt * mt * mt) +
        b * (3 * mt * mt * t) +
        c * (3 * mt * t * t) +
        d * (t * t * t);
  }

  Offset _cubicTangent(Offset a, Offset b, Offset c, Offset d, double t) {
    final mt = 1 - t;
    final tangent = (b - a) * (3 * mt * mt) +
        (c - b) * (6 * mt * t) +
        (d - c) * (3 * t * t);
    final distance = tangent.distance;
    if (distance == 0) return const Offset(1, 0);
    return tangent / distance;
  }

  void _drawNumbers(Canvas canvas, Rect rect, double cell) {
    for (var n = 1; n <= 100; n++) {
      final r = _cellRect(rect, cell, n);
      final colored = _coloredCells.containsKey(n);
      _drawText(
        canvas,
        n.toString(),
        r.topLeft + Offset(cell * 0.16, cell * 0.14),
        colored ? Colors.white : const Color(0xFF684811),
        n == 100 ? cell * 0.29 : cell * 0.25,
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
      final previewCells = [69, 42, 6, 23];
      for (var i = 0; i < previewCells.length; i++) {
        _drawToken(
          canvas,
          _cellCenter(rect, cell, previewCells[i]),
          cell * 0.34,
          _seatColor(i),
          false,
          false,
          seat: i,
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
      final total = entry.value.length;
      var center = _cellCenter(rect, cell, entry.key);
      if (entry.key == 1 && total > 1) {
        center += Offset(cell * 0.14, -cell * 0.14);
      }
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
      final radius = cell *
          (draw.total >= 4
              ? 0.18
              : draw.total == 3
                  ? 0.21
                  : 0.29);
      final isLegal = legal.contains(draw.piece.pieceId);
      hits.add(_SnakeHit(draw.piece.pieceId, pos, radius, isLegal));
      _drawToken(
        canvas,
        pos,
        radius,
        _seatColor(draw.piece.seat),
        isLegal,
        snap?.currentTurnSeat == draw.piece.seat,
        seat: draw.piece.seat,
      );
    }
  }

  void _drawToken(
    Canvas canvas,
    Offset c,
    double r,
    Color color,
    bool legal,
    bool active, {
    required int seat,
  }) {
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
        center: c.translate(0, r * 0.72),
        width: r * 1.9,
        height: r * 0.42,
      ),
      p,
    );

    final image = pieceImages[seat.clamp(0, 3)];
    if (image != null) {
      final imageH = r * 2.62;
      final imageW = imageH * image.width / image.height;
      final dest = Rect.fromCenter(
        center: c.translate(0, -r * 0.18),
        width: imageW,
        height: imageH,
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        dest,
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high,
      );
      return;
    }

    final lightColor = Color.lerp(color, Colors.white, 0.50)!;
    final darkColor = Color.lerp(color, Colors.black, 0.42)!;
    final baseRect = Rect.fromCenter(
      center: c.translate(0, r * 0.48),
      width: r * 1.58,
      height: r * 0.42,
    );
    p.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [lightColor, color, darkColor],
    ).createShader(baseRect);
    canvas.drawOval(baseRect, p);
    p.shader = null;
    p.color = darkColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, r * 0.16),
        width: r * 1.0,
        height: r * 1.28,
      ),
      p,
    );
    p.shader = RadialGradient(
      center: const Alignment(-0.28, -0.38),
      colors: [lightColor, color, darkColor],
    ).createShader(
        Rect.fromCircle(center: c.translate(0, -r * 0.66), radius: r));
    canvas.drawCircle(c.translate(0, -r * 0.56), r * 0.48, p);
    p.shader = null;
    p.color = Colors.white.withAlpha(140);
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-r * 0.18, -r * 0.82),
        width: r * 0.24,
        height: r * 0.15,
      ),
      p,
    );
  }

  Rect _cellRect(Rect inner, double cell, int number) {
    final rowFromBottom = (number - 1) ~/ 10;
    final colInRow = (number - 1) % 10;
    final col = rowFromBottom.isEven ? colInRow : 9 - colInRow;
    final row = 9 - rowFromBottom;
    return Rect.fromLTWH(
      inner.left + col * cell,
      inner.top + row * cell,
      cell,
      cell,
    );
  }

  Offset _cellCenter(Rect inner, double cell, int number) =>
      _cellRect(inner, cell, number).center;

  Offset _stackedPosition(Offset center, int index, int total, double cell) {
    if (total <= 1) return center;
    final d = cell *
        (total >= 4
            ? 0.16
            : total == 3
                ? 0.18
                : 0.20);
    final offsets = switch (total) {
      2 => [Offset(-d, 0), Offset(d, 0)],
      3 => [Offset(0, -d), Offset(-d, d), Offset(d, d)],
      _ => [Offset(-d, -d), Offset(d, -d), Offset(-d, d), Offset(d, d)],
    };
    return center + offsets[index.clamp(0, offsets.length - 1)];
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double r,
    Color fill,
    Color outline,
  ) {
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
    p.color = const Color(0x55000000);
    canvas.drawPath(path.shift(Offset(r * 0.08, r * 0.12)), p);
    p.color = fill;
    canvas.drawPath(path, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, r * 0.12)
      ..color = outline;
    canvas.drawPath(path, p);
    p.style = PaintingStyle.fill;
  }

  Color _seatColor(int seat) =>
      _seatColors[seat.clamp(0, _seatColors.length - 1)];

  void _drawOutlinedText(
    Canvas canvas,
    String text,
    Offset anchor,
    double size,
    Color fill,
    Color outline,
  ) {
    for (final offset in const [
      Offset(-2, -2),
      Offset(2, -2),
      Offset(-2, 2),
      Offset(2, 2),
      Offset(0, 3),
    ]) {
      _drawText(canvas, text, anchor + offset, outline, size,
          weight: FontWeight.w900);
    }
    _drawText(canvas, text, anchor, fill, size, weight: FontWeight.w900);
  }

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
        oldDelegate.pulse != pulse ||
        oldDelegate.titlePlaque != titlePlaque ||
        oldDelegate.pieceImages != pieceImages ||
        oldDelegate.boardTheme != boardTheme;
  }
}

enum _TextAnchor { center, topLeft }
