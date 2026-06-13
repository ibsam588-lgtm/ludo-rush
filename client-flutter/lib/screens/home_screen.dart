import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        backgroundColor: bgDeep,
        body: Stack(
          children: [
            // Radial bg
            Positioned.fill(child: CustomPaint(painter: _HomeBgPainter())),

            SafeArea(
              child: Column(
                children: [
                  _TopBar(state: state),
                  _FramesRow(),
                  // Watermark
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: Opacity(
                            opacity: 0.10,
                            child: Text(
                              'LUDO\nRUSH',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                color: goldColor,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: _ModeGrid(state: state),
                        ),
                        if (state.connecting)
                          const Positioned.fill(child: _JoiningOverlay()),
                      ],
                    ),
                  ),
                  _BottomNav(
                    selectedIndex: _navIndex,
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

// ── Background ─────────────────────────────────────────────────────────────────

class _HomeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    p.color = bgDeep;
    canvas.drawRect(Offset.zero & size, p);

    p.shader = ui.Gradient.radial(
      Offset(size.width / 2, size.height * 0.40),
      size.width * 0.75,
      [const Color(0xFF3A0058), bgDeep],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    p.color = const Color(0x15FFD426);
    for (int i = 0; i < 40; i++) {
      final x = ((i * 137 + 11) % 1000) / 1000.0 * size.width;
      final y = ((i * 211 + 37) % 1000) / 1000.0 * size.height;
      canvas.drawCircle(Offset(x, y), 1.5 + (i % 3), p);
    }
  }

  @override
  bool shouldRepaint(_HomeBgPainter _) => false;
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgMagenta,
                border: Border.all(color: Colors.white38, width: 2),
              ),
              child: Center(
                child: Text(
                  state.displayName.isNotEmpty ? state.displayName[0].toUpperCase() : 'L',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // XP
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.star, color: goldColor, size: 14),
                const SizedBox(width: 2),
                Text('${state.rating}/50',
                  style: const TextStyle(color: goldColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
              Container(
                width: 60, height: 5,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ((state.rating % 50) / 50).clamp(0.04, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: goldColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          _CurrencyPill(icon: '🏆', value: '${state.wins}',   bg: const Color(0xFF3D2800)),
          const SizedBox(width: 4),
          _CurrencyPill(icon: '🪙', value: _fmt(state.coins), bg: const Color(0xFF3D2800), gold: true),
          const SizedBox(width: 4),
          _CurrencyPill(icon: '💎', value: '30',              bg: const Color(0xFF003828)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: state.toggleDarkMode,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: bgPurple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: const Center(child: Icon(Icons.settings, color: Colors.white70, size: 18)),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _CurrencyPill extends StatelessWidget {
  final String icon;
  final String value;
  final Color bg;
  final bool gold;
  const _CurrencyPill({required this.icon, required this.value, required this.bg, this.gold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold ? goldColor : Colors.white24, width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 3),
        Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold,
        )),
      ]),
    );
  }
}

// ── Skin frames row ────────────────────────────────────────────────────────────

class _FramesRow extends StatelessWidget {
  const _FramesRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: 4,
        itemBuilder: (_, i) => Container(
          width: 62,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: bgPurple,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: AppColors.seatColors[i % 4].withAlpha(80),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white54, size: 28),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Colors.white60, size: 16),
                  const SizedBox(height: 2),
                  Text('Lv ${(i + 1) * 4}',
                    style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mode grid ──────────────────────────────────────────────────────────────────

class _ModeGrid extends StatelessWidget {
  final AppState state;
  const _ModeGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top 2 big cards
        Row(
          children: [
            Expanded(child: _BigModeCard(
              title: '2 Player',
              number: '2',
              colors: [const Color(0xFFFFB300), const Color(0xFFFF6F00)],
              seats: [boardRed, boardBlue],
              onTap: () => state.startQuickMatch('classic_2p'),
            )),
            const SizedBox(width: 8),
            Expanded(child: _BigModeCard(
              title: '4 Player',
              number: '4',
              colors: [const Color(0xFF6B1A8A), bgPurple],
              seats: [boardRed, boardBlue, boardYellow, boardGreen],
              onTap: () => state.startQuickMatch('classic_4p'),
            )),
          ],
        ),
        const SizedBox(height: 8),
        // Bottom 3 small cards
        Row(
          children: [
            Expanded(child: _SmallModeCard(
              title: 'Private',
              icon: '❤️',
              color: const Color(0xFFE91E63),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Private rooms — coming soon'))),
            )),
            const SizedBox(width: 6),
            Expanded(child: _SmallModeCard(
              title: 'Quick Match',
              icon: '🌍',
              color: boardBlue,
              onTap: () => state.startQuickMatch('classic_2p'),
            )),
            const SizedBox(width: 6),
            Expanded(child: _SmallModeCard(
              title: 'vs Bots',
              icon: '🤖',
              color: boardGreen,
              onTap: () => state.startBotMatch('classic_2p'),
            )),
          ],
        ),
      ],
    );
  }
}

class _BigModeCard extends StatelessWidget {
  final String title;
  final String number;
  final List<Color> colors;
  final List<Color> seats;
  final VoidCallback onTap;
  const _BigModeCard({
    required this.title, required this.number, required this.colors,
    required this.seats, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: colors.first.withAlpha(100), blurRadius: 12, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Stack(
          children: [
            // Big number
            Positioned(
              top: 10, right: 14,
              child: Text(number, style: TextStyle(
                fontSize: 72, fontWeight: FontWeight.w900,
                color: Colors.white.withAlpha(30),
              )),
            ),
            // Seat dots
            Positioned(
              top: 10, left: 12,
              child: Wrap(
                spacing: 4, runSpacing: 4,
                children: seats.take(4).map((c) => Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 1)),
                )).toList(),
              ),
            ),
            // Dice icon
            const Positioned(
              bottom: 32, left: 12,
              child: Text('🎲', style: TextStyle(fontSize: 28)),
            ),
            // Title at bottom
            Positioned(
              bottom: 8, left: 12, right: 8,
              child: Row(
                children: [
                  Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  )),
                  const Spacer(),
                  const Icon(Icons.play_circle_filled, color: Colors.white70, size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallModeCard extends StatelessWidget {
  final String title;
  final String icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallModeCard({
    required this.title, required this.icon, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: bgPurple,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(120), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withAlpha(40), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Joining overlay ────────────────────────────────────────────────────────────

class _JoiningOverlay extends StatelessWidget {
  const _JoiningOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgDeep.withAlpha(180),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: goldColor, strokeWidth: 3),
            SizedBox(height: 16),
            Text('Joining...', style: TextStyle(
              color: goldColor, fontSize: 18, fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav ─────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    ('🛒', 'Shop'),
    ('👥', 'Friends'),
    ('🏠', 'Home'),
    ('🎤', 'Clubs'),
    ('📦', 'Chest'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      decoration: const BoxDecoration(
        color: bgPurple,
        border: Border(top: BorderSide(color: goldColor, width: 1.5)),
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_items[i].$1,
                    style: TextStyle(fontSize: active ? 24 : 20)),
                  const SizedBox(height: 2),
                  Text(_items[i].$2,
                    style: TextStyle(
                      color: active ? goldColor : Colors.white54,
                      fontSize: 9,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    )),
                  if (active)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 20, height: 2,
                      decoration: BoxDecoration(
                        color: goldColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
