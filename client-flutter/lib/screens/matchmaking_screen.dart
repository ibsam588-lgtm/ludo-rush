// ignore_for_file: unused_element

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/levelplay_banner.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _cancel(context, state);
          },
          child: Scaffold(
            backgroundColor: bgDeep,
            bottomNavigationBar: const SafeArea(
              top: false,
              child: LevelPlayBannerAd(
                placementName: 'MatchmakingBanner',
              ),
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/rush/rush_matchmaking_scene_mobile_v1.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(10),
                          Colors.transparent,
                          bgDeep.withAlpha(205),
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final compact = box.maxHeight < 760;
                      final panelWidth = math.min(box.maxWidth - 30, 390.0);
                      return Column(
                        children: [
                          _MatchmakingTopBar(
                            state: state,
                            onCancel: () => _cancel(context, state),
                          ),
                          Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: compact
                                      ? const Alignment(0, -0.08)
                                      : const Alignment(0, -0.18),
                                  child: SizedBox(
                                    width: panelWidth,
                                    child: _WaitingPanel(pulse: _pulse),
                                  ),
                                ),
                                Positioned(
                                  bottom: compact ? 22 : 38,
                                  child: _CancelButton(
                                    onTap: () => _cancel(context, state),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _cancel(BuildContext context, AppState state) {
    state.cancelMatchmaking();
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }
}

class _MatchmakingTopBar extends StatelessWidget {
  final AppState state;
  final VoidCallback onCancel;

  const _MatchmakingTopBar({
    required this.state,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = state.statusText.isNotEmpty
        ? state.statusText
        : 'Searching for match...';
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      decoration: const BoxDecoration(
        color: Color(0x4420002D),
        border: Border(bottom: BorderSide(color: Color(0x22FFD426))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(Icons.menu_rounded,
                  color: Colors.white70, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: goldColor,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 4,
                    offset: Offset(1, 2),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MascotStage extends StatelessWidget {
  final Animation<double> pulse;
  final bool compact;

  const _MascotStage({
    required this.pulse,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => CustomPaint(
        painter: _MascotStagePainter(
          t: pulse.value,
          compact: compact,
        ),
      ),
    );
  }
}

class _WaitingPanel extends StatelessWidget {
  final Animation<double> pulse;

  const _WaitingPanel({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final glow = (100 + math.sin(pulse.value * math.pi * 2) * 44).round();
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF014293A), Color(0xF0061B20)],
            ),
            boxShadow: [
              BoxShadow(
                color: goldColor.withAlpha(glow.clamp(30, 105).toInt()),
                blurRadius: 16,
                spreadRadius: 0,
              ),
              const BoxShadow(
                color: Color(0xCC000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Waiting for match',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: goldColor,
                  fontSize: 28,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 4,
                      offset: Offset(1, 3),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Setting up your game...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFFFD7FF).withAlpha(232),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 52,
                height: 52,
                child: CustomPaint(
                  painter: _SpinnerPainter(pulse.value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CancelButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF7B1A87), Color(0xFF3A0B48)],
          ),
          border: Border.all(color: const Color(0xAAFFD426), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double t;

  _SpinnerPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;
    final p = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.085;
    p.color = const Color(0x332B4960);
    canvas.drawCircle(center, radius, p);

    p.shader = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      transform: GradientRotation(t * math.pi * 2),
      colors: const [
        Color(0x00FFD426),
        Color(0xFFFFD426),
        Color(0xFFFFA000),
      ],
      stops: const [0.15, 0.62, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + t * math.pi * 2,
      math.pi * 1.55,
      false,
      p,
    );
    p.shader = null;
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) => oldDelegate.t != t;
}

class _MascotStagePainter extends CustomPainter {
  final double t;
  final bool compact;

  const _MascotStagePainter({
    required this.t,
    required this.compact,
  });

  static const _yellowSkin = Color(0xFFFFC928);
  static const _yellowSkinHi = Color(0xFFFFF06B);
  static const _yellowSkinDk = Color(0xFFE09300);
  static const _ink = Color(0xFF1A1030);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final center = Offset(w * 0.5, h * (compact ? 0.52 : 0.50));
    _drawSpotlight(canvas, p, size, center);
    _drawFloatingBits(canvas, p, size);
    _drawMiniBoard(canvas, p, size, center);

    final bob = math.sin(t * math.pi * 2);
    final s = math.min(w, h) / 430;
    final scale = s.clamp(0.78, compact ? 1.0 : 1.15).toDouble();

    _drawMascot(
      canvas,
      base: Offset(w * 0.20, h * (compact ? 0.76 : 0.72)),
      scale: scale * 0.92,
      suit: boardRed,
      accent: boardYellow,
      bob: bob,
      flip: false,
      armMode: 0,
    );
    _drawMascot(
      canvas,
      base: Offset(w * 0.80, h * (compact ? 0.77 : 0.72)),
      scale: scale * 0.92,
      suit: boardBlue,
      accent: boardGreen,
      bob: -bob,
      flip: true,
      armMode: 1,
    );

    if (!compact || h > 620) {
      _drawMascot(
        canvas,
        base: Offset(w * 0.50, h * (compact ? 0.88 : 0.84)),
        scale: scale * 0.78,
        suit: boardGreen,
        accent: boardRed,
        bob: math.sin(t * math.pi * 2 + math.pi * 0.65),
        flip: false,
        armMode: 2,
      );
    }
  }

  void _drawSpotlight(Canvas canvas, Paint p, Size size, Offset center) {
    final rect = Offset.zero & size;
    p.shader = RadialGradient(
      center: const Alignment(0, 0.14),
      radius: 0.84,
      colors: [
        goldColor.withAlpha(46),
        const Color(0x55FF2BC2),
        Colors.transparent,
      ],
      stops: const [0.0, 0.42, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, p);
    p.shader = null;

    p.color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.86),
        width: size.width * 0.76,
        height: size.height * 0.10,
      ),
      p,
    );
  }

  void _drawFloatingBits(Canvas canvas, Paint p, Size size) {
    for (int i = 0; i < 20; i++) {
      final spin = t * math.pi * 2 + i * 0.7;
      final x = ((i * 47.0) + t * 42) % size.width;
      final y = size.height * (0.12 + ((i * 31) % 78) / 100);
      final c = switch (i % 4) {
        0 => boardRed,
        1 => boardBlue,
        2 => boardYellow,
        _ => boardGreen,
      };
      final r = 4.0 + (i % 3) * 1.6;
      p.color = c.withAlpha(44);
      canvas.save();
      canvas.translate(x, y + math.sin(spin) * 7);
      canvas.rotate(spin * 0.25);
      if (i % 5 == 0) {
        _drawDice(canvas, p, Offset.zero, r * 1.75, c.withAlpha(230));
      } else if (i % 3 == 0) {
        _drawStar(canvas, p, Offset.zero, r, c.withAlpha(205));
      } else {
        canvas.drawCircle(Offset.zero, r, p);
      }
      canvas.restore();
    }
  }

  void _drawMiniBoard(Canvas canvas, Paint p, Size size, Offset center) {
    final boardW = math.min(size.width * 0.72, 310.0);
    final boardH = boardW * 0.43;
    final top = size.height * (compact ? 0.37 : 0.35);
    final rect = Rect.fromCenter(
      center: Offset(center.dx, top + boardH / 2),
      width: boardW,
      height: boardH,
    );

    p.color = const Color(0x99000000);
    canvas.drawRRect(
      RRect.fromRectXY(rect.shift(const Offset(0, 14)), 28, 28),
      p,
    );

    p.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFE36C),
        Color(0xFFE98700),
        Color(0xFF5F2600),
      ],
    ).createShader(rect);
    canvas.drawRRect(RRect.fromRectXY(rect, 24, 24), p);
    p.shader = null;

    final inner = rect.deflate(9);
    p.color = const Color(0xFFFFF5D2);
    canvas.drawRRect(RRect.fromRectXY(inner, 17, 17), p);

    final q = [
      [inner.left, inner.top, boardBlue],
      [inner.center.dx, inner.top, boardYellow],
      [inner.left, inner.center.dy, boardRed],
      [inner.center.dx, inner.center.dy, boardGreen],
    ];
    for (final item in q) {
      final x = item[0] as double;
      final y = item[1] as double;
      final color = item[2] as Color;
      final r = Rect.fromLTWH(x, y, inner.width / 2, inner.height / 2);
      p.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withAlpha(225), Color.lerp(color, Colors.black, 0.24)!],
      ).createShader(r);
      canvas.drawRRect(RRect.fromRectXY(r.deflate(3), 12, 12), p);
      p.shader = null;
    }

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = goldColor.withAlpha(210);
    canvas.drawRRect(RRect.fromRectXY(rect.deflate(2), 23, 23), p);
    p.style = PaintingStyle.fill;
  }

  void _drawMascot(
    Canvas canvas, {
    required Offset base,
    required double scale,
    required Color suit,
    required Color accent,
    required double bob,
    required bool flip,
    required int armMode,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy + bob * 7 * scale);
    canvas.scale(flip ? -scale : scale, scale);

    final p = Paint()..isAntiAlias = true;
    p.color = const Color(0x66000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 58),
        width: 92,
        height: 18,
      ),
      p,
    );

    _drawArm(canvas, p, Offset(-35, -2), suit, accent, armMode, true);
    _drawArm(canvas, p, Offset(35, -2), suit, accent, armMode, false);

    final body = Rect.fromCenter(
      center: const Offset(0, -7),
      width: 66,
      height: 104,
    );
    p.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_yellowSkinHi, _yellowSkin, _yellowSkinDk],
      stops: [0.0, 0.52, 1.0],
    ).createShader(body);
    canvas.drawRRect(RRect.fromRectXY(body, 31, 31), p);
    p.shader = null;

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7
      ..color = const Color(0xFF8A5500);
    canvas.drawRRect(RRect.fromRectXY(body, 31, 31), p);
    p.style = PaintingStyle.fill;

    _drawCap(canvas, p, suit, accent);
    _drawGoggles(canvas, p);
    _drawSmile(canvas, p);
    _drawOveralls(canvas, p, suit, accent);
    _drawFeet(canvas, p, suit);

    if (armMode == 1) {
      _drawDice(canvas, p, const Offset(50, -8), 22, Colors.white);
    } else if (armMode == 2) {
      _drawToken(canvas, p, const Offset(48, 2), 13, accent);
    } else {
      _drawToken(canvas, p, const Offset(-50, 3), 13, accent);
    }

    canvas.restore();
  }

  void _drawArm(Canvas canvas, Paint p, Offset shoulder, Color suit,
      Color accent, int armMode, bool left) {
    final lift = armMode == 1 && !left ? -17.0 : 0.0;
    final side = left ? -1.0 : 1.0;
    final end = Offset(shoulder.dx + side * 24, shoulder.dy + 20 + lift);
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12
      ..color = _yellowSkinDk;
    canvas.drawLine(shoulder, end, p);
    p
      ..strokeWidth = 8
      ..color = _yellowSkinHi.withAlpha(210);
    canvas.drawLine(shoulder + Offset(side * 1, -1), end, p);
    p.style = PaintingStyle.fill;
    p.color = accent;
    canvas.drawCircle(end, 7.8, p);
    p.color = const Color(0x99000000);
    canvas.drawCircle(end + const Offset(0, 1), 3.8, p);
  }

  void _drawCap(Canvas canvas, Paint p, Color suit, Color accent) {
    final band = Rect.fromCenter(
      center: const Offset(0, -56),
      width: 55,
      height: 17,
    );
    p.shader = LinearGradient(
      colors: [Color.lerp(suit, Colors.white, 0.20)!, suit],
    ).createShader(band);
    canvas.drawRRect(RRect.fromRectXY(band, 9, 9), p);
    p.shader = null;

    final crown = Path()
      ..moveTo(-22, -61)
      ..lineTo(-15, -75)
      ..lineTo(-6, -64)
      ..lineTo(0, -78)
      ..lineTo(7, -64)
      ..lineTo(16, -75)
      ..lineTo(23, -61)
      ..close();
    p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF27B), goldColor, amberColor],
    ).createShader(Rect.fromLTWH(-24, -79, 48, 22));
    canvas.drawPath(crown, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..color = const Color(0xFF9D6500);
    canvas.drawPath(crown, p);
    p.style = PaintingStyle.fill;
  }

  void _drawGoggles(Canvas canvas, Paint p) {
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFF534865);
    canvas.drawLine(const Offset(-31, -31), const Offset(31, -31), p);
    p.style = PaintingStyle.fill;

    for (final x in [-15.0, 15.0]) {
      p.color = const Color(0xFF5F5871);
      canvas.drawCircle(Offset(x, -31), 15.5, p);
      p.shader = const RadialGradient(
        center: Alignment(-0.4, -0.4),
        colors: [Colors.white, Color(0xFFCDE9FF)],
      ).createShader(Rect.fromCircle(center: Offset(x, -31), radius: 12));
      canvas.drawCircle(Offset(x, -31), 10.7, p);
      p.shader = null;
      p.color = _ink;
      canvas.drawCircle(Offset(x + 2, -30), 4.2, p);
      p.color = Colors.white;
      canvas.drawCircle(Offset(x, -33), 1.7, p);
    }
  }

  void _drawSmile(Canvas canvas, Paint p) {
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.7
      ..color = const Color(0xFF6D3D00);
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, -9), width: 28, height: 15),
      0.18,
      math.pi - 0.36,
      false,
      p,
    );
    p.style = PaintingStyle.fill;
  }

  void _drawOveralls(Canvas canvas, Paint p, Color suit, Color accent) {
    final overalls = Path()
      ..moveTo(-28, 7)
      ..lineTo(-20, 44)
      ..quadraticBezierTo(0, 57, 20, 44)
      ..lineTo(28, 7)
      ..quadraticBezierTo(13, 18, 0, 18)
      ..quadraticBezierTo(-13, 18, -28, 7)
      ..close();
    p.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(suit, Colors.white, 0.18)!,
        suit,
        Color.lerp(suit, Colors.black, 0.28)!,
      ],
    ).createShader(Rect.fromLTWH(-30, 5, 60, 54));
    canvas.drawPath(overalls, p);
    p.shader = null;

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Color.lerp(suit, Colors.black, 0.45)!;
    canvas.drawPath(overalls, p);
    p.style = PaintingStyle.fill;

    p.color = accent;
    _drawStar(canvas, p, const Offset(0, 31), 8, accent);
    p.color = const Color(0xBBFFFFFF);
    canvas.drawCircle(const Offset(-13, 17), 2.4, p);
    canvas.drawCircle(const Offset(13, 17), 2.4, p);
  }

  void _drawFeet(Canvas canvas, Paint p, Color suit) {
    p.color = Color.lerp(suit, Colors.black, 0.48)!;
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(center: const Offset(-16, 52), width: 24, height: 12),
        7,
        7,
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(center: const Offset(16, 52), width: 24, height: 12),
        7,
        7,
      ),
      p,
    );
  }

  void _drawToken(Canvas canvas, Paint p, Offset c, double r, Color color) {
    p.color = const Color(0x55000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.9),
        width: r * 1.9,
        height: r * 0.45,
      ),
      p,
    );
    p.shader = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      colors: [
        Color.lerp(color, Colors.white, 0.35)!,
        color,
        Color.lerp(color, Colors.black, 0.36)!,
      ],
    ).createShader(Rect.fromCircle(center: c, radius: r * 1.25));
    canvas.drawCircle(c, r, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Color.lerp(color, Colors.black, 0.42)!;
    canvas.drawCircle(c, r, p);
    p.style = PaintingStyle.fill;
  }

  void _drawDice(Canvas canvas, Paint p, Offset c, double size, Color color) {
    final rect = Rect.fromCenter(center: c, width: size, height: size);
    p.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color.lerp(color, Colors.grey, 0.18)!],
    ).createShader(rect);
    canvas.drawRRect(RRect.fromRectXY(rect, size * 0.22, size * 0.22), p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.06
      ..color = const Color(0xFF6D5A89);
    canvas.drawRRect(RRect.fromRectXY(rect, size * 0.22, size * 0.22), p);
    p.style = PaintingStyle.fill;
    p.color = _ink;
    final pipR = size * 0.055;
    for (final o in [
      const Offset(-0.20, -0.20),
      const Offset(0.20, -0.20),
      Offset.zero,
      const Offset(-0.20, 0.20),
      const Offset(0.20, 0.20),
    ]) {
      canvas.drawCircle(c + Offset(o.dx * size, o.dy * size), pipR, p);
    }
  }

  void _drawStar(
      Canvas canvas, Paint p, Offset center, double radius, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius : radius * 0.45;
      final point = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    p.color = color;
    canvas.drawPath(path, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, radius * 0.15)
      ..color = Color.lerp(color, Colors.black, 0.34)!;
    canvas.drawPath(path, p);
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(_MascotStagePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.compact != compact;
}

class _MatchmakingBgPainter extends CustomPainter {
  final double t;

  const _MatchmakingBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final rect = Offset.zero & size;
    p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1B002B), Color(0xFF310038), Color(0xFF100018)],
    ).createShader(rect);
    canvas.drawRect(rect, p);
    p.shader = null;

    final glows = [
      Offset(size.width * 0.12, size.height * 0.22),
      Offset(size.width * 0.86, size.height * 0.20),
      Offset(size.width * 0.52, size.height * 0.86),
    ];
    for (final c in glows) {
      p.shader = RadialGradient(
        colors: const [Color(0x55FF2BC2), Color(0x0013001E)],
      ).createShader(Rect.fromCircle(center: c, radius: size.width * 0.55));
      canvas.drawCircle(c, size.width * 0.55, p);
    }
    p.shader = null;

    for (int i = 0; i < 52; i++) {
      final x = ((i * 61.0) + t * 38) % size.width;
      final y = ((i * 97.0) + t * 24) % size.height;
      final r = 1.0 + (i % 3) * 0.55;
      p.color = Color.fromARGB(34 + (i % 4) * 12, 255, 212, 38);
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(_MatchmakingBgPainter oldDelegate) => oldDelegate.t != t;
}
