import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/dice_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final AnimationController _progressCtrl;
  final _diceKey = GlobalKey<DiceWidgetState>();

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));

    _fade  = CurvedAnimation(parent: _fadeCtrl,  curve: Curves.easeIn);
    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);

    _fadeCtrl.forward();
    _scaleCtrl.forward();
    _progressCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _diceKey.currentState?.startRoll(6, () {});
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Radial bg glow
          CustomPaint(painter: _SplashBgPainter()),

          // Theatre curtain overlays
          Positioned(
            left: 0, top: 0, bottom: 0,
            width: MediaQuery.of(context).size.width * 0.12,
            child: _Curtain(left: true),
          ),
          Positioned(
            right: 0, top: 0, bottom: 0,
            width: MediaQuery.of(context).size.width * 0.12,
            child: _Curtain(left: false),
          ),

          // Scattered stars
          ..._buildStars(context),

          // Main content
          FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Crown
                ScaleTransition(
                  scale: _scale,
                  child: const Text('👑', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 8),

                // LUDO in colored letters
                _buildLudoText(),
                const SizedBox(height: 4),

                // RUSH
                const Text(
                  'RUSH',
                  style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w900,
                    color: goldColor, letterSpacing: 8,
                    shadows: [Shadow(color: Color(0xBBFFD426), blurRadius: 16)],
                  ),
                ),

                const SizedBox(height: 32),

                // 3D dice
                SizedBox(
                  width: 100, height: 100,
                  child: DiceWidget(key: _diceKey),
                ),

                const SizedBox(height: 40),

                // Loading bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      const Text(
                        'Loading...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (_, __) => Container(
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: goldColor, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _progressCtrl.value,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(greenBtn),
                              minHeight: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Play Ludo Rush with friends worldwide',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLudoText() {
    const letters = ['L', 'U', 'D', 'O'];
    const colors  = [boardRed, boardGreen, boardBlue, boardYellow];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(letters.length, (i) => Text(
        letters[i],
        style: TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w900,
          color: colors[i],
          shadows: [
            Shadow(color: colors[i].withAlpha(180), blurRadius: 12),
            const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 3)),
          ],
        ),
      )),
    );
  }

  List<Widget> _buildStars(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const positions = [
      [0.1, 0.08], [0.85, 0.06], [0.05, 0.35], [0.92, 0.28],
      [0.15, 0.72], [0.82, 0.68], [0.45, 0.05], [0.55, 0.92],
      [0.25, 0.15], [0.72, 0.18], [0.38, 0.82], [0.65, 0.78],
    ];
    const sizes   = [14.0, 18.0, 12.0, 20.0, 16.0, 14.0, 22.0, 12.0, 18.0, 16.0, 14.0, 20.0];
    const opacs   = [0.8, 0.6, 1.0, 0.7, 0.9, 0.5, 0.8, 0.6, 1.0, 0.7, 0.9, 0.5];

    return List.generate(positions.length, (i) => Positioned(
      left:  positions[i][0] * size.width,
      top:   positions[i][1] * size.height,
      child: Opacity(
        opacity: opacs[i],
        child: Icon(Icons.star, color: goldColor, size: sizes[i]),
      ),
    ));
  }
}

// ── Background painter ────────────────────────────────────────────────────────

class _SplashBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Base
    paint.color = bgDeep;
    canvas.drawRect(Offset.zero & size, paint);

    // Radial center glow
    paint.shader = ui.Gradient.radial(
      Offset(size.width / 2, size.height * 0.45),
      size.width * 0.65,
      [const Color(0xFF3D0060), bgDeep],
      [0.0, 1.0],
    );
    canvas.drawRect(Offset.zero & size, paint);
    paint.shader = null;

    // Bokeh particles
    paint.color = const Color(0x18FFD426);
    for (int i = 0; i < 30; i++) {
      final x = ((i * 137 + 23) % 1000) / 1000.0 * size.width;
      final y = ((i * 211 + 53) % 1000) / 1000.0 * size.height;
      final r = 3.0 + (i % 4) * 2.0;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
    paint.color = const Color(0x10FF69B4);
    for (int i = 0; i < 20; i++) {
      final x = ((i * 173 + 67) % 1000) / 1000.0 * size.width;
      final y = ((i * 97  + 31) % 1000) / 1000.0 * size.height;
      canvas.drawCircle(Offset(x, y), 2.0 + (i % 3), paint);
    }
  }

  @override
  bool shouldRepaint(_SplashBgPainter _) => false;
}

// ── Curtain widget ─────────────────────────────────────────────────────────────

class _Curtain extends StatelessWidget {
  final bool left;
  const _Curtain({required this.left});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurtainClipper(left: left),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Color(0xFF8B0000), Color(0xFF4A0000)],
            begin: left ? Alignment.centerLeft : Alignment.centerRight,
            end:   left ? Alignment.centerRight : Alignment.centerLeft,
          ),
        ),
      ),
    );
  }
}

class _CurtainClipper extends CustomClipper<Path> {
  final bool left;
  const _CurtainClipper({required this.left});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width * 0.5, size.height / 2);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(size.width * 0.5, size.height / 2);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(_CurtainClipper _) => false;
}
