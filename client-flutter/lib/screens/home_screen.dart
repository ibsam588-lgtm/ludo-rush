import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, state, _) => Stack(
          children: [
            // Cosmic background
            Positioned.fill(
              child: CustomPaint(painter: _CosmicBg(state.isDarkMode)),
            ),
            // Content
            SafeArea(
              child: Column(
                children: [
                  _TopBar(state: state),
                  _HeroSection(isDark: state.isDarkMode),
                  Expanded(child: _ModeList(state: state)),
                  _BottomNav(state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cosmic background CustomPainter ───────────────────────────────────────────

class _CosmicBg extends CustomPainter {
  final bool dark;
  _CosmicBg(this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final darkColors  = [const Color(0xff050027), const Color(0xff35128B), const Color(0xff9B1FE0), const Color(0xff120022)];
    final lightColors = [const Color(0xff3B14A7), const Color(0xffF04FD5), const Color(0xff47D9FF), const Color(0xffFFF0B4)];
    paint.shader = ui.Gradient.linear(
      Offset.zero, Offset(size.width, size.height),
      dark ? darkColors : lightColors,
    );
    canvas.drawRect(Offset.zero & size, paint);
    paint.shader = null;

    // Soft orbs
    paint.color = const Color(0x44FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.74, size.height * 0.10), size.width * 0.10, paint);
    paint.color = const Color(0x20FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.47), size.width * 0.38, paint);

    // Stars / sparkles
    final starColors = [0xffFFFFFF, 0xffFFD426, 0xff32E9FF, 0xffFF4FD8, 0xff58FF3B];
    for (int i = 0; i < 60; i++) {
      final x = ((i * 71 + 19) % 1000) / 1000.0 * size.width;
      final y = ((i * 127 + 43) % 1000) / 1000.0 * size.height;
      paint.color = Color(starColors[i % 5] | 0xFF000000);
      canvas.drawCircle(Offset(x, y), 1.8 + (i % 3), paint);
    }
  }

  @override
  bool shouldRepaint(_CosmicBg old) => old.dark != dark;
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppState state;
  const _TopBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff25105C), Color(0xff10042E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xff8D51FF), width: 2),
      ),
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
            ),
            child: Center(
              child: Text(
                state.displayName.isNotEmpty ? state.displayName[0].toUpperCase() : 'L',
                style: const TextStyle(
                  color: Color(0xff262066), fontSize: 22, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Name + rating
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.displayName, style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('T  ${state.rating}', style: const TextStyle(
                  color: Color(0xffFFD426), fontSize: 12, fontWeight: FontWeight.bold,
                )),
              ],
            ),
          ),
          // Coins chip
          _CurrencyChip(label: '${_fmt(state.coins)}', icon: '◈', color: AppColors.gold),
          const SizedBox(width: 4),
          // Theme toggle
          GestureDetector(
            onTap: state.toggleDarkMode,
            child: Container(
              width: 48, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffFFE15A), Color(0xffFF8A00)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffFFEE98), width: 2),
              ),
              child: Center(
                child: Text(
                  state.isDarkMode ? '☀️' : '🌙',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
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

class _CurrencyChip extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  const _CurrencyChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff321271), Color(0xff180737)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(child: Text(icon, style: TextStyle(
              color: Colors.brown.shade900, fontSize: 11, fontWeight: FontWeight.bold,
            ))),
          ),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}

// ── Hero section ───────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isDark;
  const _HeroSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  static const _letterColors = [
    Color(0xffF22F22), Color(0xff23D627), Color(0xffFFD426), Color(0xff0D9BFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final w = size.width;
    final h = size.height;

    // Crown
    _drawCrown(canvas, paint, w * 0.50, h * 0.24, w * 0.14);

    // Dice
    _drawDice(canvas, paint, w * 0.22, h * 0.56, w * 0.11, 4);
    _drawDice(canvas, paint, w * 0.78, h * 0.56, w * 0.11, 5);

    // "LUDO" text
    _drawOutlinedLetters(canvas, paint, 'LUDO', w / 2, h * 0.64, w * 0.19, _letterColors);

    // "RUSH" text
    final rushSize = w * 0.17;
    final rushY = h * 0.88;
    final tp = TextPainter(
      text: TextSpan(
        text: 'RUSH',
        style: TextStyle(
          fontSize: rushSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, rushY - rushSize), Offset(0, rushY),
              [Colors.white, const Color(0xffF7B3FF)],
            ),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, rushY - tp.height));
  }

  void _drawCrown(Canvas canvas, Paint p, double cx, double cy, double s) {
    final path = Path()
      ..moveTo(cx - s, cy + s * 0.60)
      ..lineTo(cx - s * 0.72, cy - s * 0.28)
      ..lineTo(cx - s * 0.28, cy + s * 0.16)
      ..lineTo(cx, cy - s * 0.64)
      ..lineTo(cx + s * 0.28, cy + s * 0.16)
      ..lineTo(cx + s * 0.72, cy - s * 0.28)
      ..lineTo(cx + s, cy + s * 0.60)
      ..close();
    p.shader = ui.Gradient.linear(
      Offset(cx, cy - s), Offset(cx, cy + s),
      [const Color(0xffFFF49A), const Color(0xffF49300)],
    );
    canvas.drawPath(path, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..color = const Color(0xffFFF2A1);
    canvas.drawPath(path, p);
    p.style = PaintingStyle.fill;
  }

  void _drawDice(Canvas canvas, Paint p, double cx, double cy, double s, int val) {
    final r = Rect.fromCenter(center: Offset(cx, cy), width: s, height: s);
    p.color = const Color(0x77000000);
    canvas.drawRRect(RRect.fromRectXY(r.translate(7, 8), s * 0.18, s * 0.18), p);
    p.color = Colors.white;
    canvas.drawRRect(RRect.fromRectXY(r, s * 0.18, s * 0.18), p);
    p.color = const Color(0xff221022);
    final dot = s * 0.07;
    final lx = r.left + s * 0.30;
    final rx = r.right - s * 0.30;
    final ty = r.top + s * 0.30;
    final by = r.bottom - s * 0.30;
    final mx = r.center.dx;
    final my = r.center.dy;
    if (val == 1 || val == 3 || val == 5) canvas.drawCircle(Offset(mx, my), dot, p);
    if (val >= 2) {
      canvas.drawCircle(Offset(lx, ty), dot, p);
      canvas.drawCircle(Offset(rx, by), dot, p);
    }
    if (val >= 4) {
      canvas.drawCircle(Offset(rx, ty), dot, p);
      canvas.drawCircle(Offset(lx, by), dot, p);
    }
  }

  void _drawOutlinedLetters(Canvas canvas, Paint p, String text, double cx, double baseY,
      double textSize, List<Color> colors) {
    // Measure each letter individually for precise placement
    double totalW = 0;
    final tps = <TextPainter>[];
    for (int i = 0; i < text.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: text[i], style: TextStyle(
          fontSize: textSize, fontWeight: FontWeight.w900,
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      tps.add(tp);
      totalW += tp.width;
    }
    double x = cx - totalW / 2;
    for (int i = 0; i < text.length; i++) {
      final tp = tps[i];
      final lx = x + tp.width / 2;

      // Stroke outline
      final outlinePainter = TextPainter(
        text: TextSpan(text: text[i], style: TextStyle(
          fontSize: textSize, fontWeight: FontWeight.w900,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(7, textSize * 0.10)
            ..color = const Color(0xfffff6cf),
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      outlinePainter.paint(canvas, Offset(lx - tp.width / 2, baseY - tp.height));

      // Colored fill
      final fillPainter = TextPainter(
        text: TextSpan(text: text[i], style: TextStyle(
          fontSize: textSize, fontWeight: FontWeight.w900,
          foreground: Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, baseY - textSize), Offset(0, baseY),
              [Colors.white, colors[i % colors.length]],
            ),
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      fillPainter.paint(canvas, Offset(lx - tp.width / 2, baseY - tp.height));

      x += tp.width;
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}

// ── Mode list ──────────────────────────────────────────────────────────────────

class _ModeList extends StatelessWidget {
  final AppState state;
  const _ModeList({required this.state});

  static const _modes = [
    _Mode('QUICK MATCH',  'Find players online\nand play now!',    0xffD238F5, 0xff7010B8, '🎲'),
    _Mode('1 ON 1',       'Challenge a player\nin a duel',         0xffFFB60A, 0xffCA6800, '⚔️'),
    _Mode('4 PLAYER',     'Classic Ludo with\n4 players',          0xff1DCF39, 0xff006A18, '👥'),
    _Mode('PRIVATE ROOM', 'Create a room and\ninvite your friends',0xff159CFF, 0xff003EBD, '🔒'),
    _Mode('PLAY OFFLINE', 'Play against smart\nAI opponents',      0xffDB2CCB, 0xff701070, '🤖'),
    _Mode('TEAM UP',      'Team up and win\ntogether',             0xffF14320, 0xff991000, '🤝'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      itemCount: _modes.length,
      itemBuilder: (ctx, i) => _ModeCard(
        mode: _modes[i],
        onTap: () => _onTap(context, i),
      ),
    );
  }

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0: state.startQuickMatch('classic_2p'); break;
      case 1: state.startQuickMatch('classic_2p'); break;
      case 2: state.startQuickMatch('classic_4p'); break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Private rooms — coming soon')));
        break;
      case 4: state.startBotMatch('classic_2p'); break;
      case 5:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team mode — coming soon')));
        break;
    }
  }
}

class _Mode {
  final String title;
  final String subtitle;
  final int gradStart;
  final int gradEnd;
  final String icon;
  const _Mode(this.title, this.subtitle, this.gradStart, this.gradEnd, this.icon);
}

class _ModeCard extends StatelessWidget {
  final _Mode mode;
  final VoidCallback onTap;
  const _ModeCard({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(mode.gradStart), Color(mode.gradEnd)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffFFEB75), width: 3),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 7, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            // Icon area
            SizedBox(
              width: 80,
              child: Center(
                child: Text(mode.icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.title, style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))],
                    )),
                    const SizedBox(height: 3),
                    Text(mode.subtitle, style: const TextStyle(
                      color: Color(0xffFFE0FF), fontSize: 12, height: 1.3,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
                    ), maxLines: 2),
                  ],
                ),
              ),
            ),
            // Arrow
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav ─────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final AppState state;
  const _BottomNav({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff21106B), Color(0xff100636)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xff6648FF), width: 2),
      ),
      child: Row(
        children: [
          _NavItem(label: 'SHOP',       icon: Icons.shopping_cart_rounded, active: false, onTap: () => Navigator.pushNamed(context, '/shop')),
          _NavItem(label: 'FRIENDS',    icon: Icons.people_rounded,        active: false, onTap: () {}),
          _NavItem(label: 'HOME',       icon: Icons.home_rounded,          active: true,  onTap: () {}),
          _NavItem(label: 'COLLECTION', icon: Icons.style_rounded,         active: false, onTap: () {}),
          _NavItem(label: 'EVENTS',     icon: Icons.calendar_today_rounded,active: false, onTap: () {}),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: active ? BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff9C22F4), Color(0xff32037A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffFFD426), width: 3),
          ) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: active ? 22 : 20),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(
                color: Colors.white, fontSize: active ? 9 : 8,
                fontWeight: FontWeight.w900, letterSpacing: -0.3,
              ), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
