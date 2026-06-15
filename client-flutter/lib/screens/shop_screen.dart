import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg;

  static const _items = [
    _ShopProduct('1 day', '0.99 USD', _ProductArt.energy, false),
    _ShopProduct('4 days', '2.99 USD', _ProductArt.energyPile, false),
    _ShopProduct('14 days', '9.99 USD', _ProductArt.pouch, false),
    _ShopProduct('30 days', '19.99 USD', _ProductArt.pouchBig, false),
    _ShopProduct('100 days', '54.99 USD', _ProductArt.chest, false),
    _ShopProduct('200 days', '99.99 USD', _ProductArt.chestPouch, true),
  ];

  @override
  void initState() {
    super.initState();
    _bg =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final dark = state.isDarkMode;
        final p = _ShopPalette.fromDark(dark);
        return Scaffold(
          backgroundColor: p.bg,
          body: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bg,
                  builder: (_, __) =>
                      CustomPaint(painter: _ShopBackdropPainter(_bg.value, p)),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _ShopResources(state: state, palette: p),
                    _ShopHero(palette: p, animation: _bg),
                    _BoosterBanner(palette: p),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, i) => _ShopCard(
                          product: _items[i],
                          palette: p,
                          onBuy: () {
                            state.addCoins(100);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${_items[i].title} booster selected.')),
                            );
                          },
                        ),
                      ),
                    ),
                    _ShopBottomNav(palette: p),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShopPalette {
  final bool dark;
  final Color bg;
  final Color panel;
  final Color text;
  final Color muted;
  final Color stroke;
  final Color cardTop;
  final Color cardBottom;

  const _ShopPalette({
    required this.dark,
    required this.bg,
    required this.panel,
    required this.text,
    required this.muted,
    required this.stroke,
    required this.cardTop,
    required this.cardBottom,
  });

  factory _ShopPalette.fromDark(bool dark) {
    if (dark) {
      return const _ShopPalette(
        dark: true,
        bg: Color(0xFF220627),
        panel: Color(0xE02D082F),
        text: Colors.white,
        muted: Color(0xFFEED4E8),
        stroke: goldColor,
        cardTop: Color(0xFFFFB29D),
        cardBottom: Color(0xFFE88486),
      );
    }
    return const _ShopPalette(
      dark: false,
      bg: Color(0xFFFFEAF8),
      panel: Color(0xF7FFFFFF),
      text: Color(0xFF2B1232),
      muted: Color(0xFF794A78),
      stroke: Color(0xFFE38A00),
      cardTop: Color(0xFFFFD3B8),
      cardBottom: Color(0xFFFF9AA3),
    );
  }
}

class _ShopResources extends StatelessWidget {
  final AppState state;
  final _ShopPalette palette;

  const _ShopResources({required this.state, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: palette.text, size: 20),
          ),
          const Spacer(),
          _ResourceChip(
              icon: Icons.monetization_on_rounded,
              value: '${state.coins}',
              color: amberColor,
              palette: palette),
          const SizedBox(width: 14),
          _ResourceChip(
              icon: Icons.diamond_rounded,
              value: '30',
              color: const Color(0xFF22E46C),
              palette: palette),
          const SizedBox(width: 14),
          _ResourceChip(
              icon: Icons.bolt_rounded,
              value: '${state.wins}',
              color: const Color(0xFF35D6FF),
              palette: palette),
        ],
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final _ShopPalette palette;

  const _ResourceChip({
    required this.icon,
    required this.value,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 86),
      height: 34,
      padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(palette.dark ? 105 : 20),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color.lerp(color, Colors.white, 0.35)!, color]),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 7),
          Text(value,
              style: TextStyle(
                  color: palette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ShopHero extends StatelessWidget {
  final _ShopPalette palette;
  final AnimationController animation;

  const _ShopHero({required this.palette, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 166,
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
            colors: palette.dark
                ? const [
                    Color(0xFF4B112D),
                    Color(0xFF8B2337),
                    Color(0xFF3A1026)
                  ]
                : const [
                    Color(0xFFFFC5DB),
                    Color(0xFFFF9A82),
                    Color(0xFFFFE1A5)
                  ]),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(palette.dark ? 95 : 35),
              blurRadius: 12,
              offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, __) => CustomPaint(
                  painter: _ShopHeroPainter(palette, animation.value),
                ),
              ),
            ),
            Positioned(
              right: 26,
              top: 39,
              child: Transform.rotate(
                angle: -0.03,
                child: Container(
                  width: 158,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE92861), Color(0xFF92224E)]),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0x99FFD426), width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 10,
                          offset: Offset(0, 5))
                    ],
                  ),
                  child: const Text(
                    'SHOP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 33,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                            color: Colors.black87,
                            blurRadius: 2,
                            offset: Offset(2, 3))
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF9D5528), Color(0xFF5C250E)]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoosterBanner extends StatelessWidget {
  final _ShopPalette palette;

  const _BoosterBanner({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 9, 22, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(palette.dark ? 120 : 35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: palette.dark ? Colors.transparent : const Color(0x22A00073)),
      ),
      child: Text(
        'Booster multiplies XP earned in a game',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: palette.text,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          shadows: palette.dark
              ? const [Shadow(color: Colors.black, blurRadius: 3)]
              : null,
        ),
      ),
    );
  }
}

enum _ProductArt { energy, energyPile, pouch, pouchBig, chest, chestPouch }

class _ShopProduct {
  final String title;
  final String price;
  final _ProductArt art;
  final bool best;

  const _ShopProduct(this.title, this.price, this.art, this.best);
}

class _ShopCard extends StatefulWidget {
  final _ShopProduct product;
  final _ShopPalette palette;
  final VoidCallback onBuy;

  const _ShopCard({
    required this.product,
    required this.palette,
    required this.onBuy,
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
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
        widget.onBuy();
      },
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 - _press.value * 0.05,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.palette.cardTop,
                        widget.palette.cardBottom
                      ],
                    ),
                    border:
                        Border.all(color: const Color(0xFFFFD18A), width: 1.4),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 5,
                          offset: Offset(0, 4)),
                      BoxShadow(
                          color: Color(0x663A0B22),
                          blurRadius: 0,
                          offset: Offset(0, 7)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 7),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.product.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                  color: Color(0xAA5A2100),
                                  blurRadius: 2,
                                  offset: Offset(1, 2))
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: CustomPaint(
                              painter: _ProductPainter(widget.product.art),
                              child: const SizedBox.expand()),
                        ),
                      ),
                      Container(
                        height: 34,
                        margin: const EdgeInsets.fromLTRB(8, 0, 8, 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                              colors: [Color(0xFF92F23A), Color(0xFF2EAD25)]),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x77025E00),
                                blurRadius: 0,
                                offset: Offset(0, 4))
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.product.price,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                    color: Color(0xAA124D00),
                                    blurRadius: 2,
                                    offset: Offset(1, 2))
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.product.best)
                  Positioned(
                    right: -5,
                    top: -6,
                    child: Transform.rotate(
                      angle: 0.02,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE71928),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4)),
                        ),
                        child: const Text('BEST',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShopBottomNav extends StatelessWidget {
  final _ShopPalette palette;

  const _ShopBottomNav({required this.palette});

  @override
  Widget build(BuildContext context) {
    const items = [
      _ShopNavSpec(Icons.shopping_cart_rounded, 'Shop'),
      _ShopNavSpec(Icons.groups_rounded, 'Friends'),
      _ShopNavSpec(Icons.home_rounded, 'Home'),
      _ShopNavSpec(Icons.shield_rounded, 'Clubs'),
      _ShopNavSpec(Icons.inventory_2_rounded, 'Chest'),
    ];
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.dark
            ? const Color(0xE32B0732)
            : Colors.white.withAlpha(240),
        border: Border(top: BorderSide(color: palette.stroke.withAlpha(125))),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == 0;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                SoundService.tap();
                if (i == 2) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (_) => false);
                } else if (i != 0) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${items[i].label} is coming soon.')));
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[i].icon,
                      color:
                          active ? palette.stroke : palette.text.withAlpha(205),
                      size: active ? 31 : 27),
                  const SizedBox(height: 2),
                  Text(
                    items[i].label,
                    style: TextStyle(
                      color:
                          active ? palette.stroke : palette.text.withAlpha(205),
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
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

class _ShopNavSpec {
  final IconData icon;
  final String label;
  const _ShopNavSpec(this.icon, this.label);
}

class _ShopBackdropPainter extends CustomPainter {
  final double t;
  final _ShopPalette p;

  _ShopBackdropPainter(this.t, this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, size.height),
      p.dark
          ? [
              const Color(0xFF18031F),
              const Color(0xFF5C1057),
              const Color(0xFF2B0730)
            ]
          : [
              const Color(0xFFFFEBFA),
              const Color(0xFFFFC4E3),
              const Color(0xFFFFF0B8)
            ],
    );
    canvas.drawRect(Offset.zero & size, paint);
    paint.shader = null;

    for (int i = 0; i < 34; i++) {
      final x = ((i * 89 + 21) % 1000) / 1000.0 * size.width;
      final y = ((i * 157 + 45) % 1000) / 1000.0 * size.height;
      final a = 18 + (math.sin(t * math.pi * 2 + i) * 20).abs().round();
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withAlpha(a);
      final r = 10.0 + (i % 4) * 4;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i * 0.4);
      canvas.drawRRect(
          RRect.fromRectXY(
              Rect.fromCenter(
                  center: Offset.zero, width: r * 1.8, height: r * 1.8),
              4,
              4),
          paint);
      canvas.restore();
    }
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(_ShopBackdropPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.p != p;
}

class _ShopHeroPainter extends CustomPainter {
  final _ShopPalette p;
  final double t;

  _ShopHeroPainter(this.p, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    paint.shader = ui.Gradient.radial(
      Offset(size.width * (0.38 + 0.08 * math.sin(t * math.pi * 2)),
          size.height * 0.45),
      size.width * 0.72,
      [
        const Color(0x5558D7FF),
        const Color(0x22FF38C8),
        Colors.transparent,
      ],
    );
    canvas.drawRect(Offset.zero & size, paint);
    paint.shader = null;

    for (int i = 0; i < 4; i++) {
      final x = size.width * (0.08 + i * 0.25);
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withAlpha(28);
      canvas.drawLine(Offset(x, 0), Offset(x - 60, size.height), paint);
    }
    paint.style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width * 0.25, size.height * 0.50);
    canvas.rotate(-0.10 + math.sin(t * math.pi * 2) * 0.035);
    _drawShopBoard(canvas, size.width * 0.34, paint);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * 0.53, size.height * 0.58);
    canvas.rotate(0.08 + math.cos(t * math.pi * 2) * 0.025);
    _drawShopBoard(canvas, size.width * 0.22, paint);
    canvas.restore();

    _drawGem(canvas, Offset(size.width * 0.15, size.height * 0.22), 16,
        const Color(0xFF22E66E), paint);
    _drawCoin(canvas, Offset(size.width * 0.86, size.height * 0.78), 18, paint);
    _drawCoin(canvas, Offset(size.width * 0.74, size.height * 0.84), 14, paint);
    _drawGem(canvas, Offset(size.width * 0.91, size.height * 0.27), 13,
        const Color(0xFF4DEBFF), paint);
  }

  void _drawShopBoard(Canvas canvas, double s, Paint paint) {
    final rect = Rect.fromCenter(center: Offset.zero, width: s, height: s);
    paint
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = Colors.black.withAlpha(70);
    canvas.drawRRect(
        RRect.fromRectXY(rect.shift(const Offset(5, 8)), 12, 12), paint);
    paint.maskFilter = null;

    paint.color = const Color(0xFFFFF8D8);
    canvas.drawRRect(RRect.fromRectXY(rect, 12, 12), paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..color = const Color(0xFFFFD426);
    canvas.drawRRect(RRect.fromRectXY(rect, 12, 12), paint);
    paint.style = PaintingStyle.fill;

    final colors = [boardRed, boardYellow, boardBlue, boardGreen];
    final cells = [
      Rect.fromLTWH(
          rect.left + s * 0.08, rect.top + s * 0.08, s * 0.34, s * 0.34),
      Rect.fromLTWH(
          rect.center.dx + s * 0.08, rect.top + s * 0.08, s * 0.34, s * 0.34),
      Rect.fromLTWH(
          rect.left + s * 0.08, rect.center.dy + s * 0.08, s * 0.34, s * 0.34),
      Rect.fromLTWH(rect.center.dx + s * 0.08, rect.center.dy + s * 0.08,
          s * 0.34, s * 0.34),
    ];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawRRect(RRect.fromRectXY(cells[i], 7, 7), paint);
      paint.color = Colors.white.withAlpha(225);
      canvas.drawRRect(
          RRect.fromRectXY(cells[i].deflate(s * 0.09), 5, 5), paint);
    }

    for (int i = -2; i <= 2; i++) {
      paint.color = colors[(i + 2) % 4].withAlpha(210);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(i * s * 0.055, 0),
              width: s * 0.038,
              height: s * 0.36),
          paint);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(0, i * s * 0.055),
              width: s * 0.36,
              height: s * 0.038),
          paint);
    }

    for (int i = 0; i < 4; i++) {
      final a = t * math.pi * 2 + i * math.pi / 2;
      final pos = Offset(math.cos(a) * s * 0.23, math.sin(a) * s * 0.23);
      paint.color = Colors.black.withAlpha(55);
      canvas.drawCircle(pos.translate(2, 3), s * 0.045, paint);
      paint.color = colors[i];
      canvas.drawCircle(pos, s * 0.046, paint);
      paint.color = Colors.white.withAlpha(180);
      canvas.drawCircle(
          pos.translate(-s * 0.012, -s * 0.014), s * 0.015, paint);
    }
  }

  void _drawCoin(Canvas canvas, Offset c, double r, Paint paint) {
    paint.color = const Color(0xFFFFD426);
    canvas.drawCircle(c, r, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..color = const Color(0xFFE88400);
    canvas.drawCircle(c, r * 0.64, paint);
    paint.style = PaintingStyle.fill;
  }

  void _drawGem(Canvas canvas, Offset c, double r, Color color, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    paint.color = color;
    canvas.drawPath(path, paint);
    paint.color = Colors.white.withAlpha(140);
    canvas.drawCircle(
        Offset(c.dx - r * 0.20, c.dy - r * 0.22), r * 0.18, paint);
  }

  @override
  bool shouldRepaint(_ShopHeroPainter oldDelegate) =>
      oldDelegate.p != p || oldDelegate.t != t;
}

class _ProductPainter extends CustomPainter {
  final _ProductArt art;

  _ProductPainter(this.art);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final center = Offset(size.width / 2, size.height * 0.54);
    if (art == _ProductArt.energy) {
      _drawCapsule(canvas, center, size.shortestSide * 0.28, p);
      _drawCapsule(
          canvas, center.translate(-16, 10), size.shortestSide * 0.22, p);
      _drawCapsule(
          canvas, center.translate(18, 12), size.shortestSide * 0.22, p);
    } else if (art == _ProductArt.energyPile) {
      for (int i = 0; i < 6; i++) {
        _drawCapsule(canvas, center.translate((i - 2.5) * 12, (i % 2) * 12),
            size.shortestSide * 0.20, p);
      }
    } else if (art == _ProductArt.pouch || art == _ProductArt.pouchBig) {
      _drawPouch(canvas, center, art == _ProductArt.pouchBig ? 1.10 : 0.92, p);
    } else if (art == _ProductArt.chest || art == _ProductArt.chestPouch) {
      _drawChest(canvas, center.translate(0, 8), p);
      if (art == _ProductArt.chestPouch)
        _drawPouch(canvas, center.translate(-20, 8), 0.65, p);
    }
  }

  void _drawCapsule(Canvas canvas, Offset c, double r, Paint p) {
    p.color = Colors.black.withAlpha(50);
    canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(3, 8), width: r * 1.9, height: r * 0.55),
        p);
    p.shader = const LinearGradient(colors: [
      Color(0xFF55F4FF),
      Color(0xFF087FC9)
    ]).createShader(Rect.fromCenter(center: c, width: r * 1.4, height: r * 2));
    canvas.drawRRect(
        RRect.fromRectXY(
            Rect.fromCenter(center: c, width: r * 1.1, height: r * 1.6),
            r * 0.42,
            r * 0.42),
        p);
    p.shader = null;
    p.color = Colors.white.withAlpha(140);
    canvas.drawCircle(c.translate(-r * 0.16, -r * 0.26), r * 0.16, p);
    p.color = const Color(0xFFFFF06B);
    canvas.drawPath(
        Path()
          ..moveTo(c.dx + r * 0.05, c.dy - r * 0.35)
          ..lineTo(c.dx - r * 0.12, c.dy + r * 0.05)
          ..lineTo(c.dx + r * 0.08, c.dy + r * 0.05)
          ..lineTo(c.dx - r * 0.02, c.dy + r * 0.42)
          ..lineTo(c.dx + r * 0.26, c.dy - r * 0.08)
          ..lineTo(c.dx + r * 0.06, c.dy - r * 0.08)
          ..close(),
        p);
  }

  void _drawPouch(Canvas canvas, Offset c, double scale, Paint p) {
    final w = 64 * scale;
    final h = 58 * scale;
    p.color = Colors.black.withAlpha(55);
    canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(0, h * 0.45), width: w, height: h * 0.23),
        p);
    p.shader =
        const LinearGradient(colors: [Color(0xFF9B4CDA), Color(0xFF5A189A)])
            .createShader(Rect.fromCenter(center: c, width: w, height: h));
    canvas.drawRRect(
        RRect.fromRectXY(Rect.fromCenter(center: c, width: w, height: h),
            14 * scale, 18 * scale),
        p);
    p.shader = null;
    p.color = const Color(0xFFFFC64E);
    canvas.drawRRect(
        RRect.fromRectXY(
            Rect.fromCenter(
                center: c.translate(0, -h * 0.34),
                width: w * 0.72,
                height: h * 0.18),
            8 * scale,
            8 * scale),
        p);
    for (int i = 0; i < 7; i++) {
      _drawCapsule(
          canvas,
          c.translate((i - 3) * 7 * scale, -8 * scale + (i % 2) * 8 * scale),
          10 * scale,
          p);
    }
  }

  void _drawChest(Canvas canvas, Offset c, Paint p) {
    final rect = Rect.fromCenter(center: c, width: 78, height: 58);
    p.color = Colors.black.withAlpha(55);
    canvas.drawOval(
        Rect.fromCenter(center: c.translate(0, 34), width: 80, height: 18), p);
    p.shader =
        const LinearGradient(colors: [Color(0xFFFFC257), Color(0xFFB66A14)])
            .createShader(rect);
    canvas.drawRRect(RRect.fromRectXY(rect, 8, 8), p);
    p.shader = null;
    p.color = const Color(0xFF7A3B12);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.center.dy, rect.width, 6), p);
    p.color = const Color(0xFFFFF0A0);
    canvas.drawRRect(
        RRect.fromRectXY(
            Rect.fromCenter(center: c, width: 22, height: 24), 5, 5),
        p);
  }

  @override
  bool shouldRepaint(_ProductPainter oldDelegate) => oldDelegate.art != art;
}
