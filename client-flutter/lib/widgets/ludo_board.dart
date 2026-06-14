import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/game_snapshot.dart';
import '../theme/app_theme.dart';

// ── Board geometry — exact port from Java BoardView ────────────────────────────

class _BoardConsts {
  static const path = [
    [6,14],[6,13],[6,12],[6,11],[6,10],[6,9],
    [5,8],[4,8],[3,8],[2,8],[1,8],[0,8],[0,7],
    [0,6],[1,6],[2,6],[3,6],[4,6],[5,6],
    [6,5],[6,4],[6,3],[6,2],[6,1],[6,0],[7,0],
    [8,0],[8,1],[8,2],[8,3],[8,4],[8,5],
    [9,6],[10,6],[11,6],[12,6],[13,6],[14,6],[14,7],
    [14,8],[13,8],[12,8],[11,8],[10,8],[9,8],
    [8,9],[8,10],[8,11],[8,12],[8,13],[8,14],[7,14],
  ];

  static const safe = [
    [6,14],[3,8],[0,6],[6,3],[8,0],[11,6],[14,8],[8,11],
  ];

  static const homeLanes = [
    [[7,13],[7,12],[7,11],[7,10],[7,9]],   // Red (seat 0)
    [[1,7],[2,7],[3,7],[4,7],[5,7]],        // Blue (seat 1)
    [[7,1],[7,2],[7,3],[7,4],[7,5]],        // Yellow (seat 2)
    [[13,7],[12,7],[11,7],[10,7],[9,7]],    // Green (seat 3)
  ];

  static const bases    = [[0,9],[0,0],[9,0],[9,9]];
  static const slots    = [[2.1,2.1],[3.9,2.1],[2.1,3.9],[3.9,3.9]];
  static const seatStarts      = [0, 13, 26, 39];
  static const coloredStarts   = [0, 13, 26, 39];
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
      final d  = math.sqrt(dx * dx + dy * dy);
      if (h.legal && d < h.r * 2.8 && d < bestDist) {
        bestDist = d;
        best = h;
      }
    }
    if (best != null) widget.onPieceTap(best.pieceId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: woodBrown,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x44FFD426), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTapUp: (d) => _handleTap(d.localPosition),
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => CustomPaint(
            painter: _BoardPainter(
              snapshot:   widget.snapshot,
              mySeat:     widget.mySeat,
              pulsePhase: _pulseAnim.value,
              hits:       _hits,
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
  final int?          mySeat;
  final double        pulsePhase;
  final List<_PieceHit> hits;

  static const _ivory  = creamCell;
  static const _gold   = goldColor;
  static const _goldDk = goldDark;

  _BoardPainter({
    required this.snapshot,
    required this.mySeat,
    required this.pulsePhase,
    required this.hits,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w    = size.width;
    final h    = size.height;
    final sz   = math.min(w, h).toDouble();
    final left = (w - sz) / 2;
    final top  = (h - sz) / 2;
    final cell = sz / 15.0;

    _drawShell(canvas, left, top, sz);
    _drawBases(canvas, left, top, cell);
    _drawTrack(canvas, left, top, cell);
    _drawHomeLanes(canvas, left, top, cell);
    _drawGridLines(canvas, left, top, cell, sz);
    _drawCenter(canvas, left, top, cell);
    _drawPieces(canvas, left, top, cell);
    if (snapshot == null) _drawEmpty(canvas, left, top, sz);
  }

  // ── Color helpers ──────────────────────────────────────────────────────────

  static int _toInt(Color c) =>
      (c.alpha << 24) |
      (c.red   << 16) |
      (c.green << 8)  |
      c.blue;

  static int _blend(int a, int b, double t) {
    final ia = 1.0 - t;
    final aa = ((((a >> 24) & 0xff) * ia) + (((b >> 24) & 0xff) * t)).round();
    final rr = ((((a >> 16) & 0xff) * ia) + (((b >> 16) & 0xff) * t)).round();
    final gg = ((((a >> 8)  & 0xff) * ia) + (((b >> 8)  & 0xff) * t)).round();
    final bb = (((a & 0xff) * ia) + ((b & 0xff) * t)).round();
    return (aa << 24) | (rr << 16) | (gg << 8) | bb;
  }

  static Color _seatCol(int s) => AppColors.seatColors[s.clamp(0, 3)];

  static Color _seatSoft(int s) {
    const soft = [
      Color(0xAAE53935), Color(0xAA1E88E5), Color(0xAAFFB300), Color(0xAA43A047),
    ];
    return soft[s.clamp(0, 3)];
  }

  // ── Board shell ────────────────────────────────────────────────────────────

  void _drawShell(Canvas canvas, double left, double top, double size) {
    final p = Paint();
    final rect = Rect.fromLTWH(left, top, size, size);

    // Cream board face
    p.color = const Color(0xFFFAF4E0);
    canvas.drawRect(rect, p);

    // Wooden inner border
    p.style = PaintingStyle.stroke;
    p.strokeWidth = math.max(3.0, size * 0.012);
    p.color = woodLight;
    canvas.drawRect(rect, p);

    // Gold accent line
    final inset = p.strokeWidth / 2 + math.max(1.5, size * 0.006);
    final inner = Rect.fromLTRB(
        left + inset, top + inset, left + size - inset, top + size - inset);
    p.strokeWidth = math.max(1.5, size * 0.006);
    p.color = _gold;
    canvas.drawRect(inner, p);
    p.style = PaintingStyle.fill;
  }

  // ── Bases ──────────────────────────────────────────────────────────────────

  void _drawBases(Canvas canvas, double left, double top, double cell) {
    _drawBase(canvas, left, top, cell, 0, 9, boardRed);    // Red   bottom-left
    _drawBase(canvas, left, top, cell, 0, 0, boardBlue);   // Blue  top-left
    _drawBase(canvas, left, top, cell, 9, 0, boardYellow); // Yellow top-right
    _drawBase(canvas, left, top, cell, 9, 9, boardGreen);  // Green bottom-right
  }

  void _drawBase(Canvas canvas, double left, double top, double cell,
      int gx, int gy, Color color) {
    final p  = Paint();
    final x1 = left + gx * cell;
    final y1 = top  + gy * cell;
    final x2 = left + (gx + 6) * cell;
    final y2 = top  + (gy + 6) * cell;
    final rect = Rect.fromLTRB(x1, y1, x2, y2);

    // Solid color background
    p.color = color;
    canvas.drawRect(rect, p);

    // Gold outline
    p.style = PaintingStyle.stroke;
    p.strokeWidth = cell * 0.10;
    p.color = _gold;
    canvas.drawRect(rect, p);
    p.style = PaintingStyle.fill;

    // Dark inner region for nests
    final ins = cell * 0.75;
    final inner = Rect.fromLTRB(x1 + ins, y1 + ins, x2 - ins, y2 - ins);
    p.color = Color(_blend(_toInt(color), 0xFF000000, 0.40));
    canvas.drawRect(inner, p);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = cell * 0.04;
    p.color = const Color(0x88D4AF37);
    canvas.drawRect(inner, p);
    p.style = PaintingStyle.fill;

    // 4 nest circles
    final cx  = (x1 + x2) / 2;
    final cy  = (y1 + y2) / 2;
    final off = cell * 0.88;
    final r   = cell * 0.44;

    for (int i = 0; i < 4; i++) {
      final px = cx + (i % 2 == 0 ? -off : off);
      final py = cy + (i < 2 ? -off : off);

      // Shadow
      p.color = const Color(0x66000000);
      canvas.drawCircle(Offset(px, py + r * 0.10), r, p);

      // Dark nest fill
      p.color = Color(_blend(_toInt(color), 0xFF000000, 0.38));
      canvas.drawCircle(Offset(px, py), r, p);

      // Colored ring
      p.style = PaintingStyle.stroke;
      p.strokeWidth = cell * 0.07;
      p.color = color.withAlpha(180);
      canvas.drawCircle(Offset(px, py), r, p);
      p.style = PaintingStyle.fill;

      // Gold outer ring
      p.style = PaintingStyle.stroke;
      p.strokeWidth = cell * 0.045;
      p.color = _gold;
      canvas.drawCircle(Offset(px, py), r, p);
      p.style = PaintingStyle.fill;

      // Highlight
      p.color = const Color(0x99FFFFFF);
      canvas.drawCircle(Offset(px - r * 0.30, py - r * 0.32), r * 0.18, p);
    }
  }

  // ── Track ──────────────────────────────────────────────────────────────────

  void _drawTrack(Canvas canvas, double left, double top, double cell) {
    for (int i = 0; i < _BoardConsts.path.length; i++) {
      final p    = _BoardConsts.path[i];
      Color fill    = _ivory;
      Color stroke  = const Color(0x33B8941F);

      for (int s = 0; s < _BoardConsts.coloredStarts.length; s++) {
        if (i == _BoardConsts.coloredStarts[s]) {
          fill   = _seatCol(s);
          stroke = _gold;
          break;
        }
      }
      _drawCell(canvas, left, top, cell, p[0], p[1], _toInt(fill), _toInt(stroke));
    }

    // Safe-cell stars
    for (final p in _BoardConsts.safe) {
      _drawStar5(canvas,
        left + (p[0] + 0.5) * cell,
        top  + (p[1] + 0.5) * cell,
        cell * 0.27,
        _gold,
      );
    }
  }

  // ── Home lanes ─────────────────────────────────────────────────────────────

  void _drawHomeLanes(Canvas canvas, double left, double top, double cell) {
    for (int seat = 0; seat < 4; seat++) {
      for (final p in _BoardConsts.homeLanes[seat]) {
        _drawCell(canvas, left, top, cell, p[0], p[1],
          _toInt(_seatSoft(seat)), 0x66D4AF37);
      }
    }
  }

  // ── Grid lines ─────────────────────────────────────────────────────────────

  void _drawGridLines(Canvas canvas, double left, double top, double cell, double size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, cell * 0.015)
      ..color = const Color(0x22000000);
    for (int i = 0; i <= 15; i++) {
      final pos = i * cell;
      canvas.drawLine(Offset(left + pos, top), Offset(left + pos, top + 15 * cell), p);
      canvas.drawLine(Offset(left, top + pos), Offset(left + 15 * cell, top + pos), p);
    }
  }

  // ── Center ─────────────────────────────────────────────────────────────────

  void _drawCenter(Canvas canvas, double left, double top, double cell) {
    final cx = left + 7.5 * cell;
    final cy = top  + 7.5 * cell;
    final x6 = left + 6 * cell;
    final x9 = left + 9 * cell;
    final y6 = top  + 6 * cell;
    final y9 = top  + 9 * cell;
    final p  = Paint();

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
    tri([Offset(x6, y9), Offset(x9, y9), Offset(cx, cy)], boardRed);    // bottom → red
    tri([Offset(x6, y6), Offset(x6, y9), Offset(cx, cy)], boardBlue);   // left   → blue
    tri([Offset(x6, y6), Offset(x9, y6), Offset(cx, cy)], boardYellow); // top    → yellow
    tri([Offset(x9, y6), Offset(x9, y9), Offset(cx, cy)], boardGreen);  // right  → green

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

  void _drawStar6(Canvas canvas, double cx, double cy, double r, Color fill, Color outline) {
    final path = Path();
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + i * math.pi / 6;
      final rr    = i % 2 == 0 ? r : r * 0.5;
      final x = cx + math.cos(angle) * rr;
      final y = cy + math.sin(angle) * rr;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
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

  void _drawStar5(Canvas canvas, double cx, double cy, double radius, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i % 2 == 0 ? radius : radius * 0.45;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    final p = Paint()..color = color;
    canvas.drawPath(path, p);
  }

  void _drawCell(Canvas canvas, double left, double top, double cell,
      int gx, int gy, int fill, int stroke) {
    final pad  = cell * 0.03;
    final rect = Rect.fromLTRB(
      left + gx * cell + pad,       top + gy * cell + pad,
      left + (gx + 1) * cell - pad, top + (gy + 1) * cell - pad,
    );
    final p = Paint()..color = Color(fill);
    canvas.drawRect(rect, p);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = math.max(0.5, cell * 0.03);
    p.color = Color(stroke);
    canvas.drawRect(rect, p);
    p.style = PaintingStyle.fill;
  }

  // ── Pieces ─────────────────────────────────────────────────────────────────

  void _drawPieces(Canvas canvas, double left, double top, double cell) {
    hits.clear();
    if (snapshot == null) return;
    final avail      = snapshot!.availableMoves.toSet();
    final activeSeat = snapshot!.currentTurnSeat;

    for (final piece in snapshot!.pieces) {
      final pos   = _piecePos(piece, left, top, cell);
      final legal = avail.contains(piece.pieceId);
      final r     = cell * 0.38;
      hits.add(_PieceHit(piece.pieceId, pos.dx, pos.dy, r, legal));
      _drawPiece(canvas, pos.dx, pos.dy, r,
          _seatCol(piece.seat), legal, activeSeat == piece.seat);
    }
  }

  void _drawPiece(Canvas canvas, double cx, double cy, double r,
      Color color, bool legal, bool active) {
    final p = Paint()..isAntiAlias = true;

    // Pulse / selection ring
    if (legal || active) {
      p.style = PaintingStyle.stroke;
      final alpha = legal ? pulsePhase : 0.55;
      p.color = Color(((alpha * 220).round() << 24) | (_toInt(_gold) & 0x00FFFFFF));
      p.strokeWidth = legal ? r * 0.40 : r * 0.20;
      canvas.drawCircle(Offset(cx, cy), r * (legal ? 1.70 : 1.38), p);
      p.style = PaintingStyle.fill;
    }

    // Drop shadow
    p.color = const Color(0x55000000);
    canvas.drawCircle(Offset(cx + r * 0.14, cy + r * 0.18), r, p);

    // Outer gold ring
    p.color = _gold;
    canvas.drawCircle(Offset(cx, cy), r, p);

    // Dark inner ring
    p.color = const Color(0xFF222222);
    canvas.drawCircle(Offset(cx, cy), r * 0.84, p);

    // Radial gradient colored fill
    p.shader = ui.Gradient.radial(
      Offset(cx - r * 0.26, cy - r * 0.26),
      r * 1.1,
      [
        Color(_blend(_toInt(color), 0xFFFFFFFF, 0.40)),
        color,
        Color(_blend(_toInt(color), 0xFF000000, 0.30)),
      ],
      [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(Offset(cx, cy), r * 0.76, p);
    p.shader = null;

    // Crown symbol
    final tp = TextPainter(
      text: TextSpan(
        text: '♛',
        style: TextStyle(
          fontSize: r * 0.86,
          color: Colors.white.withAlpha(220),
          shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    // Shine arc
    p.color = Colors.white.withAlpha(70);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx - r * 0.18, cy - r * 0.18), radius: r * 0.38),
      -2.5, 1.4, false, p,
    );
    p.style = PaintingStyle.fill;

    // Selection arrow above
    if (legal) {
      final ap = Paint()
        ..color = Color(((pulsePhase * 200 + 55).round() << 24) | 0x00FFFFFF);
      final arrowPath = Path()
        ..moveTo(cx,         cy - r * 2.1)
        ..lineTo(cx - r * 0.38, cy - r * 1.6)
        ..lineTo(cx + r * 0.38, cy - r * 1.6)
        ..close();
      canvas.drawPath(arrowPath, ap);
    }
  }

  // ── Piece position calculation ─────────────────────────────────────────────

  Offset _piecePos(PieceState piece, double left, double top, double cell) {
    final seat     = piece.seat;
    final pi       = _pieceIdx(piece.pieceId);
    final state    = piece.state;
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
        pi, cell * 0.4,
      );
    }

    int ti = piece.trackIndex;
    if (ti < 0 || ti >= _BoardConsts.path.length) {
      ti = (_BoardConsts.seatStarts[seat.clamp(0, 3)] + progress) % _BoardConsts.path.length;
    }
    final tp = _BoardConsts.path[ti];
    return _offsetPos(
      Offset(left + (tp[0] + 0.5) * cell, top + (tp[1] + 0.5) * cell),
      pi, cell * 0.34,
    );
  }

  Offset _yardPos(int seat, int idx, double left, double top, double cell) {
    final s    = seat.clamp(0, 3);
    final base = _BoardConsts.bases[s];
    final slot = _BoardConsts.slots[idx % 4];
    return Offset(
      left + (base[0] + slot[0]) * cell,
      top  + (base[1] + slot[1]) * cell,
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
      left + size * 0.15, top + size * 0.39,
      left + size * 0.85, top + size * 0.61,
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
    final para2 = pb2.build()..layout(ui.ParagraphConstraints(width: rect.width));
    canvas.drawParagraph(para2, Offset(rect.left, top + size * 0.506));
  }

  @override
  bool shouldRepaint(_BoardPainter old) {
    return old.snapshot != snapshot ||
           old.pulsePhase != pulsePhase ||
           old.mySeat != mySeat;
  }
}
