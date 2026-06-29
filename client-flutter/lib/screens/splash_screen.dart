// ignore_for_file: unused_element

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();
    _progress = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..forward();
    Future.delayed(const Duration(milliseconds: 3300), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0324),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/rush/rush_splash_scene_v2.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(35),
                  Colors.transparent,
                  const Color(0xFF12001D).withAlpha(220),
                ],
                stops: const [0, 0.58, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                AnimatedBuilder(
                  animation: _intro,
                  builder: (context, child) {
                    final scale =
                        Curves.elasticOut.transform(_intro.value.clamp(0, 1));
                    final fade =
                        Curves.easeOut.transform(_intro.value.clamp(0, 1));
                    return Opacity(
                      opacity: fade,
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                  child: const _LogoBlock(),
                ),
                const Spacer(flex: 18),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 46),
                    child: Column(
                      children: [
                        Text(
                          'Loading ...',
                          style: TextStyle(
                            color: Colors.white.withAlpha(235),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(
                                  color: Colors.black87,
                                  blurRadius: 3,
                                  offset: Offset(0, 2))
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 22,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A104D),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x99FFD426)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: _progress.value.clamp(0, 1),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        Color(0xFF34D647),
                                        Color(0xFF7DFF42)
                                      ]),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      '${(_progress.value * 100).round()}%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Play Ludo Rush globally with friends and matched players',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.25),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBlock extends StatelessWidget {
  const _LogoBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: _CrownPainter(),
          child: const SizedBox(width: 88, height: 50),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LogoLetter('L', boardRed),
            _LogoLetter('U', boardGreen),
            _LogoLetter('D', boardYellow),
            _LogoLetter('O', boardBlue),
          ],
        ),
        const Text(
          'RUSH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            height: 0.86,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [
              Shadow(
                  color: Color(0xFF7B176A),
                  blurRadius: 0,
                  offset: Offset(2, 4)),
              Shadow(
                  color: Colors.black87, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoLetter extends StatelessWidget {
  final String letter;
  final Color color;

  const _LogoLetter(this.letter, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      letter,
      style: TextStyle(
        color: color,
        fontSize: 64,
        height: 0.95,
        fontWeight: FontWeight.w900,
        shadows: const [
          Shadow(
              color: Color(0xFFFFF6C8), blurRadius: 0, offset: Offset(1, -1)),
          Shadow(color: Colors.black87, blurRadius: 5, offset: Offset(2, 4)),
        ],
      ),
    );
  }
}

class _SplashPainter extends CustomPainter {
  final double t;

  _SplashPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    p.shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height),
      const [Color(0xFF23052E), Color(0xFF7A1769), Color(0xFF24051E)],
      [0, 0.50, 1],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.50, size.height * 0.43),
      size.width * 0.62,
      const [Color(0x66FFD426), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    _drawCurtains(canvas, size, p);

    for (int i = 0; i < 70; i++) {
      final x = ((i * 127 + 13) % 1000) / 1000.0 * size.width;
      final y = ((i * 83 + 59) % 1000) / 1000.0 * size.height;
      final alpha = 60 + (math.sin(t * math.pi * 4 + i) * 70).abs().round();
      p.color = [
        goldColor,
        const Color(0xFFFF6B35),
        const Color(0xFF46F07D),
        Colors.white
      ][i % 4]
          .withAlpha(alpha);
      if (i % 5 == 0) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(t * math.pi + i);
        canvas.drawPath(
            Path()
              ..moveTo(0, -5)
              ..lineTo(4, 0)
              ..lineTo(0, 5)
              ..lineTo(-4, 0)
              ..close(),
            p);
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(x, y), 1.2 + (i % 3), p);
      }
    }
  }

  void _drawCurtains(Canvas canvas, Size size, Paint p) {
    p.shader =
        const LinearGradient(colors: [Color(0xFF9C174F), Color(0xFF4E0830)])
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.28));
    final left = Path()
      ..moveTo(0, 0)
      ..cubicTo(size.width * 0.12, size.height * 0.08, size.width * 0.21,
          size.height * 0.15, size.width * 0.34, size.height * 0.31)
      ..lineTo(0, size.height * 0.25)
      ..close();
    final right = Path()
      ..moveTo(size.width, 0)
      ..cubicTo(size.width * 0.88, size.height * 0.08, size.width * 0.79,
          size.height * 0.15, size.width * 0.66, size.height * 0.31)
      ..lineTo(size.width, size.height * 0.25)
      ..close();
    canvas.drawPath(left, p);
    canvas.drawPath(right, p);
    p.shader = null;

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0x66FFD426);
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(
          Offset(size.width * (0.18 + i * 0.09),
              size.height * 0.12 + math.sin(i) * 8),
          3.5,
          p);
    }
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(_SplashPainter oldDelegate) => oldDelegate.t != t;
}

class _TableScenePainter extends CustomPainter {
  final double t;

  _TableScenePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height * 0.47);

    p.color = const Color(0xFFFFD66E);
    _drawStar(canvas, center.translate(0, -6), size.width * 0.30, p);

    final board = Rect.fromCenter(
        center: center.translate(0, 48),
        width: size.width * 0.56,
        height: size.width * 0.40);
    p.color = const Color(0xFFFFF0B8);
    canvas.drawRRect(RRect.fromRectXY(board, 18, 18), p);
    p.color = boardRed;
    canvas.drawRect(
        Rect.fromLTRB(board.left, board.top, board.center.dx, board.center.dy),
        p);
    p.color = boardYellow;
    canvas.drawRect(
        Rect.fromLTRB(board.center.dx, board.top, board.right, board.center.dy),
        p);
    p.color = boardBlue;
    canvas.drawRect(
        Rect.fromLTRB(
            board.left, board.center.dy, board.center.dx, board.bottom),
        p);
    p.color = boardGreen;
    canvas.drawRect(
        Rect.fromLTRB(
            board.center.dx, board.center.dy, board.right, board.bottom),
        p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.white.withAlpha(200);
    canvas.drawRRect(RRect.fromRectXY(board, 18, 18), p);
    p.style = PaintingStyle.fill;

    final bob = math.sin(t * math.pi * 2);
    _drawMascot(
      canvas,
      Offset(size.width * 0.18, size.height * 0.70 + bob * 4),
      boardBlue,
      boardYellow,
      p,
      -0.12,
      false,
    );
    _drawMascot(
      canvas,
      Offset(size.width * 0.39, size.height * 0.64 - bob * 3),
      boardRed,
      boardGreen,
      p,
      0.04,
      false,
    );
    _drawMascot(
      canvas,
      Offset(size.width * 0.61, size.height * 0.64 + bob * 3),
      const Color(0xFFE43AB4),
      boardYellow,
      p,
      -0.03,
      true,
    );
    _drawMascot(
      canvas,
      Offset(size.width * 0.82, size.height * 0.70 - bob * 4),
      boardGreen,
      boardRed,
      p,
      0.13,
      true,
    );

    _drawDice(
        canvas,
        Offset(size.width * 0.55 + math.sin(t * math.pi * 2) * 7,
            size.height * 0.33),
        size.width * 0.20,
        p);
    _drawCoin(canvas, Offset(size.width * 0.18, size.height * 0.86), 18, p);
    _drawCoin(canvas, Offset(size.width * 0.83, size.height * 0.86), 15, p);
  }

  void _drawMascot(Canvas canvas, Offset c, Color suit, Color accent, Paint p,
      double rot, bool flip) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    canvas.scale(flip ? -1.0 : 1.0, 1.0);
    final s = 48.0;
    p.color = Colors.black.withAlpha(78);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, s * 0.72), width: s * 1.22, height: s * 0.30),
        p);

    _drawMascotArm(canvas, Offset(-s * 0.36, -s * 0.03), -1, accent, p);
    _drawMascotArm(canvas, Offset(s * 0.36, -s * 0.03), 1, accent, p);

    final body =
        Rect.fromCenter(center: Offset.zero, width: s * 0.86, height: s * 1.22);
    p.shader = ui.Gradient.linear(
      body.topLeft,
      body.bottomRight,
      const [Color(0xFFFFF06B), Color(0xFFFFC928), Color(0xFFE09300)],
      const [0.0, 0.56, 1.0],
    );
    canvas.drawRRect(RRect.fromRectXY(body, s * 0.36, s * 0.36), p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF8A5500);
    canvas.drawRRect(RRect.fromRectXY(body, s * 0.36, s * 0.36), p);
    p.style = PaintingStyle.fill;

    _drawMascotCrown(canvas, Offset(0, -s * 0.64), s * 0.36, accent, p);
    _drawMascotGoggles(canvas, s, p);

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF6D3D00);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(0, -s * 0.06), width: s * 0.38, height: s * 0.22),
        0.2,
        math.pi - 0.4,
        false,
        p);
    p
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;

    _drawMascotOveralls(canvas, s, suit, accent, p);
    p.color = Color.lerp(suit, Colors.black, 0.45)!;
    canvas.drawRRect(
        RRect.fromRectXY(
            Rect.fromCenter(
                center: Offset(-s * 0.19, s * 0.62),
                width: s * 0.32,
                height: s * 0.14),
            s * 0.08,
            s * 0.08),
        p);
    canvas.drawRRect(
        RRect.fromRectXY(
            Rect.fromCenter(
                center: Offset(s * 0.19, s * 0.62),
                width: s * 0.32,
                height: s * 0.14),
            s * 0.08,
            s * 0.08),
        p);
    canvas.restore();
  }

  void _drawMascotArm(
      Canvas canvas, Offset shoulder, int side, Color accent, Paint p) {
    final end = shoulder + Offset(side * 18, 18);
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 9
      ..color = const Color(0xFFE09300);
    canvas.drawLine(shoulder, end, p);
    p
      ..strokeWidth = 6
      ..color = const Color(0xFFFFF06B);
    canvas.drawLine(shoulder.translate(side * 0.5, -0.5), end, p);
    p.style = PaintingStyle.fill;
    p.color = accent;
    canvas.drawCircle(end, 6.2, p);
  }

  void _drawMascotCrown(
      Canvas canvas, Offset c, double r, Color accent, Paint p) {
    final crown = Path()
      ..moveTo(c.dx - r, c.dy + r * 0.32)
      ..lineTo(c.dx - r * 0.62, c.dy - r * 0.70)
      ..lineTo(c.dx - r * 0.22, c.dy)
      ..lineTo(c.dx, c.dy - r * 0.86)
      ..lineTo(c.dx + r * 0.22, c.dy)
      ..lineTo(c.dx + r * 0.62, c.dy - r * 0.70)
      ..lineTo(c.dx + r, c.dy + r * 0.32)
      ..close();
    p.shader = ui.Gradient.linear(
      c.translate(-r, -r),
      c.translate(r, r),
      [const Color(0xFFFFF27B), goldColor, accent],
    );
    canvas.drawPath(crown, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF9D6500);
    canvas.drawPath(crown, p);
    p.style = PaintingStyle.fill;
  }

  void _drawMascotGoggles(Canvas canvas, double s, Paint p) {
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF534865);
    canvas.drawLine(
        Offset(-s * 0.32, -s * 0.26), Offset(s * 0.32, -s * 0.26), p);
    p.style = PaintingStyle.fill;
    for (final x in [-s * 0.17, s * 0.17]) {
      p.color = const Color(0xFF5F5871);
      canvas.drawCircle(Offset(x, -s * 0.26), s * 0.18, p);
      p.shader = ui.Gradient.radial(
        Offset(x - s * 0.04, -s * 0.31),
        s * 0.15,
        const [Colors.white, Color(0xFFCDE9FF)],
      );
      canvas.drawCircle(Offset(x, -s * 0.26), s * 0.125, p);
      p.shader = null;
      p.color = const Color(0xFF1A1030);
      canvas.drawCircle(Offset(x + s * 0.02, -s * 0.25), s * 0.046, p);
      p.color = Colors.white;
      canvas.drawCircle(Offset(x, -s * 0.30), s * 0.022, p);
    }
  }

  void _drawMascotOveralls(
      Canvas canvas, double s, Color suit, Color accent, Paint p) {
    final overalls = Path()
      ..moveTo(-s * 0.32, s * 0.12)
      ..lineTo(-s * 0.23, s * 0.50)
      ..quadraticBezierTo(0, s * 0.64, s * 0.23, s * 0.50)
      ..lineTo(s * 0.32, s * 0.12)
      ..quadraticBezierTo(s * 0.13, s * 0.25, 0, s * 0.25)
      ..quadraticBezierTo(-s * 0.13, s * 0.25, -s * 0.32, s * 0.12)
      ..close();
    p.shader = ui.Gradient.linear(
      Offset(-s * 0.34, s * 0.10),
      Offset(s * 0.34, s * 0.62),
      [
        Color.lerp(suit, Colors.white, 0.20)!,
        suit,
        Color.lerp(suit, Colors.black, 0.28)!,
      ],
    );
    canvas.drawPath(overalls, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Color.lerp(suit, Colors.black, 0.42)!;
    canvas.drawPath(overalls, p);
    p.style = PaintingStyle.fill;
    p.color = accent;
    _drawStar(canvas, Offset(0, s * 0.38), s * 0.14, p);
  }

  void _drawDice(Canvas canvas, Offset c, double s, Paint p) {
    final rect = Rect.fromCenter(center: c, width: s, height: s);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.18);
    canvas.translate(-c.dx, -c.dy);
    p.color = Colors.black.withAlpha(70);
    canvas.drawRRect(
        RRect.fromRectXY(rect.shift(const Offset(5, 7)), 12, 12), p);
    p.color = const Color(0xFFFFF4D2);
    canvas.drawRRect(RRect.fromRectXY(rect, 12, 12), p);
    p.color = boardRed;
    for (final d in [
      Offset(rect.left + s * 0.28, rect.top + s * 0.28),
      c,
      Offset(rect.right - s * 0.28, rect.bottom - s * 0.28),
      Offset(rect.right - s * 0.28, rect.top + s * 0.28),
      Offset(rect.left + s * 0.28, rect.bottom - s * 0.28),
    ]) {
      canvas.drawCircle(d, s * 0.075, p);
    }
    canvas.restore();
  }

  void _drawCoin(Canvas canvas, Offset c, double r, Paint p) {
    p.color = goldColor;
    canvas.drawCircle(c, r, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18
      ..color = amberColor;
    canvas.drawCircle(c, r * 0.62, p);
    p.style = PaintingStyle.fill;
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final point = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_TableScenePainter oldDelegate) => oldDelegate.t != t;
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.86)
      ..lineTo(size.width * 0.23, size.height * 0.28)
      ..lineTo(size.width * 0.40, size.height * 0.58)
      ..lineTo(size.width * 0.50, size.height * 0.08)
      ..lineTo(size.width * 0.60, size.height * 0.58)
      ..lineTo(size.width * 0.77, size.height * 0.28)
      ..lineTo(size.width * 0.86, size.height * 0.86)
      ..close();
    p.shader =
        const LinearGradient(colors: [Color(0xFFFFF48C), Color(0xFFFFA000)])
            .createShader(Offset.zero & size);
    canvas.drawPath(path, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFFFF2A6);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => false;
}
