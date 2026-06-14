import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  SHOP SCREEN — Premium marketplace
// ═══════════════════════════════════════════════════════════════════════════════

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  int _tabIndex = 0;

  late final AnimationController _bgCtrl;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabCtrl.indexIsChanging || _tabCtrl.index != _tabIndex) {
          setState(() => _tabIndex = _tabCtrl.index);
        }
      });

    _bgCtrl      = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bgCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFF08001A),
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ShopBgPainter(_bgCtrl.value),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              // Header
              _ShopHeader(state: state, shimmer: _shimmerCtrl),

              // Tab bar
              _ShopTabBar(controller: _tabCtrl),

              // Grid
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _ShopGrid(tab: 0, state: state),
                    _ShopGrid(tab: 1, state: state),
                    _ShopGrid(tab: 2, state: state),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shop background ──────────────────────────────────────────────────────────

class _ShopBgPainter extends CustomPainter {
  final double t;
  _ShopBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    // Base
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, 0),
      size.height * 0.8,
      [const Color(0xFF1A0040), const Color(0xFF08001A)],
    );
    canvas.drawRect(Offset.zero & size, p);

    // Gold shimmer at top (header glow)
    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.12),
      size.width * (0.5 + 0.15 * math.sin(t * math.pi * 2)),
      [const Color(0x18FFD426), Colors.transparent],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    // Stars
    for (int i = 0; i < 40; i++) {
      final sx = ((i * 137 + 11) % 1000) / 1000.0 * size.width;
      final sy = ((i * 211 + 53) % 1000) / 1000.0 * size.height;
      final tw = 0.2 + 0.8 * (0.5 + 0.5 * math.sin(t * math.pi * 2 * 2 + i));
      p.color = Colors.white.withAlpha((tw * 80).round());
      canvas.drawCircle(Offset(sx, sy), 0.7, p);
    }
  }

  @override
  bool shouldRepaint(_ShopBgPainter old) => old.t != t;
}

// ── Shop header ──────────────────────────────────────────────────────────────

class _ShopHeader extends StatelessWidget {
  final AppState state;
  final AnimationController shimmer;
  const _ShopHeader({required this.state, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D0060), Color(0xFF1A0040), Color(0xFF08001A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: Color(0x44FFD426))),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Back button
            Positioned(
              top: 4, left: 4,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: goldColor, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Merchant avatar (right)
            Positioned(
              right: 20, bottom: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: shimmer,
                    builder: (_, __) => Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: const [
                            goldColor, Color(0xFFFF9A00), goldColor,
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
                            color: Color(0xFF2D0060),
                          ),
                          child: const Center(
                            child: Text('🧙', style: TextStyle(fontSize: 30)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: goldColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: goldColor.withAlpha(100)),
                    ),
                    child: const Text('Merchant',
                      style: TextStyle(
                        color: goldColor, fontSize: 9, fontWeight: FontWeight.bold,
                      )),
                  ),
                ],
              ),
            ),

            // Center: SHOP title + currency
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 90, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // SHOP text with glow
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [goldColor, Color(0xFFFF9A00), goldColor],
                    ).createShader(bounds),
                    child: const Text(
                      'SHOP',
                      style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 6,
                        shadows: [
                          Shadow(color: Color(0xBBFFD426), blurRadius: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Currency row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(50),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CurrChip('🪙', _fmt(state.coins), const Color(0xFFFFD426)),
                        const SizedBox(width: 16),
                        _CurrChip('💎', '30', const Color(0xFF00E5FF)),
                        const SizedBox(width: 16),
                        _CurrChip('⚡', '0', const Color(0xFFFFB300)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

class _CurrChip extends StatelessWidget {
  final String icon, value;
  final Color color;
  const _CurrChip(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 15)),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(
        color: color, fontSize: 13, fontWeight: FontWeight.bold,
      )),
    ]);
  }
}

// ── Shop tab bar ─────────────────────────────────────────────────────────────

class _ShopTabBar extends StatelessWidget {
  final TabController controller;
  const _ShopTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0025),
      child: TabBar(
        controller: controller,
        indicatorColor: goldColor,
        indicatorWeight: 3,
        labelColor: goldColor,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: goldColor, width: 3),
          insets: EdgeInsets.symmetric(horizontal: 20),
        ),
        tabs: const [
          Tab(text: '🪙  Coins'),
          Tab(text: '💎  Gems'),
          Tab(text: '⚡  Boosters'),
        ],
      ),
    );
  }
}

// ── Shop grid ────────────────────────────────────────────────────────────────

class _ShopGrid extends StatelessWidget {
  final int tab;
  final AppState state;
  const _ShopGrid({required this.tab, required this.state});

  static const _coinItems = [
    _ShopItem('500 Coins',  '+ 50 Free',   '🪙', '\$0.99',  false, false),
    _ShopItem('1,200 Coins','+ 200 Free',  '🪙', '\$1.99',  true,  false),
    _ShopItem('2,500 Coins','+ 500 Free',  '🪙', '\$3.99',  false, false),
    _ShopItem('5,000 Coins','+ 1K Free',   '🪙', '\$6.99',  false, true),
    _ShopItem('10K Coins',  '+ 3K Free',   '🪙', '\$12.99', false, false),
    _ShopItem('25K Coins',  '+ 10K Free',  '🪙', '\$24.99', true,  false),
  ];

  static const _gemItems = [
    _ShopItem('30 Gems',   '+ 5 Free',    '💎', '\$0.99',  false, false),
    _ShopItem('80 Gems',   '+ 20 Free',   '💎', '\$1.99',  true,  false),
    _ShopItem('200 Gems',  '+ 60 Free',   '💎', '\$3.99',  false, false),
    _ShopItem('500 Gems',  '+ 150 Free',  '💎', '\$6.99',  false, true),
    _ShopItem('1000 Gems', '+ 400 Free',  '💎', '\$12.99', true,  false),
    _ShopItem('3000 Gems', '+ 1.5K Free', '💎', '\$29.99', false, false),
  ];

  static const _boostItems = [
    _ShopItem('Double XP',    '2× for 1 hr',   '⚡', '\$0.49', false, false),
    _ShopItem('Coin Boost',   '3× for 30 min', '🔋', '\$0.49', true,  false),
    _ShopItem('Lucky Dice',   '5 Rolls',        '🎲', '\$0.99', false, false),
    _ShopItem('Shield',       '1 Match',        '🛡️', '\$0.99', false, true),
    _ShopItem('Double Coins', '10 Matches',     '🪙', '\$1.99', false, false),
    _ShopItem('VIP Pass',     '7 Days',         '👑', '\$4.99', true,  false),
  ];

  List<_ShopItem> get _items =>
      tab == 0 ? _coinItems : tab == 1 ? _gemItems : _boostItems;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.80,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _items.length,
      itemBuilder: (ctx, i) => _ShopCard(
        item: _items[i],
        onBuy: () {
          if (tab == 0) {
            const amounts = [500, 1200, 2500, 5000, 10000, 25000];
            state.addCoins(amounts[i]);
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('${_items[i].title} added! 🎉'),
              backgroundColor: boardGreen,
              duration: const Duration(seconds: 1),
            ));
          } else {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('In-app purchases coming soon! 🚀'),
              duration: Duration(seconds: 1),
            ));
          }
        },
      ),
    );
  }
}

class _ShopItem {
  final String title, bonus, emoji, price;
  final bool hot, bestValue;
  const _ShopItem(this.title, this.bonus, this.emoji, this.price, this.hot, this.bestValue);
}

class _ShopCard extends StatefulWidget {
  final _ShopItem item;
  final VoidCallback onBuy;
  const _ShopCard({required this.item, required this.onBuy});

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTapDown: (_) => _ctrl.forward(),
          onTapUp:   (_) { _ctrl.reverse(); widget.onBuy(); },
          onTapCancel: () => _ctrl.reverse(),
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A0060), Color(0xFF1A0040)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.item.hot
                      ? const Color(0xAAFF6B35)
                      : widget.item.bestValue
                          ? const Color(0xAA00E5FF)
                          : const Color(0x55FFD426),
                  width: (widget.item.hot || widget.item.bestValue) ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.item.hot
                        ? const Color(0x30FF6B35)
                        : widget.item.bestValue
                            ? const Color(0x3000E5FF)
                            : Colors.transparent,
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Emoji with glow
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(8),
                      border: Border.all(color: goldColor.withAlpha(40)),
                    ),
                    child: Center(
                      child: Text(widget.item.emoji,
                        style: const TextStyle(fontSize: 30)),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(widget.item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.bold,
                    )),

                  const SizedBox(height: 3),

                  // Bonus
                  Text(widget.item.bonus,
                    style: const TextStyle(
                      color: Color(0xFF69F0AE),
                      fontSize: 11, fontWeight: FontWeight.bold,
                    )),

                  const SizedBox(height: 10),

                  // Buy button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: boardGreen.withAlpha(80),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(widget.item.price,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.bold,
                      )),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),

        // HOT DEAL badge
        if (widget.item.hot)
          Positioned(
            top: -8, right: -8,
            child: Transform.rotate(
              angle: 0.35,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                ),
                child: const Text('HOT\nDEAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white, fontSize: 8,
                    fontWeight: FontWeight.bold, height: 1.1,
                  )),
              ),
            ),
          ),

        // BEST VALUE badge
        if (widget.item.bestValue)
          Positioned(
            top: -8, left: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
              ),
              child: const Text('BEST\nVALUE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white, fontSize: 8,
                  fontWeight: FontWeight.bold, height: 1.1,
                )),
            ),
          ),
      ],
    );
  }
}
