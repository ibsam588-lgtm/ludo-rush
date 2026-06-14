import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/dice_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  SPLASH SCREEN — Cinematic intro with staggered animations
// ═══════════════════════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Main sequence controller (2.4s)
  late final AnimationController _seqCtrl;

  // Background pulse
  late final AnimationController _bgCtrl;

  // Particle float
  late final AnimationController _particleCtrl;

  // Progress bar (3s total)
  late final AnimationController _progressCtrl;

  // Dice widget
  final _diceKey = GlobalKey<DiceWidgetState>();

  // Letter animations — L, U, D, O  (staggered)
  late final List<Animation<double>> _letterScale;
  late final List<Animation<double>> _letterFade;

  // RUSH text
  late final Animation<double> _rushFade;
  late final Animation<Offset> _rushSlide;

  // Subtitle fade
  late final Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();

    _seqCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200),
    );

    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 8),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat();

    _progressCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200),
    );

    // Staggered letter animations
    _letterScale = List.generate(4, (i) {
      final start = 0.0 + i * 0.07;
      final end   = start + 0.20;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _seqCtrl,
          curve: Interval(start, end, curve: Curves.elasticOut),
        ),
      );
    });

    _letterFade = List.generate(4, (i) {
      final start = 0.0 + i * 0.07;
      final end   = start + 0.14;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _seqCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _rushFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _seqCtrl,
        curve: const Interval(0.38, 0.60, curve: Curves.easeOut),
      ),
    );
    _rushSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _seqCtrl,
        curve: const Interval(0.38, 0.62, curve: Curves.easeOut),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _seqCtrl,
        curve: const Interval(0.65, 0.90, curve: Curves.easeIn),
      ),
    );

    // Start sequence
    _seqCtrl.forward();
    _progressCtrl.forward();

    // Roll dice when sequence reaches 60%
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) _diceKey.currentState?.startRoll(6, () {});
    });

    // Navigate to home after 3.2s
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _seqCtrl.dispose();
    _bgCtrl.dispose();
    _particleCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF05000F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated background ─────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              painter: _SplashBgPainter(_bgCtrl.value, _particleCtrl.value),
            ),
          ),

          // ── Floating particles (bottom to top) ─────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _FloatingParticlePainter(_particleCtrl.value),
            ),
          ),

          // ── Main content ────────────────────────────────────
          Column(
            children: [
              SizedBox(height: size.height * 0.14),

              // Crown
              AnimatedBuilder(
                animation: _letterScale[0],
                builder: (_, __) => ScaleTransition(
                  scale: _letterScale[0],
                  child: FadeTransition(
                    opacity: _letterFade[0],
                    child: const Text('👑', style: TextStyle(fontSize: 44)),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // L-U-D-O animated letters
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AnimLetter('L', boardRed,    _letterScale[0], _letterFade[0]),
                  _AnimLetter('U', boardBlue,   _letterScale[1], _letterFade[1]),
                  _AnimLetter('D', boardYellow, _letterScale[2], _letterFade[2]),
                  _AnimLetter('O', boardGreen,  _letterScale[3], _letterFade[3]),
                ],
              ),

              // RUSH
              SlideTransition(
                position: _rushSlide,
                child: FadeTransition(
                  opacity: _rushFade,
                  child: const Text(
                    'RUSH',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: goldColor,
                      letterSpacing: 10,
                      shadows: [
                        Shadow(color: Color(0xBBFFD426), blurRadius: 20),
                        Shadow(color: Color(0xFFFF9900), blurRadius: 40),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.04),

              // Dice
              SizedBox(
                width: 100, height: 100,
                child: DiceWidget(key: _diceKey),
              ),

              SizedBox(height: size.height * 0.04),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: const Text(
                        'LOADING...',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12, letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _progressCtrl,
                      builder: (_, __) => Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: _progressCtrl.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFFFFD426)],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withAlpha(130),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.035),

              // Tagline
              FadeTransition(
                opacity: _subtitleFade,
                child: const Text(
                  'Play with friends worldwide',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13, letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Animated letter widget ───────────────────────────────────────────────────

class _AnimLetter extends StatelessWidget {
  final String letter;
  final Color color;
  final Animation<double> scale;
  final Animation<double> fade;

  const _AnimLetter(this.letter, this.color, this.scale, this.fade);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scale,
      child: FadeTransition(
        opacity: fade,
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 58,
            fontWeight: FontWeight.w900,
            color: color,
            shadows: [
              Shadow(color: color.withAlpha(200), blurRadius: 18),
              Shadow(color: color.withAlpha(100), blurRadius: 40),
              const Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Splash background painter ────────────────────────────────────────────────

class _SplashBgPainter extends CustomPainter {
  final double t;
  final double pt;
  _SplashBgPainter(this.t, this.pt);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    // Deep base
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.40),
      size.height * 0.85,
      [const Color(0xFF1E0050), const Color(0xFF05000F)],
      [0.0, 1.0],
    );
    canvas.drawRect(Offset.zero & size, p);

    // Cyan pulse (top)
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.1),
      size.width * (0.5 + 0.2 * pulse),
      [Color.fromARGB((18 + (pulse * 12).round()), 0, 229, 255), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);

    // Magenta pulse (center)
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * (0.35 + 0.15 * (1 - pulse)),
      [Color.fromARGB((12 + ((1 - pulse) * 10).round()), 224, 64, 251), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    // Stars
    for (int i = 0; i < 80; i++) {
      final sx = ((i * 137 + 23) % 1000) / 1000.0 * size.width;
      final sy = ((i * 211 + 79) % 1000) / 1000.0 * size.height;
      final twinkle = 0.15 + 0.85 * (0.5 + 0.5 * math.sin(t * math.pi * 2 * 2 + i * 0.8));
      final r = 0.5 + (i % 4) * 0.55;
      p.color = Color.fromARGB((twinkle * 180).round(), 255, 255, 255);
      canvas.drawCircle(Offset(sx, sy), r, p);
    }
  }

  @override
  bool shouldRepaint(_SplashBgPainter old) => old.t != t || old.pt != pt;
}

// ── Floating particles ───────────────────────────────────────────────────────

class _FloatingParticlePainter extends CustomPainter {
  final double t;
  _FloatingParticlePainter(this.t);

  static const _colors = [
    Color(0xFF00E5FF), Color(0xFFE040FB), Color(0xFFFFD426),
    Color(0xFF69F0AE), Color(0xFFFF6B35), Color(0xFFFFB300),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final baseX = ((i * 317 + 53) % 1000) / 1000.0 * size.width;
      final speed = 0.08 + (i % 5) * 0.04;
      // Start from bottom, rise to top, loop
      final rawY = 1.0 - ((i * 0.03 + t * speed) % 1.0);
      final y = rawY * size.height;
      final x = baseX + math.sin(t * math.pi * 2 * 0.7 + i * 0.4) * 18;

      final alpha = (math.sin(rawY * math.pi).clamp(0.0, 1.0) * 160).round();
      if (alpha <= 0) continue;

      p.color = _colors[i % _colors.length].withAlpha(alpha);
      final r = 1.5 + (i % 4) * 1.2;
      canvas.drawCircle(Offset(x, y), r, p);
    }

    // Larger gems/diamonds occasionally
    for (int i = 0; i < 8; i++) {
      final baseX = ((i * 127 + 11) % 1000) / 1000.0 * size.width;
      final speed = 0.05 + (i % 3) * 0.02;
      final rawY = 1.0 - ((i * 0.12 + t * speed) % 1.0);
      final y = rawY * size.height;
      final x = baseX + math.cos(t * math.pi * 2 * 0.5 + i * 0.9) * 22;

      final alpha = (math.sin(rawY * math.pi).clamp(0.0, 1.0) * 120).round();
      if (alpha <= 0) continue;

      p.color = _colors[i % _colors.length].withAlpha(alpha);

      // Draw diamond shape
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * math.pi + i * 0.8);
      final path = Path()
        ..moveTo(0, -5)
        ..lineTo(3.5, 0)
        ..lineTo(0, 5)
        ..lineTo(-3.5, 0)
        ..close();
      canvas.drawPath(path, p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FloatingParticlePainter old) => old.t != t;
}
