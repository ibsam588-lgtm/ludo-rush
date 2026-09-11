import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Vector artwork shared by the live previews and both playable boards.
/// The artwork never changes track coordinates or player colours.
class AdventureBoardArt {
  final String id;
  final String label;
  final List<Color> shell;
  final List<Color> tiles;
  final List<Color> nests;
  final List<Color> snakes;
  final List<Color> ladder;
  final Color accent;
  final Color ink;

  const AdventureBoardArt(this.id, this.label, this.shell, this.tiles,
      this.nests, this.snakes, this.ladder, this.accent, this.ink);

  static const themes = {
    'ocean': AdventureBoardArt(
      'ocean',
      'OCEAN VOYAGE',
      [Color(0xFF9DF3EA), Color(0xFF087E99), Color(0xFF033649)],
      [Color(0xFFE2FFF6), Color(0xFF9AD9DA)],
      [Color(0xFF0A7791), Color(0xFF034058)],
      [
        Color(0xFFF58C9F),
        Color(0xFF68E6DB),
        Color(0xFFFFBF64),
        Color(0xFF9F8DF0)
      ],
      [Color(0xFF663E26), Color(0xFFDEA764), Color(0xFFFFE9B0)],
      Color(0xFFA3FFF0),
      Color(0xFF073F55),
    ),
    'astral': AdventureBoardArt(
      'astral',
      'STAR OBSERVATORY',
      [Color(0xFFD7C8FF), Color(0xFF574482), Color(0xFF11122D)],
      [Color(0xFF29233F), Color(0xFF131C32)],
      [Color(0xFF25294C), Color(0xFF0F132C)],
      [
        Color(0xFFFFBD70),
        Color(0xFFEFA7ED),
        Color(0xFF91E1CC),
        Color(0xFFA6BCFF)
      ],
      [Color(0xFF33234F), Color(0xFFA8AED9), Color(0xFFF9DE9B)],
      Color(0xFFF5DEAC),
      Color(0xFFF1E9FF),
    ),
    'volcano': AdventureBoardArt(
      'volcano',
      'LAVA CITADEL',
      [Color(0xFFFFB356), Color(0xFF873D2D), Color(0xFF241C20)],
      [Color(0xFF4B3639), Color(0xFF302A32)],
      [Color(0xFF452D31), Color(0xFF221D27)],
      [
        Color(0xFFFF8B34),
        Color(0xFFD7AD81),
        Color(0xFFF06F64),
        Color(0xFFEDC449)
      ],
      [Color(0xFF1D202A), Color(0xFF9B9FA9), Color(0xFFFFAD61)],
      Color(0xFFFFA24B),
      Color(0xFFFFE8CF),
    ),
  };

  static AdventureBoardArt? forTheme(String theme) => themes[theme];

  void paintTexture(Canvas canvas, Rect rect, {double opacity = 1}) {
    canvas.save();
    canvas.clipRect(rect);
    final unit = rect.shortestSide;
    final p = Paint()
      ..isAntiAlias = true
      ..color = accent.withAlpha((100 * opacity).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, unit * .008)
      ..strokeCap = StrokeCap.round;
    if (id == 'ocean') {
      for (var row = 0; row < 7; row++) {
        final y = rect.top + unit * (.12 + row * .16);
        final path = Path()..moveTo(rect.left - unit * .2, y);
        for (var col = 0; col < 6; col++) {
          final x = rect.left + unit * (col * .25 - .2);
          path.relativeQuadraticBezierTo(
              unit * .0625, -unit * .06, unit * .125, 0);
          path.quadraticBezierTo(
              x + unit * .1875, y + unit * .06, x + unit * .25, y);
        }
        canvas.drawPath(path, p);
      }
      canvas.drawCircle(
          rect.center + Offset(unit * .25, -unit * .3), unit * .065, p);
      canvas.drawCircle(
          rect.center + Offset(unit * .34, -unit * .18), unit * .025, p);
    } else if (id == 'astral') {
      final points = [
        Offset(.12, .3),
        Offset(.3, .16),
        Offset(.48, .34),
        Offset(.7, .2),
        Offset(.88, .42),
        Offset(.68, .78),
      ]
          .map((o) =>
              rect.topLeft + Offset(o.dx * rect.width, o.dy * rect.height))
          .toList();
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, p);
      for (final point in points) {
        canvas.drawCircle(point, unit * .018, p..style = PaintingStyle.fill);
        canvas.drawLine(
            point - Offset(unit * .035, 0), point + Offset(unit * .035, 0), p);
        canvas.drawLine(
            point - Offset(0, unit * .035), point + Offset(0, unit * .035), p);
      }
      p.style = PaintingStyle.stroke;
      canvas.drawOval(
          Rect.fromCenter(
              center: rect.center, width: unit * .72, height: unit * .36),
          p);
    } else {
      for (var col = 0; col < 4; col++) {
        final x = rect.left + unit * (.08 + col * .3);
        final path = Path()
          ..moveTo(x, rect.top)
          ..relativeLineTo(unit * .09, unit * .2)
          ..relativeLineTo(-unit * .14, unit * .16)
          ..relativeLineTo(unit * .2, unit * .25)
          ..relativeLineTo(-unit * .13, unit * .22)
          ..relativeLineTo(unit * .08, unit * .2);
        canvas.drawPath(
            path,
            Paint()
              ..color = accent.withAlpha((30 * opacity).round())
              ..style = PaintingStyle.stroke
              ..strokeWidth = unit * .035);
        canvas.drawPath(path, p);
      }
    }
    canvas.restore();
  }

  void paintEmblem(Canvas canvas, Offset center, double radius) {
    final p = Paint()
      ..isAntiAlias = true
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * .1;
    if (id == 'ocean') {
      // Compass rose.
      canvas.drawCircle(center, radius * .8, p);
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2;
        final tip = center + Offset(math.cos(a), math.sin(a)) * radius;
        final side = Offset(-math.sin(a), math.cos(a)) * radius * .18;
        canvas.drawPath(
            Path()
              ..moveTo(tip.dx, tip.dy)
              ..lineTo(center.dx + side.dx, center.dy + side.dy)
              ..lineTo(center.dx - side.dx, center.dy - side.dy)
              ..close(),
            p);
      }
    } else if (id == 'astral') {
      canvas.drawCircle(center, radius * .48, p);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-.4);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: radius * 2, height: radius * .6),
          p);
      canvas.restore();
    } else {
      final path = Path()
        ..moveTo(center.dx - radius, center.dy + radius * .6)
        ..lineTo(center.dx - radius * .4, center.dy - radius * .7)
        ..lineTo(center.dx, center.dy - radius * .35)
        ..lineTo(center.dx + radius * .4, center.dy - radius * .7)
        ..lineTo(center.dx + radius, center.dy + radius * .6)
        ..close();
      canvas.drawPath(path, p);
      canvas.drawLine(center - Offset(0, radius * .2),
          center + Offset(radius * .25, radius * .5), p);
    }
  }
}
