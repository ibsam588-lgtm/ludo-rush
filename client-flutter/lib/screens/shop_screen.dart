// ignore_for_file: unused_element

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/profile_catalog.dart';
import '../data/economy.dart';
import '../state/app_state.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/levelplay_banner.dart';
import '../widgets/dice_widget.dart';
import '../widgets/ludo_board.dart';
import '../widgets/snakes_ladders_board.dart';

const _shopDiceAtlasAsset =
    'assets/images/rush/rush_shop_dice_showcase_mobile_v1.jpg';
const _shopRewardsAtlasAsset =
    'assets/images/rush/rush_shop_rewards_atlas_mobile_v1.jpg';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg;

  static const _items = [
    _ShopProduct('Daily Coins', 'FREE', '${GameEconomy.dailyCoins} coins',
        _ProductArt.daily, false, GameEconomy.dailyCoins,
        dailyReward: true),
    _ShopProduct('Royal Dice', '3 WINS', 'rare win reward',
        _ProductArt.royalDice, false, 0,
        diceSkin: 'royal', rarity: 'RARE'),
    _ShopProduct(
        'Neon Dice', '5 WINS', 'arcade reward', _ProductArt.neonDice, false, 0,
        diceSkin: 'neon', rarity: 'RARE'),
    _ShopProduct('Ruby Dice', '0.99 USD', 'premium red gem',
        _ProductArt.rubyDice, false, 0,
        diceSkin: 'ruby', rarity: 'PREMIUM'),
    _ShopProduct('Emerald Dice', '8 WINS', 'rare green gem',
        _ProductArt.emeraldDice, false, 0,
        diceSkin: 'emerald', rarity: 'RARE'),
    _ShopProduct('Cosmic Dice', '1.99 USD', 'premium star glow',
        _ProductArt.cosmicDice, true, 0,
        diceSkin: 'cosmic', rarity: 'PREMIUM'),
    _ShopProduct('Carnival Board', 'EQUIP', 'approved theme',
        _ProductArt.carnivalBoard, false, 0,
        ludoBoardTheme: 'carnival', rarity: 'COMMON'),
    _ShopProduct('Royal Board', '6 WINS', 'gold palace', _ProductArt.royalBoard,
        false, 0,
        ludoBoardTheme: 'royal', rarity: 'RARE'),
    _ShopProduct('Neon Board', '1.99 USD', 'premium arcade board',
        _ProductArt.neonBoard, false, 0,
        ludoBoardTheme: 'neon', rarity: 'PREMIUM'),
    _ShopProduct('Classic Board', '2 WINS', 'clean table',
        _ProductArt.classicBoard, false, 0,
        ludoBoardTheme: 'classic', rarity: 'COMMON'),
    _ShopProduct('Coin Stack', '0.99 USD', '1,200 coins', _ProductArt.coinPack,
        false, 1200,
        rarity: 'PREMIUM'),
    _ShopProduct('Gem Chest', '1.49 USD', '3,500 coins', _ProductArt.clubChest,
        false, 3500,
        rarity: 'PREMIUM'),
    _ShopProduct('Royal Vault', '1.99 USD', '7,500 coins',
        _ProductArt.royalVault, true, 7500,
        rarity: 'PREMIUM'),
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
          bottomNavigationBar: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LevelPlayBannerAd(placementName: 'ShopBanner'),
                _ShopBottomNav(palette: p),
              ],
            ),
          ),
          body: LayoutBuilder(
            builder: (context, viewport) {
              return SizedBox(
                width: viewport.maxWidth,
                height: viewport.maxHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _ShopBackdropPainter(0.35, p),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final narrow = box.maxWidth < 370;
                          final compactHeight = box.maxHeight < 720;
                          final heroHeight =
                              (box.maxHeight * (compactHeight ? 0.30 : 0.34))
                                  .clamp(narrow ? 210.0 : 230.0, 330.0)
                                  .toDouble();
                          final columns = box.maxWidth < 360 ? 2 : 3;
                          final cardAspect = columns == 2
                              ? (compactHeight ? 0.76 : 0.82)
                              : (compactHeight ? 0.66 : 0.70);
                          final gridPad = EdgeInsets.fromLTRB(
                            narrow ? 12 : 16,
                            compactHeight ? 6 : 8,
                            narrow ? 12 : 16,
                            18,
                          );

                          return Column(
                            children: [
                              _ShopResources(state: state, palette: p),
                              Expanded(
                                child: CustomScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  slivers: [
                                    SliverToBoxAdapter(
                                      child: _ShopHero(
                                        palette: p,
                                        animation: _bg,
                                        height: heroHeight,
                                      ),
                                    ),
                                    if (!compactHeight || box.maxWidth >= 390)
                                      SliverToBoxAdapter(
                                        child: _BoosterBanner(palette: p),
                                      ),
                                    SliverToBoxAdapter(
                                      child: _DiceSkinStrip(
                                        palette: p,
                                        state: state,
                                      ),
                                    ),
                                    SliverToBoxAdapter(
                                      child: _BoardThemeStrip(
                                        palette: p,
                                        state: state,
                                      ),
                                    ),
                                    SliverToBoxAdapter(
                                      child: _AvatarShopStrip(
                                        palette: p,
                                        state: state,
                                      ),
                                    ),
                                    SliverPadding(
                                      padding: gridPad,
                                      sliver: SliverGrid(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          childAspectRatio: cardAspect,
                                          crossAxisSpacing: narrow ? 8 : 10,
                                          mainAxisSpacing:
                                              compactHeight ? 10 : 14,
                                        ),
                                        delegate: SliverChildBuilderDelegate(
                                          (context, i) => _ShopCard(
                                            product: _items[i],
                                            palette: p,
                                            locked: _items[i].isLocked(state),
                                            actionLabel:
                                                _items[i].actionLabel(state),
                                            onBuy: () async {
                                              final product = _items[i];
                                              var message =
                                                  '${product.title} selected.';
                                              if (product.dailyReward) {
                                                final claimed = await state
                                                    .claimDailyReward();
                                                if (!context.mounted) return;
                                                message = claimed
                                                    ? 'Daily coins claimed. +${state.dailyRewardAmount} coins.'
                                                    : (state.socialError
                                                            .isNotEmpty
                                                        ? state.socialError
                                                        : 'Daily coins already claimed. Come back tomorrow.');
                                              } else if (product
                                                  .requiresPurchase(state)) {
                                                message =
                                                    '${product.title} is a ${product.price} preview. Google Play checkout is not available yet.';
                                              } else if (product.diceSkin !=
                                                  null) {
                                                if (state.isDiceSkinUnlocked(
                                                    product.diceSkin!)) {
                                                  state.setDiceSkin(
                                                      product.diceSkin!);
                                                  message =
                                                      '${product.title} equipped for your dice.';
                                                } else {
                                                  message =
                                                      state.diceSkinUnlockLabel(
                                                          product.diceSkin!);
                                                }
                                              } else if (product
                                                      .ludoBoardTheme !=
                                                  null) {
                                                if (state.isBoardThemeUnlocked(
                                                    product.ludoBoardTheme!)) {
                                                  state.setLudoBoardTheme(
                                                      product.ludoBoardTheme!);
                                                  message =
                                                      '${product.title} equipped for Ludo.';
                                                } else {
                                                  message = state
                                                      .boardThemeUnlockLabel(
                                                          product
                                                              .ludoBoardTheme!);
                                                }
                                              } else if (product.premium) {
                                                message =
                                                    '${product.title} requires a verified Google Play purchase. No coins were added.';
                                              } else if (product.coinReward >
                                                  0) {
                                                message =
                                                    '${product.title} is unavailable until its reward source is earned.';
                                              }
                                              ScaffoldMessenger.of(context)
                                                ..clearSnackBars()
                                                ..showSnackBar(
                                                  SnackBar(
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    backgroundColor:
                                                        const Color(0xEE22082E),
                                                    duration: const Duration(
                                                        milliseconds: 1200),
                                                    content: Text(message),
                                                  ),
                                                );
                                            },
                                          ),
                                          childCount: _items.length,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        final gap = compact ? 5.0 : 14.0;
        return Container(
          height: 52,
          padding:
              EdgeInsets.fromLTRB(compact ? 7 : 14, 6, compact ? 7 : 14, 4),
          child: Row(
            children: [
              IconButton(
                constraints: BoxConstraints.tightFor(
                  width: compact ? 34 : 42,
                  height: 38,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: palette.text, size: compact ? 18 : 20),
              ),
              const Spacer(),
              _ResourceChip(
                  icon: Icons.monetization_on_rounded,
                  value: '${state.coins}',
                  color: amberColor,
                  palette: palette,
                  compact: compact),
              SizedBox(width: gap),
              _ResourceChip(
                  icon: Icons.diamond_rounded,
                  value: '30',
                  color: const Color(0xFF22E46C),
                  palette: palette,
                  compact: compact),
              SizedBox(width: gap),
              _ResourceChip(
                  icon: Icons.bolt_rounded,
                  value: '${state.wins}',
                  color: const Color(0xFF35D6FF),
                  palette: palette,
                  compact: compact),
            ],
          ),
        );
      },
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final _ShopPalette palette;
  final bool compact;

  const _ResourceChip({
    required this.icon,
    required this.value,
    required this.color,
    required this.palette,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 69 : 86,
      height: compact ? 32 : 34,
      padding: EdgeInsets.fromLTRB(3, 3, compact ? 5 : 8, 3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(palette.dark ? 105 : 20),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 26 : 28,
            height: compact ? 26 : 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color.lerp(color, Colors.white, 0.35)!, color]),
            ),
            child: Icon(icon, color: Colors.white, size: compact ? 15 : 17),
          ),
          SizedBox(width: compact ? 4 : 7),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  maxLines: 1,
                  style: TextStyle(
                      color: palette.text,
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w900)),
            ),
          ),
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/rush/rush_shop_hero_mobile_v1.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.medium,
            ),
            AnimatedBuilder(
              animation: animation,
              builder: (_, __) => CustomPaint(
                painter: _ShopHeroSparklePainter(animation.value),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    palette.bg.withAlpha(215),
                  ],
                  stops: const [0, 0.63, 1],
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 16,
              child: _ShopHeroCopy(palette: palette),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopHeroCopy extends StatelessWidget {
  final _ShopPalette palette;

  const _ShopHeroCopy({required this.palette});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withAlpha(palette.dark ? 86 : 36),
        border: Border.all(color: goldColor.withAlpha(150), width: 1),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dice Shop',
              style: TextStyle(
                color: goldColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(1, 2),
                  )
                ],
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Daily coins and custom rolls',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black, blurRadius: 3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopHeroSparklePainter extends CustomPainter {
  final double t;

  const _ShopHeroSparklePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    for (int i = 0; i < 18; i++) {
      final phase = t * math.pi * 2 + i * 0.75;
      final x = ((i * 71.0) + t * 34) % size.width;
      final y = size.height * (0.05 + ((i * 37) % 74) / 100);
      final r = 1.6 + (i % 3) * 1.1 + math.sin(phase).abs() * 1.3;
      p.color = [
        goldColor,
        const Color(0xFFFF4BD8),
        const Color(0xFF48E9FF),
        Colors.white,
      ][i % 4]
          .withAlpha((70 + math.sin(phase).abs() * 140).round());
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(_ShopHeroSparklePainter oldDelegate) => oldDelegate.t != t;
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

class _ShopMascotWidget extends StatelessWidget {
  final AnimationController animation;

  const _ShopMascotWidget({required this.animation});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) {
          final phase = animation.value * math.pi * 2;
          final bob = math.sin(phase) * 2.8;
          return Transform.translate(
            offset: Offset(0, bob),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 0,
                  height: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(90),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  height: 18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFE06E),
                          Color(0xFFD87900),
                          Color(0xFF632800),
                        ],
                      ),
                      border: Border.all(color: Color(0xFFFFF08A), width: 1.4),
                      boxShadow: const [
                        BoxShadow(color: Color(0x88000000), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFF06B),
                          Color(0xFFFFC928),
                          Color(0xFFE09300),
                        ],
                      ),
                      border: Border.all(color: Color(0xFF8A5500), width: 1.4),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 8,
                            offset: Offset(0, 4)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 21,
                  right: 21,
                  top: -1,
                  height: 26,
                  child: CustomPaint(
                    painter: _MiniCrownPainter(boardYellow),
                  ),
                ),
                Positioned(
                  left: 23,
                  right: 23,
                  top: 31,
                  height: 26,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _MiniGoggle(),
                      _MiniGoggle(),
                    ],
                  ),
                ),
                Positioned(
                  left: 25,
                  right: 25,
                  bottom: 19,
                  height: 30,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                        bottom: Radius.circular(18),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(boardBlue, Colors.white, 0.18)!,
                          boardBlue,
                          Color.lerp(boardBlue, Colors.black, 0.28)!,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: boardYellow,
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  left: -2,
                  bottom: 28,
                  width: 26,
                  height: 26,
                  child: Transform.rotate(
                    angle: -0.22 + math.sin(phase) * 0.08,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFFFF27D),
                            Color(0xFFFFC21F),
                            Color(0xFFE07E00),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 32,
                  width: 28,
                  height: 28,
                  child: Transform.rotate(
                    angle: 0.16 - math.sin(phase) * 0.08,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color: const Color(0xFFFFD426), width: 1.4),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 5,
                              offset: Offset(1, 3)),
                        ],
                      ),
                      child: const Icon(
                        Icons.casino_rounded,
                        color: boardRed,
                        size: 19,
                      ),
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

class _MiniGoggle extends StatelessWidget {
  const _MiniGoggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF5F5871),
        border: Border.all(color: const Color(0xFF534865), width: 2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 15,
        height: 15,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.45, -0.45),
            colors: [Colors.white, Color(0xFFCDE9FF)],
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1A1030),
          ),
        ),
      ),
    );
  }
}

class _MiniCrownPainter extends CustomPainter {
  final Color accent;

  const _MiniCrownPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.86)
      ..lineTo(size.width * 0.23, size.height * 0.22)
      ..lineTo(size.width * 0.40, size.height * 0.58)
      ..lineTo(size.width * 0.50, size.height * 0.10)
      ..lineTo(size.width * 0.60, size.height * 0.58)
      ..lineTo(size.width * 0.77, size.height * 0.22)
      ..lineTo(size.width * 0.92, size.height * 0.86)
      ..close();
    p.shader = LinearGradient(
      colors: [const Color(0xFFFFF27B), goldColor, accent],
    ).createShader(Offset.zero & size);
    canvas.drawPath(path, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF9D6500);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_MiniCrownPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _ShopMascotShelfPainter extends CustomPainter {
  final double t;

  const _ShopMascotShelfPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final phase = t * math.pi * 2;
    final center = Offset(size.width * 0.50, size.height * 0.55);
    final s = math.min(size.width, size.height) * 0.44;

    p.shader = ui.Gradient.radial(
      center.translate(0, -s * 0.20),
      s * 1.30,
      const [Color(0x66FFD426), Color(0x00220627)],
    );
    canvas.drawCircle(center, s * 1.30, p);
    p.shader = null;

    final shelf = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.82),
      width: size.width * 0.92,
      height: size.height * 0.22,
    );
    p.color = const Color(0x77000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(shelf.center.dx, shelf.bottom + 5),
        width: shelf.width * 0.92,
        height: shelf.height * 0.42,
      ),
      p,
    );
    p.shader = ui.Gradient.linear(
      shelf.topLeft,
      shelf.bottomRight,
      const [Color(0xFFFFE06E), Color(0xFFD87900), Color(0xFF632800)],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawRRect(RRect.fromRectXY(shelf, 14, 14), p);
    p.shader = null;

    _drawMascot(
      canvas,
      center.translate(0, math.sin(phase) * size.height * 0.025),
      s,
      boardBlue,
      boardYellow,
      p,
    );
    _drawCoin(
      canvas,
      Offset(size.width * 0.16, size.height * (0.70 + math.sin(phase) * 0.03)),
      s * 0.18,
      p,
    );
    _drawDice(
      canvas,
      Offset(size.width * 0.84, size.height * (0.70 + math.cos(phase) * 0.03)),
      s * 0.31,
      p,
    );
  }

  void _drawMascot(
      Canvas canvas, Offset c, double s, Color suit, Color accent, Paint p) {
    canvas.save();
    canvas.translate(c.dx, c.dy);

    p.color = const Color(0x66000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.72),
        width: s * 1.28,
        height: s * 0.28,
      ),
      p,
    );

    final body = Rect.fromCenter(
      center: Offset.zero,
      width: s * 0.82,
      height: s * 1.16,
    );
    p.shader = ui.Gradient.linear(
      body.topLeft,
      body.bottomRight,
      const [Color(0xFFFFF06B), Color(0xFFFFC928), Color(0xFFE09300)],
      const [0.0, 0.56, 1.0],
    );
    canvas.drawRRect(RRect.fromRectXY(body, s * 0.34, s * 0.34), p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, s * 0.035)
      ..color = const Color(0xFF8A5500);
    canvas.drawRRect(RRect.fromRectXY(body, s * 0.34, s * 0.34), p);
    p.style = PaintingStyle.fill;

    _drawCrown(canvas, Offset(0, -s * 0.62), s * 0.34, accent, p);
    _drawGoggles(canvas, s, p);
    _drawSmile(canvas, s, p);
    _drawOveralls(canvas, s, suit, accent, p);
    canvas.restore();
  }

  void _drawCrown(Canvas canvas, Offset c, double r, Color accent, Paint p) {
    final crown = Path()
      ..moveTo(c.dx - r, c.dy + r * 0.30)
      ..lineTo(c.dx - r * 0.62, c.dy - r * 0.70)
      ..lineTo(c.dx - r * 0.22, c.dy)
      ..lineTo(c.dx, c.dy - r * 0.86)
      ..lineTo(c.dx + r * 0.22, c.dy)
      ..lineTo(c.dx + r * 0.62, c.dy - r * 0.70)
      ..lineTo(c.dx + r, c.dy + r * 0.30)
      ..close();
    p.shader = ui.Gradient.linear(
      c.translate(-r, -r),
      c.translate(r, r),
      [const Color(0xFFFFF27B), goldColor, accent],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawPath(crown, p);
    p.shader = null;
  }

  void _drawGoggles(Canvas canvas, double s, Paint p) {
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, s * 0.08)
      ..color = const Color(0xFF534865);
    canvas.drawLine(
        Offset(-s * 0.32, -s * 0.25), Offset(s * 0.32, -s * 0.25), p);
    p.style = PaintingStyle.fill;
    for (final x in [-s * 0.17, s * 0.17]) {
      p.color = const Color(0xFF5F5871);
      canvas.drawCircle(Offset(x, -s * 0.25), s * 0.18, p);
      p.shader = ui.Gradient.radial(
        Offset(x - s * 0.04, -s * 0.30),
        s * 0.15,
        const [Colors.white, Color(0xFFCDE9FF)],
      );
      canvas.drawCircle(Offset(x, -s * 0.25), s * 0.125, p);
      p.shader = null;
      p.color = const Color(0xFF1A1030);
      canvas.drawCircle(Offset(x + s * 0.02, -s * 0.24), s * 0.046, p);
      p.color = Colors.white;
      canvas.drawCircle(Offset(x, -s * 0.29), s * 0.022, p);
    }
  }

  void _drawSmile(Canvas canvas, double s, Paint p) {
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, s * 0.055)
      ..color = const Color(0xFF6D3D00);
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(0, -s * 0.04), width: s * 0.38, height: s * 0.22),
      0.2,
      math.pi - 0.4,
      false,
      p,
    );
    p
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;
  }

  void _drawOveralls(
      Canvas canvas, double s, Color suit, Color accent, Paint p) {
    final overalls = Path()
      ..moveTo(-s * 0.32, s * 0.12)
      ..lineTo(-s * 0.23, s * 0.50)
      ..quadraticBezierTo(0, s * 0.64, s * 0.23, s * 0.50)
      ..lineTo(s * 0.32, s * 0.12)
      ..quadraticBezierTo(s * 0.13, s * 0.25, 0, s * 0.25)
      ..quadraticBezierTo(-s * 0.13, s * 0.25, -s * 0.32, s * 0.12)
      ..close();
    p.shader = ui.Gradient.linear(
      Offset(-s * 0.34, s * 0.10),
      Offset(s * 0.34, s * 0.62),
      [
        Color.lerp(suit, Colors.white, 0.20)!,
        suit,
        Color.lerp(suit, Colors.black, 0.28)!,
      ],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawPath(overalls, p);
    p.shader = null;
    p.color = accent;
    _drawStar(canvas, Offset(0, s * 0.38), s * 0.14, p);
  }

  void _drawCoin(Canvas canvas, Offset c, double r, Paint p) {
    p.shader = ui.Gradient.radial(
      c.translate(-r * 0.20, -r * 0.20),
      r * 1.20,
      const [Color(0xFFFFF27D), Color(0xFFFFC21F), Color(0xFFE07E00)],
      const [0.0, 0.58, 1.0],
    );
    canvas.drawCircle(c, r, p);
    p.shader = null;
  }

  void _drawDice(Canvas canvas, Offset c, double s, Paint p) {
    final rect = Rect.fromCenter(center: c, width: s, height: s);
    p.shader = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      const [Colors.white, Color(0xFFFFEFC8)],
    );
    canvas.drawRRect(RRect.fromRectXY(rect, s * 0.22, s * 0.22), p);
    p.shader = null;
    p.color = boardRed;
    for (final dot in [
      rect.center,
      Offset(rect.left + s * 0.30, rect.top + s * 0.30),
      Offset(rect.right - s * 0.30, rect.bottom - s * 0.30),
      Offset(rect.right - s * 0.30, rect.top + s * 0.30),
      Offset(rect.left + s * 0.30, rect.bottom - s * 0.30),
    ]) {
      canvas.drawCircle(dot, s * 0.055, p);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final point = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ShopMascotShelfPainter oldDelegate) => oldDelegate.t != t;
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
        'Win +${GameEconomy.onlineWinCoins} | Finish +${GameEconomy.onlineFinishCoins} | Daily +${GameEconomy.dailyCoins} | Chest +${GameEconomy.goldChestCoins} every ${GameEconomy.winsPerGoldChest} wins',
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

class _BoardThemeOption {
  final String id;
  final String label;
  final List<Color> colors;
  final String rarity;
  final String asset;

  const _BoardThemeOption(
    this.id,
    this.label,
    this.colors, {
    required this.asset,
    this.rarity = 'COMMON',
  });
}

class _AvatarShopStrip extends StatelessWidget {
  final _ShopPalette palette;
  final AppState state;

  const _AvatarShopStrip({required this.palette, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0x8420062C),
        border: Border.all(color: palette.stroke.withAlpha(165), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 76,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avatar',
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Styles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: profileAvatarCatalog.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final avatar = profileAvatarCatalog[index];
                final unlocked = state.isAvatarUnlocked(index);
                return _ShopAvatarButton(
                  avatar: avatar,
                  selected: state.avatarPreset == index &&
                      state.avatarImagePath == null,
                  unlocked: unlocked,
                  actionLabel: state.avatarUnlockLabel(index),
                  onTap: () {
                    var message = '${avatar.label} equipped.';
                    if (unlocked) {
                      state.updateProfile(avatar: index, clearImage: true);
                    } else if (avatar.rarity == AvatarRarity.premium) {
                      message =
                          '${avatar.label} requires a verified Google Play purchase (${avatar.price}).';
                    } else {
                      message = state.avatarUnlockLabel(index);
                    }
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xEE22082E),
                          duration: const Duration(milliseconds: 1200),
                          content: Text(message),
                        ),
                      );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopAvatarButton extends StatelessWidget {
  final ProfileAvatarSpec avatar;
  final bool selected;
  final bool unlocked;
  final String actionLabel;
  final VoidCallback onTap;

  const _ShopAvatarButton({
    required this.avatar,
    required this.selected,
    required this.unlocked,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = switch (avatar.rarity) {
      AvatarRarity.common => boardGreen,
      AvatarRarity.rare => boardBlue,
      AvatarRarity.premium => boardPurple,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 86,
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              Color.lerp(accent, Colors.white, 0.22)!,
              accent.withAlpha(170),
            ],
          ),
          border: Border.all(
            color: selected ? goldColor : Colors.white.withAlpha(80),
            width: selected ? 2.2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _ShopAvatarImage(avatar: avatar),
                  ),
                  if (!unlocked)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0x99000000),
                      ),
                      child: Icon(
                        avatar.rarity == AvatarRarity.premium
                            ? Icons.workspace_premium_rounded
                            : Icons.lock_rounded,
                        color: goldColor,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              avatar.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              actionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: avatar.rarity == AvatarRarity.premium
                    ? goldColor
                    : Colors.white70,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopAvatarImage extends StatelessWidget {
  final ProfileAvatarSpec avatar;

  const _ShopAvatarImage({required this.avatar});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final height = box.maxHeight;
        final column = avatar.atlasIndex % 2;
        final row = avatar.atlasIndex ~/ 2;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -column * width,
                top: -row * height,
                width: width * 2,
                height: height * 2,
                child: Image.asset(
                  avatar.asset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BoardThemeStrip extends StatelessWidget {
  final _ShopPalette palette;
  final AppState state;

  const _BoardThemeStrip({
    required this.palette,
    required this.state,
  });

  static const _options = [
    _BoardThemeOption(
        'carnival',
        'Carnival',
        [
          Color(0xFFFF36B8),
          Color(0xFFFFD426),
          Color(0xFF22B7FF),
        ],
        asset: 'assets/images/rush/rush_snakes_frame_carnival_mobile_v1.jpg'),
    _BoardThemeOption(
        'royal',
        'Royal',
        [
          Color(0xFF5B2CFF),
          Color(0xFFFFD426),
          Color(0xFFB145FF),
        ],
        asset: 'assets/images/rush/rush_board_royal_locked_v1.png',
        rarity: 'RARE'),
    _BoardThemeOption(
        'neon',
        'Neon',
        [
          Color(0xFF00F5FF),
          Color(0xFFFF35D6),
          Color(0xFF6EFF3A),
        ],
        asset: 'assets/images/rush/rush_board_neon_locked_v1.png',
        rarity: 'PREMIUM'),
    _BoardThemeOption(
        'classic',
        'Classic',
        [
          Color(0xFFFF3B3F),
          Color(0xFF2DBB52),
          Color(0xFF1E9BFF),
        ],
        asset: 'assets/images/rush/rush_snakes_frame_classic_mobile_v1.jpg'),
    _BoardThemeOption(
        'jungle',
        'Jungle',
        [
          Color(0xFF35B96D),
          Color(0xFFFFC93C),
          Color(0xFF21BDEB),
        ],
        asset: 'assets/images/rush/rush_snakes_frame_jungle_mobile_v1.webp',
        rarity: 'RARE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0x8420062C),
        border: Border.all(color: palette.stroke.withAlpha(165), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Snakes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Boards',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final option = _options[i];
                return _BoardThemeButton(
                  option: option,
                  selected: state.snakesBoardTheme == option.id,
                  locked: !state.isBoardThemeUnlocked(option.id),
                  actionLabel: state.boardThemePremiumPrice(option.id) ??
                      (state.isBoardThemeUnlocked(option.id)
                          ? 'Owned'
                          : '${state.boardThemeRequiredWins(option.id)} wins'),
                  onTap: () {
                    if (state.isBoardThemeUnlocked(option.id)) {
                      state.setSnakesBoardTheme(option.id);
                    }
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xEE22082E),
                          duration: const Duration(milliseconds: 1100),
                          content: Text(state.isBoardThemeUnlocked(option.id)
                              ? '${option.label} board selected.'
                              : state.boardThemeUnlockLabel(option.id)),
                        ),
                      );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardThemeButton extends StatelessWidget {
  final _BoardThemeOption option;
  final bool selected;
  final bool locked;
  final String actionLabel;
  final VoidCallback onTap;

  const _BoardThemeButton({
    required this.option,
    required this.selected,
    required this.locked,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 124,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              option.colors[0].withAlpha(selected ? 245 : 180),
              option.colors[1].withAlpha(selected ? 235 : 155),
            ],
          ),
          border: Border.all(
            color: selected ? goldColor : Colors.white.withAlpha(80),
            width: selected ? 2.2 : 1.1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: goldColor.withAlpha(105),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      option.asset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  if (locked)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x77000000),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        option.rarity == 'PREMIUM'
                            ? Icons.workspace_premium_rounded
                            : Icons.lock_rounded,
                        color: goldColor,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: [
                  Text(
                    option.label,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                    ),
                  ),
                  Text(
                    actionLabel,
                    maxLines: 1,
                    style: TextStyle(
                      color: option.rarity == 'PREMIUM'
                          ? const Color(0xFFFFF08A)
                          : Colors.white.withAlpha(210),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 3)
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
}

class _LudoThemePreview extends StatelessWidget {
  final String theme;

  const _LudoThemePreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    return LudoBoard(
      snapshot: null,
      mySeat: null,
      boardTheme: theme,
      showWaitingOverlay: false,
      animate: false,
      onPieceTap: (_) {},
    );
  }
}

class _SnakesThemePreview extends StatelessWidget {
  final String theme;

  const _SnakesThemePreview({
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SnakesLaddersBoard(
      snapshot: null,
      mySeat: null,
      boardTheme: theme,
      showTitle: false,
      showPieces: false,
      animate: false,
      onPieceTap: (_) {},
    );
  }
}

class _DiceSkinOption {
  final String id;
  final String label;
  final int value;
  final List<Color> colors;
  final String rarity;

  const _DiceSkinOption(this.id, this.label, this.value, this.colors,
      {this.rarity = 'COMMON'});
}

class _DiceSkinStrip extends StatelessWidget {
  final _ShopPalette palette;
  final AppState state;

  const _DiceSkinStrip({
    required this.palette,
    required this.state,
  });

  static const _options = [
    _DiceSkinOption('classic', 'Classic', 5, [
      Color(0xFFFFFDF4),
      goldColor,
    ]),
    _DiceSkinOption(
        'royal',
        'Royal',
        6,
        [
          Color(0xFFFFE26A),
          Color(0xFFE58A00),
        ],
        rarity: 'RARE'),
    _DiceSkinOption(
        'neon',
        'Neon',
        4,
        [
          Color(0xFF162A72),
          Color(0xFF42F3FF),
        ],
        rarity: 'RARE'),
    _DiceSkinOption(
        'ruby',
        'Ruby',
        3,
        [
          Color(0xFFFF4055),
          Color(0xFFFFD866),
        ],
        rarity: 'PREMIUM'),
    _DiceSkinOption(
        'emerald',
        'Emerald',
        2,
        [
          Color(0xFF18C94B),
          Color(0xFFFFD866),
        ],
        rarity: 'RARE'),
    _DiceSkinOption(
        'cosmic',
        'Cosmic',
        6,
        [
          Color(0xFF7A25FF),
          Color(0xFFFF54FF),
        ],
        rarity: 'PREMIUM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke.withAlpha(175), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/rush/rush_shop_dice_showcase_mobile_v1.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xF02B0537),
                  const Color(0xD0350842),
                  const Color(0x88350842),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
            child: Row(
              children: [
                const SizedBox(
                  width: 88,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dice',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Skins',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _options.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final option = _options[i];
                      return _DiceSkinButton(
                        option: option,
                        selected: state.diceSkin == option.id,
                        locked: !state.isDiceSkinUnlocked(option.id),
                        actionLabel: state.diceSkinPremiumPrice(option.id) ??
                            (state.isDiceSkinUnlocked(option.id)
                                ? 'Owned'
                                : '${state.diceSkinRequiredWins(option.id)} wins'),
                        onTap: () {
                          if (state.isDiceSkinUnlocked(option.id)) {
                            state.setDiceSkin(option.id);
                          }
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xEE22082E),
                                duration: const Duration(milliseconds: 1100),
                                content: Text(
                                    state.isDiceSkinUnlocked(option.id)
                                        ? '${option.label} dice equipped.'
                                        : state.diceSkinUnlockLabel(option.id)),
                              ),
                            );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceSkinButton extends StatelessWidget {
  final _DiceSkinOption option;
  final bool selected;
  final bool locked;
  final String actionLabel;
  final VoidCallback onTap;

  const _DiceSkinButton({
    required this.option,
    required this.selected,
    required this.locked,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 76,
        padding: const EdgeInsets.fromLTRB(6, 7, 6, 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              option.colors.first.withAlpha(selected ? 245 : 180),
              option.colors.last.withAlpha(selected ? 238 : 150),
            ],
          ),
          border: Border.all(
            color: selected ? goldColor : Colors.white.withAlpha(95),
            width: selected ? 2.4 : 1.1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: goldColor.withAlpha(115),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DiceWidget(
                      value: option.value,
                      size: 42,
                      skin: option.id,
                    ),
                    if (locked)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x99000000),
                          border: Border.all(color: goldColor, width: 1.3),
                        ),
                        child: Icon(
                          option.rarity == 'PREMIUM'
                              ? Icons.workspace_premium_rounded
                              : Icons.lock_rounded,
                          color: goldColor,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                option.label,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                actionLabel,
                maxLines: 1,
                style: TextStyle(
                  color: option.rarity == 'PREMIUM'
                      ? const Color(0xFFFFF08A)
                      : Colors.white.withAlpha(210),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProductArt {
  daily,
  coinPack,
  clubChest,
  royalVault,
  royalDice,
  neonDice,
  rubyDice,
  emeraldDice,
  cosmicDice,
  carnivalBoard,
  royalBoard,
  neonBoard,
  classicBoard,
}

List<double> _evenColorStops(int count) {
  if (count <= 1) return const [0.0];
  return List<double>.generate(count, (i) => i / (count - 1));
}

class _ShopProduct {
  final String title;
  final String price;
  final String description;
  final _ProductArt art;
  final bool best;
  final int coinReward;
  final String? diceSkin;
  final String? ludoBoardTheme;
  final bool dailyReward;
  final String rarity;

  const _ShopProduct(
    this.title,
    this.price,
    this.description,
    this.art,
    this.best,
    this.coinReward, {
    this.diceSkin,
    this.ludoBoardTheme,
    this.dailyReward = false,
    this.rarity = 'COMMON',
  });

  bool isLocked(AppState state) {
    if (diceSkin != null) return !state.isDiceSkinUnlocked(diceSkin!);
    if (ludoBoardTheme != null) {
      return !state.isBoardThemeUnlocked(ludoBoardTheme!);
    }
    return false;
  }

  bool isEquipped(AppState state) {
    if (diceSkin != null) return state.diceSkin == diceSkin;
    if (ludoBoardTheme != null) return state.ludoBoardTheme == ludoBoardTheme;
    return false;
  }

  bool get premium => rarity == 'PREMIUM';

  bool requiresPurchase(AppState state) {
    if (!premium) return false;
    if (diceSkin != null) return !state.isDiceSkinUnlocked(diceSkin!);
    if (ludoBoardTheme != null) {
      return !state.isBoardThemeUnlocked(ludoBoardTheme!);
    }
    return true;
  }

  String actionLabel(AppState state) {
    if (dailyReward) {
      return state.canClaimDailyReward ? 'FREE' : 'CLAIMED';
    }
    if (isEquipped(state)) return 'EQUIPPED';
    if (requiresPurchase(state)) return 'PREVIEW $price';
    if (diceSkin != null && !state.isDiceSkinUnlocked(diceSkin!)) {
      return state.diceSkinPremiumPrice(diceSkin!) ?? price;
    }
    if (ludoBoardTheme != null &&
        !state.isBoardThemeUnlocked(ludoBoardTheme!)) {
      return state.boardThemePremiumPrice(ludoBoardTheme!) ?? price;
    }
    if (diceSkin != null || ludoBoardTheme != null) return 'EQUIP';
    return price;
  }
}

class _ShopCard extends StatefulWidget {
  final _ShopProduct product;
  final _ShopPalette palette;
  final VoidCallback onBuy;
  final bool locked;
  final String actionLabel;

  const _ShopCard({
    required this.product,
    required this.palette,
    required this.onBuy,
    required this.locked,
    required this.actionLabel,
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
    final cardColors = switch (widget.product.rarity) {
      'PREMIUM' => const [Color(0xFFB91B7A), Color(0xFF4C0A65)],
      'RARE' => const [Color(0xFF355FC7), Color(0xFF40116A)],
      _ => const [Color(0xFF8B2F62), Color(0xFF35093F)],
    };
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapCancel: _press.reverse,
      onTapUp: (_) {
        _press.reverse();
        SoundService.tap();
        _showShopProductPreview(
          context,
          product: widget.product,
          locked: widget.locked,
          actionLabel: widget.actionLabel,
          onAction: widget.onBuy,
        );
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
                      colors: cardColors,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          widget.product.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withAlpha(218),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 2)
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _RarityPill(
                          label: widget.product.rarity,
                          premium: widget.product.premium,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 2, 5, 3),
                          child: _ShopProductVisual(product: widget.product),
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
                            widget.actionLabel,
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
                if (widget.locked && !widget.product.dailyReward)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0x66000000),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xCC250631),
                              border: Border.all(color: goldColor, width: 1.4),
                            ),
                            child: Icon(
                              widget.product.premium
                                  ? Icons.workspace_premium_rounded
                                  : Icons.lock_rounded,
                              color: goldColor,
                              size: 24,
                            ),
                          ),
                        ),
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

void _showShopProductPreview(
  BuildContext context, {
  required _ShopProduct product,
  required bool locked,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF681064), Color(0xFF22062D)],
              ),
              border: Border.all(color: goldColor, width: 2),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.title,
                        style: const TextStyle(
                          color: goldColor,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close preview',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white70,
                    ),
                  ],
                ),
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: _ShopProductVisual(product: product),
                      ),
                      if (locked)
                        const Align(
                          alignment: Alignment.topRight,
                          child: CircleAvatar(
                            radius: 19,
                            backgroundColor: Color(0xDD22082E),
                            child: Icon(
                              Icons.lock_rounded,
                              color: goldColor,
                              size: 21,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  product.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      onAction();
                    },
                    icon: Icon(
                      locked
                          ? Icons.lock_open_rounded
                          : Icons.shopping_cart_checkout_rounded,
                    ),
                    label: Text(actionLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2EAD25),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _RarityPill extends StatelessWidget {
  final String label;
  final bool premium;

  const _RarityPill({required this.label, required this.premium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: premium ? const Color(0xFFE61D7A) : const Color(0x66250631),
        border: Border.all(
          color: premium ? const Color(0xFFFFF08A) : const Color(0x55FFD426),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
    );
  }
}

class _ShopProductVisual extends StatelessWidget {
  final _ShopProduct product;

  const _ShopProductVisual({required this.product});

  @override
  Widget build(BuildContext context) {
    if (product.ludoBoardTheme != null) {
      return SizedBox.expand(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: RepaintBoundary(
            child: _LudoThemePreview(theme: product.ludoBoardTheme!),
          ),
        ),
      );
    }
    final diceIndex = _diceAtlasIndex(product.art);
    if (diceIndex != null) {
      return _AtlasSprite(
        asset: _shopDiceAtlasAsset,
        columns: 3,
        rows: 2,
        index: diceIndex,
      );
    }
    final rewardIndex = _rewardAtlasIndex(product.art);
    if (rewardIndex != null) {
      return _AtlasSprite(
        asset: _shopRewardsAtlasAsset,
        columns: 2,
        rows: 2,
        index: rewardIndex,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withAlpha(78),
            goldColor.withAlpha(42),
            Colors.transparent,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _ProductPainter(product.art),
        child: const SizedBox.expand(),
      ),
    );
  }

  static int? _diceAtlasIndex(_ProductArt art) => switch (art) {
        _ProductArt.royalDice => 0,
        _ProductArt.neonDice => 1,
        _ProductArt.rubyDice => 2,
        _ProductArt.emeraldDice => 3,
        _ProductArt.cosmicDice => 4,
        _ => null,
      };

  static int? _rewardAtlasIndex(_ProductArt art) => switch (art) {
        _ProductArt.daily => 0,
        _ProductArt.coinPack => 1,
        _ProductArt.clubChest => 2,
        _ProductArt.royalVault => 3,
        _ => null,
      };

  static List<Color> _boardColors(String theme) => switch (theme) {
        'royal' => const [Color(0xFF7D35FF), goldColor, Color(0xFF2FE8FF)],
        'neon' => const [
            Color(0xFF00E7FF),
            Color(0xFFFF35D6),
            Color(0xFF6BFF39)
          ],
        'classic' => const [boardRed, boardGreen, boardBlue],
        _ => const [boardRed, boardBlue, boardGreen],
      };
}

class _AtlasSprite extends StatelessWidget {
  final String asset;
  final int columns;
  final int rows;
  final int index;

  const _AtlasSprite({
    required this.asset,
    required this.columns,
    required this.rows,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final height = box.maxHeight;
        final column = index % columns;
        final row = index ~/ columns;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -column * width,
                top: -row * height,
                width: width * columns,
                height: height * rows,
                child: Image.asset(
                  asset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          ),
        );
      },
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
      _ShopNavSpec(Icons.inventory_2_rounded, 'Rewards'),
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
                if (i == 0) {
                  return;
                }
                if (i == 2) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (_) => false,
                  );
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (_) => false,
                    arguments: i,
                  );
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
      const [0.0, 0.58, 1.0],
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
      const [0.0, 0.52, 1.0],
    );
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;

    final mascotBob = math.sin(phase + 0.4) * size.shortestSide * 0.018;
    _drawShopCounter(canvas, size, p);
    _drawMascot(
      canvas,
      Offset(size.width * 0.57, size.height * 0.56 + mascotBob),
      size.shortestSide * 0.37,
      boardBlue,
      boardYellow,
      p,
      false,
    );
    _drawMascot(
      canvas,
      Offset(size.width * 0.18, size.height * 0.72 - mascotBob * 0.7),
      size.shortestSide * 0.22,
      boardGreen,
      boardRed,
      p,
      false,
    );

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

  void _drawShopCounter(Canvas canvas, Size size, Paint p) {
    final counter = Rect.fromLTWH(
      size.width * 0.10,
      size.height * 0.72,
      size.width * 0.78,
      size.height * 0.20,
    );
    p.color = Colors.black.withAlpha(72);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.49, counter.bottom + size.height * 0.03),
        width: counter.width * 0.94,
        height: size.height * 0.09,
      ),
      p,
    );
    p.shader = ui.Gradient.linear(
      counter.topLeft,
      counter.bottomRight,
      const [Color(0xFFFFD765), Color(0xFFD97800), Color(0xFF6B2B00)],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawRRect(RRect.fromRectXY(counter, 16, 16), p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFF08A);
    canvas.drawRRect(RRect.fromRectXY(counter.deflate(2), 14, 14), p);
    p.style = PaintingStyle.fill;
  }

  void _drawMascot(Canvas canvas, Offset base, double s, Color suit,
      Color accent, Paint p, bool flip) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(flip ? -1.0 : 1.0, 1.0);

    p.color = const Color(0x66000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.70),
        width: s * 1.28,
        height: s * 0.28,
      ),
      p,
    );

    _drawMascotArm(canvas, Offset(-s * 0.36, -s * 0.02), -1, accent, p, s);
    _drawMascotArm(canvas, Offset(s * 0.36, -s * 0.02), 1, accent, p, s);

    final body = Rect.fromCenter(
      center: Offset.zero,
      width: s * 0.86,
      height: s * 1.18,
    );
    p.shader = ui.Gradient.linear(
      body.topLeft,
      body.bottomRight,
      const [Color(0xFFFFF06B), Color(0xFFFFC928), Color(0xFFE09300)],
      const [0.0, 0.56, 1.0],
    );
    canvas.drawRRect(RRect.fromRectXY(body, s * 0.36, s * 0.36), p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, s * 0.035)
      ..color = const Color(0xFF8A5500);
    canvas.drawRRect(RRect.fromRectXY(body, s * 0.36, s * 0.36), p);
    p.style = PaintingStyle.fill;

    _drawMascotCrown(canvas, Offset(0, -s * 0.62), s * 0.34, accent, p);
    _drawMascotGoggles(canvas, s, p);
    _drawMascotSmile(canvas, s, p);
    _drawMascotOveralls(canvas, s, suit, accent, p);

    p.color = Color.lerp(suit, Colors.black, 0.48)!;
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(
            center: Offset(-s * 0.19, s * 0.61),
            width: s * 0.30,
            height: s * 0.13),
        s * 0.08,
        s * 0.08,
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(
            center: Offset(s * 0.19, s * 0.61),
            width: s * 0.30,
            height: s * 0.13),
        s * 0.08,
        s * 0.08,
      ),
      p,
    );
    canvas.restore();
  }

  void _drawMascotArm(Canvas canvas, Offset shoulder, int side, Color accent,
      Paint p, double s) {
    final end = shoulder + Offset(side * s * 0.38, s * 0.24);
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(3.0, s * 0.16)
      ..color = const Color(0xFFE09300);
    canvas.drawLine(shoulder, end, p);
    p
      ..strokeWidth = math.max(2.0, s * 0.10)
      ..color = const Color(0xFFFFF06B);
    canvas.drawLine(shoulder.translate(side * 0.6, -0.5), end, p);
    p.style = PaintingStyle.fill;
    p.color = accent;
    canvas.drawCircle(end, math.max(2.6, s * 0.11), p);
  }

  void _drawMascotCrown(
      Canvas canvas, Offset c, double r, Color accent, Paint p) {
    final crown = Path()
      ..moveTo(c.dx - r, c.dy + r * 0.30)
      ..lineTo(c.dx - r * 0.62, c.dy - r * 0.70)
      ..lineTo(c.dx - r * 0.22, c.dy)
      ..lineTo(c.dx, c.dy - r * 0.86)
      ..lineTo(c.dx + r * 0.22, c.dy)
      ..lineTo(c.dx + r * 0.62, c.dy - r * 0.70)
      ..lineTo(c.dx + r, c.dy + r * 0.30)
      ..close();
    p.shader = ui.Gradient.linear(
      c.translate(-r, -r),
      c.translate(r, r),
      [const Color(0xFFFFF27B), goldColor, accent],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawPath(crown, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, r * 0.10)
      ..color = const Color(0xFF9D6500);
    canvas.drawPath(crown, p);
    p.style = PaintingStyle.fill;
  }

  void _drawMascotGoggles(Canvas canvas, double s, Paint p) {
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, s * 0.08)
      ..color = const Color(0xFF534865);
    canvas.drawLine(
        Offset(-s * 0.32, -s * 0.25), Offset(s * 0.32, -s * 0.25), p);
    p.style = PaintingStyle.fill;

    for (final x in [-s * 0.17, s * 0.17]) {
      p.color = const Color(0xFF5F5871);
      canvas.drawCircle(Offset(x, -s * 0.25), s * 0.18, p);
      p.shader = ui.Gradient.radial(
        Offset(x - s * 0.04, -s * 0.30),
        s * 0.15,
        const [Colors.white, Color(0xFFCDE9FF)],
      );
      canvas.drawCircle(Offset(x, -s * 0.25), s * 0.125, p);
      p.shader = null;
      p.color = const Color(0xFF1A1030);
      canvas.drawCircle(Offset(x + s * 0.02, -s * 0.24), s * 0.046, p);
      p.color = Colors.white;
      canvas.drawCircle(Offset(x, -s * 0.29), s * 0.022, p);
    }
  }

  void _drawMascotSmile(Canvas canvas, double s, Paint p) {
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, s * 0.055)
      ..color = const Color(0xFF6D3D00);
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(0, -s * 0.04), width: s * 0.38, height: s * 0.22),
      0.2,
      math.pi - 0.4,
      false,
      p,
    );
    p
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;
  }

  void _drawMascotOveralls(
      Canvas canvas, double s, Color suit, Color accent, Paint p) {
    final overalls = Path()
      ..moveTo(-s * 0.32, s * 0.12)
      ..lineTo(-s * 0.23, s * 0.50)
      ..quadraticBezierTo(0, s * 0.64, s * 0.23, s * 0.50)
      ..lineTo(s * 0.32, s * 0.12)
      ..quadraticBezierTo(s * 0.13, s * 0.25, 0, s * 0.25)
      ..quadraticBezierTo(-s * 0.13, s * 0.25, -s * 0.32, s * 0.12)
      ..close();
    p.shader = ui.Gradient.linear(
      Offset(-s * 0.34, s * 0.10),
      Offset(s * 0.34, s * 0.62),
      [
        Color.lerp(suit, Colors.white, 0.20)!,
        suit,
        Color.lerp(suit, Colors.black, 0.28)!,
      ],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawPath(overalls, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, s * 0.032)
      ..color = Color.lerp(suit, Colors.black, 0.42)!;
    canvas.drawPath(overalls, p);
    p.style = PaintingStyle.fill;
    p.color = accent;
    _drawSpark(canvas, Offset(0, s * 0.38), s * 0.14, p);
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
      const [0.0, 0.58, 1.0],
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
      const [0.0, 0.50, 1.0],
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
    _drawHeroMascot(
      canvas,
      Offset(heroWidth * 0.88, heroHeight * (0.72 + float * 0.02)),
      heroHeight * 0.34,
      boardBlue,
      boardYellow,
      paint,
    );
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

  void _drawHeroMascot(Canvas canvas, Offset c, double s, Color suit,
      Color accent, Paint paint) {
    canvas.save();
    canvas.translate(c.dx, c.dy);

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0x66000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, s * 0.72),
        width: s * 1.35,
        height: s * 0.30,
      ),
      paint,
    );

    final body = Rect.fromCenter(
      center: Offset.zero,
      width: s * 0.86,
      height: s * 1.18,
    );
    paint.shader = ui.Gradient.linear(
      body.topLeft,
      body.bottomRight,
      const [Color(0xFFFFF06B), Color(0xFFFFC928), Color(0xFFE09300)],
      const [0.0, 0.56, 1.0],
    );
    canvas.drawRRect(RRect.fromRectXY(body, s * 0.34, s * 0.34), paint);
    paint.shader = null;

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, s * 0.035)
      ..color = const Color(0xFF8A5500);
    canvas.drawRRect(RRect.fromRectXY(body, s * 0.34, s * 0.34), paint);
    paint.style = PaintingStyle.fill;

    _drawHeroMascotCrown(canvas, Offset(0, -s * 0.62), s * 0.34, accent, paint);
    _drawHeroMascotGoggles(canvas, s, paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, s * 0.055)
      ..color = const Color(0xFF6D3D00);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, -s * 0.04),
        width: s * 0.38,
        height: s * 0.22,
      ),
      0.2,
      math.pi - 0.4,
      false,
      paint,
    );
    paint
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;

    final overalls = Path()
      ..moveTo(-s * 0.32, s * 0.12)
      ..lineTo(-s * 0.23, s * 0.50)
      ..quadraticBezierTo(0, s * 0.64, s * 0.23, s * 0.50)
      ..lineTo(s * 0.32, s * 0.12)
      ..quadraticBezierTo(s * 0.13, s * 0.25, 0, s * 0.25)
      ..quadraticBezierTo(-s * 0.13, s * 0.25, -s * 0.32, s * 0.12)
      ..close();
    paint.shader = ui.Gradient.linear(
      Offset(-s * 0.34, s * 0.10),
      Offset(s * 0.34, s * 0.62),
      [
        Color.lerp(suit, Colors.white, 0.20)!,
        suit,
        Color.lerp(suit, Colors.black, 0.28)!,
      ],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawPath(overalls, paint);
    paint.shader = null;
    paint.color = accent;
    _drawHeroStar(canvas, Offset(0, s * 0.38), s * 0.14, paint);
    canvas.restore();
  }

  void _drawHeroMascotCrown(
      Canvas canvas, Offset c, double r, Color accent, Paint paint) {
    final crown = Path()
      ..moveTo(c.dx - r, c.dy + r * 0.30)
      ..lineTo(c.dx - r * 0.62, c.dy - r * 0.70)
      ..lineTo(c.dx - r * 0.22, c.dy)
      ..lineTo(c.dx, c.dy - r * 0.86)
      ..lineTo(c.dx + r * 0.22, c.dy)
      ..lineTo(c.dx + r * 0.62, c.dy - r * 0.70)
      ..lineTo(c.dx + r, c.dy + r * 0.30)
      ..close();
    paint.shader = ui.Gradient.linear(
      c.translate(-r, -r),
      c.translate(r, r),
      [const Color(0xFFFFF27B), goldColor, accent],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawPath(crown, paint);
    paint.shader = null;
  }

  void _drawHeroMascotGoggles(Canvas canvas, double s, Paint paint) {
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, s * 0.08)
      ..color = const Color(0xFF534865);
    canvas.drawLine(
        Offset(-s * 0.32, -s * 0.25), Offset(s * 0.32, -s * 0.25), paint);
    paint.style = PaintingStyle.fill;
    for (final x in [-s * 0.17, s * 0.17]) {
      paint.color = const Color(0xFF5F5871);
      canvas.drawCircle(Offset(x, -s * 0.25), s * 0.18, paint);
      paint.shader = ui.Gradient.radial(
        Offset(x - s * 0.04, -s * 0.30),
        s * 0.15,
        const [Colors.white, Color(0xFFCDE9FF)],
      );
      canvas.drawCircle(Offset(x, -s * 0.25), s * 0.125, paint);
      paint.shader = null;
      paint.color = const Color(0xFF1A1030);
      canvas.drawCircle(Offset(x + s * 0.02, -s * 0.24), s * 0.046, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(x, -s * 0.29), s * 0.022, paint);
    }
  }

  void _drawHeroStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final point = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
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
    final s = size.shortestSide;
    final scale = (s / 72).clamp(0.86, 1.22).toDouble();
    switch (art) {
      case _ProductArt.daily:
        _drawGift(canvas, center.translate(-s * 0.04, 1), s * 0.78, p);
        _drawCoin(canvas, center.translate(s * 0.36, s * 0.23), s * 0.10, p);
        _drawCoin(canvas, center.translate(s * 0.46, s * 0.06), s * 0.09, p);
        break;
      case _ProductArt.coinPack:
        for (var i = 0; i < 8; i++) {
          final row = i ~/ 4;
          _drawCoin(
            canvas,
            center.translate((i % 4 - 1.5) * s * 0.22, row * s * 0.15 - 5),
            s * 0.10,
            p,
          );
        }
        _drawPouch(canvas, center.translate(0, s * 0.18), scale, p);
        break;
      case _ProductArt.clubChest:
        _drawChest(canvas, center.translate(0, s * 0.13), p, scale: scale);
        _drawShieldBadge(
            canvas, center.translate(-s * 0.42, -s * 0.26), s * 0.20, p);
        break;
      case _ProductArt.royalVault:
        _drawChest(canvas, center.translate(s * 0.10, s * 0.11), p,
            scale: scale);
        _drawChest(canvas, center.translate(-s * 0.23, s * 0.21), p,
            scale: scale * 0.68);
        for (var i = 0; i < 5; i++) {
          _drawGem(
            canvas,
            center.translate(
                (i - 2) * s * 0.20, -s * 0.35 + (i.isEven ? 0 : s * 0.11)),
            s * 0.065,
            p,
          );
        }
        break;
      case _ProductArt.royalDice:
        _drawProductDice(
          canvas,
          center,
          s * 0.82,
          const [Color(0xFFFFF08A), Color(0xFFFFB11B), Color(0xFFB86100)],
          const Color(0xFFFFF2A4),
          const Color(0xFF714000),
          p,
        );
        break;
      case _ProductArt.neonDice:
        _drawProductDice(
          canvas,
          center,
          s * 0.82,
          const [Color(0xFF10205E), Color(0xFF07102D), Color(0xFF00C9FF)],
          const Color(0xFF43F4FF),
          const Color(0xFF7DFFFF),
          p,
        );
        break;
      case _ProductArt.rubyDice:
        _drawProductDice(
          canvas,
          center,
          s * 0.82,
          const [Color(0xFFFF7272), Color(0xFFD31622), Color(0xFF6A0612)],
          const Color(0xFFFFD866),
          const Color(0xFFFFE17C),
          p,
        );
        break;
      case _ProductArt.emeraldDice:
        _drawProductDice(
          canvas,
          center,
          s * 0.82,
          const [Color(0xFF70FF90), Color(0xFF0EA63D), Color(0xFF064B21)],
          const Color(0xFFFFD866),
          const Color(0xFFFFEA7A),
          p,
        );
        break;
      case _ProductArt.cosmicDice:
        _drawProductDice(
          canvas,
          center,
          s * 0.82,
          const [Color(0xFFB95DFF), Color(0xFF48109A), Color(0xFF13072C)],
          const Color(0xFFFF5CFF),
          const Color(0xFFFFD866),
          p,
        );
        break;
      case _ProductArt.carnivalBoard:
        _drawBoardTheme(
          canvas,
          center,
          s * 0.86,
          const [boardRed, boardBlue, boardGreen, boardYellow],
          p,
        );
        break;
      case _ProductArt.royalBoard:
        _drawBoardTheme(
          canvas,
          center,
          s * 0.86,
          const [
            Color(0xFF7D35FF),
            Color(0xFFFFD426),
            Color(0xFFCA48FF),
            Color(0xFF2FE8FF),
          ],
          p,
        );
        break;
      case _ProductArt.neonBoard:
        _drawBoardTheme(
          canvas,
          center,
          s * 0.86,
          const [
            Color(0xFF00E7FF),
            Color(0xFFFF35D6),
            Color(0xFF6BFF39),
            Color(0xFFFFEA31),
          ],
          p,
        );
        break;
      case _ProductArt.classicBoard:
        _drawBoardTheme(
          canvas,
          center,
          s * 0.86,
          const [boardRed, boardYellow, boardBlue, boardGreen],
          p,
        );
        break;
    }
  }

  void _drawBoardTheme(
      Canvas canvas, Offset c, double s, List<Color> colors, Paint p) {
    final shadow = Rect.fromCenter(
      center: c.translate(0, s * 0.08),
      width: s * 1.05,
      height: s * 0.92,
    );
    p.color = Colors.black.withAlpha(58);
    canvas.drawOval(shadow, p);

    final board = Rect.fromCenter(center: c, width: s, height: s * 0.82);
    p.shader = ui.Gradient.linear(
      board.topLeft,
      board.bottomRight,
      const [Color(0xFFFFF7D7), Color(0xFFFFD36A), Color(0xFFAC6414)],
      const [0.0, 0.62, 1.0],
    );
    canvas.drawRRect(RRect.fromRectXY(board, s * 0.10, s * 0.10), p);
    p.shader = null;

    final inner = board.deflate(s * 0.075);
    p.color = const Color(0xFFFFF9DF);
    canvas.drawRRect(RRect.fromRectXY(inner, s * 0.045, s * 0.045), p);

    final quadW = inner.width * 0.34;
    final quadH = inner.height * 0.34;
    final quads = [
      Rect.fromLTWH(inner.left, inner.top, quadW, quadH),
      Rect.fromLTWH(inner.right - quadW, inner.top, quadW, quadH),
      Rect.fromLTWH(inner.left, inner.bottom - quadH, quadW, quadH),
      Rect.fromLTWH(inner.right - quadW, inner.bottom - quadH, quadW, quadH),
    ];
    for (var i = 0; i < quads.length; i++) {
      p.shader = ui.Gradient.linear(
        quads[i].topLeft,
        quads[i].bottomRight,
        [Color.lerp(colors[i], Colors.white, 0.28)!, colors[i]],
      );
      canvas.drawRRect(RRect.fromRectXY(quads[i], s * 0.035, s * 0.035), p);
      p.shader = null;
      p.color = Colors.white.withAlpha(120);
      canvas.drawRRect(
          RRect.fromRectXY(quads[i].deflate(s * 0.026), s * 0.025, s * 0.025),
          p);
    }

    final laneW = inner.width * 0.11;
    for (var i = 0; i < 4; i++) {
      p.color = colors[i].withAlpha(235);
      if (i < 2) {
        final x = i == 0 ? inner.center.dx - laneW * 1.2 : inner.center.dx;
        canvas.drawRRect(
          RRect.fromRectXY(
            Rect.fromLTWH(
                x, inner.top + inner.height * 0.11, laneW, inner.height * 0.78),
            s * 0.015,
            s * 0.015,
          ),
          p,
        );
      } else {
        final y = i == 2 ? inner.center.dy - laneW * 1.2 : inner.center.dy;
        canvas.drawRRect(
          RRect.fromRectXY(
            Rect.fromLTWH(
                inner.left + inner.width * 0.11, y, inner.width * 0.78, laneW),
            s * 0.015,
            s * 0.015,
          ),
          p,
        );
      }
    }

    final starPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + math.pi / 4;
      final pos = inner.center +
          Offset(math.cos(angle) * inner.width * 0.28,
              math.sin(angle) * inner.height * 0.28);
      _drawMiniStar(canvas, pos, s * 0.055, colors[i], starPaint);
    }

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, s * 0.025)
      ..color = const Color(0xFFFFF2A4);
    canvas.drawRRect(RRect.fromRectXY(board.deflate(1), s * 0.10, s * 0.10), p);
    p.style = PaintingStyle.fill;
  }

  void _drawMiniStar(
      Canvas canvas, Offset c, double r, Color color, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.46;
      final a = -math.pi / 2 + i * math.pi / 5;
      final point = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    paint.color = Colors.black.withAlpha(62);
    canvas.drawPath(path.shift(Offset(r * 0.10, r * 0.12)), paint);
    paint.color = color;
    canvas.drawPath(path, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, r * 0.14)
      ..color = const Color(0xFFFFF2A4);
    canvas.drawPath(path, paint);
    paint.style = PaintingStyle.fill;
  }

  void _drawGift(Canvas canvas, Offset c, double s, Paint p) {
    p.color = Colors.black.withAlpha(50);
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(0, s * 0.34), width: s, height: s * 0.22),
      p,
    );
    final box = Rect.fromCenter(
        center: c.translate(0, s * 0.12), width: s * 0.70, height: s * 0.56);
    final lid = Rect.fromCenter(
        center: c.translate(0, -s * 0.21), width: s * 0.82, height: s * 0.22);
    p.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF07A), Color(0xFFFF2E4C), Color(0xFFC5112D)],
    ).createShader(box);
    canvas.drawRRect(RRect.fromRectXY(box, s * 0.07, s * 0.07), p);
    canvas.drawRRect(RRect.fromRectXY(lid, s * 0.07, s * 0.07), p);
    p.shader = null;
    p.color = const Color(0xFFFFD426);
    canvas.drawRect(
        Rect.fromCenter(
            center: box.center, width: s * 0.13, height: box.height),
        p);
    canvas.drawRect(
        Rect.fromCenter(center: box.center, width: box.width, height: s * 0.12),
        p);
    p.color = Colors.white.withAlpha(170);
    canvas.drawCircle(c.translate(-s * 0.21, -s * 0.30), s * 0.07, p);
    _drawBow(canvas, c.translate(0, -s * 0.36), s * 0.28, p);
  }

  void _drawBow(Canvas canvas, Offset c, double s, Paint p) {
    p.shader = const LinearGradient(
      colors: [Color(0xFFFFF188), Color(0xFFFFB300), Color(0xFFFF5A24)],
    ).createShader(Rect.fromCenter(center: c, width: s * 2.0, height: s));
    canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(-s * 0.35, 0),
            width: s * 0.78,
            height: s * 0.52),
        p);
    canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(s * 0.35, 0),
            width: s * 0.78,
            height: s * 0.52),
        p);
    p.shader = null;
    p.color = const Color(0xFFFFE46A);
    canvas.drawCircle(c, s * 0.18, p);
  }

  void _drawProductDice(Canvas canvas, Offset c, double s, List<Color> face,
      Color rim, Color pip, Paint p) {
    final rect = Rect.fromCenter(center: c, width: s, height: s);
    p.color = Colors.black.withAlpha(60);
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(0, s * 0.48), width: s * 0.92, height: s * 0.22),
      p,
    );
    p.shader = ui.Gradient.radial(c, s * 0.95, [
      rim.withAlpha(105),
      Colors.transparent,
    ]);
    canvas.drawCircle(c, s * 0.65, p);
    p.shader = null;

    p.shader = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      face,
      _evenColorStops(face.length),
    );
    canvas.drawRRect(RRect.fromRectXY(rect, s * 0.22, s * 0.22), p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..color = rim;
    canvas.drawRRect(
        RRect.fromRectXY(rect.deflate(s * 0.035), s * 0.19, s * 0.19), p);
    p.style = PaintingStyle.fill;
    p.color = Colors.white.withAlpha(135);
    canvas.drawCircle(c.translate(-s * 0.23, -s * 0.24), s * 0.09, p);
    for (final dot in [
      c,
      c.translate(-s * 0.24, -s * 0.24),
      c.translate(s * 0.24, s * 0.24),
      c.translate(s * 0.24, -s * 0.24),
      c.translate(-s * 0.24, s * 0.24),
    ]) {
      p.color = Colors.black.withAlpha(70);
      canvas.drawCircle(dot.translate(s * 0.018, s * 0.026), s * 0.055, p);
      p.color = pip;
      canvas.drawCircle(dot, s * 0.052, p);
    }
  }

  void _drawShieldBadge(Canvas canvas, Offset c, double s, Paint p) {
    final shield = Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 0.72, c.dy - s * 0.62)
      ..lineTo(c.dx + s * 0.55, c.dy + s * 0.34)
      ..quadraticBezierTo(c.dx, c.dy + s, c.dx - s * 0.55, c.dy + s * 0.34)
      ..lineTo(c.dx - s * 0.72, c.dy - s * 0.62)
      ..close();
    p.shader = ui.Gradient.linear(
      c.translate(-s, -s),
      c.translate(s, s),
      const [Color(0xFF45D8FF), Color(0xFF0E75FF), Color(0xFF103978)],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawPath(shield, p);
    p.shader = null;
    p.color = goldColor;
    _drawStar(canvas, c.translate(0, -s * 0.02), s * 0.34, p);
  }

  void _drawGem(Canvas canvas, Offset c, double r, Paint p) {
    final gem = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.85, c.dy - r * 0.10)
      ..lineTo(c.dx + r * 0.45, c.dy + r)
      ..lineTo(c.dx - r * 0.45, c.dy + r)
      ..lineTo(c.dx - r * 0.85, c.dy - r * 0.10)
      ..close();
    p.shader = ui.Gradient.linear(
      c.translate(-r, -r),
      c.translate(r, r),
      const [Color(0xFFB6FFF6), Color(0xFF20E48A), Color(0xFF067B70)],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawPath(gem, p);
    p.shader = null;
    p.color = Colors.white.withAlpha(170);
    canvas.drawCircle(c.translate(-r * 0.22, -r * 0.32), r * 0.16, p);
  }

  void _drawPouch(Canvas canvas, Offset c, double scale, Paint p) {
    final w = 62 * scale;
    final h = 54 * scale;
    p.color = Colors.black.withAlpha(55);
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(0, h * 0.44), width: w, height: h * 0.23),
      p,
    );
    p.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB94CFF), Color(0xFF5A189A), Color(0xFF2A063C)],
    ).createShader(Rect.fromCenter(center: c, width: w, height: h));
    canvas.drawRRect(
      RRect.fromRectXY(Rect.fromCenter(center: c, width: w, height: h),
          14 * scale, 18 * scale),
      p,
    );
    p.shader = null;
    p.color = const Color(0xFFFFC64E);
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(
            center: c.translate(0, -h * 0.34),
            width: w * 0.72,
            height: h * 0.18),
        8 * scale,
        8 * scale,
      ),
      p,
    );
  }

  void _drawCoin(Canvas canvas, Offset c, double r, Paint p) {
    p.color = Colors.black.withAlpha(45);
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(2, r * 0.42), width: r * 2.0, height: r * 0.68),
      p,
    );
    p.shader = ui.Gradient.radial(
      c.translate(-r * 0.26, -r * 0.28),
      r * 1.2,
      const [Color(0xFFFFF6A6), Color(0xFFFFC21F), Color(0xFFD87800)],
      const [0.0, 0.58, 1.0],
    );
    canvas.drawCircle(c, r, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, r * 0.12)
      ..color = const Color(0xFF9C5600);
    canvas.drawCircle(c, r * 0.70, p);
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFFFFF0A0);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r * 0.48)
        ..lineTo(c.dx + r * 0.14, c.dy - r * 0.08)
        ..lineTo(c.dx + r * 0.48, c.dy - r * 0.08)
        ..lineTo(c.dx + r * 0.20, c.dy + r * 0.12)
        ..lineTo(c.dx + r * 0.31, c.dy + r * 0.52)
        ..lineTo(c.dx, c.dy + r * 0.28)
        ..lineTo(c.dx - r * 0.31, c.dy + r * 0.52)
        ..lineTo(c.dx - r * 0.20, c.dy + r * 0.12)
        ..lineTo(c.dx - r * 0.48, c.dy - r * 0.08)
        ..lineTo(c.dx - r * 0.14, c.dy - r * 0.08)
        ..close(),
      p,
    );
  }

  void _drawChest(Canvas canvas, Offset c, Paint p, {double scale = 1.0}) {
    final w = 78.0 * scale;
    final h = 58.0 * scale;
    final rect = Rect.fromCenter(center: c, width: w, height: h);
    p.color = Colors.black.withAlpha(55);
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(0, h * 0.58), width: w * 1.03, height: h * 0.30),
      p,
    );
    p.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD966), Color(0xFFD78713), Color(0xFF733A07)],
    ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectXY(rect, 8 * scale, 8 * scale),
      p,
    );
    p.shader = null;
    p.color = const Color(0xFF7A3B12);
    canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.center.dy, rect.width, 6 * scale), p);
    p.color = const Color(0xFFFFF0A0);
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(center: c, width: 22 * scale, height: 24 * scale),
        5 * scale,
        5 * scale,
      ),
      p,
    );
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final point = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_ProductPainter oldDelegate) => oldDelegate.art != art;
}
