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
                  builder: (_, __) => CustomPaint(
                    painter: _ShopBackdropPainter(_bg.value, p),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final narrow = box.maxWidth < 370;
                    final compactHeight = box.maxHeight < 720;
                    final heroHeight = math
                        .min(box.maxWidth * 0.42,
                            box.maxHeight * (compactHeight ? 0.18 : 0.20))
                        .clamp(narrow ? 116.0 : 128.0, 168.0)
                        .toDouble();
                    final columns = box.maxWidth < 360 ? 2 : 3;
                    final cardAspect = columns == 2
                        ? (compactHeight ? 0.82 : 0.88)
                        : (compactHeight ? 0.74 : 0.78);
                    final gridPad = EdgeInsets.fromLTRB(
                      narrow ? 12 : 16,
                      compactHeight ? 6 : 8,
                      narrow ? 12 : 16,
                      18,
                    );

                    return Column(
                      children: [
                        _ShopResources(state: state, palette: p),
                        _ShopHero(
                          palette: p,
                          animation: _bg,
                          height: heroHeight,
                        ),
                        if (!compactHeight || box.maxWidth >= 390)
                          _BoosterBanner(palette: p),
                        Expanded(
                          child: GridView.builder(
                            padding: gridPad,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              childAspectRatio: cardAspect,
                              crossAxisSpacing: narrow ? 8 : 10,
                              mainAxisSpacing: compactHeight ? 10 : 14,
                            ),
                            itemCount: _items.length,
                            itemBuilder: (context, i) => _ShopCard(
                              product: _items[i],
                              palette: p,
                              onBuy: () {
                                state.addCoins(100);
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xEE22082E),
                                      duration:
                                          const Duration(milliseconds: 1200),
                                      content: Text(
                                          '${_items[i].title} booster selected.'),
                                    ),
                                  );
                              },
                            ),
                          ),
                        ),
                        _ShopBottomNav(palette: p),
                      ],
                    );
                  },
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
  final double height;

  const _ShopHero({
    required this.palette,
    required this.animation,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
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
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;
            final signWidth = (w * 0.36).clamp(126.0, 164.0).toDouble();
            final signHeight = signWidth * 0.40;
            final signLeft =
                (w * 0.16).clamp(24.0, w - signWidth - 18).toDouble();
            final coverWidth = (w * 0.56).clamp(184.0, 252.0).toDouble();
            final boardRight = (w * 0.23).clamp(70.0, 116.0).toDouble();
            final railHeight = (h * 0.14).clamp(18.0, 24.0).toDouble();

            return Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (_, __) => CustomPaint(
                      painter: _ShopHeroPainter(palette, animation.value),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Positioned(
                  left: -w * 0.07,
                  top: -h * 0.16,
                  bottom: -h * 0.12,
                  right: boardRight,
                  child: AnimatedBuilder(
                    animation: animation,
                    child: Opacity(
                      opacity: 0.66,
                      child: Image.asset(
                        'assets/images/home_ludo_board_window.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    builder: (_, child) {
                      final wave = math.sin(animation.value * math.pi * 2);
                      return Transform.translate(
                        offset: Offset(0, wave * 3),
                        child: Transform.rotate(
                          angle: -0.035 + wave * 0.008,
                          child: child,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: -w * 0.02,
                  top: h * 0.04,
                  bottom: h * 0.13,
                  width: coverWidth,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (_, __) => CustomPaint(
                        painter: _ShopCoverSignArtPainter(animation.value),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                _ShopCoverBubbles(
                  animation: animation,
                  width: (w * 0.70).clamp(210.0, 292.0).toDouble(),
                  height: h * 0.84,
                ),
                Positioned(
                  left: signLeft,
                  top: -signHeight * 0.64,
                  child: _AnimatedShopSign(
                    animation: animation,
                    width: signWidth,
                    height: signHeight,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: railHeight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF9D5528), Color(0xFF5C250E)]),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedShopSign extends StatelessWidget {
  final AnimationController animation;
  final double width;
  final double height;

  const _AnimatedShopSign({
    required this.animation,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final phase = animation.value * math.pi * 2;
        final bob = math.sin(phase) * 2.4;
        final scale = 1 + (0.018 * (0.5 + math.sin(phase + 0.7) * 0.5));
        final glow = 74 + (math.sin(phase).abs() * 62).round();
        final shineX = -width + animation.value * width * 2.2;

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: -0.035 + math.sin(phase * 1.2) * 0.014,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color.fromARGB(178 + glow ~/ 5, 255, 212, 38),
                    width: 2,
                  ),
                  boxShadow: [
                    const BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 10,
                        offset: Offset(0, 5)),
                    BoxShadow(
                      color: Color.fromARGB(glow, 255, 212, 38),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color(0xFFFF2F72),
                          Color(0xFF92224E),
                        ]),
                      ),
                    ),
                    Positioned(
                      left: shineX,
                      top: -height * 0.30,
                      bottom: -height * 0.30,
                      width: width * 0.22,
                      child: Transform.rotate(
                        angle: -0.35,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withAlpha(0),
                                Colors.white.withAlpha(135),
                                Colors.white.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'SHOP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: height * 0.46,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(
                                  color: Colors.black87,
                                  blurRadius: 2,
                                  offset: Offset(2, 3))
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShopCoverBubbles extends StatelessWidget {
  final AnimationController animation;
  final double width;
  final double height;

  const _ShopCoverBubbles({
    required this.animation,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      top: 4,
      width: width,
      height: height,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, __) {
            final phase = animation.value * math.pi * 2;
            final sx = width / 292.0;
            final sy = height / 128.0;
            final scale = math.min(sx, sy);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _coverBubble(
                  left: 8 * sx,
                  top: (7 + math.sin(phase) * 3) * sy,
                  size: 40 * scale,
                  color: Colors.white,
                  icon: Icons.casino_rounded,
                  iconColor: boardRed,
                  tilt: -0.18 + math.sin(phase) * 0.04,
                ),
                _coverBubble(
                  right: 8 * sx,
                  top: (9 + math.cos(phase) * 3) * sy,
                  size: 34 * scale,
                  color: const Color(0xFF46D8FF),
                  icon: Icons.bolt_rounded,
                  iconColor: Colors.white,
                  tilt: 0.16,
                ),
                _coverBubble(
                  right: 12 * sx,
                  bottom: (8 + math.sin(phase + 1.1) * 3) * sy,
                  size: 48 * scale,
                  color: const Color(0xFFFFC21F),
                  icon: Icons.monetization_on_rounded,
                  iconColor: const Color(0xFF7A4300),
                  tilt: 0.12 + math.cos(phase) * 0.03,
                ),
                _coverBubble(
                  left: 42 * sx,
                  bottom: (13 + math.cos(phase + 0.7) * 3) * sy,
                  size: 31 * scale,
                  color: const Color(0xFF35DE72),
                  icon: Icons.diamond_rounded,
                  iconColor: Colors.white,
                  tilt: -0.10,
                ),
                _spark(
                    left: 82 * sx, top: 15 * sy, size: 9 * scale, phase: phase),
                _spark(
                    left: 236 * sx,
                    top: 46 * sy,
                    size: 8 * scale,
                    phase: phase + 0.9),
                _spark(
                    left: 28 * sx,
                    top: 78 * sy,
                    size: 7 * scale,
                    phase: phase + 1.7),
                _spark(
                    left: 212 * sx,
                    top: 101 * sy,
                    size: 10 * scale,
                    phase: phase + 2.4),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _coverBubble({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
    required IconData icon,
    required Color iconColor,
    required double tilt,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Transform.rotate(
        angle: tilt,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(color, Colors.white, 0.35)!, color],
            ),
            border: Border.all(color: const Color(0xFFFFD426), width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 8,
                  offset: Offset(0, 4)),
              BoxShadow(color: Color(0x55FFD426), blurRadius: 12),
            ],
          ),
          child: Icon(icon, color: iconColor, size: size * 0.58),
        ),
      ),
    );
  }

  Widget _spark({
    required double left,
    required double top,
    required double size,
    required double phase,
  }) {
    return Positioned(
      left: left + math.sin(phase) * 2,
      top: top + math.cos(phase) * 2,
      child: Transform.rotate(
        angle: phase * 0.25,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF27D).withAlpha(210),
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(color: Color(0x88FFD426), blurRadius: 8),
            ],
          ),
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
      margin: const EdgeInsets.fromLTRB(22, 7, 22, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  ScaffoldMessenger.of(context).clearSnackBars();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (_) => false);
                } else if (i != 0) {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xEE22082E),
                      duration: const Duration(milliseconds: 1200),
                      content: Text('${items[i].label} is coming soon.'),
                    ));
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

    canvas.save();
    canvas.translate(
      size.width * 0.52,
      size.height * (0.39 + math.sin(t * math.pi * 2) * 0.008),
    );
    canvas.rotate(-0.10);
    _drawBackdropBoard(canvas, size.width * 0.78, paint);
    canvas.restore();

    _drawBackdropDice(
      canvas,
      Offset(size.width * 0.12, size.height * 0.24),
      size.width * 0.105,
      5,
      paint,
    );
    _drawBackdropDice(
      canvas,
      Offset(size.width * 0.86, size.height * 0.47),
      size.width * 0.085,
      3,
      paint,
    );

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

  void _drawBackdropBoard(Canvas canvas, double s, Paint paint) {
    final rect = Rect.fromCenter(center: Offset.zero, width: s, height: s);
    final shell = RRect.fromRectXY(rect, s * 0.05, s * 0.05);
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.black.withAlpha(p.dark ? 42 : 18);
    canvas.drawRRect(shell.shift(Offset(s * 0.025, s * 0.035)), paint);
    paint.color = Colors.white.withAlpha(p.dark ? 18 : 70);
    canvas.drawRRect(shell, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..color = p.stroke.withAlpha(p.dark ? 70 : 100);
    canvas.drawRRect(shell.deflate(s * 0.012), paint);
    paint.style = PaintingStyle.fill;

    final colors = [boardRed, boardYellow, boardBlue, boardGreen];
    final inset = s * 0.075;
    final base = s * 0.29;
    final bases = [
      Rect.fromLTWH(rect.left + inset, rect.top + inset, base, base),
      Rect.fromLTWH(rect.right - inset - base, rect.top + inset, base, base),
      Rect.fromLTWH(rect.left + inset, rect.bottom - inset - base, base, base),
      Rect.fromLTWH(
          rect.right - inset - base, rect.bottom - inset - base, base, base),
    ];
    for (int i = 0; i < bases.length; i++) {
      paint.color = colors[i].withAlpha(p.dark ? 62 : 82);
      canvas.drawRRect(RRect.fromRectXY(bases[i], s * 0.032, s * 0.032), paint);
    }

    for (int i = -2; i <= 2; i++) {
      paint.color = colors[(i + 2) % 4].withAlpha(p.dark ? 70 : 105);
      canvas.drawRRect(
        RRect.fromRectXY(
          Rect.fromCenter(
            center: Offset(i * s * 0.042, 0),
            width: s * 0.032,
            height: s * 0.46,
          ),
          s * 0.008,
          s * 0.008,
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectXY(
          Rect.fromCenter(
            center: Offset(0, i * s * 0.042),
            width: s * 0.46,
            height: s * 0.032,
          ),
          s * 0.008,
          s * 0.008,
        ),
        paint,
      );
    }

    for (int i = 0; i < 8; i++) {
      final a = t * math.pi * 2 + i * math.pi / 4;
      final pos = Offset(math.cos(a) * s * 0.27, math.sin(a) * s * 0.27);
      paint.color = colors[i % 4].withAlpha(p.dark ? 105 : 135);
      canvas.drawCircle(pos, s * 0.032, paint);
      paint.color = Colors.white.withAlpha(p.dark ? 58 : 120);
      canvas.drawCircle(
          pos.translate(-s * 0.010, -s * 0.010), s * 0.010, paint);
    }
  }

  void _drawBackdropDice(
      Canvas canvas, Offset c, double s, int value, Paint paint) {
    final rect = Rect.fromCenter(center: c, width: s, height: s);
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.black.withAlpha(p.dark ? 42 : 24);
    canvas.drawRRect(
        RRect.fromRectXY(
            rect.shift(Offset(s * 0.10, s * 0.12)), s * 0.18, s * 0.18),
        paint);
    paint.color = Colors.white.withAlpha(p.dark ? 42 : 130);
    canvas.drawRRect(RRect.fromRectXY(rect, s * 0.18, s * 0.18), paint);
    paint.color = p.dark ? const Color(0x88FFD426) : const Color(0xAA803500);
    final dots = <Offset>[
      if (value == 1 || value == 3 || value == 5) c,
      if (value >= 2) Offset(rect.left + s * 0.30, rect.top + s * 0.30),
      if (value >= 2) Offset(rect.right - s * 0.30, rect.bottom - s * 0.30),
      if (value >= 4) Offset(rect.right - s * 0.30, rect.top + s * 0.30),
      if (value >= 4) Offset(rect.left + s * 0.30, rect.bottom - s * 0.30),
      if (value == 6) Offset(rect.left + s * 0.30, c.dy),
      if (value == 6) Offset(rect.right - s * 0.30, c.dy),
    ];
    for (final dot in dots) {
      canvas.drawCircle(dot, s * 0.055, paint);
    }
  }

  @override
  bool shouldRepaint(_ShopBackdropPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.p != p;
}

class _ShopCoverSignArtPainter extends CustomPainter {
  final double t;

  _ShopCoverSignArtPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final phase = t * math.pi * 2;

    p.shader = ui.Gradient.radial(
      Offset(size.width * 0.55, size.height * 0.50),
      size.width * 0.48,
      [
        const Color(0x66FFD426),
        const Color(0x22FF2F72),
        Colors.transparent,
      ],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    _drawDice(
      canvas,
      Offset(size.width * 0.30, size.height * (0.25 + math.sin(phase) * 0.03)),
      size.shortestSide * 0.20,
      4,
      p,
    );
    _drawDice(
      canvas,
      Offset(size.width * 0.86, size.height * (0.76 + math.cos(phase) * 0.025)),
      size.shortestSide * 0.16,
      2,
      p,
    );

    for (int i = 0; i < 7; i++) {
      final x = size.width * (0.22 + i * 0.10);
      final y = size.height * (0.70 + math.sin(phase + i) * 0.08);
      _drawCoin(
          canvas, Offset(x, y), size.shortestSide * (0.055 + i % 2 * 0.012), p);
    }

    _drawGem(
      canvas,
      Offset(size.width * 0.80, size.height * 0.23),
      size.shortestSide * 0.075,
      const Color(0xFF40E67C),
      p,
    );
    _drawGem(
      canvas,
      Offset(size.width * 0.13, size.height * 0.55),
      size.shortestSide * 0.055,
      const Color(0xFF58D7FF),
      p,
    );

    for (int i = 0; i < 8; i++) {
      final a = phase + i * 0.9;
      final c = Offset(
        size.width * (0.18 + ((i * 29) % 70) / 100),
        size.height * (0.18 + ((i * 43) % 62) / 100),
      );
      _drawSpark(canvas, c.translate(math.sin(a) * 3, math.cos(a) * 3),
          size.shortestSide * 0.028, p);
    }
  }

  void _drawCoin(Canvas canvas, Offset c, double r, Paint p) {
    p
      ..style = PaintingStyle.fill
      ..color = Colors.black.withAlpha(60);
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(r * 0.25, r * 0.35),
          width: r * 1.9,
          height: r * 0.58),
      p,
    );
    p.shader = ui.Gradient.radial(
      c.translate(-r * 0.22, -r * 0.22),
      r * 1.25,
      const [Color(0xFFFFF27D), Color(0xFFFFC21F), Color(0xFFE07E00)],
    );
    canvas.drawCircle(c, r, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..color = const Color(0xFF9C5800);
    canvas.drawCircle(c, r * 0.62, p);
    p.style = PaintingStyle.fill;
  }

  void _drawDice(Canvas canvas, Offset c, double s, int value, Paint p) {
    final rect = Rect.fromCenter(center: c, width: s, height: s);
    p
      ..style = PaintingStyle.fill
      ..color = Colors.black.withAlpha(70);
    canvas.drawRRect(
        RRect.fromRectXY(
            rect.shift(Offset(s * 0.13, s * 0.16)), s * 0.22, s * 0.22),
        p);
    p.shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight,
        const [Colors.white, Color(0xFFFFEFC8)]);
    canvas.drawRRect(RRect.fromRectXY(rect, s * 0.22, s * 0.22), p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..color = const Color(0xFFFFD426);
    canvas.drawRRect(
        RRect.fromRectXY(rect.deflate(s * 0.02), s * 0.20, s * 0.20), p);
    p
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE51F32);
    final center = rect.center;
    final dots = <Offset>[
      if (value == 1 || value == 3 || value == 5) center,
      if (value >= 2) Offset(rect.left + s * 0.30, rect.top + s * 0.30),
      if (value >= 2) Offset(rect.right - s * 0.30, rect.bottom - s * 0.30),
      if (value >= 4) Offset(rect.right - s * 0.30, rect.top + s * 0.30),
      if (value >= 4) Offset(rect.left + s * 0.30, rect.bottom - s * 0.30),
      if (value == 6) Offset(rect.left + s * 0.30, center.dy),
      if (value == 6) Offset(rect.right - s * 0.30, center.dy),
    ];
    for (final dot in dots) {
      canvas.drawCircle(dot, s * 0.055, p);
    }
  }

  void _drawGem(Canvas canvas, Offset c, double r, Color color, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.95, c.dy - r * 0.08)
      ..lineTo(c.dx + r * 0.45, c.dy + r)
      ..lineTo(c.dx - r * 0.45, c.dy + r)
      ..lineTo(c.dx - r * 0.95, c.dy - r * 0.08)
      ..close();
    p.color = Colors.black.withAlpha(45);
    canvas.drawPath(path.shift(Offset(r * 0.14, r * 0.18)), p);
    p.shader = ui.Gradient.linear(
      c.translate(-r, -r),
      c.translate(r, r),
      [Color.lerp(color, Colors.white, 0.45)!, color],
    );
    canvas.drawPath(path, p);
    p.shader = null;
    p.color = Colors.white.withAlpha(150);
    canvas.drawCircle(c.translate(-r * 0.24, -r * 0.24), r * 0.18, p);
  }

  void _drawSpark(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.24, c.dy - r * 0.24)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.24, c.dy + r * 0.24)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.24, c.dy + r * 0.24)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.24, c.dy - r * 0.24)
      ..close();
    p.color = const Color(0xFFFFF27D).withAlpha(190);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ShopCoverSignArtPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _ShopHeroPainter extends CustomPainter {
  final _ShopPalette p;
  final double t;

  _ShopHeroPainter(this.p, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final heroWidth = size.width;
    final heroHeight = math.min(size.height, 154.0);

    paint.shader = ui.Gradient.radial(
      Offset(heroWidth * (0.38 + 0.08 * math.sin(t * math.pi * 2)),
          heroHeight * 0.45),
      heroWidth * 0.72,
      [
        const Color(0x5558D7FF),
        const Color(0x22FF38C8),
        Colors.transparent,
      ],
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, heroWidth, heroHeight), paint);
    paint.shader = null;

    for (int i = 0; i < 4; i++) {
      final x = heroWidth * (0.08 + i * 0.25);
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withAlpha(28);
      canvas.drawLine(Offset(x, 0), Offset(x - 60, heroHeight), paint);
    }
    paint.style = PaintingStyle.fill;

    final boardSize = heroHeight * 1.12;
    final float = math.sin(t * math.pi * 2);
    canvas.save();
    canvas.translate(heroWidth * 0.28, heroHeight * (0.55 + float * 0.018));
    canvas.rotate(-0.14 + float * 0.025);
    _drawShopBoard(canvas, boardSize, paint);
    canvas.restore();

    _drawHeroDice(
      canvas,
      Offset(heroWidth * 0.55, heroHeight * (0.36 - float * 0.018)),
      heroHeight * 0.33,
      6,
      paint,
    );
    _drawHeroDice(
      canvas,
      Offset(heroWidth * 0.64, heroHeight * (0.67 + float * 0.012)),
      heroHeight * 0.25,
      3,
      paint,
    );

    _drawPawn(canvas, Offset(heroWidth * 0.12, heroHeight * 0.75),
        heroHeight * 0.20, boardRed, paint);
    _drawPawn(canvas, Offset(heroWidth * 0.41, heroHeight * 0.23),
        heroHeight * 0.17, boardBlue, paint);

    _drawGem(canvas, Offset(heroWidth * 0.15, heroHeight * 0.22), 16,
        const Color(0xFF22E66E), paint);
    _drawCoin(canvas, Offset(heroWidth * 0.86, heroHeight * 0.78), 18, paint);
    _drawCoin(canvas, Offset(heroWidth * 0.74, heroHeight * 0.84), 14, paint);
    _drawGem(canvas, Offset(heroWidth * 0.91, heroHeight * 0.27), 13,
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

  void _drawHeroDice(
      Canvas canvas, Offset c, double s, int value, Paint paint) {
    final rect = Rect.fromCenter(center: c, width: s, height: s);
    paint
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = Colors.black.withAlpha(75);
    canvas.drawRRect(
        RRect.fromRectXY(
            rect.shift(Offset(s * 0.12, s * 0.16)), s * 0.20, s * 0.20),
        paint);
    paint.maskFilter = null;

    paint.shader = ui.Gradient.linear(
      const Offset(-30, -30),
      const Offset(40, 40),
      const [Color(0xFFFFFFFF), Color(0xFFFFEBD0)],
    );
    canvas.drawRRect(RRect.fromRectXY(rect, s * 0.20, s * 0.20), paint);
    paint.shader = null;

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..color = const Color(0xFFFFD426);
    canvas.drawRRect(
        RRect.fromRectXY(rect.deflate(s * 0.02), s * 0.18, s * 0.18), paint);

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFD7192A);
    final dots = _diceDots(rect, value);
    for (final dot in dots) {
      canvas.drawCircle(dot, s * 0.055, paint);
    }
  }

  List<Offset> _diceDots(Rect rect, int value) {
    final s = rect.width;
    final c = rect.center;
    return [
      if (value == 1 || value == 3 || value == 5) c,
      if (value >= 2) Offset(rect.left + s * 0.30, rect.top + s * 0.30),
      if (value >= 2) Offset(rect.right - s * 0.30, rect.bottom - s * 0.30),
      if (value >= 4) Offset(rect.right - s * 0.30, rect.top + s * 0.30),
      if (value >= 4) Offset(rect.left + s * 0.30, rect.bottom - s * 0.30),
      if (value == 6) Offset(rect.left + s * 0.30, c.dy),
      if (value == 6) Offset(rect.right - s * 0.30, c.dy),
    ];
  }

  void _drawPawn(
      Canvas canvas, Offset base, double s, Color color, Paint paint) {
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.black.withAlpha(60);
    canvas.drawOval(
        Rect.fromCenter(
            center: base.translate(s * 0.10, s * 0.22),
            width: s * 0.70,
            height: s * 0.24),
        paint);
    paint.color = color;
    canvas.drawOval(
        Rect.fromCenter(
            center: base.translate(0, -s * 0.30),
            width: s * 0.46,
            height: s * 0.42),
        paint);
    canvas.drawRRect(
        RRect.fromRectXY(
            Rect.fromCenter(
                center: base.translate(0, s * 0.08),
                width: s * 0.46,
                height: s * 0.58),
            s * 0.16,
            s * 0.16),
        paint);
    paint.color = Color.lerp(color, Colors.white, 0.38)!;
    canvas.drawOval(
        Rect.fromCenter(
            center: base.translate(-s * 0.10, -s * 0.40),
            width: s * 0.14,
            height: s * 0.10),
        paint);
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
