import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

  static const safeSeats = [
    [6, 13, 0],
    [3, 8, 0],
    [1, 6, 1],
    [6, 3, 1],
    [8, 1, 2],
    [11, 6, 2],
    [13, 8, 3],
    [8, 11, 3],
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
  static const coloredStarts = [1, 14, 27, 40];
}

// ── Tap hit record ─────────────────────────────────────────────────────────────

class _PieceHit {
  final String pieceId;
  final double cx, cy, r;
  final bool legal;
  const _PieceHit(this.pieceId, this.cx, this.cy, this.r, this.legal);
}

// ── Public widget ──────────────────────────────────────────────────────────────

class LudoBoard extends StatefulWidget {
  final GameSnapshot? snapshot;
  final int? mySeat;
  final void Function(String pieceId) onPieceTap;

  const LudoBoard({
    super.key,
    required this.snapshot,
    required this.mySeat,
    required this.onPieceTap,
  });

  @override
  State<LudoBoard> createState() => _LudoBoardState();
}

class _LudoBoardState extends State<LudoBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;
  final List<_PieceHit> _hits = [];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.2, end: 1.0).animate(_pulse);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
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

  static const _ivory = creamCell;
  static const _gold = goldColor;
  static const _goldDk = goldDark;

  _BoardPainter({
    required this.snapshot,
    required this.mySeat,
    required this.pulsePhase,
    required this.hits,
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
    _drawCenter(canvas, boardLeft, boardTop, cell);
    _drawPieces(canvas, boardLeft, boardTop, cell);
    canvas.restore();

    _drawTopGloss(canvas, boardLeft, boardTop, boardSize);
    if (snapshot == null) _drawEmpty(canvas, boardLeft, boardTop, boardSize);
  }

  // ── Color helpers ──────────────────────────────────────────────────────────

  static int _toInt(Color c) =>
      ((c.a * 255).round() << 24) |
      ((c.r * 255).round() << 16) |
      ((c.g * 255).round() << 8) |
      (c.b * 255).round();

  static int _blend(int a, int b, double t) {
    final ia = 1.0 - t;
    final aa = ((((a >> 24) & 0xff) * ia) + (((b >> 24) & 0xff) * t)).round();
    final rr = ((((a >> 16) & 0xff) * ia) + (((b >> 16) & 0xff) * t)).round();
    final gg = ((((a >> 8) & 0xff) * ia) + (((b >> 8) & 0xff) * t)).round();
    final bb = (((a & 0xff) * ia) + ((b & 0xff) * t)).round();
    return (aa << 24) | (rr << 16) | (gg << 8) | bb;
  }

  static Color _seatCol(int s) => AppColors.seatColors[s.clamp(0, 3)];

  static int? _safeSeatAt(int gx, int gy) {
    for (final safe in _BoardConsts.safeSeats) {
      if (safe[0] == gx && safe[1] == gy) return safe[2];
    }
    return null;
  }

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
    p.color = Colors.white.withAlpha(42);
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
    p.color = _gold.withAlpha(125);
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
        [Color(_blend(_toInt(color), 0xFFFFFFFF, 0.48)), color],
      );
      canvas.drawCircle(Offset(px, py), r, p);
      p.shader = null;

      // Slightly darker edge for 3D depth
      p.style = PaintingStyle.stroke;
      p.strokeWidth = cell * 0.035;
      p.color = Color(_blend(_toInt(color), 0xFF000000, 0.22));
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
      Color fill = _ivory;
      Color stroke = const Color(0x33B8941F);
      final safeSeat = _safeSeatAt(p[0], p[1]);

      if (safeSeat != null) {
        fill = _seatCol(safeSeat);
        stroke = _gold;
      } else {
        for (int s = 0; s < _BoardConsts.coloredStarts.length; s++) {
          if (i == _BoardConsts.coloredStarts[s]) {
            fill = _seatCol(s);
            stroke = _gold;
            break;
          }
        }
      }
      _drawCell(
          canvas, left, top, cell, p[0], p[1], _toInt(fill), _toInt(stroke));
    }

    // Safe/start stars are filled with the matching player color.
    for (final p in _BoardConsts.safeSeats) {
      final seat = p[2];
      _drawStar5(
        canvas,
        left + (p[0] + 0.5) * cell,
        top + (p[1] + 0.5) * cell,
        cell * 0.27,
        seat == 2 ? const Color(0xFFFFFFFF) : _gold,
      );
    }
  }

  // ── Home lanes ─────────────────────────────────────────────────────────────

  void _drawHomeLanes(Canvas canvas, double left, double top, double cell) {
    for (int seat = 0; seat < 4; seat++) {
      for (final p in _BoardConsts.homeLanes[seat]) {
        // Use vivid seat color (not semi-transparent) like Ludo Star
        _drawCell(canvas, left, top, cell, p[0], p[1], _toInt(_seatCol(seat)),
            0xCCD4AF37);
      }
    }
  }

  // ── Grid lines ─────────────────────────────────────────────────────────────

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

    for (final piece in snapshot!.pieces) {
      final pos = _piecePos(piece, left, top, cell);
      final legal = avail.contains(piece.pieceId);
      final r = cell * 0.43;
      hits.add(_PieceHit(piece.pieceId, pos.dx, pos.dy, r, legal));
      _drawPiece(canvas, pos.dx, pos.dy, r, _seatCol(piece.seat), legal,
          activeSeat == piece.seat);
    }
  }

  void _drawPiece(Canvas canvas, double cx, double cy, double r, Color color,
      bool legal, bool active) {
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

    final darkColor = Color(_blend(_toInt(color), 0xFF000000, 0.36));
    final markColor = color == boardYellow
        ? const Color(0xFF7A5200)
        : const Color(0xFFFFF4A3);

    p.color = const Color(0x47000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 0.98),
        width: r * 2.25,
        height: r * 0.48,
      ),
      p,
    );

    p.color = const Color(0xFF7A4A08);
    canvas.drawCircle(Offset(cx, cy + r * 0.48), r * 1.02, p);

    p.shader = ui.Gradient.radial(
      Offset(cx - r * 0.20, cy + r * 0.10),
      r * 1.15,
      const [Color(0xFFE8A81A), Color(0xFFB46D05), Color(0xFF6E4100)],
      const [0.0, 0.62, 1.0],
    );
    canvas.drawCircle(Offset(cx, cy + r * 0.28), r * 1.02, p);
    p.shader = null;

    p.shader = ui.Gradient.radial(
      Offset(cx - r * 0.24, cy - r * 0.22),
      r * 1.22,
      const [Color(0xFFFFF4A3), goldColor, Color(0xFFB87800)],
      const [0.0, 0.54, 1.0],
    );
    canvas.drawCircle(Offset(cx, cy + r * 0.04), r * 1.03, p);
    p.shader = null;

    p.style = PaintingStyle.stroke;
    p.strokeWidth = math.max(1.0, r * 0.10);
    p.color = const Color(0xFF815000);
    canvas.drawCircle(Offset(cx, cy + r * 0.04), r * 1.03, p);
    p.style = PaintingStyle.fill;

    p.color = darkColor;
    canvas.drawCircle(Offset(cx, cy + r * 0.04), r * 0.78, p);

    p.shader = ui.Gradient.radial(
      Offset(cx - r * 0.24, cy - r * 0.30),
      r * 0.92,
      [
        Color(_blend(_toInt(color), 0xFFFFFFFF, 0.46)),
        color,
        darkColor,
      ],
      const [0.0, 0.56, 1.0],
    );
    canvas.drawCircle(Offset(cx, cy - r * 0.12), r * 0.68, p);
    p.shader = null;

    p.color = Colors.white.withAlpha(95);
    canvas.drawCircle(Offset(cx - r * 0.32, cy - r * 0.38), r * 0.23, p);

    p.color = markColor.withAlpha(235);
    final crown = Path()
      ..moveTo(cx - r * 0.47, cy + r * 0.18)
      ..lineTo(cx - r * 0.35, cy - r * 0.28)
      ..lineTo(cx - r * 0.11, cy - r * 0.06)
      ..lineTo(cx, cy - r * 0.40)
      ..lineTo(cx + r * 0.13, cy - r * 0.06)
      ..lineTo(cx + r * 0.35, cy - r * 0.28)
      ..lineTo(cx + r * 0.47, cy + r * 0.18)
      ..close();
    canvas.drawPath(crown, p);

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, r * 0.12)
      ..strokeCap = StrokeCap.round
      ..color = markColor.withAlpha(235);
    canvas.drawLine(
      Offset(cx - r * 0.42, cy + r * 0.30),
      Offset(cx + r * 0.42, cy + r * 0.30),
      p,
    );
    p.style = PaintingStyle.fill;

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * 0.10)
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withAlpha(44);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy + r * 0.08), radius: r * 0.75),
      0.55,
      1.45,
      false,
      p,
    );
    p.style = PaintingStyle.fill;

    // Selection arrow above
    if (legal) {
      final ap = Paint()
        ..color = Color(((pulsePhase * 200 + 55).round() << 24) | 0x00FFFFFF);
      final arrowPath = Path()
        ..moveTo(cx, cy - r * 2.1)
        ..lineTo(cx - r * 0.38, cy - r * 1.6)
        ..lineTo(cx + r * 0.38, cy - r * 1.6)
        ..close();
      canvas.drawPath(arrowPath, ap);
    }
  }

  // ── Piece position calculation ─────────────────────────────────────────────

  Offset _piecePos(PieceState piece, double left, double top, double cell) {
    final seat = piece.seat;
    final pi = _pieceIdx(piece.pieceId);
    final state = piece.state;
    final progress = piece.progress;

    if (state == 'yard' || progress < 0) {
      return _yardPos(seat, pi, left, top, cell);
    }
    if (state == 'finished' || progress >= 57) {
      return _offsetPos(Offset(left + 7.5 * cell, top + 7.5 * cell), pi, cell);
    }
    if (state == 'home' || progress > 51) {
      final li = (progress - 52).clamp(0, 4);
      final lp = _BoardConsts.homeLanes[seat.clamp(0, 3)][li];
      return _offsetPos(
        Offset(left + (lp[0] + 0.5) * cell, top + (lp[1] + 0.5) * cell),
        pi,
        cell * 0.4,
      );
    }

    int ti = piece.trackIndex;
    if (ti < 0 || ti >= _BoardConsts.path.length) {
      ti = (_BoardConsts.seatStarts[seat.clamp(0, 3)] + progress) %
          _BoardConsts.path.length;
    }
    final tp = _BoardConsts.path[ti];
    return _offsetPos(
      Offset(left + (tp[0] + 0.5) * cell, top + (tp[1] + 0.5) * cell),
      pi,
      cell * 0.34,
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

  Offset _offsetPos(Offset center, int idx, double amt) {
    final d = math.max(3.0, amt * 0.16);
    return Offset(
      center.dx + (idx % 2 == 0 ? -d : d),
      center.dy + (idx < 2 ? -d : d),
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
        old.mySeat != mySeat;
  }
}
