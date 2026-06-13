import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabCtrl.indexIsChanging || _tabCtrl.index != _tabIndex) {
          setState(() => _tabIndex = _tabCtrl.index);
        }
      });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: bgDeep,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────
          _ShopHeader(state: state),

          // ── Tabs ──────────────────────────────────────────
          Container(
            color: const Color(0xFF1E002E),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: goldColor,
              indicatorWeight: 3,
              labelColor: goldColor,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Coins'),
                Tab(text: 'Gems'),
                Tab(text: 'Boosters'),
              ],
            ),
          ),

          // ── Grid ──────────────────────────────────────────
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
    );
  }
}

// ── Shop header ────────────────────────────────────────────────────────────────

class _ShopHeader extends StatelessWidget {
  final AppState state;
  const _ShopHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [woodBrown, Color(0xFF4A2810)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Back button
            Positioned(
              top: 4, left: 4,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: goldColor, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Merchant illustration
            Positioned(
              right: 20, bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4A2810),
                      border: Border.all(color: goldColor, width: 3),
                    ),
                    child: const Center(
                      child: Text('🧙', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: goldColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Merchant',
                      style: TextStyle(color: Color(0xFF4A2810), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // SHOP banner
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                    ),
                    child: const Text(
                      'SHOP',
                      style: TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(2, 2))],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Currency row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CurrItem('🪙', '${_fmt(state.coins)}'),
                        const SizedBox(width: 16),
                        const _CurrItem('💎', '30'),
                        const SizedBox(width: 16),
                        const _CurrItem('⚡', '0'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

class _CurrItem extends StatelessWidget {
  final String icon;
  final String value;
  const _CurrItem(this.icon, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 4),
      Text(value, style: const TextStyle(
        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold,
      )),
    ]);
  }
}

// ── Shop grid ──────────────────────────────────────────────────────────────────

class _ShopGrid extends StatelessWidget {
  final int tab;
  final AppState state;
  const _ShopGrid({required this.tab, required this.state});

  static const _coinItems = [
    _ShopItem('500 Coins',  '+ 50 Free',  '🪙', '\$0.99',  false),
    _ShopItem('1200 Coins', '+ 200 Free', '🪙', '\$1.99',  true),
    _ShopItem('2500 Coins', '+ 500 Free', '🪙', '\$3.99',  false),
    _ShopItem('5000 Coins', '+ 1K Free',  '🪙', '\$6.99',  false),
    _ShopItem('10K Coins',  '+ 3K Free',  '🪙', '\$12.99', false),
    _ShopItem('25K Coins',  '+ 10K Free', '🪙', '\$24.99', true),
  ];

  static const _gemItems = [
    _ShopItem('30 Gems',   '+ 5 Free',   '💎', '\$0.99',  false),
    _ShopItem('80 Gems',   '+ 20 Free',  '💎', '\$1.99',  true),
    _ShopItem('200 Gems',  '+ 60 Free',  '💎', '\$3.99',  false),
    _ShopItem('500 Gems',  '+ 150 Free', '💎', '\$6.99',  false),
    _ShopItem('1000 Gems', '+ 400 Free', '💎', '\$12.99', true),
    _ShopItem('3000 Gems', '+ 1.5K Free','💎', '\$29.99', false),
  ];

  static const _boostItems = [
    _ShopItem('Double XP',    '2× for 1 hr',  '⚡', '\$0.49', false),
    _ShopItem('Coin Boost',   '3× for 30 min','🔋', '\$0.49', true),
    _ShopItem('Lucky Dice',   '5 Rolls',       '🎲', '\$0.99', false),
    _ShopItem('Shield',       '1 match',       '🛡️', '\$0.99', false),
    _ShopItem('Double Coins', '10 matches',    '🪙', '\$1.99', false),
    _ShopItem('VIP Pass',     '7 days',        '👑', '\$4.99', true),
  ];

  List<_ShopItem> get _items {
    if (tab == 0) return _coinItems;
    if (tab == 1) return _gemItems;
    return _boostItems;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _items.length,
      itemBuilder: (ctx, i) => _ShopCard(item: _items[i], onBuy: () {
        // Add coins preview
        if (tab == 0) {
          final amounts = [500, 1200, 2500, 5000, 10000, 25000];
          state.addCoins(amounts[i]);
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('Added ${_items[i].title}!'),
            backgroundColor: greenBtn,
            duration: const Duration(seconds: 1),
          ));
        } else {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('In-app purchases coming soon!'),
            duration: Duration(seconds: 1),
          ));
        }
      }),
    );
  }
}

class _ShopItem {
  final String title;
  final String bonus;
  final String emoji;
  final String price;
  final bool hot;
  const _ShopItem(this.title, this.bonus, this.emoji, this.price, this.hot);
}

class _ShopCard extends StatelessWidget {
  final _ShopItem item;
  final VoidCallback onBuy;
  const _ShopCard({required this.item, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onBuy,
          child: Container(
            decoration: BoxDecoration(
              color: salmonCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Text(item.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 6),
                Text(item.title, style: const TextStyle(
                  color: Color(0xFF3E1800),
                  fontSize: 15, fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 2),
                Text(item.bonus, style: const TextStyle(
                  color: greenBtn,
                  fontSize: 11, fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [greenBtn, greenDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item.price,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.bold,
                    )),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // HOT DEAL badge
        if (item.hot)
          Positioned(
            top: -6, right: -6,
            child: Transform.rotate(
              angle: 0.35,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                ),
                child: const Text('HOT\nDEAL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, height: 1.1,
                  )),
              ),
            ),
          ),
      ],
    );
  }
}
