import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'adventure_board_art.dart';

class MatchPalette {
  final String theme;
  final Color background;
  final Color surface;
  final Color accent;
  const MatchPalette(this.theme, this.background, this.surface, this.accent);
  factory MatchPalette.forTheme(String theme) {
    final art = AdventureBoardArt.forTheme(theme);
    if (art != null)
      return MatchPalette(theme, art.shell.last, art.nests.first, art.accent);
    return switch (theme) {
      'neon' => const MatchPalette(
          'neon', Color(0xFF080B23), Color(0xFF20204A), Color(0xFF62F2FF)),
      'royal' => const MatchPalette(
          'royal', Color(0xFF1D0E36), Color(0xFF45235E), Color(0xFFE9C98F)),
      'classic' => const MatchPalette(
          'classic', Color(0xFF241C19), Color(0xFF59402C), Color(0xFFE3C59C)),
      'jungle' => const MatchPalette(
          'jungle', Color(0xFF092E26), Color(0xFF24573B), Color(0xFFBAE3A0)),
      _ => const MatchPalette(
          'carnival', Color(0xFF230D30), Color(0xFF622453), Color(0xFFF6CE79)),
    };
  }
  List<Color> get panel => [surface.withAlpha(245), background.withAlpha(245)];
}

class MatchStyle extends InheritedWidget {
  final MatchPalette palette;
  const MatchStyle({super.key, required this.palette, required super.child});
  static MatchPalette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MatchStyle>()?.palette ??
      MatchPalette.forTheme('carnival');
  @override
  bool updateShouldNotify(MatchStyle oldWidget) =>
      oldWidget.palette.theme != palette.theme;
}

class MatchBackdrop extends StatelessWidget {
  final MatchPalette palette;
  final double phase;
  const MatchBackdrop({super.key, required this.palette, this.phase = 0});
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          gradient: RadialGradient(
        center: const Alignment(0, -.5),
        radius: 1.3,
        colors: [palette.surface, palette.background, const Color(0xFF090A12)],
        stops: const [0, .65, 1],
      )),
      child: CustomPaint(painter: _Atmosphere(palette, phase)));
}

class _Atmosphere extends CustomPainter {
  final MatchPalette palette;
  final double phase;
  _Atmosphere(this.palette, this.phase);
  @override
  void paint(Canvas canvas, Size size) {
    final art = AdventureBoardArt.forTheme(palette.theme);
    if (art != null) art.paintTexture(canvas, Offset.zero & size, opacity: .13);
    final p = Paint()
      ..color = palette.accent.withAlpha(32)
      ..isAntiAlias = true;
    for (var i = 0; i < 18; i++) {
      final x = size.width * ((i * 37 % 101) / 100);
      final y = size.height * ((i * 61 % 103) / 102) +
          math.sin(phase * math.pi * 2 + i) * 8;
      if (palette.theme == 'ocean') {
        p.style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(x, y), 3 + i % 4.0, p);
      } else {
        p.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 1 + i % 3.0, p);
      }
    }
  }

  @override
  bool shouldRepaint(_Atmosphere oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.palette.theme != palette.theme;
}
