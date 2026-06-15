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
  late final AnimationController _bg;
  late final AnimationController _intro;
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat(reverse: true);
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
    _bg.dispose();
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
          AnimatedBuilder(
            animation: _bg,
            builder: (_, __) => CustomPaint(painter: _SplashPainter(_bg.value)),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 8),
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
                const Spacer(flex: 3),
                Expanded(
                  flex: 15,
                  child: AnimatedBuilder(
                    animation: _bg,
                    builder: (_, __) => CustomPaint(
                      painter: _TableScenePainter(_bg.value),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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

    _drawMascot(canvas, Offset(size.width * 0.20, size.height * 0.67),
        boardBlue, p, -0.18);
    _drawMascot(canvas, Offset(size.width * 0.40, size.height * 0.63), boardRed,
        p, 0.04);
    _drawMascot(canvas, Offset(size.width * 0.61, size.height * 0.63),
        const Color(0xFFFF5BBE), p, 0.10);
    _drawMascot(canvas, Offset(size.width * 0.80, size.height * 0.67),
        boardGreen, p, 0.20);

    _drawDice(
        canvas,
        Offset(size.width * 0.55 + math.sin(t * math.pi * 2) * 7,
            size.height * 0.33),
        size.width * 0.20,
        p);
    _drawCoin(canvas, Offset(size.width * 0.18, size.height * 0.86), 18, p);
    _drawCoin(canvas, Offset(size.width * 0.83, size.height * 0.86), 15, p);
  }

  void _drawMascot(Canvas canvas, Offset c, Color color, Paint p, double rot) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final s = 45.0;
    p.color = Colors.black.withAlpha(70);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, s * 0.52), width: s * 1.15, height: s * 0.35),
        p);
    p.shader = ui.Gradient.linear(Offset(-s, -s), Offset(s, s),
        [Color.lerp(color, Colors.white, 0.28)!, color]);
    canvas.drawRRect(
        RRect.fromRectXY(
            Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.92),
            16,
            16),
        p);
    p.shader = null;
    p.color = Colors.white;
    canvas.drawCircle(Offset(-s * 0.18, -s * 0.10), 7, p);
    canvas.drawCircle(Offset(s * 0.18, -s * 0.10), 7, p);
    p.color = const Color(0xFF251021);
    canvas.drawCircle(Offset(-s * 0.18, -s * 0.08), 3.3, p);
    canvas.drawCircle(Offset(s * 0.18, -s * 0.08), 3.3, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(0, s * 0.06), width: s * 0.36, height: s * 0.28),
        0.2,
        math.pi - 0.4,
        false,
        p);
    p
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;
    canvas.restore();
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
