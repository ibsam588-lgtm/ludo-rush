import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  HOME SCREEN — Warm Cartoon Game Lobby
// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _navIndex = 2;

  late final AnimationController _bgCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _starCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl      = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _pulseCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _starCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        backgroundColor: const Color(0xFF1A0520),
        body: Stack(
          children: [
            // ── Animated warm background ──────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _WarmBgPainter(_bgCtrl.value, _starCtrl.value),
                ),
              ),
            ),

            // ── Main UI ───────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  _TopBar(state: state, shimmer: _shimmerCtrl),
                  _SkinFrames(),
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                          child: _ModeGrid(
                            state: state,
                            pulse: _pulseCtrl,
                            shimmer: _shimmerCtrl,
                          ),
                        ),
                        if (state.connecting)
                          const Positioned.fill(child: _JoiningOverlay()),
                      ],
                    ),
                  ),
                  _BottomNav(
                    index: _navIndex,
                    onTap: (i) {
                      setState(() => _navIndex = i);
                      if (i == 0) Navigator.pushNamed(context, '/shop');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated warm background ─────────────────────────────────────────────────

class _WarmBgPainter extends CustomPainter {
  final double t;
  final double starT;
  _WarmBgPainter(this.t, this.starT);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    // Warm deep base
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.25),
      size.height * 0.9,
      [const Color(0xFF2D0A3A), const Color(0xFF1A0520)],
      [0.0, 1.0],
    );
    canvas.drawRect(Offset.zero & size, p);

    // Amber orb (top-left wandering)
    final cx1 = size.width * (0.15 + 0.25 * math.sin(t * math.pi * 2));
    final cy1 = size.height * (0.08 + 0.12 * math.cos(t * math.pi * 2));
    p.shader = ui.Gradient.radial(
      Offset(cx1, cy1),
      size.width * 0.55,
      [const Color(0x18FF9A00), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);

    // Orange-red orb (right-center wandering)
    final cx2 = size.width * (0.80 + 0.15 * math.cos(t * math.pi * 2 + 2.1));
    final cy2 = size.height * (0.45 + 0.18 * math.sin(t * math.pi * 2 + 2.1));
    p.shader = ui.Gradient.radial(
      Offset(cx2, cy2),
      size.width * 0.50,
      [const Color(0x14FF6040), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);

    // Gold orb (bottom-center)
    final cx3 = size.width * (0.45 + 0.1 * math.sin(t * math.pi * 2 + 4.2));
    final cy3 = size.height * (0.75 + 0.08 * math.cos(t * math.pi * 2 + 4.2));
    p.shader = ui.Gradient.radial(
      Offset(cx3, cy3),
      size.width * 0.40,
      [const Color(0x14FFD426), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    // Twinkling warm stars/sparks
    for (int i = 0; i < 60; i++) {
      final sx = ((i * 137 + 11) % 1000) / 1000.0 * size.width;
      final sy = ((i * 211 + 37) % 1000) / 1000.0 * size.height;
      final twinkle = 0.2 + 0.8 * (0.5 + 0.5 * math.sin(starT * math.pi * 2 * 3 + i * 0.9));
      final r = 0.6 + (i % 4) * 0.5;
      p.color = Color.fromARGB((twinkle * 140).round(), 255, 220, 180);
      canvas.drawCircle(Offset(sx, sy), r, p);
    }

    // Warm sparkles
    const sparkColors = [Color(0xFFFF9A00), Color(0xFFFF6B35), Color(0xFFFFD426)];
    for (int i = 0; i < 15; i++) {
      final sx = ((i * 317 + 53) % 1000) / 1000.0 * size.width;
      final sy = ((i * 173 + 79) % 1000) / 1000.0 * size.height;
      final phase = starT * math.pi * 2 + i * 1.2;
      final brightness = (0.5 + 0.5 * math.sin(phase)).clamp(0.0, 1.0);
      p.color = sparkColors[i % 3].withAlpha((brightness * 100).round());
      canvas.drawCircle(Offset(sx, sy), 1.2, p);
    }
  }

  @override
  bool shouldRepaint(_WarmBgPainter old) => old.t != t || old.starT != starT;
}

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppState state;
  final AnimationController shimmer;
  const _TopBar({required this.state, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          // Warm gradient avatar ring
          GestureDetector(
            onTap: () {},
            child: AnimatedBuilder(
              animation: shimmer,
              builder: (_, __) => Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: const [
                      Color(0xFFFF9A00), Color(0xFFFF4500), Color(0xFFFFD426),
                      Color(0xFFFF6B35), Color(0xFFFF9A00),
                    ],
                    startAngle: shimmer.value * math.pi * 2,
                    endAngle:   shimmer.value * math.pi * 2 + math.pi * 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2D0A3A),
                    ),
                    child: Center(
                      child: Text(
                        state.displayName.isNotEmpty
                            ? state.displayName[0].toUpperCase()
                            : 'L',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Name + XP bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.displayName,
                style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.stars_rounded, color: goldColor, size: 12),
                const SizedBox(width: 3),
                Text('Lv ${state.rating ~/ 50 + 1}',
                  style: const TextStyle(color: goldColor, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                _WarmXpBar(shimmer: shimmer, value: (state.rating % 50) / 50.0),
              ]),
            ],
          ),

          const Spacer(),

          // Currency pills
          _WarmPill(icon: '🏆', val: '${state.wins}',     glow: const Color(0xFFFFD426)),
          const SizedBox(width: 5),
          _WarmPill(icon: '🪙', val: _fmt(state.coins),   glow: const Color(0xFFFF9A00)),
          const SizedBox(width: 5),
          _WarmPill(icon: '💎', val: '30',               glow: const Color(0xFFFF6B35)),
          const SizedBox(width: 6),

          // Settings button
          GestureDetector(
            onTap: state.toggleDarkMode,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.settings_rounded, color: Colors.white54, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

class _WarmXpBar extends StatelessWidget {
  final AnimationController shimmer;
  final double value;
  const _WarmXpBar({required this.shimmer, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70, height: 8,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          AnimatedBuilder(
            animation: shimmer,
            builder: (_, __) => FractionallySizedBox(
              widthFactor: value.clamp(0.05, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: const [Color(0xFFFF9A00), Color(0xFFFFD426), Color(0xFFFF9A00)],
                    stops: const [0, 0.5, 1],
                    begin: Alignment(shimmer.value * 2 - 1, 0),
                    end:   Alignment(shimmer.value * 2 + 1, 0),
                  ),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFFFF9A00).withAlpha(100),
                    blurRadius: 4,
                  )],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmPill extends StatelessWidget {
  final String icon, val;
  final Color glow;
  const _WarmPill({required this.icon, required this.val, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: glow.withAlpha(22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: glow.withAlpha(100), width: 1),
        boxShadow: [BoxShadow(color: glow.withAlpha(35), blurRadius: 6)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(val, style: const TextStyle(
          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold,
        )),
      ]),
    );
  }
}

// ── Skin frames row ──────────────────────────────────────────────────────────

class _SkinFrames extends StatelessWidget {
  const _SkinFrames();

  static const _colors = [
    Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFFFFB300),
    Color(0xFF43A047), Color(0xFFFF6B35),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        itemCount: 5,
        itemBuilder: (_, i) {
          final c = _colors[i];
          return Container(
            width: 58, height: 64,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D0A3A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withAlpha(100), width: 1.5),
              boxShadow: [BoxShadow(color: c.withAlpha(40), blurRadius: 8)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, color: c.withAlpha(200), size: 18),
                const SizedBox(height: 4),
                Text('Lv ${(i + 1) * 5}',
                  style: TextStyle(
                    color: c.withAlpha(160), fontSize: 9, fontWeight: FontWeight.bold,
                  )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Mode grid ────────────────────────────────────────────────────────────────

class _ModeGrid extends StatelessWidget {
  final AppState state;
  final AnimationController pulse;
  final AnimationController shimmer;
  const _ModeGrid({required this.state, required this.pulse, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Big mode cards
        Row(children: [
          Expanded(child: _BigModeCard(
            title: '2 Players',
            subtitle: 'Quick Duel',
            gradient: [const Color(0xFFE65100), const Color(0xFF8B0000)],
            glowColor: const Color(0xFFFF6B35),
            seats: [boardRed, boardBlue],
            emoji: '⚔️',
            pulse: pulse,
            onTap: () => state.startQuickMatch('classic_2p'),
          )),
          const SizedBox(width: 10),
          Expanded(child: _BigModeCard(
            title: '4 Players',
            subtitle: 'Battle Royal',
            gradient: [const Color(0xFF6A1B9A), const Color(0xFF2D0A3A)],
            glowColor: const Color(0xFFFF9A00),
            seats: [boardRed, boardBlue, boardYellow, boardGreen],
            emoji: '👑',
            pulse: pulse,
            onTap: () => state.startQuickMatch('classic_4p'),
          )),
        ]),
        const SizedBox(height: 10),

        // Small mode cards
        Row(children: [
          Expanded(child: _SmallModeCard(
            title: 'Private',
            emoji: '❤️',
            gradient: [const Color(0xFFE91E63), const Color(0xFF880E4F)],
            pulse: pulse,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Private rooms — coming soon'))),
          )),
          const SizedBox(width: 8),
          Expanded(child: _SmallModeCard(
            title: 'Online',
            emoji: '🌍',
            gradient: [const Color(0xFF0288D1), const Color(0xFF01579B)],
            pulse: pulse,
            onTap: () => state.startQuickMatch('classic_2p'),
          )),
          const SizedBox(width: 8),
          Expanded(child: _SmallModeCard(
            title: 'vs Bots',
            emoji: '🤖',
            gradient: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
            pulse: pulse,
            onTap: () => state.startBotMatch('classic_2p'),
          )),
        ]),
      ],
    );
  }
}

// ── Big mode card ────────────────────────────────────────────────────────────

class _BigModeCard extends StatefulWidget {
  final String title, subtitle, emoji;
  final List<Color> gradient;
  final Color glowColor;
  final List<Color> seats;
  final AnimationController pulse;
  final VoidCallback onTap;

  const _BigModeCard({
    required this.title, required this.subtitle, required this.emoji,
    required this.gradient, required this.glowColor, required this.seats,
    required this.pulse, required this.onTap,
  });

  @override
  State<_BigModeCard> createState() => _BigModeCardState();
}

class _BigModeCardState extends State<_BigModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _pressAnim,
        child: AnimatedBuilder(
          animation: widget.pulse,
          builder: (_, __) {
            final glow = 0.4 + 0.6 * widget.pulse.value;
            return Container(
              height: 178,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.glowColor.withAlpha((glow * 200).round()),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withAlpha((glow * 90).round()),
                    blurRadius: 20 + glow * 10,
                    spreadRadius: glow * 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Hex grid pattern overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CustomPaint(painter: _HexPatternPainter()),
                    ),
                  ),

                  // Big emoji watermark
                  Positioned(
                    right: -10, top: -10,
                    child: Opacity(
                      opacity: 0.12,
                      child: Text(widget.emoji, style: const TextStyle(fontSize: 100)),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seat dots
                        Row(children: widget.seats.map((c) => Container(
                          width: 14, height: 14,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white60, width: 1.5),
                            boxShadow: [BoxShadow(color: c.withAlpha(180), blurRadius: 6)],
                          ),
                        )).toList()),

                        const Spacer(),

                        // Emoji
                        Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 3),

                        // Title
                        Text(widget.title, style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        )),
                        Text(widget.subtitle, style: TextStyle(
                          color: Colors.white.withAlpha(190), fontSize: 11,
                          fontWeight: FontWeight.w500,
                        )),
                      ],
                    ),
                  ),

                  // Play button
                  Positioned(
                    right: 12, bottom: 12,
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(25),
                        border: Border.all(color: Colors.white54, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: widget.glowColor.withAlpha((glow * 80).round()),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Hexagonal grid background pattern
class _HexPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withAlpha(12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const r = 13.0;
    const h = r * 1.732;

    for (double col = -r; col < size.width + r; col += r * 1.5) {
      for (double row = -h; row < size.height + h; row += h) {
        final offset = ((col / (r * 1.5)).toInt() % 2 == 0) ? 0.0 : h / 2;
        final cx = col;
        final cy = row + offset;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = i * math.pi / 3 - math.pi / 6;
          final px = cx + r * math.cos(a);
          final py = cy + r * math.sin(a);
          if (i == 0) path.moveTo(px, py);
          else path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(_HexPatternPainter _) => false;
}

// ── Small mode card ──────────────────────────────────────────────────────────

class _SmallModeCard extends StatefulWidget {
  final String title, emoji;
  final List<Color> gradient;
  final AnimationController pulse;
  final VoidCallback onTap;
  const _SmallModeCard({
    required this.title, required this.emoji, required this.gradient,
    required this.pulse, required this.onTap,
  });

  @override
  State<_SmallModeCard> createState() => _SmallModeCardState();
}

class _SmallModeCardState extends State<_SmallModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _pressAnim,
        child: AnimatedBuilder(
          animation: widget.pulse,
          builder: (_, __) => Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.gradient.first.withAlpha(60),
                  widget.gradient.last.withAlpha(60),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.gradient.first.withAlpha(
                  (60 + widget.pulse.value * 110).round()),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.gradient.first.withAlpha(
                    (widget.pulse.value * 55).round()),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 5),
                Text(widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold,
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Joining overlay ──────────────────────────────────────────────────────────

class _JoiningOverlay extends StatelessWidget {
  const _JoiningOverlay();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: const Color(0xFF1A0520).withAlpha(190),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60, height: 60,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD426), strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 22),
                Text('Finding Match...', style: TextStyle(
                  color: Color(0xFFFFD426),
                  fontSize: 20, fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Color(0xFFFF9A00), blurRadius: 16)],
                )),
                SizedBox(height: 8),
                Text('Searching for players worldwide',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int index;
  final void Function(int) onTap;
  const _BottomNav({required this.index, required this.onTap});

  static const _items = [
    ('🛒', 'Shop'),
    ('👥', 'Friends'),
    ('🏠', 'Home'),
    ('🎤', 'Clubs'),
    ('📦', 'Chest'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xBB2A0830),
            border: Border(top: BorderSide(color: Color(0x55FF9A00))),
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(active ? 7 : 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? goldColor.withAlpha(30) : Colors.transparent,
                          boxShadow: active
                              ? [BoxShadow(color: goldColor.withAlpha(50), blurRadius: 8)]
                              : null,
                        ),
                        child: Text(_items[i].$1,
                          style: TextStyle(fontSize: active ? 22 : 18)),
                      ),
                      Text(_items[i].$2, style: TextStyle(
                        color: active ? goldColor : Colors.white38,
                        fontSize: 9,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      )),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(top: 2),
                        width: active ? 20 : 0,
                        height: 2,
                        decoration: BoxDecoration(
                          color: goldColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: active
                              ? [const BoxShadow(color: goldColor, blurRadius: 6)]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
