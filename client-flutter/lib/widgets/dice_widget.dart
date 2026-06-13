import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DiceWidget extends StatefulWidget {
  final int? value;
  final double size;
  const DiceWidget({super.key, this.value, this.size = 60});

  @override
  State<DiceWidget> createState() => DiceWidgetState();
}

class DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  int _displayValue = 0;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounce;

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
    _bounceCtrl.dispose();
    super.dispose();
  }

  void setValue(int v) {
    if (mounted) setState(() => _displayValue = v);
  }

  void startRoll(int finalValue, VoidCallback onDone) {
    const seq = [3, 1, 5, 2, 6, 4, 1, 3, 5, 2, 4];
    final frames = [...seq, finalValue];
    for (int i = 0; i < frames.length; i++) {
      final face   = frames[i];
      final isLast = i == frames.length - 1;
      Timer(Duration(milliseconds: 55 * (i + 1)), () {
        if (!mounted) return;
        setState(() => _displayValue = face);
        if (isLast) {
          _bounceCtrl.forward(from: 0);
          onDone();
        }
      });
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
          painter: _DicePainter(_displayValue),
        ),
      ),
    );
  }
}

// ── Dice face painter ──────────────────────────────────────────────────────────

class _DicePainter extends CustomPainter {
  final int value;
  _DicePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final s = size.shortestSide;
    final pad = s * 0.10;
    final left   = (size.width  - s) / 2 + pad;
    final top    = (size.height - s) / 2 + pad;
    final right  = (size.width  + s) / 2 - pad;
    final bottom = (size.height + s) / 2 - pad;
    final cw = right - left;
    final ch = bottom - top;
    final rad = cw * 0.22;
    final r = Rect.fromLTRB(left, top, right, bottom);

    // Drop shadow
    paint.color = const Color(0x55000000);
    canvas.drawRRect(
      RRect.fromRectXY(r.translate(0, s * 0.06), rad, rad), paint);

    // Ivory face with gradient
    paint.shader = ui.Gradient.linear(
      Offset(left, top), Offset(right, bottom),
      [const Color(0xFFFFFDF4), const Color(0xFFEADFC0)],
    );
    canvas.drawRRect(RRect.fromRectXY(r, rad, rad), paint);
    paint.shader = null;

    // Gold rim
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = s * 0.055;
    paint.color = goldColor;
    canvas.drawRRect(RRect.fromRectXY(r, rad, rad), paint);
    paint.style = PaintingStyle.fill;

    if (value < 1 || value > 6) {
      paint.color = const Color(0xFF9A8A5E);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = s * 0.045;
      paint.strokeCap = StrokeCap.round;
      final cx = left + cw / 2;
      final cy = top + ch / 2;
      canvas.drawLine(Offset(cx - cw * 0.15, cy), Offset(cx + cw * 0.15, cy), paint);
      paint.style = PaintingStyle.fill;
      return;
    }

    // Pips
    final pr = cw * 0.092;
    final lx = left + cw * 0.30;
    final rx = right - cw * 0.30;
    final ty = top  + ch * 0.30;
    final by = bottom - ch * 0.30;
    final mx = left + cw / 2;
    final my = top  + ch / 2;
    paint.color = const Color(0xFF8B0000);

    void pip(double x, double y) => canvas.drawCircle(Offset(x, y), pr, paint);

    if (value == 1 || value == 3 || value == 5) pip(mx, my);
    if (value >= 2) { pip(lx, ty); pip(rx, by); }
    if (value >= 4) { pip(rx, ty); pip(lx, by); }
    if (value == 6) { pip(lx, my); pip(rx, my); }
  }

  @override
  bool shouldRepaint(_DicePainter old) => old.value != value;
}
