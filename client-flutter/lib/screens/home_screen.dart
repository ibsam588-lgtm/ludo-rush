import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _shimmer;
  int _tabIndex = 2;
  bool _routeTabApplied = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _shimmer =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeTabApplied) return;
    _routeTabApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args >= 1 && args <= 4) {
      _tabIndex = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final p = _RushPalette.fromDark(state.isDarkMode);
        return Scaffold(
          backgroundColor: p.bg,
          bottomNavigationBar: SafeArea(
            top: false,
            child: _BottomNav(
              palette: p,
              activeIndex: _tabIndex,
              onSelect: (index) {
                SoundService.tap();
                if (index == 0) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  Navigator.pushNamed(context, '/shop');
                  return;
                }
                setState(() => _tabIndex = index);
              },
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: _GeneratedLobbyBackground(palette: p),
              ),
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final compact = box.maxWidth < 370;
                      final brandHeight = compact ? 74.0 : 88.0;
                      final hudHeight = 94.0;
                      final rewardHeight = compact ? 76.0 : 84.0;
                      final stageTop = brandHeight + hudHeight + rewardHeight;
                      final stageHeight =
                          math.max(0.0, box.maxHeight - stageTop);
                      return SizedBox.expand(
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              right: 0,
                              height: brandHeight,
                              child: _BrandHeader(palette: p),
                            ),
                            Positioned(
                              left: 0,
                              top: brandHeight,
                              right: 0,
                              height: hudHeight,
                              child: _TopHud(
                                  state: state, palette: p, shimmer: _shimmer),
                            ),
                            Positioned(
                              left: 0,
                              top: brandHeight + hudHeight,
                              right: 0,
                              height: rewardHeight,
                              child: _RewardStrip(palette: p),
                            ),
                            Positioned(
                              left: 0,
                              top: stageTop,
                              right: 0,
                              height: stageHeight,
                              child: ClipRect(
                                child: _HomeTabStage(
                                  index: _tabIndex,
                                  state: state,
                                  palette: p,
                                  pulse: _pulse,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (state.shouldShowStartChoice)
                Positioned.fill(
                  child: _StartChoiceOverlay(
                    state: state,
                    palette: p,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StartChoiceOverlay extends StatelessWidget {
  final AppState state;
  final _RushPalette palette;

  const _StartChoiceOverlay({
    required this.state,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xB8000012),
      child: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, box) {
              final width = math.min(box.maxWidth - 30, 380.0);
              return Container(
                width: width,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xF25B1057), Color(0xF20D0618)],
                  ),
                  border: Border.all(color: palette.stroke, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xCC000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 96,
                      child: CustomPaint(
                        painter: _SignupTokensPainter(),
                        child: SizedBox.expand(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Play as guest or sign up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: goldColor,
                        fontSize: 24,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 5,
                            offset: Offset(1, 3),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save your country, avatar, and age, or jump straight into a match.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileButton(
                            label: 'Sign up',
                            icon: Icons.person_add_alt_1_rounded,
                            palette: palette,
                            filled: false,
                            onTap: () async {
                              SoundService.tap();
                              await _showProfileEditor(
                                context,
                                state,
                                palette,
                                title: 'Sign up',
                                saveLabel: 'Create',
                                onSaved: state.markStartChoiceSeen,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileButton(
                            label: 'Start playing',
                            icon: Icons.play_arrow_rounded,
                            palette: palette,
                            filled: true,
                            onTap: () {
                              SoundService.tap();
                              state.startGuestMatch();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SignupTokensPainter extends CustomPainter {
  const _SignupTokensPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height * 0.56);
    final board = Rect.fromCenter(
      center: center,
      width: size.width * 0.64,
      height: size.height * 0.46,
    );

    p.color = const Color(0x77000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, board.bottom + 9),
        width: board.width * 0.95,
        height: 18,
      ),
      p,
    );
    p.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFE36B), Color(0xFFD07A00), Color(0xFF5C2500)],
    ).createShader(board);
    canvas.drawRRect(RRect.fromRectXY(board, 12, 12), p);
    p.shader = null;

    final inner = board.deflate(5);
    p.color = const Color(0xFFFFF4CF);
    canvas.drawRRect(RRect.fromRectXY(inner, 8, 8), p);
    _drawToken(
        canvas,
        inner.topLeft + Offset(inner.width * 0.28, inner.height * 0.46),
        13,
        boardRed,
        p);
    _drawToken(
        canvas,
        inner.topLeft + Offset(inner.width * 0.50, inner.height * 0.32),
        13,
        boardBlue,
        p);
    _drawToken(
        canvas,
        inner.topLeft + Offset(inner.width * 0.70, inner.height * 0.50),
        13,
        boardYellow,
        p);
    _drawDice(canvas, Offset(size.width * 0.76, size.height * 0.30), 31, p);
  }

  void _drawToken(Canvas canvas, Offset c, double r, Color color, Paint p) {
    p.color = const Color(0x55000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.95),
        width: r * 2.15,
        height: r * 0.48,
      ),
      p,
    );
    p.shader = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      colors: [
        Color.lerp(color, Colors.white, 0.42)!,
        color,
        Color.lerp(color, Colors.black, 0.38)!,
      ],
    ).createShader(Rect.fromCircle(center: c, radius: r * 1.35));
    canvas.drawCircle(c, r, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = goldColor;
    canvas.drawCircle(c, r * 1.06, p);
    p.style = PaintingStyle.fill;
    p.color = Colors.white.withAlpha(140);
    canvas.drawCircle(Offset(c.dx - r * 0.30, c.dy - r * 0.34), r * 0.18, p);
  }

  void _drawDice(Canvas canvas, Offset c, double s, Paint p) {
    final rect = Rect.fromCenter(center: c, width: s, height: s);
    p.color = const Color(0x77000000);
    canvas.drawRRect(RRect.fromRectXY(rect.shift(const Offset(4, 5)), 8, 8), p);
    p.color = Colors.white;
    canvas.drawRRect(RRect.fromRectXY(rect, 8, 8), p);
    p.color = const Color(0xFF201124);
    for (final dot in [
      rect.topLeft + Offset(s * 0.28, s * 0.28),
      c,
      rect.bottomRight - Offset(s * 0.28, s * 0.28),
      rect.topRight + Offset(-s * 0.28, s * 0.28),
      rect.bottomLeft + Offset(s * 0.28, -s * 0.28),
    ]) {
      canvas.drawCircle(dot, s * 0.06, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RushPalette {
  final bool dark;
  final Color bg;
  final Color bg2;
  final Color panel;
  final Color panel2;
  final Color stroke;
  final Color text;
  final Color muted;
  final Color gold;
  final Color shadow;

  const _RushPalette({
    required this.dark,
    required this.bg,
    required this.bg2,
    required this.panel,
    required this.panel2,
    required this.stroke,
    required this.text,
    required this.muted,
    required this.gold,
    required this.shadow,
  });

  factory _RushPalette.fromDark(bool dark) {
    if (dark) {
      return const _RushPalette(
        dark: true,
        bg: Color(0xFF1A0324),
        bg2: Color(0xFF8A176D),
        panel: Color(0xE12A0734),
        panel2: Color(0xFF5B145B),
        stroke: Color(0xFFFFD426),
        text: Colors.white,
        muted: Color(0xFFD7C3E0),
        gold: goldColor,
        shadow: Color(0x99000000),
      );
    }
    return const _RushPalette(
      dark: false,
      bg: Color(0xFFFFE7F7),
      bg2: Color(0xFFFFB5D9),
      panel: Color(0xF7FFFFFF),
      panel2: Color(0xFFFFD7F0),
      stroke: Color(0xFFE38A00),
      text: Color(0xFF2B1232),
      muted: Color(0xFF6E446D),
      gold: Color(0xFFFFB300),
      shadow: Color(0x33000000),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final _RushPalette palette;

  const _BrandHeader({required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 370;
        return SizedBox(
          height: compact ? 74 : 88,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: palette.dark
                          ? const [
                              Color(0xAA050016),
                              Color(0x22050016),
                              Color(0x00050016),
                            ]
                          : const [
                              Color(0xAAFFFFFF),
                              Color(0x44FFFFFF),
                              Color(0x00FFFFFF),
                            ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Transform.scale(
                  scale: compact ? 0.88 : 1.06,
                  alignment: Alignment.topCenter,
                  child: const _LudoRushLogo(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LudoRushLogo extends StatelessWidget {
  const _LudoRushLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 70,
            top: -5,
            width: 42,
            height: 30,
            child: CustomPaint(painter: _LogoCrownPainter()),
          ),
          Positioned(
            left: 0,
            top: 7,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF37D),
                  Color(0xFFFFB000),
                  Color(0xFFFF6A00),
                ],
              ).createShader(bounds),
              child: const Text(
                'Ludo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(
                        color: Color(0xFF7A1200),
                        blurRadius: 0,
                        offset: Offset(2.4, 3.2)),
                    Shadow(
                        color: Color(0xCC000000),
                        blurRadius: 9,
                        offset: Offset(0, 4)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 43,
            child: Stack(
              children: const [
                Text(
                  'Rush',
                  style: TextStyle(
                    color: Color(0xFF1D326A),
                    fontSize: 34,
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    shadows: [
                      Shadow(
                          color: Color(0xAA000000),
                          blurRadius: 7,
                          offset: Offset(0, 4)),
                    ],
                  ),
                ),
                Positioned(
                  top: -2,
                  left: 0,
                  child: Text(
                    'Rush',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 143,
            top: 39,
            width: 34,
            height: 34,
            child: Transform.rotate(
              angle: -0.35,
              child: CustomPaint(painter: _LogoDicePainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoCrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.82)
      ..lineTo(size.width * 0.20, size.height * 0.34)
      ..lineTo(size.width * 0.38, size.height * 0.66)
      ..lineTo(size.width * 0.52, size.height * 0.10)
      ..lineTo(size.width * 0.66, size.height * 0.66)
      ..lineTo(size.width * 0.84, size.height * 0.34)
      ..lineTo(size.width * 0.95, size.height * 0.82)
      ..close();
    p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF795), Color(0xFFFFB000), Color(0xFFD46A00)],
    ).createShader(Offset.zero & size);
    canvas.drawPath(path, p);
    p
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withAlpha(210);
    canvas.drawPath(path, p);
    p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFF8A6);
    for (final c in [
      Offset(size.width * 0.20, size.height * 0.28),
      Offset(size.width * 0.52, size.height * 0.08),
      Offset(size.width * 0.84, size.height * 0.28),
    ]) {
      canvas.drawCircle(c, size.width * 0.065, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoDicePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectXY(Offset.zero & size, 8, 8);
    final p = Paint()..isAntiAlias = true;
    p.color = Colors.black.withAlpha(120);
    canvas.drawRRect(r.shift(const Offset(3, 4)), p);
    p.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFE8E4DA)],
    ).createShader(Offset.zero & size);
    canvas.drawRRect(r, p);
    p
      ..shader = null
      ..color = const Color(0xFF170619);
    final dots = [
      Offset(size.width * 0.28, size.height * 0.28),
      Offset(size.width * 0.72, size.height * 0.28),
      Offset(size.width * 0.28, size.height * 0.72),
      Offset(size.width * 0.72, size.height * 0.72),
      Offset(size.width * 0.50, size.height * 0.50),
    ];
    for (final dot in dots) {
      canvas.drawCircle(dot, size.width * 0.055, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GeneratedLobbyBackground extends StatelessWidget {
  final _RushPalette palette;

  const _GeneratedLobbyBackground({required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/rush/rush_home_royal_backdrop_v4.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
            Positioned.fill(
              child: ColoredBox(
                color: palette.dark
                    ? const Color(0x14080015)
                    : const Color(0x55FFFFFF),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: palette.dark
                      ? const [
                          Color(0x44050019),
                          Color(0x00050019),
                          Color(0x00050019),
                          Color(0x66050019),
                        ]
                      : const [
                          Color(0x33FFFFFF),
                          Color(0x11FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x55FFFFFF),
                        ],
                  stops: const [0, 0.28, 0.58, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.92),
                  radius: 0.95,
                  colors: palette.dark
                      ? const [Color(0x00FF2BC2), Color(0x33100022)]
                      : const [Color(0x00FFFFFF), Color(0x99FFE0F4)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopHud extends StatelessWidget {
  final AppState state;
  final _RushPalette palette;
  final AnimationController shimmer;

  const _TopHud({
    required this.state,
    required this.palette,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: palette.dark
              ? const [Color(0xFF78145E), Color(0xFF301145)]
              : const [Color(0xFFFFFFFF), Color(0xFFFFD4F0)],
        ),
        border: Border.all(color: palette.stroke, width: 2),
        boxShadow: [
          BoxShadow(
              color: palette.shadow, blurRadius: 14, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                SoundService.tap();
                _showProfileEditor(context, state, palette);
              },
              child: Row(
                children: [
                  _AvatarBadge(
                      name: state.displayName,
                      level: (state.rating ~/ 90 + 1).clamp(1, 99),
                      preset: state.avatarPreset,
                      imagePath: state.avatarImagePath),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _cleanName(state.displayName),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  shadows: palette.dark
                                      ? const [
                                          Shadow(
                                              color: Colors.black54,
                                              blurRadius: 4)
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _CountryMiniBadge(
                                code: state.countryCode, palette: palette),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.emoji_events_rounded,
                                color: palette.gold, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '${state.rating}',
                              style: TextStyle(
                                  color: palette.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CurrencyPill(
                        icon: Icons.bolt_rounded,
                        value: '${state.wins}',
                        color: const Color(0xFF9EA5B5),
                        palette: palette),
                    const SizedBox(width: 3),
                    _CurrencyPill(
                        icon: Icons.monetization_on_rounded,
                        value: _fmt(state.coins),
                        color: amberColor,
                        palette: palette),
                    const SizedBox(width: 3),
                    _CurrencyPill(
                        icon: Icons.diamond_rounded,
                        value: '30',
                        color: const Color(0xFF21D972),
                        palette: palette),
                    const SizedBox(width: 3),
                    _ThemeToggle(state: state, palette: palette),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
  static String _cleanName(String s) =>
      s.trim().isEmpty || s == 'Ludo Player' ? 'Ibsam' : s.trim();
}

class _AvatarBadge extends StatelessWidget {
  final String name;
  final int level;
  final int preset;
  final String? imagePath;

  const _AvatarBadge({
    required this.name,
    required this.level,
    required this.preset,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'I' : name.trim()[0].toUpperCase();
    final path = imagePath;
    final hasImage = path != null && File(path).existsSync();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
                colors: [goldColor, amberColor, boardRed, goldColor]),
            border: Border.all(color: const Color(0xFFFFF3A8), width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 3))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: ClipOval(
              child: hasImage
                  ? Image.file(File(path), fit: BoxFit.cover)
                  : CustomPaint(painter: _AvatarPainter(initial, preset)),
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -3,
          child: Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE39A00),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text('$level',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _CountryMiniBadge extends StatelessWidget {
  final String code;
  final _RushPalette palette;

  const _CountryMiniBadge({required this.code, required this.palette});

  @override
  Widget build(BuildContext context) {
    final country = _countryFor(code);
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: palette.dark ? const Color(0x66100020) : Colors.white70,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.stroke.withAlpha(180), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniFlag(country: country, width: 12, height: 8),
          const SizedBox(width: 3),
          Text(
            country.code,
            style: TextStyle(
              color: palette.text,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountrySpec {
  final String code;
  final String name;
  final List<Color> colors;

  const _CountrySpec(this.code, this.name, this.colors);
}

const _countries = [
  _CountrySpec('US', 'United States',
      [Color(0xFFB22234), Colors.white, Color(0xFF3C3B6E)]),
  _CountrySpec(
      'IN', 'India', [Color(0xFFFF9933), Colors.white, Color(0xFF138808)]),
  _CountrySpec(
      'PK', 'Pakistan', [Color(0xFF01411C), Colors.white, Color(0xFF01411C)]),
  _CountrySpec('GB', 'United Kingdom',
      [Color(0xFF012169), Colors.white, Color(0xFFC8102E)]),
  _CountrySpec(
      'CA', 'Canada', [Color(0xFFFF0000), Colors.white, Color(0xFFFF0000)]),
  _CountrySpec('AE', 'United Arab Emirates',
      [Color(0xFF00732F), Colors.white, Color(0xFF000000)]),
  _CountrySpec('SA', 'Saudi Arabia',
      [Color(0xFF006C35), Colors.white, Color(0xFF006C35)]),
  _CountrySpec(
      'AU', 'Australia', [Color(0xFF00008B), Colors.white, Color(0xFFE4002B)]),
  _CountrySpec('BD', 'Bangladesh',
      [Color(0xFF006A4E), Color(0xFFF42A41), Color(0xFF006A4E)]),
  _CountrySpec('DE', 'Germany',
      [Color(0xFF000000), Color(0xFFDD0000), Color(0xFFFFCE00)]),
];

_CountrySpec _countryFor(String code) {
  final normalized = code.trim().toUpperCase();
  return _countries.firstWhere(
    (c) => c.code == normalized,
    orElse: () => _countries.first,
  );
}

class _MiniFlag extends StatelessWidget {
  final _CountrySpec country;
  final double width;
  final double height;

  const _MiniFlag({
    required this.country,
    this.width = 26,
    this.height = 17,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height * 0.18),
      child: SizedBox(
        width: width,
        height: height,
        child: Row(
          children: [
            for (final color in country.colors)
              Expanded(child: Container(color: color)),
          ],
        ),
      ),
    );
  }
}

Future<void> _showProfileEditor(
  BuildContext context,
  AppState state,
  _RushPalette palette, {
  String title = 'Edit profile',
  String saveLabel = 'Save',
  VoidCallback? onSaved,
}) async {
  final nameController =
      TextEditingController(text: _TopHud._cleanName(state.displayName));
  final ageController =
      TextEditingController(text: state.age > 0 ? state.age.toString() : '');
  var selectedCountry = state.countryCode;
  var selectedAvatar = state.avatarPreset;
  var selectedImagePath = state.avatarImagePath;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final selected = _countryFor(selectedCountry);
          final bottom = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, bottom + 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: palette.dark
                      ? const [Color(0xFF4A0B58), Color(0xFF18041F)]
                      : const [Color(0xFFFFFFFF), Color(0xFFFFD7F2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: palette.stroke, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ProfileAvatarPreview(
                          name: nameController.text,
                          preset: selectedAvatar,
                          imagePath: selectedImagePath,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  _MiniFlag(country: selected),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      '${selected.name} (${selected.code})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: palette.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      maxLength: 18,
                      onChanged: (_) => setSheetState(() {}),
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Player name',
                        labelStyle: TextStyle(color: palette.muted),
                        filled: true,
                        fillColor: palette.dark
                            ? const Color(0x66250A31)
                            : const Color(0xFFFFF4FC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: palette.stroke.withAlpha(130)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: palette.stroke, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Age',
                        helperText: 'Chat unlocks for players 13+.',
                        helperStyle: TextStyle(
                          color: palette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                        labelStyle: TextStyle(color: palette.muted),
                        filled: true,
                        fillColor: palette.dark
                            ? const Color(0x66250A31)
                            : const Color(0xFFFFF4FC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: palette.stroke.withAlpha(130)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: palette.stroke, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SheetLabel('Country', palette: palette),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final country in _countries)
                          _CountryChoice(
                            country: country,
                            selected: country.code == selectedCountry,
                            palette: palette,
                            onTap: () => setSheetState(
                                () => selectedCountry = country.code),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _SheetLabel('Avatar', palette: palette),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 8,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () => setSheetState(() {
                            selectedAvatar = i;
                            selectedImagePath = null;
                          }),
                          child: Container(
                            width: 54,
                            height: 54,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedAvatar == i &&
                                        selectedImagePath == null
                                    ? palette.stroke
                                    : Colors.white24,
                                width: selectedAvatar == i &&
                                        selectedImagePath == null
                                    ? 3
                                    : 1,
                              ),
                            ),
                            child: CustomPaint(
                              painter: _AvatarPainter(
                                  nameController.text.trim().isEmpty
                                      ? 'I'
                                      : nameController.text
                                          .trim()[0]
                                          .toUpperCase(),
                                  i),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileButton(
                            label: 'Upload avatar',
                            icon: Icons.photo_library_rounded,
                            palette: palette,
                            filled: false,
                            onTap: () async {
                              final picked = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 86,
                                maxWidth: 512,
                                maxHeight: 512,
                              );
                              if (picked != null) {
                                setSheetState(
                                    () => selectedImagePath = picked.path);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileButton(
                            label: saveLabel,
                            icon: Icons.check_rounded,
                            palette: palette,
                            filled: true,
                            onTap: () {
                              state.updateProfile(
                                name: nameController.text,
                                country: selectedCountry,
                                avatar: selectedAvatar,
                                age: int.tryParse(ageController.text.trim()),
                                imagePath: selectedImagePath,
                                clearImage: selectedImagePath == null,
                              );
                              onSaved?.call();
                              Navigator.pop(sheetContext);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  nameController.dispose();
  ageController.dispose();
}

class _ProfileAvatarPreview extends StatelessWidget {
  final String name;
  final int preset;
  final String? imagePath;

  const _ProfileAvatarPreview({
    required this.name,
    required this.preset,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'I' : name.trim()[0].toUpperCase();
    final path = imagePath;
    final hasImage = path != null && File(path).existsSync();
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
            colors: [goldColor, amberColor, boardBlue, boardRed, goldColor]),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12)],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.file(File(path), fit: BoxFit.cover)
            : CustomPaint(painter: _AvatarPainter(initial, preset)),
      ),
    );
  }
}

class _CountryChoice extends StatelessWidget {
  final _CountrySpec country;
  final bool selected;
  final _RushPalette palette;
  final VoidCallback onTap;

  const _CountryChoice({
    required this.country,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: selected
              ? palette.stroke.withAlpha(palette.dark ? 50 : 85)
              : (palette.dark ? const Color(0x55200A2D) : Colors.white70),
          border: Border.all(
              color: selected ? palette.stroke : Colors.white24,
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            _MiniFlag(country: country),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                country.code,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  final _RushPalette palette;

  const _SheetLabel(this.text, {required this.palette});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: palette.text,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final _RushPalette palette;
  final bool filled;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.label,
    required this.icon,
    required this.palette,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: filled
              ? const LinearGradient(
                  colors: [Color(0xFFFFD426), Color(0xFFFF8F00)])
              : null,
          color: filled
              ? null
              : (palette.dark ? const Color(0x66250A31) : Colors.white),
          border: Border.all(color: palette.stroke, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: filled ? const Color(0xFF3D1600) : palette.text,
                size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: filled ? const Color(0xFF3D1600) : palette.text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final _RushPalette palette;

  const _CurrencyPill({
    required this.icon,
    required this.value,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
      decoration: BoxDecoration(
        color: palette.dark ? const Color(0xAA21072C) : Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
            color: palette.dark ? Colors.white24 : const Color(0x22000000)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color.lerp(color, Colors.white, 0.35)!, color]),
              boxShadow: [BoxShadow(color: color.withAlpha(90), blurRadius: 6)],
            ),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  color: palette.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final AppState state;
  final _RushPalette palette;

  const _ThemeToggle({required this.state, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: state.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
      child: GestureDetector(
        onTap: state.toggleDarkMode,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: state.isDarkMode
                  ? const [Color(0xFF2D126A), Color(0xFF09021A)]
                  : const [Color(0xFFFFF4A3), Color(0xFFFFAF21)],
            ),
            border: Border.all(color: palette.stroke, width: 1.5),
            boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 7)],
          ),
          child: Icon(
            state.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _RewardStrip extends StatelessWidget {
  final _RushPalette palette;

  const _RewardStrip({required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 370;
        final gap = compact ? 7.0 : 10.0;
        return SizedBox(
          height: compact ? 76 : 84,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, compact ? 5 : 7),
            child: Row(
              children: [
                Expanded(
                  child: _RewardTile(
                    palette: palette,
                    label: 'Free',
                    art: _RewardArt.gift,
                    start: const Color(0xFFE93836),
                    end: const Color(0xFFFFB21C),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _RewardTile(
                    palette: palette,
                    label: 'Level 4',
                    art: _RewardArt.shield,
                    start: const Color(0xFFFFE066),
                    end: const Color(0xFFD89100),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _RewardTile(
                    palette: palette,
                    label: 'Level 5',
                    art: _RewardArt.medal,
                    start: const Color(0xFFFFD426),
                    end: const Color(0xFFE03068),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _RewardTile(
                    palette: palette,
                    label: 'Locked',
                    art: _RewardArt.lock,
                    start: const Color(0xFFFFD35B),
                    end: const Color(0xFF8C4B00),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _RewardArt { gift, shield, medal, lock }

class _RewardTile extends StatelessWidget {
  final _RushPalette palette;
  final String label;
  final _RewardArt art;
  final Color start;
  final Color end;

  const _RewardTile({
    required this.palette,
    required this.label,
    required this.art,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.dark
              ? const [Color(0xFF8A1776), Color(0xFF421048)]
              : const [Color(0xFFFFEFFB), Color(0xFFFFB9E3)],
        ),
        border: Border.all(color: palette.stroke, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: palette.gold.withAlpha(45),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _RewardTilePattern())),
            Align(
              alignment: const Alignment(0, -0.28),
              child: SizedBox(
                width: 48,
                height: 44,
                child: CustomPaint(
                  painter: _RewardIconPainter(art: art, start: start, end: end),
                ),
              ),
            ),
            Positioned(
              left: 5,
              right: 5,
              bottom: 9,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    shadows: palette.dark
                        ? const [
                            Shadow(
                              color: Color(0xCC000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardIconPainter extends CustomPainter {
  final _RewardArt art;
  final Color start;
  final Color end;

  const _RewardIconPainter({
    required this.art,
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final c = Offset(size.width / 2, size.height / 2);
    p.color = const Color(0x77000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, size.height * 0.88),
        width: size.width * 0.62,
        height: size.height * 0.18,
      ),
      p,
    );

    switch (art) {
      case _RewardArt.gift:
        _drawGift(canvas, size, p);
        break;
      case _RewardArt.shield:
        _drawShield(canvas, size, p);
        break;
      case _RewardArt.medal:
        _drawMedal(canvas, size, p);
        break;
      case _RewardArt.lock:
        _drawLock(canvas, size, p);
        break;
    }
  }

  void _drawGift(Canvas canvas, Size size, Paint p) {
    final box = Rect.fromLTWH(size.width * 0.14, size.height * 0.34,
        size.width * 0.56, size.height * 0.45);
    p.shader = LinearGradient(colors: [start, end])
        .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(RRect.fromRectXY(box, 5, 5), p);
    p.shader = null;
    p.color = const Color(0xFFFFF1A6);
    canvas.drawRect(
        Rect.fromLTWH(
            box.left + box.width * 0.42, box.top, box.width * 0.18, box.height),
        p);
    canvas.drawRect(
        Rect.fromLTWH(box.left, box.top + box.height * 0.36, box.width,
            box.height * 0.18),
        p);
    p.color = const Color(0xFFFF2B4F);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.33, size.height * 0.26),
            width: size.width * 0.28,
            height: size.height * 0.18),
        p);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.56, size.height * 0.26),
            width: size.width * 0.28,
            height: size.height * 0.18),
        p);
    p
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = Colors.white.withAlpha(210);
    canvas.drawRRect(RRect.fromRectXY(box, 5, 5), p);
    p.style = PaintingStyle.fill;
  }

  void _drawShield(Canvas canvas, Size size, Paint p) {
    final path = Path()
      ..moveTo(size.width * 0.50, size.height * 0.12)
      ..quadraticBezierTo(size.width * 0.76, size.height * 0.22,
          size.width * 0.79, size.height * 0.28)
      ..lineTo(size.width * 0.74, size.height * 0.60)
      ..quadraticBezierTo(size.width * 0.62, size.height * 0.78,
          size.width * 0.50, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.78,
          size.width * 0.26, size.height * 0.60)
      ..lineTo(size.width * 0.21, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.24, size.height * 0.22,
          size.width * 0.50, size.height * 0.12)
      ..close();
    p.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.lerp(start, Colors.white, 0.28)!, end],
    ).createShader(Offset.zero & size);
    canvas.drawPath(path, p);
    p
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFFFFF0A0);
    canvas.drawPath(path, p);
    p.style = PaintingStyle.fill;
  }

  void _drawMedal(Canvas canvas, Size size, Paint p) {
    final left = Path()
      ..moveTo(size.width * 0.31, size.height * 0.48)
      ..lineTo(size.width * 0.20, size.height * 0.86)
      ..lineTo(size.width * 0.40, size.height * 0.73)
      ..close();
    final right = Path()
      ..moveTo(size.width * 0.69, size.height * 0.48)
      ..lineTo(size.width * 0.80, size.height * 0.86)
      ..lineTo(size.width * 0.60, size.height * 0.73)
      ..close();
    p.color = const Color(0xFFE62752);
    canvas.drawPath(left, p);
    p.color = const Color(0xFFB40F45);
    canvas.drawPath(right, p);
    p.shader = LinearGradient(colors: [start, const Color(0xFFFFEE8E), end])
        .createShader(Offset.zero & size);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.42),
        size.shortestSide * 0.30, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFFFFF4B8);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.42),
        size.shortestSide * 0.30, p);
    p.style = PaintingStyle.fill;
    _drawStar(canvas, Offset(size.width * 0.50, size.height * 0.42),
        size.shortestSide * 0.14, const Color(0xFFFFF7B0), p);
  }

  void _drawLock(Canvas canvas, Size size, Paint p) {
    final c = Offset(size.width * 0.50, size.height * 0.48);
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.11
      ..color = const Color(0xFFFFE776);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(c.dx, c.dy - size.height * 0.09),
            width: size.width * 0.44,
            height: size.height * 0.44),
        math.pi,
        math.pi,
        false,
        p);
    p
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;
    final body = Rect.fromCenter(
        center: Offset(c.dx, c.dy + size.height * 0.10),
        width: size.width * 0.52,
        height: size.height * 0.42);
    p.shader = LinearGradient(colors: [start, end]).createShader(body);
    canvas.drawRRect(RRect.fromRectXY(body, 6, 6), p);
    p.shader = null;
    p.color = const Color(0xFF6B3500);
    canvas.drawCircle(
        Offset(c.dx, c.dy + size.height * 0.06), size.shortestSide * 0.05, p);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(c.dx, c.dy + size.height * 0.14),
            width: size.width * 0.045,
            height: size.height * 0.13),
        p);
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color, Paint p) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.42;
      final point = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    p.color = color;
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_RewardIconPainter oldDelegate) =>
      oldDelegate.art != art ||
      oldDelegate.start != start ||
      oldDelegate.end != end;
}

class _RewardTilePattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withAlpha(24);
    for (double x = -size.height; x < size.width + size.height; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
    p
      ..style = PaintingStyle.fill
      ..color = Colors.white.withAlpha(18);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.18),
        size.shortestSide * 0.25, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LobbyStage extends StatelessWidget {
  final AppState state;
  final _RushPalette palette;
  final AnimationController pulse;

  const _LobbyStage({
    required this.state,
    required this.palette,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 370;
        final compact = box.maxHeight < 500;
        final rowGap = compact ? 6.0 : 8.0;
        final bottomGap = compact ? 4.0 : 6.0;
        final baseBigHeight = (box.maxWidth * (narrow ? 0.27 : 0.285))
            .clamp(94.0, 124.0)
            .toDouble();
        final baseSmallHeight = (box.maxWidth * (narrow ? 0.19 : 0.205))
            .clamp(66.0, 86.0)
            .toDouble();
        final idealBoardHeight = (box.maxWidth * (narrow ? 0.72 : 0.74))
            .clamp(210.0, 292.0)
            .toDouble();
        final needed =
            idealBoardHeight + baseBigHeight + rowGap + baseSmallHeight;
        final scale =
            math.min(1.0, math.max(0.78, (box.maxHeight - 10) / needed));
        final bigHeight = baseBigHeight * scale;
        final smallHeight = baseSmallHeight * scale;
        final boardHeight = math.min(
          idealBoardHeight * scale,
          math.max(
            compact ? 178.0 : 212.0,
            box.maxHeight - bigHeight - smallHeight - rowGap - bottomGap,
          ),
        );
        final sidePadding = narrow ? 10.0 : 14.0;
        final largeGap = narrow ? 8.0 : 12.0;
        final smallGap = narrow ? 6.0 : 8.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 0),
          child: Column(
            children: [
              SizedBox(
                height: boardHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: compact ? 0 : 4,
                    bottom: compact ? 5 : 7,
                  ),
                  child: _RoyalBoardHero(palette: palette),
                ),
              ),
              SizedBox(
                height: bigHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeTile(
                        palette: palette,
                        pulse: pulse,
                        large: true,
                        label: '2 Player',
                        headline: '2',
                        subtitle: '',
                        start: const Color(0xFFFF3B3F),
                        end: const Color(0xFFC30C21),
                        art: _ModeArt.duel,
                        onTap: () => state.startQuickMatch('classic_2p'),
                      ),
                    ),
                    SizedBox(width: largeGap),
                    Expanded(
                      child: _ModeTile(
                        palette: palette,
                        pulse: pulse,
                        large: true,
                        label: '4 Player',
                        headline: '4',
                        subtitle: '',
                        start: const Color(0xFF25C8FF),
                        end: const Color(0xFF064BC3),
                        art: _ModeArt.four,
                        onTap: () => state.startQuickMatch('classic_4p'),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: rowGap),
              SizedBox(
                height: smallHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeTile(
                        palette: palette,
                        pulse: pulse,
                        label: 'Offline',
                        headline: '',
                        subtitle: 'Bot',
                        start: const Color(0xFF8C35FF),
                        end: const Color(0xFF5010A8),
                        art: _ModeArt.quick,
                        onTap: () => state.startOfflineMatch('classic_2p'),
                      ),
                    ),
                    SizedBox(width: smallGap),
                    Expanded(
                      child: _ModeTile(
                        palette: palette,
                        pulse: pulse,
                        label: 'Snakes',
                        headline: '',
                        subtitle: 'Ladders',
                        start: const Color(0xFF25D876),
                        end: const Color(0xFF087C3C),
                        art: _ModeArt.snakes,
                        imageAsset:
                            'assets/images/rush/rush_snakes_ladders_mode_v1.png',
                        onTap: () => state.startQuickMatch(
                          AppState.snakesLaddersMode,
                        ),
                      ),
                    ),
                    SizedBox(width: smallGap),
                    Expanded(
                      child: _ModeTile(
                        palette: palette,
                        pulse: pulse,
                        label: 'Quick Match',
                        headline: '',
                        subtitle: '',
                        start: const Color(0xFFFFC22D),
                        end: const Color(0xFFE47B00),
                        art: _ModeArt.quick,
                        onTap: () => state.startQuickMatch('classic_2p'),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: bottomGap),
            ],
          ),
        );
      },
    );
  }
}

class _HomeTabStage extends StatelessWidget {
  final int index;
  final AppState state;
  final _RushPalette palette;
  final AnimationController pulse;

  const _HomeTabStage({
    required this.index,
    required this.state,
    required this.palette,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    if (index == 1) {
      return _FeatureTabStage(
        palette: palette,
        title: 'Friends',
        subtitle: 'Online rivals and quick invites',
        accent: const Color(0xFFFFD426),
        icon: Icons.groups_rounded,
        rows: const [
          _FeatureRow('Leo', 'Online', '790'),
          _FeatureRow('Maya', 'In match', '1120'),
          _FeatureRow('Ava', 'Invite ready', '980'),
        ],
        actions: const ['Invite', 'Add', 'Gift'],
        onAction: (context, action) => _handleFeatureAction(context, action),
      );
    }
    if (index == 3) {
      return _FeatureTabStage(
        palette: palette,
        title: 'Clubs',
        subtitle: 'Season league and team rewards',
        accent: const Color(0xFFFF5D6C),
        icon: Icons.shield_rounded,
        rows: const [
          _FeatureRow('Royal Rollers', 'Rank #12', '4.8K'),
          _FeatureRow('Crown League', '3 days left', '2.1K'),
          _FeatureRow('Club Chest', '8 wins needed', '850'),
        ],
        actions: const ['Join', 'Leaders', 'Rewards'],
        onAction: (context, action) => _handleFeatureAction(context, action),
      );
    }
    if (index == 4) {
      return _FeatureTabStage(
        palette: palette,
        title: 'Chest',
        subtitle: 'Open prizes earned from matches',
        accent: const Color(0xFFFFB22D),
        icon: Icons.inventory_2_rounded,
        rows: const [
          _FeatureRow('Gold Chest', 'Ready', '500'),
          _FeatureRow('Crown Chest', '2 wins away', '1.2K'),
          _FeatureRow('Energy Vault', 'Bonus spins', '30'),
        ],
        actions: const ['Open', 'Boost', 'History'],
        onAction: (context, action) => _handleFeatureAction(context, action),
      );
    }
    return _LobbyStage(state: state, palette: palette, pulse: pulse);
  }

  void _handleFeatureAction(BuildContext context, String action) {
    SoundService.tap();
    switch (action) {
      case 'Invite':
        state.startOfflineMatch('classic_2p');
        return;
      case 'Add':
        _showFeatureSnack(context, 'Friend request queued for nearby players.');
        return;
      case 'Gift':
        state.addCoins(25);
        _showFeatureSnack(context, 'Gift sent. +25 coins added for testing.');
        return;
      case 'Join':
        _showFeatureSnack(context, 'Club join request sent.');
        return;
      case 'Leaders':
        _showLeaderboardSheet(context, state);
        return;
      case 'Rewards':
        state.addCoins(150);
        _showFeatureSnack(context, 'Club reward opened. +150 coins.');
        return;
      case 'Open':
        state.addCoins(500);
        _showFeatureSnack(context, 'Gold chest opened. +500 coins.');
        return;
      case 'Boost':
        state.startOfflineMatch(AppState.snakesLaddersMode);
        return;
      case 'History':
        _showFeatureSnack(
            context, 'Chest history is ready after your next win.');
        return;
    }
  }

  void _showFeatureSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xEE22082E),
          duration: const Duration(milliseconds: 1500),
          content: Text(message),
        ),
      );
  }

  void _showLeaderboardSheet(BuildContext context, AppState state) {
    final rows = [
      _FeatureRow(state.displayName, 'You', state.rating.toString()),
      const _FeatureRow('Royal Rollers', 'Club', '4.8K'),
      const _FeatureRow('Leo', 'Weekly rival', '1.2K'),
      const _FeatureRow('Maya', 'Hot streak', '1.1K'),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF531060), Color(0xFF18041F)],
              ),
              border: Border.all(color: goldColor, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xCC000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Leaders',
                      style: TextStyle(
                        color: goldColor,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < rows.length; i++) ...[
                  _FeatureListTile(
                    row: rows[i],
                    accent: i == 0 ? goldColor : const Color(0xFFFF5D6C),
                    index: i,
                  ),
                  if (i != rows.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureRow {
  final String title;
  final String subtitle;
  final String value;

  const _FeatureRow(this.title, this.subtitle, this.value);
}

class _FeatureTabStage extends StatelessWidget {
  final _RushPalette palette;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final List<_FeatureRow> rows;
  final List<String> actions;
  final void Function(BuildContext context, String action) onAction;

  const _FeatureTabStage({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.rows,
    required this.actions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 370;
        return Padding(
          padding:
              EdgeInsets.fromLTRB(narrow ? 12 : 16, 10, narrow ? 12 : 16, 8),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(narrow ? 14 : 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xF279126E), Color(0xEE26043E)],
                    ),
                    border: Border.all(color: goldColor, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xAA000000),
                        blurRadius: 18,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _FeatureMedallion(icon: icon, accent: accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    height: 0.95,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(220),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (int i = 0; i < rows.length; i++) ...[
                        _FeatureListTile(
                          row: rows[i],
                          accent: accent,
                          index: i,
                        ),
                        if (i != rows.length - 1) const SizedBox(height: 8),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          for (int i = 0; i < actions.length; i++) ...[
                            Expanded(
                              child: _FeatureActionButton(
                                label: actions[i],
                                accent: accent,
                                onTap: () => onAction(context, actions[i]),
                              ),
                            ),
                            if (i != actions.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureMedallion extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _FeatureMedallion({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white, accent, const Color(0xFF7A103F)],
        ),
        border: Border.all(color: goldColor, width: 3),
        boxShadow: [
          BoxShadow(color: accent.withAlpha(130), blurRadius: 18),
          const BoxShadow(
            color: Color(0x99000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF4A073B), size: 34),
    );
  }
}

class _FeatureListTile extends StatelessWidget {
  final _FeatureRow row;
  final Color accent;
  final int index;

  const _FeatureListTile({
    required this.row,
    required this.accent,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0x7A140020),
        border: Border.all(color: Colors.white.withAlpha(35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: accent,
            child: Text(
              row.title.isEmpty ? '?' : row.title.substring(0, 1),
              style: const TextStyle(
                color: Color(0xFF3A0430),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(190),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.emoji_events_rounded, color: goldColor, size: 18),
          const SizedBox(width: 4),
          Text(
            row.value,
            style: const TextStyle(
              color: goldColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureActionButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _FeatureActionButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [Color.lerp(accent, Colors.white, 0.18)!, accent],
          ),
          border: Border.all(color: goldColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}

class _RoyalBoardHero extends StatelessWidget {
  final _RushPalette palette;

  const _RoyalBoardHero({required this.palette});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final short = box.maxHeight < 175;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.18),
                    radius: 0.82,
                    colors: palette.dark
                        ? const [
                            Color(0x4DFF36D6),
                            Color(0x12150335),
                            Color(0x00050018),
                          ]
                        : const [
                            Color(0x66FFFFFF),
                            Color(0x22FFBDE9),
                            Color(0x00FFFFFF),
                          ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Transform.scale(
                  scale: short ? 1.0 : 1.05,
                  child: Image.asset(
                    'assets/images/rush/rush_home_royal_board_cutout_v5.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Color(0x00050018),
                        Color(0x00050018),
                        Color(0x33050018),
                      ],
                      stops: const [0, 0.74, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _ModeArt { duel, four, private, team, snakes, quick }

class _ModeTile extends StatefulWidget {
  final _RushPalette palette;
  final AnimationController pulse;
  final bool large;
  final String label;
  final String headline;
  final String subtitle;
  final Color start;
  final Color end;
  final _ModeArt art;
  final String? imageAsset;
  final VoidCallback onTap;

  const _ModeTile({
    required this.palette,
    required this.pulse,
    required this.label,
    required this.headline,
    required this.subtitle,
    required this.start,
    required this.end,
    required this.art,
    required this.onTap,
    this.imageAsset,
    this.large = false,
  });

  @override
  State<_ModeTile> createState() => _ModeTileState();
}

class _ModeTileState extends State<_ModeTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0,
        upperBound: 1);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapCancel: _press.reverse,
      onTapUp: (_) {
        _press.reverse();
        SoundService.tap();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_press, widget.pulse]),
        builder: (context, _) {
          final scale = 1 - _press.value * 0.045;
          final glow = 0.45 + widget.pulse.value * 0.55;
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.large ? 18 : 14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.start, widget.end],
                ),
                border: Border.all(
                    color: widget.palette.stroke,
                    width: widget.large ? 2.4 : 1.6),
                boxShadow: [
                  BoxShadow(
                      color: widget.start.withAlpha((85 * glow).round()),
                      blurRadius: widget.large ? 18 : 12,
                      offset: const Offset(0, 5)),
                  const BoxShadow(
                      color: Color(0x77000000),
                      blurRadius: 5,
                      offset: Offset(0, 3)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.large ? 16 : 12),
                child: Stack(
                  children: [
                    if (widget.imageAsset != null)
                      Positioned.fill(
                        child: Image.asset(
                          widget.imageAsset!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                    if (widget.imageAsset != null)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha(10),
                                Colors.black.withAlpha(110),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                        child: CustomPaint(
                            painter: _ModePatternPainter(widget.palette.dark))),
                    Positioned(
                      left: widget.large ? 18 : 10,
                      top: widget.large ? 13 : 10,
                      width: widget.large ? 78 : 38,
                      height: widget.large ? 70 : 38,
                      child: _ModeGlyph(
                        art: widget.art,
                        large: widget.large,
                      ),
                    ),
                    if (widget.headline.isNotEmpty)
                      Positioned(
                        right: widget.large ? 15 : 10,
                        top: widget.large ? 8 : 11,
                        child: Text(
                          widget.headline,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.large ? 70 : 25,
                            fontWeight: FontWeight.w900,
                            height: 0.9,
                            shadows: const [
                              Shadow(
                                  color: Color(0xCC4A0038),
                                  blurRadius: 0,
                                  offset: Offset(2, 3)),
                              Shadow(
                                  color: Color(0x99000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 4)),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      left: widget.large ? 22 : 8,
                      right: widget.large ? 86 : 8,
                      bottom: widget.large ? 12 : 9,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: widget.large
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: widget.large
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: _ModeLabelText(
                                      widget.label,
                                      large: true,
                                    ),
                                  )
                                : FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: _ModeLabelText(widget.label),
                                  ),
                          ),
                          if (widget.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: widget.large
                                  ? TextAlign.left
                                  : TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withAlpha(210),
                                fontSize: widget.large ? 12 : 11,
                                fontWeight: FontWeight.w800,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 3)
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModeGlyph extends StatelessWidget {
  final _ModeArt art;
  final bool large;

  const _ModeGlyph({required this.art, required this.large});

  @override
  Widget build(BuildContext context) {
    if (art == _ModeArt.duel) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
              left: 2, bottom: 1, child: _MiniPawn(color: boardRed)),
          Positioned(
            right: large ? -10 : -5,
            top: large ? 17 : 9,
            child: _MiniDice(size: large ? 39 : 24),
          ),
        ],
      );
    }
    if (art == _ModeArt.four) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
              left: 0, bottom: 5, child: _MiniPawn(color: boardBlue)),
          const Positioned(left: 24, top: 0, child: _MiniPawn(color: boardRed)),
          const Positioned(
              left: 42, bottom: 2, child: _MiniPawn(color: boardGreen)),
          const Positioned(
              right: -4, top: 14, child: _MiniPawn(color: boardYellow)),
          Positioned(
            left: large ? 24 : 15,
            bottom: large ? -8 : -4,
            child: _MiniDice(size: large ? 38 : 22),
          ),
        ],
      );
    }
    if (art == _ModeArt.team) {
      return const Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 2, bottom: 0, child: _MiniPawn(color: boardRed)),
          Positioned(right: 1, bottom: 0, child: _MiniPawn(color: boardBlue)),
        ],
      );
    }
    if (art == _ModeArt.snakes) {
      return CustomPaint(
        painter: _SnakeModeGlyphPainter(),
        child: const SizedBox.expand(),
      );
    }

    final icon =
        art == _ModeArt.private ? Icons.lock_rounded : Icons.bolt_rounded;
    final accent = art == _ModeArt.private
        ? const Color(0xFFFFC42D)
        : const Color(0xFFFFD426);
    return _RoundIconBadge(icon: icon, accent: accent, large: large);
  }
}

class _SnakeModeGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;
    final cell = size.shortestSide / 3.1;
    final board = Rect.fromLTWH(
      size.width * 0.02,
      size.height * 0.08,
      size.width * 0.82,
      size.height * 0.78,
    );
    p.color = const Color(0x99000000);
    canvas.drawRRect(
      RRect.fromRectXY(board.shift(const Offset(2, 3)), 6, 6),
      p,
    );
    p.shader = const LinearGradient(
      colors: [Color(0xFFFFF4BF), Color(0xFFFFC33D)],
    ).createShader(board);
    canvas.drawRRect(RRect.fromRectXY(board, 6, 6), p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF8F6110);
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(board.left + board.width * i / 3, board.top),
        Offset(board.left + board.width * i / 3, board.bottom),
        p,
      );
      canvas.drawLine(
        Offset(board.left, board.top + board.height * i / 3),
        Offset(board.right, board.top + board.height * i / 3),
        p,
      );
    }

    p
      ..strokeWidth = cell * 0.18
      ..color = const Color(0xFF18A85A);
    final snake = Path()
      ..moveTo(board.left + board.width * 0.72, board.top + board.height * 0.18)
      ..cubicTo(
        board.left + board.width * 0.30,
        board.top + board.height * 0.28,
        board.left + board.width * 0.82,
        board.top + board.height * 0.54,
        board.left + board.width * 0.36,
        board.top + board.height * 0.78,
      );
    canvas.drawPath(snake, p);
    p
      ..strokeWidth = cell * 0.08
      ..color = const Color(0xFF8CF19E);
    canvas.drawPath(snake, p);

    p
      ..strokeWidth = cell * 0.11
      ..color = goldColor;
    final a = Offset(board.left + board.width * 0.17, board.bottom - 5);
    final b = Offset(board.left + board.width * 0.56, board.top + 5);
    final dir = b - a;
    final len = dir.distance;
    final unit = dir / len;
    final normal = Offset(-unit.dy, unit.dx) * cell * 0.20;
    canvas.drawLine(a - normal, b - normal, p);
    canvas.drawLine(a + normal, b + normal, p);
    for (var i = 1; i < 4; i++) {
      final t = i / 4;
      final c = Offset.lerp(a, b, t)!;
      canvas.drawLine(c - normal * 1.1, c + normal * 1.1, p);
    }
    p.style = PaintingStyle.fill;
    p.color = Colors.white.withAlpha(220);
    canvas.drawCircle(Offset(board.right - 3, board.top + 5), cell * 0.15, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoundIconBadge extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool large;

  const _RoundIconBadge({
    required this.icon,
    required this.accent,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [Colors.white, accent]),
        border: Border.all(color: Colors.white.withAlpha(190), width: 1.6),
        boxShadow: const [
          BoxShadow(
              color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF5B104A), size: large ? 42 : 24),
    );
  }
}

class _MiniPawn extends StatelessWidget {
  final Color color;

  const _MiniPawn({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 2,
            child: Container(
              width: 27,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0x77000000),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            child: Container(
              width: 22,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [Color.lerp(color, Colors.white, 0.35)!, color],
                ),
                border: Border.all(color: const Color(0xFFFFF1A0), width: 1),
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            child: Container(
              width: 18,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(color, Colors.white, 0.48)!,
                    color,
                    Color.lerp(color, Colors.black, 0.28)!,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 1,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.45),
                  colors: [
                    Color.lerp(color, Colors.white, 0.55)!,
                    color,
                    Color.lerp(color, Colors.black, 0.28)!,
                  ],
                ),
                border: Border.all(color: const Color(0xFFFFF1A0), width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDice extends StatelessWidget {
  final double size;

  const _MiniDice({required this.size});

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.08;
    return Transform.rotate(
      angle: -0.18,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x99000000), blurRadius: 6, offset: Offset(2, 3)),
          ],
        ),
        child: Stack(
          children: [
            for (final offset in const [
              Offset(0.28, 0.28),
              Offset(0.72, 0.28),
              Offset(0.50, 0.50),
              Offset(0.28, 0.72),
              Offset(0.72, 0.72),
            ])
              Positioned(
                left: size * offset.dx - dot,
                top: size * offset.dy - dot,
                child: Container(
                  width: dot * 2,
                  height: dot * 2,
                  decoration: const BoxDecoration(
                    color: Color(0xFF241221),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeLabelText extends StatelessWidget {
  final String text;
  final bool large;

  const _ModeLabelText(this.text, {this.large = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: large ? 1 : 2,
      overflow: large ? TextOverflow.visible : TextOverflow.ellipsis,
      textAlign: large ? TextAlign.left : TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: large ? 25 : 15,
        height: 0.96,
        fontWeight: FontWeight.w900,
        shadows: const [
          Shadow(
            color: Colors.black87,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final _RushPalette palette;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const _BottomNav({
    required this.palette,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavSpec(_NavArt.shop, 'Shop'),
      _NavSpec(_NavArt.friends, 'Friends'),
      _NavSpec(_NavArt.home, 'Home'),
      _NavSpec(_NavArt.clubs, 'Clubs'),
      _NavSpec(_NavArt.chest, 'Chest'),
    ];
    return Container(
      height: 82,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 7),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: palette.dark
            ? const Color(0xED2A0747)
            : Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: palette.dark
                ? const Color(0xAA7B2CFF)
                : const Color(0x44E38A00),
            width: 1.4),
        boxShadow: [
          BoxShadow(
              color: palette.shadow,
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == activeIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                onSelect(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: active
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFB522FF), Color(0xFF5B099F)]),
                        border: Border.all(color: palette.stroke, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: palette.gold.withAlpha(115),
                              blurRadius: 13),
                          const BoxShadow(
                            color: Color(0xAA000000),
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          )
                        ],
                      )
                    : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (active)
                      Positioned(
                        top: -9,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: 20,
                          child: CustomPaint(
                            painter: _NavCrownPainter(color: palette.gold),
                          ),
                        ),
                      ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: active ? 38 : 34,
                          height: active ? 34 : 31,
                          child: CustomPaint(
                            painter: _NavIconPainter(
                              art: items[i].art,
                              active: active,
                              palette: palette,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            items[i].label,
                            style: TextStyle(
                              color: active
                                  ? palette.gold
                                  : palette.text.withAlpha(225),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              shadows: const [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 3,
                                  offset: Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

enum _NavArt { shop, friends, home, clubs, chest }

class _NavSpec {
  final _NavArt art;
  final String label;
  const _NavSpec(this.art, this.label);
}

class _NavCrownPainter extends CustomPainter {
  final Color color;

  const _NavCrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final path = Path()
      ..moveTo(size.width * 0.23, size.height * 0.82)
      ..lineTo(size.width * 0.33, size.height * 0.30)
      ..lineTo(size.width * 0.46, size.height * 0.58)
      ..lineTo(size.width * 0.55, size.height * 0.12)
      ..lineTo(size.width * 0.65, size.height * 0.58)
      ..lineTo(size.width * 0.78, size.height * 0.30)
      ..lineTo(size.width * 0.88, size.height * 0.82)
      ..close();
    p.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.lerp(color, Colors.white, 0.35)!, color],
    ).createShader(Offset.zero & size);
    canvas.drawPath(path, p);
    p
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withAlpha(190);
    canvas.drawPath(path, p);
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(_NavCrownPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _NavIconPainter extends CustomPainter {
  final _NavArt art;
  final bool active;
  final _RushPalette palette;

  const _NavIconPainter({
    required this.art,
    required this.active,
    required this.palette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final main = switch (art) {
      _NavArt.shop => const Color(0xFFFFE36E),
      _NavArt.friends => const Color(0xFFFFE95C),
      _NavArt.home => palette.gold,
      _NavArt.clubs => const Color(0xFFFFD65B),
      _NavArt.chest => const Color(0xFFFFC54D),
    };
    final accent = switch (art) {
      _NavArt.shop => const Color(0xFFFF3E4F),
      _NavArt.friends => const Color(0xFFFFFFFF),
      _NavArt.home => const Color(0xFFFFF09A),
      _NavArt.clubs => const Color(0xFFE83C43),
      _NavArt.chest => const Color(0xFF9A4D14),
    };
    p.color = const Color(0x8A000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.88),
        width: size.width * 0.62,
        height: size.height * 0.15,
      ),
      p,
    );
    switch (art) {
      case _NavArt.shop:
        _drawShop(canvas, size, p, main, accent);
        break;
      case _NavArt.friends:
        _drawFriends(canvas, size, p, main, accent);
        break;
      case _NavArt.home:
        _drawHome(canvas, size, p, main, accent);
        break;
      case _NavArt.clubs:
        _drawShield(canvas, size, p, main, accent);
        break;
      case _NavArt.chest:
        _drawChest(canvas, size, p, main, accent);
        break;
    }
  }

  void _drawShop(Canvas canvas, Size size, Paint p, Color main, Color accent) {
    final body = Rect.fromLTWH(size.width * 0.20, size.height * 0.38,
        size.width * 0.58, size.height * 0.38);
    p.color = main;
    canvas.drawRRect(RRect.fromRectXY(body, 3, 3), p);
    p.color = accent;
    final awning = Rect.fromLTWH(size.width * 0.16, size.height * 0.18,
        size.width * 0.66, size.height * 0.22);
    canvas.drawRRect(RRect.fromRectXY(awning, 4, 4), p);
    p.color = accent;
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
          Rect.fromLTWH(awning.left + awning.width * (i / 3), awning.top,
              awning.width / 6, awning.height),
          p);
    }
    p.color = const Color(0xFFFFB21C);
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.72),
        size.shortestSide * 0.13, p);
  }

  void _drawFriends(
      Canvas canvas, Size size, Paint p, Color main, Color accent) {
    p.color = main;
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.36),
        size.shortestSide * 0.17, p);
    canvas.drawCircle(Offset(size.width * 0.64, size.height * 0.38),
        size.shortestSide * 0.16, p);
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromLTWH(size.width * 0.20, size.height * 0.54, size.width * 0.36,
            size.height * 0.24),
        8,
        8,
      ),
      p,
    );
    p.color = accent;
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromLTWH(size.width * 0.48, size.height * 0.56, size.width * 0.34,
            size.height * 0.22),
        8,
        8,
      ),
      p,
    );
  }

  void _drawHome(Canvas canvas, Size size, Paint p, Color main, Color accent) {
    final roof = Path()
      ..moveTo(size.width * 0.16, size.height * 0.50)
      ..lineTo(size.width * 0.50, size.height * 0.18)
      ..lineTo(size.width * 0.84, size.height * 0.50)
      ..lineTo(size.width * 0.76, size.height * 0.56)
      ..lineTo(size.width * 0.50, size.height * 0.32)
      ..lineTo(size.width * 0.24, size.height * 0.56)
      ..close();
    p.color = main;
    canvas.drawPath(roof, p);
    final body = Rect.fromLTWH(size.width * 0.28, size.height * 0.48,
        size.width * 0.44, size.height * 0.32);
    canvas.drawRRect(RRect.fromRectXY(body, 4, 4), p);
    p.color = const Color(0xFF7F19D9);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.46, size.height * 0.61, size.width * 0.10,
            size.height * 0.19),
        p);
  }

  void _drawShield(
      Canvas canvas, Size size, Paint p, Color main, Color accent) {
    final path = Path()
      ..moveTo(size.width * 0.50, size.height * 0.15)
      ..lineTo(size.width * 0.77, size.height * 0.28)
      ..lineTo(size.width * 0.70, size.height * 0.66)
      ..lineTo(size.width * 0.50, size.height * 0.83)
      ..lineTo(size.width * 0.30, size.height * 0.66)
      ..lineTo(size.width * 0.23, size.height * 0.28)
      ..close();
    p.color = main;
    canvas.drawPath(path, p);
    p.color = accent;
    final inner = Path()
      ..moveTo(size.width * 0.50, size.height * 0.27)
      ..lineTo(size.width * 0.64, size.height * 0.36)
      ..lineTo(size.width * 0.59, size.height * 0.58)
      ..lineTo(size.width * 0.50, size.height * 0.67)
      ..lineTo(size.width * 0.41, size.height * 0.58)
      ..lineTo(size.width * 0.36, size.height * 0.36)
      ..close();
    canvas.drawPath(inner, p);
    _drawTinyStar(canvas, Offset(size.width * 0.50, size.height * 0.46),
        size.shortestSide * 0.10, accent, p);
  }

  void _drawChest(Canvas canvas, Size size, Paint p, Color main, Color accent) {
    final body = Rect.fromLTWH(size.width * 0.18, size.height * 0.36,
        size.width * 0.64, size.height * 0.38);
    p.color = main;
    canvas.drawRRect(RRect.fromRectXY(body, 5, 5), p);
    p.color = accent;
    canvas.drawRect(
        Rect.fromLTWH(body.left, body.top + body.height * 0.38, body.width,
            body.height * 0.20),
        p);
    p.color = accent;
    canvas.drawRect(
        Rect.fromLTWH(body.left + body.width * 0.44, body.top,
            body.width * 0.14, body.height),
        p);
    p.color = const Color(0xFFFFB21C);
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(
            center: Offset(size.width * 0.50, size.height * 0.56),
            width: size.width * 0.20,
            height: size.height * 0.18),
        3,
        3,
      ),
      p,
    );
  }

  void _drawTinyStar(Canvas canvas, Offset c, double r, Color color, Paint p) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.42;
      final point = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    p.color = color;
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_NavIconPainter oldDelegate) =>
      oldDelegate.art != art ||
      oldDelegate.active != active ||
      oldDelegate.palette != palette;
}

class _ModePatternPainter extends CustomPainter {
  final bool dark;

  _ModePatternPainter(this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withAlpha(dark ? 20 : 45);
    for (double x = -size.height; x < size.width + size.height; x += 22) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.white.withAlpha(dark ? 18 : 45);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.16),
        size.width * 0.22, paint);
  }

  @override
  bool shouldRepaint(_ModePatternPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

class _AvatarPainter extends CustomPainter {
  final String initial;
  final int preset;

  _AvatarPainter(this.initial, this.preset);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final c = Offset(size.width / 2, size.height / 2);
    final bg = [
      const Color(0xFF27145C),
      const Color(0xFF0A5D83),
      const Color(0xFF7A1554),
      const Color(0xFF185B2C),
      const Color(0xFF7A3C05),
      const Color(0xFF3B247D),
      const Color(0xFF0C5C55),
      const Color(0xFF8E1C28),
    ][preset.clamp(0, 7)];
    final skin = [
      const Color(0xFFFFBE7D),
      const Color(0xFFFFD19A),
      const Color(0xFFB8744F),
      const Color(0xFFE79A63),
      const Color(0xFFF5C28D),
      const Color(0xFF8B5A3C),
      const Color(0xFFFFCFA8),
      const Color(0xFFD28A64),
    ][preset.clamp(0, 7)];
    final hair = [
      const Color(0xFF321506),
      const Color(0xFF111111),
      const Color(0xFFFFD426),
      const Color(0xFF5B2600),
      const Color(0xFF1D1D1D),
      const Color(0xFF4D2217),
      const Color(0xFFEB4B84),
      const Color(0xFF0D2C74),
    ][preset.clamp(0, 7)];

    p.color = bg;
    canvas.drawCircle(c, size.shortestSide * 0.50, p);
    p.color = skin;
    canvas.drawCircle(
        Offset(c.dx, c.dy + size.height * 0.05), size.shortestSide * 0.30, p);
    p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFD23E), Color(0xFFE58A00)],
    ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy + size.height * 0.40),
          width: size.width * 0.48,
          height: size.height * 0.32,
        ),
        14,
        14,
      ),
      p,
    );
    p.shader = null;

    p.color = hair;
    if (preset % 3 == 0) {
      for (int i = 0; i < 7; i++) {
        canvas.drawCircle(
            Offset(c.dx - 17 + i * 6, c.dy - 13 - (i % 2) * 2), 7, p);
      }
    } else if (preset % 3 == 1) {
      canvas.drawRRect(
        RRect.fromRectXY(
          Rect.fromCenter(
              center: Offset(c.dx, c.dy - 13),
              width: size.width * 0.58,
              height: size.height * 0.24),
          12,
          12,
        ),
        p,
      );
    } else {
      final cap = Path()
        ..moveTo(c.dx - size.width * 0.30, c.dy - size.height * 0.10)
        ..quadraticBezierTo(c.dx, c.dy - size.height * 0.40,
            c.dx + size.width * 0.32, c.dy - size.height * 0.08)
        ..quadraticBezierTo(c.dx, c.dy - size.height * 0.20,
            c.dx - size.width * 0.30, c.dy - size.height * 0.10)
        ..close();
      canvas.drawPath(cap, p);
    }

    p.color = Colors.white.withAlpha(230);
    canvas.drawCircle(Offset(c.dx - size.width * 0.11, c.dy + 1),
        size.shortestSide * 0.045, p);
    canvas.drawCircle(Offset(c.dx + size.width * 0.11, c.dy + 1),
        size.shortestSide * 0.045, p);
    p.color = const Color(0xFF321506);
    canvas.drawCircle(Offset(c.dx - size.width * 0.11, c.dy + 2),
        size.shortestSide * 0.022, p);
    canvas.drawCircle(Offset(c.dx + size.width * 0.11, c.dy + 2),
        size.shortestSide * 0.022, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5B2105);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + size.height * 0.13),
        width: size.width * 0.20,
        height: size.height * 0.12,
      ),
      0,
      math.pi,
      false,
      p,
    );
    p
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;
    p.color = Colors.white.withAlpha(160);
    canvas.drawCircle(
        Offset(c.dx - size.width * 0.16, c.dy - size.height * 0.13),
        size.shortestSide * 0.035,
        p);
  }

  @override
  bool shouldRepaint(_AvatarPainter oldDelegate) =>
      oldDelegate.initial != initial || oldDelegate.preset != preset;
}
