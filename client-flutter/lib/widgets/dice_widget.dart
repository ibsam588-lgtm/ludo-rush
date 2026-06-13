import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DiceWidget extends StatefulWidget {
  const DiceWidget({super.key});

  @override
  State<DiceWidget> createState() => DiceWidgetState();
}

class DiceWidgetState extends State<DiceWidget> {
  int _displayValue = 0;

  int get displayValue => _displayValue;

  void setValue(int v) {
    if (mounted) setState(() => _displayValue = v);
  }

  // 12-frame animation sequence, 55 ms per frame — exact port from Java
  void startRoll(int finalValue, VoidCallback onDone) {
    const seq = [3, 1, 5, 2, 6, 4, 1, 3, 5, 2, 4];
    final allFrames = [...seq, finalValue];
    for (int i = 0; i < allFrames.length; i++) {
      final face   = allFrames[i];
      final isLast = i == allFrames.length - 1;
      Timer(Duration(milliseconds: 55 * (i + 1)), () {
        if (!mounted) return;
        setState(() => _displayValue = face);
        if (isLast) onDone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DicePainter(_displayValue),
    );
  }
}

class _DicePainter extends CustomPainter {
  final int value;
  _DicePainter(this.value);

  static const _ivory1 = Color(0xffFFFDF4);
  static const _ivory2 = Color(0xffEADFC0);

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
    final rad = cw * 0.24;

    // Drop shadow
    final shadowRect = Rect.fromLTRB(left, top + s * 0.05, right, bottom + s * 0.05);
    paint.color = const Color(0x40000000);
    canvas.drawRRect(RRect.fromRectXY(shadowRect, rad, rad), paint);

    // Ivory face with gradient sheen
    final faceRect = Rect.fromLTRB(left, top, right, bottom);
    paint.shader = ui.Gradient.linear(
      Offset(left, top), Offset(right, bottom),
      [_ivory1, _ivory2],
    );
    canvas.drawRRect(RRect.fromRectXY(faceRect, rad, rad), paint);
    paint.shader = null;

    // Gold rim
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.06
      ..color = AppColors.gold;
    canvas.drawRRect(RRect.fromRectXY(faceRect, rad, rad), paint);
    paint.style = PaintingStyle.fill;

    final cx = left + cw / 2;
    final cy = top  + ch / 2;

    if (value < 1 || value > 6) {
      // No-roll dash
      paint
        ..style       = PaintingStyle.stroke
        ..strokeWidth = s * 0.05
        ..strokeCap   = StrokeCap.round
        ..color       = const Color(0xff9A8A5E);
      canvas.drawLine(Offset(cx - cw * 0.16, cy), Offset(cx + cw * 0.16, cy), paint);
      paint.style = PaintingStyle.fill;
      return;
    }

    // Navy pips — standard arrangement
    final pr = cw * 0.10;
    final lx = left + cw * 0.29;
    final rx = right - cw * 0.29;
    final ty = top + ch * 0.29;
    final by = bottom - ch * 0.29;
    paint.color = AppColors.navy;

    final diag   = value == 2 || value == 3;
    final fourUp = value >= 4;
    final mid    = value % 2 == 1;
    final sixMid = value == 6;

    if (fourUp) {
      canvas.drawCircle(Offset(lx, ty), pr, paint);
      canvas.drawCircle(Offset(rx, ty), pr, paint);
      canvas.drawCircle(Offset(lx, by), pr, paint);
      canvas.drawCircle(Offset(rx, by), pr, paint);
    } else if (diag) {
      canvas.drawCircle(Offset(lx, ty), pr, paint);
      canvas.drawCircle(Offset(rx, by), pr, paint);
    }
    if (sixMid) {
      canvas.drawCircle(Offset(lx, cy), pr, paint);
      canvas.drawCircle(Offset(rx, cy), pr, paint);
    }
    if (mid) {
      canvas.drawCircle(Offset(cx, cy), pr, paint);
    }
  }

  @override
  bool shouldRepaint(_DicePainter old) => old.value != value;
}
