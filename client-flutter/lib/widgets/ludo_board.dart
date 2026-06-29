// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/game_snapshot.dart';
import '../theme/app_theme.dart';

// ── Board geometry — exact port from Java BoardView ────────────────────────────

class _BoardConsts {
  static const path = [
    [6, 14],
    [6, 13],
    [6, 12],
    [6, 11],
    [6, 10],
    [6, 9],
    [5, 8],
    [4, 8],
    [3, 8],
    [2, 8],
    [1, 8],
    [0, 8],
    [0, 7],
    [0, 6],
    [1, 6],
    [2, 6],
    [3, 6],
    [4, 6],
    [5, 6],
    [6, 5],
    [6, 4],
    [6, 3],
    [6, 2],
    [6, 1],
    [6, 0],
    [7, 0],
    [8, 0],
    [8, 1],
    [8, 2],
    [8, 3],
    [8, 4],
    [8, 5],
    [9, 6],
    [10, 6],
    [11, 6],
    [12, 6],
    [13, 6],
    [14, 6],
    [14, 7],
    [14, 8],
    [13, 8],
    [12, 8],
    [11, 8],
    [10, 8],
    [9, 8],
    [8, 9],
    [8, 10],
    [8, 11],
    [8, 12],
    [8, 13],
    [8, 14],
    [7, 14],
  ];

  // Stop/safe stars are paired around each colored home lane. Keep this in
  // sync with AppState._localSafeTrackIndexes so captures and visuals agree.
  static const safeSeats = [
    [6, 13, 0],
    [8, 13, 0],
    [1, 6, 1],
    [1, 8, 1],
    [6, 1, 2],
    [8, 1, 2],
    [13, 6, 3],
    [13, 8, 3],
  ];

  static const homeLanes = [
    [
      [7, 13],
      [7, 12],
      [7, 11],
      [7, 10],
      [7, 9]
    ], // Red (seat 0)
    [
      [1, 7],
      [2, 7],
      [3, 7],
      [4, 7],
      [5, 7]
    ], // Blue (seat 1)
    [
      [7, 1],
      [7, 2],
      [7, 3],
      [7, 4],
      [7, 5]
    ], // Yellow (seat 2)
    [
      [13, 7],
      [12, 7],
      [11, 7],
      [10, 7],
      [9, 7]
    ], // Green (seat 3)
  ];

  static const bases = [
    [0, 9],
    [0, 0],
    [9, 0],
    [9, 9]
  ];
  static const slots = [
    [2.1, 2.1],
    [3.9, 2.1],
    [2.1, 3.9],
    [3.9, 3.9]
  ];
  static const seatStarts = [1, 14, 27, 40];
}

// ── Tap hit record ─────────────────────────────────────────────────────────────

class _PieceHit {
  final String pieceId;
  final double cx, cy, r;
  final bool legal;
  const _PieceHit(this.pieceId, this.cx, this.cy, this.r, this.legal);
}

class _PieceDraw {
  final PieceState piece;
  final String key;
  final Offset center;

  const _PieceDraw({
    required this.piece,
    required this.key,
    required this.center,
  });
}

// ── Public widget ──────────────────────────────────────────────────────────────

class LudoBoard extends StatefulWidget {
  final GameSnapshot? snapshot;
  final int? mySeat;
  final void Function(String pieceId) onPieceTap;
  final bool showWaitingOverlay;

  const LudoBoard({
    super.key,
    required this.snapshot,
    required this.mySeat,
    required this.onPieceTap,
    this.showWaitingOverlay = true,
  });

  @override
  State<LudoBoard> createState() => _LudoBoardState();
}

class _LudoBoardState extends State<LudoBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;
  final List<_PieceHit> _hits = [];
  Map<int, ui.Image> _pieceImages = const {};

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.2, end: 1.0).animate(_pulse);
    _loadPieceImages();
  }

  @override
  void dispose() {
    _pulse.dispose();
    for (final image in _pieceImages.values) {
      image.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPieceImages() async {
    const paths = [
      'assets/images/rush/rush_goti_red_v2.png',
      'assets/images/rush/rush_goti_blue_v2.png',
      'assets/images/rush/rush_goti_yellow_v2.png',
      'assets/images/rush/rush_goti_green_v2.png',
    ];
    final loaded = <int, ui.Image>{};
    for (int i = 0; i < paths.length; i++) {
      final data = await rootBundle.load(paths[i]);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      loaded[i] = frame.image;
    }
    if (!mounted) {
      for (final image in loaded.values) {
        image.dispose();
      }
      return;
    }
    setState(() {
      for (final image in _pieceImages.values) {
        image.dispose();
      }
      _pieceImages = loaded;
    });
  }

  void _handleTap(Offset pos) {
    _PieceHit? best;
    double bestDist = double.infinity;
    for (final h in _hits) {
      final dx = pos.dx - h.cx;
      final dy = pos.dy - h.cy;
      final d = math.sqrt(dx * dx + dy * dy);
      if (h.legal && d < h.r * 2.8 && d < bestDist) {
        bestDist = d;
        best = h;
      }
    }
    if (best != null) widget.onPieceTap(best.pieceId);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: GestureDetector(
        onTapUp: (d) => _handleTap(d.localPosition),
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => CustomPaint(
            painter: _BoardPainter(
              snapshot: widget.snapshot,
              mySeat: widget.mySeat,
              pulsePhase: _pulseAnim.value,
              hits: _hits,
              showWaitingOverlay: widget.showWaitingOverlay,
              pieceImages: _pieceImages,
            ),
          ),
        ),
      ),
    );
  }
}

// ── CustomPainter ──────────────────────────────────────────────────────────────

class _BoardPainter extends CustomPainter {
  final GameSnapshot? snapshot;
  final int? mySeat;
  final double pulsePhase;
  final List<_PieceHit> hits;
  final bool showWaitingOverlay;
  final Map<int, ui.Image> pieceImages;
  static const _ivory = creamCell;
  static const _gold = goldColor;
  static const _goldDk = goldDark;

  _BoardPainter({
    required this.snapshot,
    required this.mySeat,
    required this.pulsePhase,
    required this.hits,
    required this.showWaitingOverlay,
    required this.pieceImages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outer = math.min(w, h).toDouble();
    final left = (w - outer) / 2;
    final top = (h - outer) / 2;
    final margin = outer * (13 / 600);
    final boardSize = outer - margin * 2;
    final boardLeft = left + margin;
    final boardTop = top + margin;
    final cell = boardSize / 15.0;

    _drawShell(canvas, left, top, outer, margin);

    final boardRect = Rect.fromLTWH(boardLeft, boardTop, boardSize, boardSize);
    canvas.save();
    canvas.clipRRect(RRect.fromRectXY(boardRect, outer * 0.012, outer * 0.012));
    _drawBases(canvas, boardLeft, boardTop, cell);
    _drawTrack(canvas, boardLeft, boardTop, cell);
    _drawHomeLanes(canvas, boardLeft, boardTop, cell);
    _drawGridLines(canvas, boardLeft, boardTop, cell, boardSize);
    _drawBaseNestPanels(canvas, boardLeft, boardTop, cell);
    _drawSafeStars(canvas, boardLeft, boardTop, cell);
    _drawHomeLaneArrows(canvas, boardLeft, boardTop, cell);
    _drawCenter(canvas, boardLeft, boardTop, cell);
    if (snapshot == null) _drawPreviewPieces(canvas, boardLeft, boardTop, cell);
    if (snapshot != null)
      _drawMissingSeatPieces(canvas, boardLeft, boardTop, cell);
    _drawPieces(canvas, boardLeft, boardTop, cell);
    canvas.restore();

    _drawTopGloss(canvas, boardLeft, boardTop, boardSize);
    if (snapshot == null && showWaitingOverlay) {
      _drawEmpty(canvas, boardLeft, boardTop, boardSize);
    }
  }

  // ── Color helpers ──────────────────────────────────────────────────────────

  // Flutter 3.22 in GitHub Actions does not expose Color.a/r/g/b yet.
  static int _toInt(Color c) =>
      (c.alpha << 24) | (c.red << 16) | (c.green << 8) | c.blue;

  static int _blend(int a, int b, double t) {
    final ia = 1.0 - t;
    final aa = ((((a >> 24) & 0xff) * ia) + (((b >> 24) & 0xff) * t)).round();
    final rr = ((((a >> 16) & 0xff) * ia) + (((b >> 16) & 0xff) * t)).round();
    final gg = ((((a >> 8) & 0xff) * ia) + (((b >> 8) & 0xff) * t)).round();
    final bb = (((a & 0xff) * ia) + ((b & 0xff) * t)).round();
    return (aa << 24) | (rr << 16) | (gg << 8) | bb;
  }

  static Color _seatCol(int s) => AppColors.seatColors[s.clamp(0, 3)];

  // ── Board shell ────────────────────────────────────────────────────────────

  void _drawShell(
      Canvas canvas, double left, double top, double size, double margin) {
    final p = Paint()..isAntiAlias = true;
    final outerRect = Rect.fromLTWH(
      left + size * 0.012,
      top + size * 0.012,
      size * 0.976,
      size * 0.976,
    );
    final outerR = RRect.fromRectXY(outerRect, size * 0.018, size * 0.018);

    p.color = const Color(0x66000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(left + size * 0.5, top + size * 0.968),
        width: size * 0.86,
        height: size * 0.07,
      ),
      p,
    );

    p.shader = ui.Gradient.linear(
      outerRect.topLeft,
      outerRect.bottomRight,
      const [
        Color(0xFFFFE35C),
        Color(0xFFC77B09),
        Color(0xFF6F3708),
        Color(0xFF3C1904),
      ],
      const [0.0, 0.45, 0.78, 1.0],
    );
    canvas.drawRRect(outerR, p);
    p.shader = null;

    p.style = PaintingStyle.stroke;
    p.strokeWidth = size * 0.006;
    p.color = const Color(0xFFFFF0A3);
    canvas.drawRRect(outerR.deflate(size * 0.006), p);
    p.style = PaintingStyle.fill;

    final innerRect = Rect.fromLTWH(
        left + margin, top + margin, size - margin * 2, size - margin * 2);
    final innerR = RRect.fromRectXY(innerRect, size * 0.011, size * 0.011);
    p.shader = ui.Gradient.linear(
      innerRect.topLeft,
      innerRect.bottomRight,
      const [Color(0xFFFFF7DC), Color(0xFFF1DFAD)],
    );
    canvas.drawRRect(innerR, p);
    p.shader = null;

    p.style = PaintingStyle.stroke;
    p.strokeWidth = size * 0.006;
    p.color = const Color(0xFFD79A12);
    canvas.drawRRect(innerR, p);
    p.style = PaintingStyle.fill;
  }

  void _drawTopGloss(Canvas canvas, double left, double top, double size) {
    final p = Paint()..isAntiAlias = true;
    final rect = Rect.fromLTWH(left, top, size, size * 0.18);
    p.shader = ui.Gradient.linear(
      rect.topCenter,
      rect.bottomCenter,
      [Colors.white.withAlpha(42), Colors.white.withAlpha(0)],
    );
    canvas.drawRect(rect, p);
    p.shader = null;
  }

  // ── Bases ──────────────────────────────────────────────────────────────────

  void _drawBases(Canvas canvas, double left, double top, double cell) {
    _drawBase(canvas, left, top, cell, 0, 9, boardRed); // Red   bottom-left
    _drawBase(canvas, left, top, cell, 0, 0, boardBlue); // Blue  top-left
    _drawBase(canvas, left, top, cell, 9, 0, boardYellow); // Yellow top-right
    _drawBase(canvas, left, top, cell, 9, 9, boardGreen); // Green bottom-right
  }

  void _drawBaseNestPanels(
      Canvas canvas, double left, double top, double cell) {
    for (final base in _BoardConsts.bases) {
      _drawBaseNestPanel(canvas, left, top, cell, base[0], base[1]);
    }
  }

  void _drawBaseNestPanel(
      Canvas canvas, double left, double top, double cell, int gx, int gy) {
    final p = Paint()..isAntiAlias = true;
    final x1 = left + gx * cell;
    final y1 = top + gy * cell;
    final x2 = left + (gx + 6) * cell;
    final y2 = top + (gy + 6) * cell;

    final ins = cell * 0.64;
    final innerRect = Rect.fromLTRB(x1 + ins, y1 + ins, x2 - ins, y2 - ins);
    final innerRR = RRect.fromRectXY(innerRect, cell * 0.35, cell * 0.35);
    p.shader = ui.Gradient.linear(
      innerRect.topLeft,
      innerRect.bottomRight,
      const [Color(0xFFFFFCF4), Color(0xFFF2E5C8)],
    );
    canvas.drawRRect(innerRR, p);
    p.shader = null;

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.05
      ..color = _gold.withAlpha(180);
    canvas.drawRRect(innerRR, p);
    p.style = PaintingStyle.fill;

    p.shader = ui.Gradient.linear(
      innerRect.topCenter,
      innerRect.bottomCenter,
      [Colors.white.withAlpha(64), Colors.white.withAlpha(0)],
    );
    canvas.drawRRect(innerRR.deflate(cell * 0.10), p);
    p.shader = null;
  }

  void _drawBase(Canvas canvas, double left, double top, double cell, int gx,
      int gy, Color color) {
    final p = Paint()..isAntiAlias = true;
    final x1 = left + gx * cell;
    final y1 = top + gy * cell;
    final x2 = left + (gx + 6) * cell;
    final y2 = top + (gy + 6) * cell;
    final rect = Rect.fromLTRB(x1, y1, x2, y2);

    final dark = Color(_blend(_toInt(color), 0xFF000000, 0.24));
    final light = Color(_blend(_toInt(color), 0xFFFFFFFF, 0.18));
    p.shader = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      [light, color, dark],
      const [0.0, 0.62, 1.0],
    );
    canvas.drawRect(rect, p);
    p.shader = null;

    p.style = PaintingStyle.stroke;
    p.strokeWidth = cell * 0.08;
    p.color = _gold;
    canvas.drawRect(rect, p);
    p.style = PaintingStyle.fill;

    // WHITE inner region for nests (Ludo Star style)
    p.color = Colors.white.withAlpha(48);
    p.strokeWidth = cell * 0.10;
    canvas.drawLine(
      Offset(x1 + cell * 0.35, y1 + cell * 0.35),
      Offset(x2 - cell * 0.35, y1 + cell * 0.35),
      p,
    );

    final ins = cell * 0.64;
    final innerRect = Rect.fromLTRB(x1 + ins, y1 + ins, x2 - ins, y2 - ins);
    final innerRR = RRect.fromRectXY(innerRect, cell * 0.35, cell * 0.35);
    p.shader = ui.Gradient.linear(
      innerRect.topLeft,
      innerRect.bottomRight,
      const [Color(0xFFFFFBF2), Color(0xFFF1E4C5)],
    );
    canvas.drawRRect(innerRR, p);
    p.shader = null;
    // Subtle inner border
    p.style = PaintingStyle.stroke;
    p.strokeWidth = cell * 0.05;
    p.color = _gold.withAlpha(165);
    canvas.drawRRect(innerRR, p);
    p.style = PaintingStyle.fill;

    // 4 nest circles — vivid, 3D-looking
    final cx = (x1 + x2) / 2;
    final cy = (y1 + y2) / 2;
    final off = cell * 0.82;
    final r = cell * 0.28;

    for (int i = 0; i < 4; i++) {
      final px = cx + (i % 2 == 0 ? -off : off);
      final py = cy + (i < 2 ? -off : off);

      // Drop shadow
      p.color = const Color(0x28000000);
      canvas.drawCircle(Offset(px, py + r * 0.10), r * 1.08, p);

      // VIVID color fill (like Ludo Star)
      p.shader = ui.Gradient.radial(
        Offset(px - r * 0.25, py - r * 0.25),
        r * 1.25,
        const [Color(0xFFFFFCF4), Color(0xFFF3E5C4)],
      );
      canvas.drawCircle(Offset(px, py), r, p);
      p.shader = null;

      // Slightly darker edge for 3D depth
      p.style = PaintingStyle.stroke;
      p.strokeWidth = cell * 0.035;
      p.color = const Color(0xD6B78016);
      canvas.drawCircle(Offset(px, py), r, p);
      p.style = PaintingStyle.fill;

      // Gold outer ring
      p.style = PaintingStyle.stroke;
      p.strokeWidth = cell * 0.05;
      p.color = _gold;
      canvas.drawCircle(Offset(px, py), r * 1.15, p);
      p.style = PaintingStyle.fill;

      // White top-left shine for 3D sphere effect
      p.color = const Color(0x88FFFFFF);
      canvas.drawCircle(Offset(px - r * 0.28, py - r * 0.30), r * 0.38, p);
      p.color = const Color(0x44FFFFFF);
      canvas.drawCircle(Offset(px - r * 0.14, py - r * 0.16), r * 0.20, p);
    }
  }

  // ── Track ──────────────────────────────────────────────────────────────────

  void _drawTrack(Canvas canvas, double left, double top, double cell) {
    for (int i = 0; i < _BoardConsts.path.length; i++) {
      final p = _BoardConsts.path[i];
      _drawCell(
        canvas,
        left,
        top,
        cell,
        p[0],
        p[1],
        _toInt(_ivory),
        0xCC9B701F,
      );
    }
  }

  // ── Home lanes ─────────────────────────────────────────────────────────────

  void _drawHomeLanes(Canvas canvas, double left, double top, double cell) {
    for (int seat = 0; seat < 4; seat++) {
      for (final p in _BoardConsts.homeLanes[seat]) {
        // Use vivid seat color (not semi-transparent) like Ludo Star
        _drawCell(canvas, left, top, cell, p[0], p[1], _toInt(_seatCol(seat)),
            0xCC9B701F);
      }
    }
  }

  // ── Grid lines ─────────────────────────────────────────────────────────────

  void _drawSafeStars(Canvas canvas, double left, double top, double cell) {
    for (final p in _BoardConsts.safeSeats) {
      final seatColor = _seatCol(p[2]);
      _drawStar5(
        canvas,
        left + (p[0] + 0.5) * cell,
        top + (p[1] + 0.5) * cell,
        cell * 0.30,
        seatColor,
        Color(_blend(_toInt(seatColor), 0xFF000000, 0.34)),
      );
    }
  }

  void _drawHomeLaneArrows(
      Canvas canvas, double left, double top, double cell) {
    for (int seat = 0; seat < 4; seat++) {
      final p = _BoardConsts.homeLanes[seat].first;
      _drawHomeLaneArrow(
        canvas,
        left + (p[0] + 0.5) * cell,
        top + (p[1] + 0.5) * cell,
        cell,
        seat,
        _seatCol(seat),
      );
    }
  }

  void _drawHomeLaneArrow(
      Canvas canvas, double cx, double cy, double cell, int seat, Color color) {
    final angle = switch (seat) {
      0 => 0.0, // Red moves up toward center.
      1 => math.pi / 2, // Blue moves right toward center.
      2 => math.pi, // Yellow moves down toward center.
      _ => -math.pi / 2, // Green moves left toward center.
    };
    final s = cell * 0.58;
    final dark = Color(_blend(_toInt(color), 0xFF000000, 0.45));
    final path = Path()
      ..moveTo(0, -s * 0.46)
      ..lineTo(-s * 0.30, -s * 0.08)
      ..lineTo(-s * 0.12, -s * 0.08)
      ..lineTo(-s * 0.12, s * 0.34)
      ..lineTo(s * 0.12, s * 0.34)
      ..lineTo(s * 0.12, -s * 0.08)
      ..lineTo(s * 0.30, -s * 0.08)
      ..close();

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    final p = Paint()..isAntiAlias = true;
    p.color = const Color(0x33000000);
    canvas.drawPath(path.shift(Offset(0, cell * 0.045)), p);
    p.color = Colors.white.withAlpha(185);
    canvas.drawPath(path, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, cell * 0.035)
      ..color = dark;
    canvas.drawPath(path, p);
    p.style = PaintingStyle.fill;
    canvas.restore();
  }

  void _drawPreviewPieces(Canvas canvas, double left, double top, double cell) {
    for (int seat = 0; seat < 4; seat++) {
      for (int i = 0; i < 4; i++) {
        final pos = _yardPos(seat, i, left, top, cell);
        _drawPiece(
            canvas, pos.dx, pos.dy, cell * 0.45, _seatCol(seat), false, false,
            seat: seat);
      }
    }
  }

  void _drawMissingSeatPieces(
      Canvas canvas, double left, double top, double cell) {
    final activeSeats = snapshot!.pieces.map((piece) => piece.seat).toSet();
    for (int seat = 0; seat < 4; seat++) {
      if (activeSeats.contains(seat)) continue;
      for (int i = 0; i < 4; i++) {
        final pos = _yardPos(seat, i, left, top, cell);
        _drawPiece(
            canvas, pos.dx, pos.dy, cell * 0.45, _seatCol(seat), false, false,
            seat: seat);
      }
    }
  }

  void _drawGridLines(
      Canvas canvas, double left, double top, double cell, double size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, cell * 0.015)
      ..color = const Color(0x22000000);
    for (int i = 0; i <= 15; i++) {
      final pos = i * cell;
      canvas.drawLine(
          Offset(left + pos, top), Offset(left + pos, top + 15 * cell), p);
      canvas.drawLine(
          Offset(left, top + pos), Offset(left + 15 * cell, top + pos), p);
    }
  }

  // ── Center ─────────────────────────────────────────────────────────────────

  void _drawCenter(Canvas canvas, double left, double top, double cell) {
    final cx = left + 7.5 * cell;
    final cy = top + 7.5 * cell;
    final x6 = left + 6 * cell;
    final x9 = left + 9 * cell;
    final y6 = top + 6 * cell;
    final y9 = top + 9 * cell;
    final p = Paint();

    // Cream background
    p.color = const Color(0xFFFFF8E8);
    canvas.drawRect(Rect.fromLTRB(x6, y6, x9, y9), p);

    // 4 colored triangles
    void tri(List<Offset> pts, Color color) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy)
        ..close();
      p.color = color;
      canvas.drawPath(path, p);
    }

    tri([Offset(x6, y9), Offset(x9, y9), Offset(cx, cy)],
        boardRed); // bottom to red
    tri([Offset(x6, y6), Offset(x6, y9), Offset(cx, cy)],
        boardBlue); // left to blue
    tri([Offset(x6, y6), Offset(x9, y6), Offset(cx, cy)],
        boardYellow); // top to yellow
    tri([Offset(x9, y6), Offset(x9, y9), Offset(cx, cy)],
        boardGreen); // right to green

    // Diagonal accent lines
    p.style = PaintingStyle.stroke;
    p.strokeWidth = cell * 0.04;
    p.color = const Color(0x88D4AF37);
    canvas.drawLine(Offset(x6, y6), Offset(x9, y9), p);
    canvas.drawLine(Offset(x6, y9), Offset(x9, y6), p);

    // Gold ring
    p.strokeWidth = cell * 0.20;
    p.color = _gold;
    canvas.drawCircle(Offset(cx, cy), cell * 0.96, p);

    p.strokeWidth = cell * 0.04;
    p.color = _goldDk;
    canvas.drawCircle(Offset(cx, cy), cell * 1.10, p);
    p.style = PaintingStyle.fill;

    // Cream fill
    p.color = const Color(0xFFFFF8E8);
    canvas.drawCircle(Offset(cx, cy), cell * 0.64, p);

    _drawStar6(canvas, cx, cy, cell * 0.58, _gold, _goldDk);
  }

  void _drawStar6(Canvas canvas, double cx, double cy, double r, Color fill,
      Color outline) {
    final path = Path();
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + i * math.pi / 6;
      final rr = i % 2 == 0 ? r : r * 0.5;
      final x = cx + math.cos(angle) * rr;
      final y = cy + math.sin(angle) * rr;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    final p = Paint()..color = fill;
    canvas.drawPath(path, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..color = outline;
    canvas.drawPath(path, p);
    p.style = PaintingStyle.fill;
  }

  void _drawStar5(
      Canvas canvas, double cx, double cy, double radius, Color color,
      [Color outline = const Color(0xFFA36D00)]) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i % 2 == 0 ? radius : radius * 0.45;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r;
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    final p = Paint()..color = color;
    canvas.drawPath(path, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, radius * 0.10)
      ..color = outline;
    canvas.drawPath(path, p);
    p.style = PaintingStyle.fill;
  }

  void _drawCell(Canvas canvas, double left, double top, double cell, int gx,
      int gy, int fill, int stroke) {
    final pad = cell * 0.03;
    final rect = Rect.fromLTRB(
      left + gx * cell + pad,
      top + gy * cell + pad,
      left + (gx + 1) * cell - pad,
      top + (gy + 1) * cell - pad,
    );
    final p = Paint()..isAntiAlias = true;
    final fillColor = Color(fill);
    final isIvory = fill == _toInt(_ivory);
    p.shader = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      isIvory
          ? const [Color(0xFFFFFBEA), Color(0xFFF1E1B4)]
          : [
              Color(_blend(fill, 0xFFFFFFFF, 0.22)),
              fillColor,
              Color(_blend(fill, 0xFF000000, 0.16)),
            ],
      isIvory ? null : const [0.0, 0.56, 1.0],
    );
    canvas.drawRRect(
      RRect.fromRectXY(rect, cell * 0.05, cell * 0.05),
      p,
    );
    p.shader = null;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = math.max(0.8, cell * 0.030);
    p.color = Color(stroke);
    canvas.drawRRect(
      RRect.fromRectXY(rect, cell * 0.05, cell * 0.05),
      p,
    );
    p.style = PaintingStyle.fill;
  }

  // ── Pieces ─────────────────────────────────────────────────────────────────

  void _drawPieces(Canvas canvas, double left, double top, double cell) {
    hits.clear();
    if (snapshot == null) return;
    final avail = snapshot!.availableMoves.toSet();
    final activeSeat = snapshot!.currentTurnSeat;

    final groups = <String, List<_PieceDraw>>{};
    for (final piece in snapshot!.pieces) {
      final draw = _pieceDraw(piece, left, top, cell);
      groups.putIfAbsent(draw.key, () => []).add(draw);
    }

    for (final group in groups.values) {
      final total = group.length;
      for (int i = 0; i < total; i++) {
        final draw = group[i];
        final piece = draw.piece;
        final pos = _stackedPiecePos(draw.center, i, total, cell);
        final r = _stackedPieceRadius(cell, total);
        final legal = avail.contains(piece.pieceId);
        hits.add(_PieceHit(piece.pieceId, pos.dx, pos.dy, r, legal));
        _drawPiece(canvas, pos.dx, pos.dy, r, _seatCol(piece.seat), legal,
            activeSeat == piece.seat,
            seat: piece.seat);
      }
    }
  }

  double _stackedPieceRadius(double cell, int total) {
    if (total <= 1) return cell * 0.46;
    if (total == 2) return cell * 0.38;
    if (total == 3) return cell * 0.34;
    return cell * 0.31;
  }

  Offset _stackedPiecePos(Offset center, int index, int total, double cell) {
    if (total <= 1) return center;
    final d = cell * (total == 2 ? 0.19 : 0.21);
    final offsets = switch (total) {
      2 => [Offset(-d, 0), Offset(d, 0)],
      3 => [
          Offset(0, -d * 0.88),
          Offset(-d, d * 0.74),
          Offset(d, d * 0.74),
        ],
      _ => [
          Offset(-d, -d),
          Offset(d, -d),
          Offset(-d, d),
          Offset(d, d),
        ],
    };
    return center + offsets[index.clamp(0, offsets.length - 1)];
  }

  void _drawPiece(Canvas canvas, double cx, double cy, double r, Color color,
      bool legal, bool active,
      {required int seat}) {
    final p = Paint()..isAntiAlias = true;

    // Pulse / selection ring
    if (legal || active) {
      p.style = PaintingStyle.stroke;
      final alpha = legal ? pulsePhase : 0.55;
      p.color =
          Color(((alpha * 220).round() << 24) | (_toInt(_gold) & 0x00FFFFFF));
      p.strokeWidth = legal ? r * 0.40 : r * 0.20;
      canvas.drawCircle(Offset(cx, cy), r * (legal ? 1.70 : 1.38), p);
      p.style = PaintingStyle.fill;
    }

    final image = pieceImages[seat.clamp(0, 3)];
    if (image != null) {
      final imageH = r * 2.34;
      final imageW = imageH * image.width / image.height;
      final dest = Rect.fromCenter(
        center: Offset(cx, cy - r * 0.06),
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
      if (legal) {
        _drawLegalArrow(canvas, cx, cy, r);
      }
      return;
    }

    final lightColor = Color(_blend(_toInt(color), 0xFFFFFFFF, 0.42));
    final midColor = color;
    final darkColor = Color(_blend(_toInt(color), 0xFF000000, 0.38));
    final edgeColor = Color(_blend(_toInt(color), 0xFF000000, 0.58));

    p.color = const Color(0x47000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.82),
        width: r * 1.95,
        height: r * 0.40,
      ),
      p,
    );

    final baseRect = Rect.fromCenter(
      center: Offset(cx, cy + r * 0.56),
      width: r * 1.56,
      height: r * 0.48,
    );
    p
      ..shader = null
      ..style = PaintingStyle.fill
      ..color = edgeColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.64),
        width: r * 1.62,
        height: r * 0.44,
      ),
      p,
    );
    p.shader = ui.Gradient.linear(
      baseRect.topLeft,
      baseRect.bottomRight,
      [lightColor, midColor, edgeColor],
      const [0.0, 0.48, 1.0],
    );
    canvas.drawOval(baseRect, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r * 0.08)
      ..color = edgeColor;
    canvas.drawOval(baseRect, p);
    p.style = PaintingStyle.fill;

    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy + r * 0.18),
      width: r * 1.08,
      height: r * 1.32,
    );
    p.color = edgeColor;
    canvas.drawOval(bodyRect.inflate(r * 0.06), p);
    p.shader = ui.Gradient.linear(
      bodyRect.topLeft,
      bodyRect.bottomRight,
      [lightColor, midColor, darkColor],
      const [0.0, 0.48, 1.0],
    );
    canvas.drawOval(bodyRect, p);
    p.shader = null;

    final neckRect = Rect.fromCenter(
      center: Offset(cx, cy - r * 0.20),
      width: r * 0.78,
      height: r * 0.30,
    );
    p.shader = ui.Gradient.linear(
      neckRect.topLeft,
      neckRect.bottomRight,
      [lightColor, midColor, darkColor],
      const [0.0, 0.52, 1.0],
    );
    canvas.drawOval(neckRect, p);
    p.shader = null;

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r * 0.07)
      ..color = edgeColor;
    canvas.drawOval(neckRect, p);
    p.style = PaintingStyle.fill;

    p.color = edgeColor;
    canvas.drawCircle(Offset(cx, cy - r * 0.66), r * 0.52, p);
    p.shader = ui.Gradient.radial(
      Offset(cx - r * 0.20, cy - r * 0.86),
      r * 0.76,
      [lightColor, midColor, darkColor],
      const [0.0, 0.58, 1.0],
    );
    canvas.drawCircle(Offset(cx, cy - r * 0.66), r * 0.46, p);
    p.shader = null;

    p.color = Colors.white.withAlpha(110);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - r * 0.18, cy - r * 0.90),
        width: r * 0.26,
        height: r * 0.18,
      ),
      p,
    );

    p.color = Colors.white.withAlpha(72);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - r * 0.28, cy + r * 0.16),
        width: r * 0.20,
        height: r * 0.62,
      ),
      p,
    );

    // Selection arrow above
    if (legal) {
      _drawLegalArrow(canvas, cx, cy, r);
    }
  }

  void _drawLegalArrow(Canvas canvas, double cx, double cy, double r) {
    final ap = Paint()
      ..isAntiAlias = true
      ..color = Color(((pulsePhase * 200 + 55).round() << 24) | 0x00FFFFFF);
    final arrowPath = Path()
      ..moveTo(cx, cy - r * 2.1)
      ..lineTo(cx - r * 0.38, cy - r * 1.6)
      ..lineTo(cx + r * 0.38, cy - r * 1.6)
      ..close();
    canvas.drawPath(arrowPath, ap);
  }

  // ── Piece position calculation ─────────────────────────────────────────────

  _PieceDraw _pieceDraw(
      PieceState piece, double left, double top, double cell) {
    final seat = piece.seat;
    final pi = _pieceIdx(piece.pieceId);
    final state = piece.state;
    final progress = piece.progress;

    if (state == 'yard' || progress < 0) {
      return _PieceDraw(
        piece: piece,
        key: 'yard-$seat-$pi',
        center: _yardPos(seat, pi, left, top, cell),
      );
    }
    if (state == 'finished' || progress >= 57) {
      return _PieceDraw(
        piece: piece,
        key: 'finished',
        center: Offset(left + 7.5 * cell, top + 7.5 * cell),
      );
    }
    if (state == 'home' || progress > 51) {
      final li = (progress - 52).clamp(0, 4);
      final lp = _BoardConsts.homeLanes[seat.clamp(0, 3)][li];
      return _PieceDraw(
        piece: piece,
        key: 'home-$seat-$li',
        center: Offset(left + (lp[0] + 0.5) * cell, top + (lp[1] + 0.5) * cell),
      );
    }

    int ti = piece.trackIndex;
    if (ti < 0 || ti >= _BoardConsts.path.length) {
      ti = (_BoardConsts.seatStarts[seat.clamp(0, 3)] + progress) %
          _BoardConsts.path.length;
    }
    final tp = _BoardConsts.path[ti];
    return _PieceDraw(
      piece: piece,
      key: 'track-$ti',
      center: Offset(left + (tp[0] + 0.5) * cell, top + (tp[1] + 0.5) * cell),
    );
  }

  Offset _yardPos(int seat, int idx, double left, double top, double cell) {
    final s = seat.clamp(0, 3);
    final base = _BoardConsts.bases[s];
    final slot = _BoardConsts.slots[idx % 4];
    return Offset(
      left + (base[0] + slot[0]) * cell,
      top + (base[1] + slot[1]) * cell,
    );
  }

  int _pieceIdx(String id) {
    if (id.isEmpty) return 0;
    final c = id.codeUnitAt(id.length - 1);
    if (c >= 0x30 && c <= 0x33) return c - 0x30;
    return 0;
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  void _drawEmpty(Canvas canvas, double left, double top, double size) {
    final rect = Rect.fromLTRB(
      left + size * 0.15,
      top + size * 0.39,
      left + size * 0.85,
      top + size * 0.61,
    );
    final p = Paint()..color = const Color(0xE6091428);
    canvas.drawRRect(RRect.fromRectXY(rect, size * 0.05, size * 0.05), p);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = math.max(2.0, size * 0.006);
    p.color = _gold;
    canvas.drawRRect(RRect.fromRectXY(rect, size * 0.05, size * 0.05), p);
    p.style = PaintingStyle.fill;

    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: size * 0.044,
    ))
      ..pushStyle(ui.TextStyle(color: _gold, fontWeight: FontWeight.bold))
      ..addText('Waiting for match');
    final para = pb.build()..layout(ui.ParagraphConstraints(width: rect.width));
    canvas.drawParagraph(para, Offset(rect.left, top + size * 0.432));

    final pb2 = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: size * 0.030,
    ))
      ..pushStyle(ui.TextStyle(color: const Color(0xffC0C7D2)))
      ..addText('Setting up your game...');
    final para2 = pb2.build()
      ..layout(ui.ParagraphConstraints(width: rect.width));
    canvas.drawParagraph(para2, Offset(rect.left, top + size * 0.506));
  }

  @override
  bool shouldRepaint(_BoardPainter old) {
    return old.snapshot != snapshot ||
        old.pulsePhase != pulsePhase ||
        old.mySeat != mySeat ||
        old.showWaitingOverlay != showWaitingOverlay ||
        old.pieceImages != pieceImages;
  }
}
