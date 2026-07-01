import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DiceWidget extends StatefulWidget {
  final int? value;
  final double size;
  final String skin;
  const DiceWidget({
    super.key,
    this.value,
    this.size = 60,
    this.skin = 'classic',
  });

  @override
  State<DiceWidget> createState() => DiceWidgetState();
}

class DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  int _displayValue = 0;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounce;
  final List<Timer> _rollTimers = [];

  int get displayValue => _displayValue;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value ?? 0;
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _bounce = Tween<double>(begin: 1.0, end: 1.14)
        .chain(CurveTween(curve: Curves.bounceOut))
        .animate(_bounceCtrl);
  }

  @override
  void dispose() {
    for (final timer in _rollTimers) {
      timer.cancel();
    }
    _rollTimers.clear();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void setValue(int v) {
    if (mounted) setState(() => _displayValue = v);
  }

  void startRoll(int finalValue, VoidCallback onDone) {
    for (final timer in _rollTimers) {
      timer.cancel();
    }
    _rollTimers.clear();
    const seq = [3, 1, 5, 2, 6, 4, 1, 3, 5, 2, 4];
    final frames = [...seq, finalValue];
    for (int i = 0; i < frames.length; i++) {
      final face = frames[i];
      final isLast = i == frames.length - 1;
      final timer = Timer(Duration(milliseconds: 55 * (i + 1)), () {
        if (!mounted) return;
        setState(() => _displayValue = face);
        if (isLast) {
          _bounceCtrl.forward(from: 0);
          onDone();
        }
      });
      _rollTimers.add(timer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounce,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _DicePainter(_displayValue, widget.skin),
        ),
      ),
    );
  }
}

// ── Dice face painter ──────────────────────────────────────────────────────────

class _DicePainter extends CustomPainter {
  final int value;
  final String skin;
  _DicePainter(this.value, this.skin);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final palette = _DiceSkinPalette.from(skin);
    final s = size.shortestSide;
    final pad = s * 0.10;
    final left = (size.width - s) / 2 + pad;
    final top = (size.height - s) / 2 + pad;
    final right = (size.width + s) / 2 - pad;
    final bottom = (size.height + s) / 2 - pad;
    final cw = right - left;
    final ch = bottom - top;
    final rad = cw * 0.22;
    final r = Rect.fromLTRB(left, top, right, bottom);

    // Drop shadow
    paint.color = palette.shadow;
    canvas.drawRRect(
        RRect.fromRectXY(r.translate(0, s * 0.06), rad, rad), paint);

    // Face with selected skin gradient
    paint.shader = ui.Gradient.linear(
      Offset(left, top),
      Offset(right, bottom),
      palette.face,
    );
    canvas.drawRRect(RRect.fromRectXY(r, rad, rad), paint);
    paint.shader = null;

    if ((palette.innerGlow.a * 255).round() > 0) {
      paint.shader = ui.Gradient.radial(
        Offset(left + cw * 0.30, top + ch * 0.22),
        cw * 0.92,
        [palette.innerGlow, Colors.transparent],
      );
      canvas.drawRRect(RRect.fromRectXY(r.deflate(s * 0.02), rad, rad), paint);
      paint.shader = null;
    }

    // Rim
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = s * 0.055;
    paint.color = palette.rim;
    canvas.drawRRect(RRect.fromRectXY(r, rad, rad), paint);
    paint.style = PaintingStyle.fill;

    if (value < 1 || value > 6) {
      final cx = left + cw / 2;
      final cy = top + ch / 2;
      paint.color = palette.pip.withAlpha(190);
      final crown = Path()
        ..moveTo(cx - cw * 0.26, cy + ch * 0.15)
        ..lineTo(cx - cw * 0.20, cy - ch * 0.18)
        ..lineTo(cx - cw * 0.07, cy + ch * 0.02)
        ..lineTo(cx, cy - ch * 0.24)
        ..lineTo(cx + cw * 0.07, cy + ch * 0.02)
        ..lineTo(cx + cw * 0.20, cy - ch * 0.18)
        ..lineTo(cx + cw * 0.26, cy + ch * 0.15)
        ..close();
      canvas.drawPath(crown, paint);
      paint.color = palette.pip;
      canvas.drawRRect(
        RRect.fromRectXY(
          Rect.fromCenter(
              center: Offset(cx, cy + ch * 0.20),
              width: cw * 0.54,
              height: ch * 0.10),
          3,
          3,
        ),
        paint,
      );
      paint.style = PaintingStyle.fill;
      return;
    }

    // Pips
    final pr = cw * 0.092;
    final lx = left + cw * 0.30;
    final rx = right - cw * 0.30;
    final ty = top + ch * 0.30;
    final by = bottom - ch * 0.30;
    final mx = left + cw / 2;
    final my = top + ch / 2;

    void pip(double x, double y) {
      paint.color = palette.pipShadow;
      canvas.drawCircle(Offset(x + pr * 0.20, y + pr * 0.22), pr * 1.08, paint);
      paint.color = palette.pip;
      canvas.drawCircle(Offset(x, y), pr, paint);
      paint.color = Colors.white.withAlpha(palette.highlightAlpha);
      canvas.drawCircle(Offset(x - pr * 0.30, y - pr * 0.34), pr * 0.28, paint);
    }

    if (value == 1 || value == 3 || value == 5) pip(mx, my);
    if (value >= 2) {
      pip(lx, ty);
      pip(rx, by);
    }
    if (value >= 4) {
      pip(rx, ty);
      pip(lx, by);
    }
    if (value == 6) {
      pip(lx, my);
      pip(rx, my);
    }
  }

  @override
  bool shouldRepaint(_DicePainter old) =>
      old.value != value || old.skin != skin;
}

class _DiceSkinPalette {
  final List<Color> face;
  final Color rim;
  final Color pip;
  final Color pipShadow;
  final Color shadow;
  final Color innerGlow;
  final int highlightAlpha;

  const _DiceSkinPalette({
    required this.face,
    required this.rim,
    required this.pip,
    required this.pipShadow,
    required this.shadow,
    required this.innerGlow,
    required this.highlightAlpha,
  });

  factory _DiceSkinPalette.from(String skin) {
    switch (skin.toLowerCase()) {
      case 'royal':
        return const _DiceSkinPalette(
          face: [Color(0xFFFFF08A), Color(0xFFFFB11B), Color(0xFFB86100)],
          rim: Color(0xFFFFF2A4),
          pip: Color(0xFF714000),
          pipShadow: Color(0x77421E00),
          shadow: Color(0x773B1600),
          innerGlow: Color(0x55FFFFFF),
          highlightAlpha: 190,
        );
      case 'neon':
        return const _DiceSkinPalette(
          face: [Color(0xFF10205E), Color(0xFF07102D), Color(0xFF00C9FF)],
          rim: Color(0xFF43F4FF),
          pip: Color(0xFF7DFFFF),
          pipShadow: Color(0xAA001A3D),
          shadow: Color(0xAA000000),
          innerGlow: Color(0x5538D7FF),
          highlightAlpha: 210,
        );
      case 'ruby':
        return const _DiceSkinPalette(
          face: [Color(0xFFFF7272), Color(0xFFD31622), Color(0xFF6A0612)],
          rim: Color(0xFFFFD866),
          pip: Color(0xFFFFE17C),
          pipShadow: Color(0x99470000),
          shadow: Color(0x883B0000),
          innerGlow: Color(0x44FFFFFF),
          highlightAlpha: 185,
        );
      case 'emerald':
        return const _DiceSkinPalette(
          face: [Color(0xFF70FF90), Color(0xFF0EA63D), Color(0xFF064B21)],
          rim: Color(0xFFFFD866),
          pip: Color(0xFFFFEA7A),
          pipShadow: Color(0x88320700),
          shadow: Color(0x88200500),
          innerGlow: Color(0x44FFFFFF),
          highlightAlpha: 185,
        );
      case 'cosmic':
        return const _DiceSkinPalette(
          face: [Color(0xFFB95DFF), Color(0xFF48109A), Color(0xFF13072C)],
          rim: Color(0xFFFF5CFF),
          pip: Color(0xFFFFD866),
          pipShadow: Color(0xAA17002C),
          shadow: Color(0xAA000000),
          innerGlow: Color(0x55FFFFFF),
          highlightAlpha: 215,
        );
      case 'classic':
      default:
        return const _DiceSkinPalette(
          face: [Color(0xFFFFFDF4), Color(0xFFEADFC0)],
          rim: goldColor,
          pip: Color(0xFF8B0000),
          pipShadow: Color(0x55280000),
          shadow: Color(0x55000000),
          innerGlow: Color(0x00FFFFFF),
          highlightAlpha: 130,
        );
    }
  }
}
