import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/profile_catalog.dart';
import '../data/economy.dart';
import '../state/app_state.dart';
import '../services/levelplay_ad_service.dart';
import '../services/sound_service.dart';
import '../services/soundtrack_service.dart';
import '../theme/app_theme.dart';
import '../widgets/levelplay_banner.dart';
import '../widgets/snakes_ladders_board.dart';

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
  bool _exitDialogOpen = false;

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
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_confirmAppExit());
          },
          child: Scaffold(
            backgroundColor: p.bg,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LevelPlayBannerAd(placementName: 'LobbyBanner'),
                SafeArea(
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
                      if (index == 1 || index == 3 || index == 4) {
                        unawaited(state.refreshSocial());
                      }
                      setState(() => _tabIndex = index);
                    },
                  ),
                ),
              ],
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
                                    state: state,
                                    palette: p,
                                    shimmer: _shimmer),
                              ),
                              Positioned(
                                left: 0,
                                top: brandHeight + hudHeight,
                                right: 0,
                                height: rewardHeight,
                                child: _RewardStrip(state: state, palette: p),
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
          ),
        );
      },
    );
  }

  Future<void> _confirmAppExit() async {
    if (_exitDialogOpen || !mounted) return;
    _exitDialogOpen = true;
    final shouldExit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF2D0A35),
            title: const Text(
              'Exit Ludo Rush?',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Your current progress is saved.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: boardRed),
                ),
              ),
            ],
          ),
        ) ??
        false;
    _exitDialogOpen = false;
    if (!shouldExit || !mounted) return;

    await LevelPlayAdService.instance.showBeforeAppExit();
    if (mounted) await SystemNavigator.pop();
  }
}

void _showHomeSnack(BuildContext context, String message) {
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

String _privateModeForPlayers(int players) {
  if (players == 4) return 'classic_4p';
  if (players == 3) return 'classic_3p';
  return 'classic_2p';
}

class _HomeBoardThemeOption {
  final String id;
  final String label;
  final String asset;
  final List<Color> colors;

  const _HomeBoardThemeOption(this.id, this.label, this.asset, this.colors);
}

class _GiftShopItem {
  final String id;
  final String title;
  final String subtitle;
  final String rarity;
  final List<Color> colors;
  final int? coinCost;
  final String? price;

  const _GiftShopItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.rarity,
    required this.colors,
    this.coinCost,
    this.price,
  }) : assert((coinCost == null) != (price == null));

  String get asset => 'assets/images/rush/rush_gift_${id}_mobile_v1.webp';

  bool get premium => price != null;

  String get cost => price ?? '$coinCost coins';
}

const _homeBoardThemes = [
  _HomeBoardThemeOption('carnival', 'Carnival',
      'assets/images/rush/rush_snakes_frame_carnival_mobile_v1.jpg', [
    Color(0xFFFF36B8),
    Color(0xFFFFD426),
    Color(0xFF22B7FF),
  ]),
  _HomeBoardThemeOption(
      'royal', 'Royal', 'assets/images/rush/rush_board_royal_locked_v1.png', [
    Color(0xFF5B2CFF),
    Color(0xFFFFD426),
    Color(0xFFB145FF),
  ]),
  _HomeBoardThemeOption(
      'neon', 'Neon', 'assets/images/rush/rush_board_neon_locked_v1.png', [
    Color(0xFF00F5FF),
    Color(0xFFFF35D6),
    Color(0xFF6EFF3A),
  ]),
  _HomeBoardThemeOption('classic', 'Classic',
      'assets/images/rush/rush_snakes_frame_classic_mobile_v1.jpg', [
    Color(0xFFFF3B3F),
    Color(0xFF2DBB52),
    Color(0xFF1E9BFF),
  ]),
  _HomeBoardThemeOption('jungle', 'Jungle Temple',
      'assets/images/rush/rush_snakes_frame_jungle_mobile_v1.webp', [
    Color(0xFF35B96D),
    Color(0xFFFFC93C),
    Color(0xFF21BDEB),
  ]),
];

const _giftShopItems = [
  _GiftShopItem(
    id: 'lucky_dice',
    title: 'Lucky Dice',
    subtitle: 'One bright dice reaction',
    coinCost: GameEconomy.luckyDiceGiftCoins,
    rarity: 'COMMON',
    colors: [Color(0xFFFFF4AF), Color(0xFFFFB22D), Color(0xFFE85A00)],
  ),
  _GiftShopItem(
    id: 'friendship_heart',
    title: 'Friendship Heart',
    subtitle: 'Two goti share a ruby heart',
    coinCost: GameEconomy.friendshipHeartGiftCoins,
    rarity: 'COMMON',
    colors: [Color(0xFFFFA4BE), Color(0xFFE93062), Color(0xFF8D1745)],
  ),
  _GiftShopItem(
    id: 'coin_ship',
    title: 'Coin Ship',
    subtitle: 'Gift boat with coins',
    coinCost: GameEconomy.coinShipGiftCoins,
    rarity: 'COMMON',
    colors: [Color(0xFF5CEBFF), Color(0xFF2E7CFF), Color(0xFFFFD426)],
  ),
  _GiftShopItem(
    id: 'crown_chest',
    title: 'Crown Chest',
    subtitle: 'Rare chest animation',
    coinCost: GameEconomy.crownChestGiftCoins,
    rarity: 'RARE',
    colors: [Color(0xFFFFD426), Color(0xFFFF5D6C), Color(0xFF7A20C8)],
  ),
  _GiftShopItem(
    id: 'mascot_cheer',
    title: 'Mascot Cheer',
    subtitle: 'A royal high-five reaction',
    coinCost: GameEconomy.mascotCheerGiftCoins,
    rarity: 'RARE',
    colors: [Color(0xFFFF775D), Color(0xFF2988FF), Color(0xFFFFD426)],
  ),
  _GiftShopItem(
    id: 'firework_castle',
    title: 'Firework Castle',
    subtitle: 'A full celebration animation',
    coinCost: GameEconomy.fireworkCastleGiftCoins,
    rarity: 'RARE',
    colors: [Color(0xFF67E7FF), Color(0xFF7847EF), Color(0xFFFF9A2C)],
  ),
  _GiftShopItem(
    id: 'royal_crown',
    title: 'Royal Crown',
    subtitle: 'Premium friend gift',
    price: '0.99 USD',
    rarity: 'PREMIUM',
    colors: [Color(0xFFFFF2A3), Color(0xFFFF36B8), Color(0xFF5B2CFF)],
  ),
  _GiftShopItem(
    id: 'victory_parade',
    title: 'Victory Parade',
    subtitle: 'Trophy cart and dancing dice',
    price: '1.99 USD',
    rarity: 'PREMIUM',
    colors: [Color(0xFFFFE780), Color(0xFFE54E45), Color(0xFF275DEB)],
  ),
];

List<_FeatureRow> _friendRowsForState(AppState state) {
  final rows = <_FeatureRow>[
    for (final friend in state.friends)
      _FeatureRow(
        friend.displayName,
        'Accepted friend',
        friend.rating.toString(),
        id: friend.id,
      ),
    for (final request in state.incomingFriendRequests)
      _FeatureRow(
        request.displayName,
        'Request waiting for you',
        request.rating.toString(),
        id: request.id,
      ),
    for (final request in state.outgoingFriendRequests)
      _FeatureRow(
        request.displayName,
        'Friend request pending',
        request.rating.toString(),
        id: request.id,
      ),
    for (final gift in state.receivedFriendGifts.take(2))
      _FeatureRow(
        'Gift from ${gift.senderName}',
        _giftShopItems
                .where((item) => item.id == gift.giftId)
                .firstOrNull
                ?.title ??
            gift.giftId.replaceAll('_', ' '),
        'NEW',
      ),
  ];
  if (rows.isEmpty) {
    rows.add(const _FeatureRow(
      'No friends yet',
      'Play online to meet recent opponents',
      '0',
    ));
  }
  return rows;
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

void _showSnakesBoardSheet(
  BuildContext context,
  AppState state,
) {
  var selectedTheme = state.snakesBoardTheme;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final unlocked = state.isBoardThemeUnlocked(selectedTheme);
          final compactSheet = MediaQuery.sizeOf(context).height < 720;
          return _HomeActionSheet(
            title: 'Snakes Board',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose the approved board design before starting.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: compactSheet ? 225 : 340,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: goldColor, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SnakesLaddersBoard(
                        snapshot: null,
                        mySeat: null,
                        boardTheme: selectedTheme,
                        onPieceTap: (_) {},
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: compactSheet ? 92 : 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _homeBoardThemes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final option = _homeBoardThemes[index];
                      final optionUnlocked =
                          state.isBoardThemeUnlocked(option.id);
                      final premium = state.boardThemePremiumPrice(option.id);
                      final status = optionUnlocked
                          ? 'OWNED'
                          : premium ??
                              '${state.boardThemeRequiredWins(option.id)} WINS';
                      return _HomeThemeButton(
                        option: option,
                        selected: selectedTheme == option.id,
                        locked: !optionUnlocked,
                        status: status,
                        width: compactSheet ? 140 : 154,
                        onTap: () {
                          selectedTheme = option.id;
                          if (optionUnlocked) {
                            state.setSnakesBoardTheme(option.id);
                          }
                          setSheetState(() {});
                        },
                      );
                    },
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 10),
                  _EconomyHint(
                    icon: state.isBoardThemePremium(selectedTheme)
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_rounded,
                    text: state.boardThemeUnlockLabel(selectedTheme),
                  ),
                ],
                const SizedBox(height: 14),
                _HomeSheetButton(
                  label: unlocked ? 'Play This Board' : 'Locked Board',
                  icon:
                      unlocked ? Icons.play_arrow_rounded : Icons.lock_rounded,
                  color: unlocked ? boardGreen : boardPurple,
                  onTap: () {
                    SoundService.tap();
                    if (!unlocked) {
                      _showFeatureSnack(
                        context,
                        state.boardThemeUnlockLabel(selectedTheme),
                      );
                      return;
                    }
                    Navigator.pop(sheetContext);
                    state.setSnakesBoardTheme(selectedTheme);
                    state.startQuickMatch(AppState.snakesLaddersMode);
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showRewardsEconomySheet(BuildContext context, AppState state) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _HomeActionSheet(
        title: 'Rewards',
        child: Consumer<AppState>(
          builder: (context, liveState, _) {
            final chestProgress = liveState.wins % GameEconomy.winsPerGoldChest;
            final winsToChest = chestProgress == 0
                ? GameEconomy.winsPerGoldChest
                : GameEconomy.winsPerGoldChest - chestProgress;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EconomyHint(
                  icon: Icons.account_balance_wallet_rounded,
                  text:
                      '${liveState.coins} coins available. Online wins pay ${GameEconomy.onlineWinCoins} coins; other online finishes pay ${GameEconomy.onlineFinishCoins}.',
                ),
                const SizedBox(height: 10),
                _EconomyTierCard(
                  title: liveState.canClaimDailyReward
                      ? 'Daily Coins Ready'
                      : 'Daily Coins Claimed',
                  subtitle:
                      'One server-verified claim each day adds ${liveState.dailyRewardAmount} coins.',
                  accent: boardGreen,
                  icon: Icons.card_giftcard_rounded,
                ),
                const SizedBox(height: 8),
                _EconomyTierCard(
                  title:
                      '${liveState.availableGoldChests} Gold Chest${liveState.availableGoldChests == 1 ? '' : 's'} Ready',
                  subtitle: liveState.availableGoldChests > 0
                      ? 'Each chest adds ${GameEconomy.goldChestCoins} coins.'
                      : '$winsToChest more online ${winsToChest == 1 ? 'win' : 'wins'} earns the next ${GameEconomy.goldChestCoins}-coin chest.',
                  accent: goldColor,
                  icon: Icons.inventory_2_rounded,
                ),
                const SizedBox(height: 8),
                _EconomyTierCard(
                  title: 'Cosmetic Progress',
                  subtitle: liveState.rewardEconomySummary(),
                  accent: boardBlue,
                  icon: Icons.auto_awesome_rounded,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _HomeSheetButton(
                        label: liveState.canClaimDailyReward
                            ? 'Claim Daily'
                            : 'Daily Claimed',
                        icon: Icons.card_giftcard_rounded,
                        color: boardGreen,
                        onTap: () async {
                          final claimed = await liveState.claimDailyReward();
                          if (!sheetContext.mounted) return;
                          _showFeatureSnack(
                            sheetContext,
                            claimed
                                ? '+${liveState.dailyRewardAmount} coins claimed.'
                                : (liveState.socialError.isNotEmpty
                                    ? liveState.socialError
                                    : 'Daily coins are already claimed.'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HomeSheetButton(
                        label: liveState.availableGoldChests > 0
                            ? 'Open Chest'
                            : 'Chest Locked',
                        icon: Icons.inventory_2_rounded,
                        color: goldColor,
                        onTap: () async {
                          if (liveState.availableGoldChests <= 0) {
                            _showFeatureSnack(
                              sheetContext,
                              'Earn one Gold Chest every 3 online wins.',
                            );
                            return;
                          }
                          final claimed = await liveState.claimGoldChest();
                          if (!sheetContext.mounted) return;
                          _showFeatureSnack(
                            sheetContext,
                            claimed
                                ? 'Gold Chest opened. +${GameEconomy.goldChestCoins} coins.'
                                : liveState.socialError,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _HomeSheetButton(
                  label: 'View Cosmetic Shop',
                  icon: Icons.storefront_rounded,
                  color: boardPurple,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, '/shop');
                  },
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

void _showGiftShopSheet(
  BuildContext context,
  AppState state,
) {
  var selectedFriendId = state.friends.isEmpty ? '' : state.friends.first.id;
  var selectedGift = _giftShopItems.first.id;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final gift =
              _giftShopItems.firstWhere((item) => item.id == selectedGift);
          return _HomeActionSheet(
            title: 'Gift Shop',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 124,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/rush/rush_gift_ship_shop_mobile_v1.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => CustomPaint(
                        painter: _GiftShopHeroPainter(gift.colors),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pick a friend, choose a gift, then send it.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.friends.isEmpty ? 1 : state.friends.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (state.friends.isEmpty) {
                        return _ChoiceChipButton(
                          label: 'No friends',
                          subtitle: 'Add a recent opponent first',
                          selected: true,
                          accent: boardPurple,
                          onTap: () => _showFeatureSnack(
                            context,
                            'Add a recent opponent from the Friends tab first.',
                          ),
                        );
                      }
                      final friend = state.friends[index];
                      final selected = friend.id == selectedFriendId;
                      return _ChoiceChipButton(
                        label: friend.displayName,
                        subtitle: 'Accepted friend',
                        selected: selected,
                        accent: index.isEven ? boardBlue : boardGreen,
                        onTap: () =>
                            setSheetState(() => selectedFriendId = friend.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _giftShopItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 132,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final item = _giftShopItems[index];
                    return _GiftShopCard(
                      item: item,
                      selected: selectedGift == item.id,
                      onTap: () => setSheetState(() => selectedGift = item.id),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _HomeSheetButton(
                  label: selectedFriendId.isEmpty
                      ? 'Add a friend first'
                      : gift.premium
                          ? 'Preview ${gift.cost}'
                          : 'Send ${gift.cost}',
                  icon: selectedFriendId.isEmpty
                      ? Icons.person_add_alt_1_rounded
                      : gift.premium
                          ? Icons.workspace_premium_rounded
                          : Icons.send_rounded,
                  color: selectedFriendId.isEmpty
                      ? boardPurple
                      : gift.premium
                          ? boardPurple
                          : goldColor,
                  onTap: () async {
                    SoundService.tap();
                    if (selectedFriendId.isEmpty) {
                      _showFeatureSnack(
                        context,
                        'Add and accept a recent opponent before sending gifts.',
                      );
                      return;
                    }
                    if (gift.premium) {
                      _showFeatureSnack(
                        context,
                        'Premium gift purchases are currently unavailable.',
                      );
                      return;
                    }
                    final message = await state.sendFriendGift(
                      selectedFriendId,
                      gift.id,
                    );
                    if (!sheetContext.mounted) return;
                    if (message == 'Gift sent.') {
                      final friend = state.friends
                          .where((item) => item.id == selectedFriendId)
                          .firstOrNull;
                      Navigator.pop(sheetContext);
                      _showFeatureSnack(
                        context,
                        '${gift.title} sent to ${friend?.displayName ?? 'friend'}.',
                      );
                    } else {
                      _showFeatureSnack(context, message);
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

typedef _PrivateRoomIntent = ({String action, String mode, String code});

Future<void> _showPrivateRoomSheet(
  BuildContext context,
  AppState state,
) async {
  final codeController = TextEditingController();
  var players = 2;
  final intent = await showModalBottomSheet<_PrivateRoomIntent>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottom = MediaQuery.of(sheetContext).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final mode = _privateModeForPlayers(players);
            return _HomeActionSheet(
              title: 'Private Room',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create an invite code or join a friend. The table starts when all selected seats are filled.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final count in const [2, 3, 4]) ...[
                        Expanded(
                          child: _PlayerCountButton(
                            count: count,
                            selected: players == count,
                            onTap: () => setSheetState(() => players = count),
                          ),
                        ),
                        if (count != 4) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _HomeSheetButton(
                    label: 'Create Code',
                    icon: Icons.add_link_rounded,
                    color: boardGreen,
                    onTap: () {
                      SoundService.tap();
                      Navigator.pop(sheetContext, (
                        action: 'create',
                        mode: mode,
                        code: '',
                      ));
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Invite code',
                      hintStyle: TextStyle(color: Colors.white.withAlpha(140)),
                      filled: true,
                      fillColor: const Color(0x88250631),
                      prefixIcon:
                          const Icon(Icons.vpn_key_rounded, color: goldColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0x55FFD426)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: goldColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeSheetButton(
                          label: 'Join Code',
                          icon: Icons.login_rounded,
                          color: boardBlue,
                          onTap: () {
                            final code = codeController.text.trim();
                            if (code.isEmpty) {
                              _showHomeSnack(context, 'Enter an invite code.');
                              return;
                            }
                            SoundService.tap();
                            Navigator.pop(sheetContext, (
                              action: 'join',
                              mode: mode,
                              code: code,
                            ));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HomeSheetButton(
                          label: 'Play Offline',
                          icon: Icons.person_rounded,
                          color: boardPurple,
                          onTap: () {
                            SoundService.tap();
                            Navigator.pop(sheetContext, (
                              action: 'offline',
                              mode: mode,
                              code: '',
                            ));
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
      );
    },
  );
  codeController.dispose();
  if (intent == null) return;
  switch (intent.action) {
    case 'create':
      state.createPrivateRoom(intent.mode);
      return;
    case 'join':
      state.joinPrivateRoom(intent.code);
      return;
    case 'offline':
      state.startOfflineMatch(intent.mode);
      return;
  }
}

class _HomeActionSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _HomeActionSheet({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        constraints: BoxConstraints(maxHeight: maxHeight),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
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
                      color: Colors.white70, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSheetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeSheetButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Color.lerp(color, Colors.white, 0.24)!, color],
          ),
          border: Border.all(color: goldColor, width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EconomyHint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EconomyHint({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x8A19031F),
        border: Border.all(color: goldColor.withAlpha(150)),
      ),
      child: Row(
        children: [
          Icon(icon, color: goldColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withAlpha(225),
                fontSize: 12.5,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EconomyTierCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _EconomyTierCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Color.lerp(accent, Colors.white, 0.15)!.withAlpha(190),
            accent.withAlpha(120),
          ],
        ),
        border: Border.all(color: goldColor.withAlpha(135)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xAA25042F),
              border: Border.all(color: goldColor, width: 1.4),
            ),
            child: Icon(icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 10),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(215),
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
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

class _ChoiceChipButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _ChoiceChipButton({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 128,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              Color.lerp(accent, Colors.white, selected ? 0.25 : 0.08)!,
              accent.withAlpha(selected ? 230 : 145),
            ],
          ),
          border: Border.all(
            color: selected ? goldColor : Colors.white.withAlpha(80),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: goldColor,
              child: Text(
                label.substring(0, 1),
                style: const TextStyle(
                  color: Color(0xFF3A0430),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withAlpha(205),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
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

class _GiftShopCard extends StatelessWidget {
  final _GiftShopItem item;
  final bool selected;
  final VoidCallback onTap;

  const _GiftShopCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.colors[0].withAlpha(selected ? 240 : 185),
              item.colors[1].withAlpha(selected ? 225 : 150),
              item.colors[2].withAlpha(selected ? 215 : 145),
            ],
          ),
          border: Border.all(
            color: selected ? goldColor : Colors.white.withAlpha(85),
            width: selected ? 2.4 : 1.1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: goldColor.withAlpha(110), blurRadius: 14)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 92,
                  height: 62,
                  child: Image.asset(
                    item.asset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                    ),
                  ),
                ),
                Icon(
                  item.premium
                      ? Icons.workspace_premium_rounded
                      : Icons.monetization_on_rounded,
                  color: goldColor,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(210),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${item.rarity}  •  ${item.cost}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFF18F),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftShopHeroPainter extends CustomPainter {
  final List<Color> colors;

  const _GiftShopHeroPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final rect = Offset.zero & size;
    p.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors.first.withAlpha(220),
        colors[1].withAlpha(160),
        const Color(0xFF25042F),
      ],
    ).createShader(rect);
    canvas.drawRRect(RRect.fromRectXY(rect, 18, 18), p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = goldColor.withAlpha(190);
    canvas.drawRRect(RRect.fromRectXY(rect.deflate(1), 17, 17), p);
    p.style = PaintingStyle.fill;

    final hull = Path()
      ..moveTo(size.width * 0.15, size.height * 0.62)
      ..lineTo(size.width * 0.82, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.84,
        size.width * 0.26,
        size.height * 0.83,
      )
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.75,
        size.width * 0.15,
        size.height * 0.62,
      );
    p.color = const Color(0xFF8B38FF);
    canvas.drawPath(hull.shift(const Offset(0, 3)), p);
    p.shader = const LinearGradient(
      colors: [Color(0xFFFFD426), Color(0xFFFF7D21)],
    ).createShader(rect);
    canvas.drawPath(hull, p);
    p.shader = null;

    final sail = Path()
      ..moveTo(size.width * 0.45, size.height * 0.18)
      ..lineTo(size.width * 0.45, size.height * 0.62)
      ..lineTo(size.width * 0.72, size.height * 0.55)
      ..close();
    p.color = const Color(0xFFFF36B8);
    canvas.drawPath(sail, p);
    p.color = Colors.white.withAlpha(210);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.28), 8, p);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.25), 6, p);
    p.color = goldColor;
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.22 + i * 0.11), size.height * 0.58),
        4,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GiftShopHeroPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _PlayerCountButton extends StatelessWidget {
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _PlayerCountButton({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? const Color(0xFF7A20C8) : const Color(0x88250631),
          border: Border.all(
            color: selected ? goldColor : Colors.white.withAlpha(70),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          '$count Players',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: count == 4 ? 12 : 13,
            fontWeight: FontWeight.w900,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}

class _HomeThemeButton extends StatelessWidget {
  final _HomeBoardThemeOption option;
  final bool selected;
  final bool locked;
  final String status;
  final double width;
  final VoidCallback onTap;

  const _HomeThemeButton({
    required this.option,
    required this.selected,
    required this.locked,
    required this.status,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              option.colors[0].withAlpha(selected ? 235 : 170),
              option.colors[1].withAlpha(selected ? 230 : 150),
            ],
          ),
          border: Border.all(
            color: selected ? goldColor : Colors.white.withAlpha(85),
            width: selected ? 2.2 : 1.1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: goldColor.withAlpha(105), blurRadius: 12)]
              : null,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        option.asset,
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => CustomPaint(
                          painter: _HomeThemePreviewPainter(option),
                        ),
                      ),
                      CustomPaint(
                        painter: _HomeThemePreviewPainter(
                          option,
                          paintShell: false,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: locked ? Colors.black.withAlpha(80) : null,
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xAA16001F)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: locked
                      ? const Color(0xDD25052D)
                      : const Color(0xDD087C3C),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: goldColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      locked ? Icons.lock_rounded : Icons.check_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeThemePreviewPainter extends CustomPainter {
  static const Map<int, int> _ladders = {
    6: 26,
    23: 37,
    48: 68,
    65: 85,
    79: 99,
  };

  static const Map<int, int> _snakes = {
    47: 13,
    57: 35,
    84: 64,
    93: 68,
  };

  static const Map<int, Color> _coloredCells = {
    100: boardRed,
    97: boardBlue,
    94: boardGreen,
    90: boardRed,
    79: boardPurple,
    67: boardRed,
    60: boardBlue,
    49: boardPurple,
    36: boardGreen,
    25: boardBlue,
    20: boardRed,
    9: boardPurple,
  };

  static const Set<int> _starCells = {
    97,
    94,
    90,
    79,
    67,
    49,
    36,
    25,
    20,
    9,
  };

  final _HomeBoardThemeOption option;
  final bool paintShell;

  const _HomeThemePreviewPainter(this.option, {this.paintShell = true});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final shell = Offset.zero & size;
    if (paintShell) {
      p.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _shellColors,
      ).createShader(shell);
      canvas.drawRRect(RRect.fromRectXY(shell, 8, 8), p);
      p.shader = null;
    }

    final side = paintShell
        ? math.min(size.width, size.height) * 0.90
        : math.min(size.height * 0.82, size.width * 0.56);
    final board = Rect.fromCenter(
      center: shell.center,
      width: side,
      height: side,
    );
    p.color = const Color(0x66000000);
    canvas.drawRRect(
      RRect.fromRectXY(board.shift(const Offset(2, 2)), 8, 8),
      p,
    );
    p.color = const Color(0xFFFFF5C9);
    canvas.drawRRect(RRect.fromRectXY(board, 8, 8), p);

    final inner = board.deflate(side * 0.035);
    final cell = inner.width / 10;
    for (var number = 1; number <= 100; number++) {
      final rect = _cellRect(number, inner, cell);
      final themed = _coloredCells[number];
      p.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: themed == null ? _plainCellColors(number) : _themeCell(themed),
      ).createShader(rect);
      canvas.drawRect(rect, p);
      p.shader = null;
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.55
        ..color = _gridColor;
      canvas.drawRect(rect, p);
      p.style = PaintingStyle.fill;
      if (_starCells.contains(number)) {
        _drawStar(canvas, rect.center, cell * 0.24, p);
      }
    }

    _drawLadders(canvas, inner, cell, p);
    _drawSnakes(canvas, inner, cell, p);

    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = goldColor;
    canvas.drawRRect(RRect.fromRectXY(board.deflate(1), 8, 8), p);
    p.style = PaintingStyle.fill;
  }

  List<Color> get _shellColors {
    switch (option.id) {
      case 'royal':
        return const [
          Color(0xFFFFF8C9),
          Color(0xFFD69BFF),
          Color(0xFF4B1688),
        ];
      case 'neon':
        return const [
          Color(0xFFB9FFFF),
          Color(0xFFFF4CE2),
          Color(0xFF160051),
        ];
      case 'classic':
        return const [
          Color(0xFFFFF8D6),
          Color(0xFFFFC448),
          Color(0xFF7D430E),
        ];
      case 'carnival':
      default:
        return const [
          Color(0xFFFFF7A6),
          Color(0xFFFFB61C),
          Color(0xFF713100),
        ];
    }
  }

  Color get _gridColor {
    switch (option.id) {
      case 'royal':
        return const Color(0xD18F58C9);
      case 'neon':
        return const Color(0xD129BFFF);
      case 'classic':
        return const Color(0xD6BE8A25);
      case 'carnival':
      default:
        return const Color(0xD9D8A115);
    }
  }

  List<Color> _plainCellColors(int number) {
    final even = (number + (number ~/ 10)).isEven;
    switch (option.id) {
      case 'royal':
        return even
            ? const [Color(0xFFFFF8FF), Color(0xFFF4DFFF)]
            : const [Color(0xFFFFF2F8), Color(0xFFEAD8FF)];
      case 'neon':
        return even
            ? const [Color(0xFFFFFFFF), Color(0xFFE1FBFF)]
            : const [Color(0xFFFFF5FF), Color(0xFFEAF8FF)];
      case 'classic':
        return even
            ? const [Color(0xFFFFFDF4), Color(0xFFFFE7B5)]
            : const [Color(0xFFFFF7E1), Color(0xFFFFE0A0)];
      case 'carnival':
      default:
        return even
            ? const [Color(0xFFFFFDF0), Color(0xFFFFF0C7)]
            : const [Color(0xFFFFF9E6), Color(0xFFFFEAB1)];
    }
  }

  List<Color> _themeCell(Color color) {
    switch (option.id) {
      case 'royal':
        return [Color.lerp(color, Colors.white, 0.34)!, color];
      case 'neon':
        return [Color.lerp(color, const Color(0xFF39F6FF), 0.24)!, color];
      case 'classic':
        return [Color.lerp(color, Colors.white, 0.22)!, color];
      case 'carnival':
      default:
        return [Color.lerp(color, Colors.white, 0.20)!, color];
    }
  }

  Rect _cellRect(int number, Rect board, double cell) {
    final rowFromBottom = (number - 1) ~/ 10;
    final rawCol = (number - 1) % 10;
    final col = rowFromBottom.isEven ? rawCol : 9 - rawCol;
    final row = 9 - rowFromBottom;
    return Rect.fromLTWH(
      board.left + col * cell,
      board.top + row * cell,
      cell,
      cell,
    );
  }

  Offset _cellCenter(int number, Rect board, double cell) =>
      _cellRect(number, board, cell).center;

  void _drawLadders(Canvas canvas, Rect board, double cell, Paint p) {
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, cell * 0.12)
      ..color = const Color(0xFFFFD33F);
    for (final entry in _ladders.entries) {
      final a = _cellCenter(entry.key, board, cell);
      final b = _cellCenter(entry.value, board, cell);
      final dir = b - a;
      final len = dir.distance;
      if (len == 0) continue;
      final unit = dir / len;
      final normal = Offset(-unit.dy, unit.dx) * cell * 0.15;
      canvas.drawLine(a - normal, b - normal, p);
      canvas.drawLine(a + normal, b + normal, p);
      p
        ..strokeWidth = math.max(0.9, cell * 0.07)
        ..color = const Color(0xFFFFF5A8);
      for (var i = 1; i < 5; i++) {
        final c = Offset.lerp(a, b, i / 5)!;
        canvas.drawLine(c - normal * 1.15, c + normal * 1.15, p);
      }
      p
        ..strokeWidth = math.max(1.4, cell * 0.12)
        ..color = const Color(0xFFFFD33F);
    }
    p
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;
  }

  void _drawSnakes(Canvas canvas, Rect board, double cell, Paint p) {
    final colors = _snakeColors;
    var i = 0;
    for (final entry in _snakes.entries) {
      final start = _cellCenter(entry.key, board, cell);
      final end = _cellCenter(entry.value, board, cell);
      final color = colors[i % colors.length];
      final midY = (start.dy + end.dy) / 2;
      final sway = (i.isEven ? -1 : 1) * cell * 1.15;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx + sway, midY, end.dx - sway, midY, end.dx, end.dy);
      p
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(2.4, cell * 0.24)
        ..color = Color.lerp(color, Colors.black, 0.18)!;
      canvas.drawPath(path, p);
      p
        ..strokeWidth = math.max(1.5, cell * 0.14)
        ..color = Color.lerp(color, Colors.white, 0.34)!;
      canvas.drawPath(path, p);
      p
        ..style = PaintingStyle.fill
        ..color = Color.lerp(color, Colors.white, 0.24)!;
      canvas.drawCircle(start, cell * 0.16, p);
      p.color = Colors.white.withAlpha(230);
      canvas.drawCircle(
        start.translate(-cell * 0.04, -cell * 0.03),
        cell * 0.045,
        p,
      );
      i++;
    }
    p
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt;
  }

  List<Color> get _snakeColors {
    switch (option.id) {
      case 'royal':
        return const [
          Color(0xFFFF873D),
          Color(0xFFB85CFF),
          Color(0xFF54DD78),
          Color(0xFF33B9FF),
        ];
      case 'neon':
        return const [
          Color(0xFFFF7A00),
          Color(0xFFFF4CFF),
          Color(0xFF79FF35),
          Color(0xFF20F0FF),
        ];
      case 'classic':
        return const [
          Color(0xFFFF8122),
          Color(0xFFB15CE0),
          Color(0xFF53C846),
          Color(0xFF2AA8EA),
        ];
      case 'carnival':
      default:
        return const [
          boardOrange,
          boardPurple,
          Color(0xFF56D82D),
          Color(0xFF22B7FF),
        ];
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.43;
      final a = -math.pi / 2 + i * math.pi / 5;
      final point = center + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    p
      ..style = PaintingStyle.fill
      ..color = Colors.white.withAlpha(235);
    canvas.drawPath(path, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, radius * 0.18)
      ..color = const Color(0xFFFFD426);
    canvas.drawPath(path, p);
    p.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant _HomeThemePreviewPainter oldDelegate) =>
      oldDelegate.option.id != option.id ||
      oldDelegate.paintShell != paintShell;
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
              'assets/images/rush/rush_home_royal_backdrop_mobile_v1.jpg',
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
                        value: '${state.energy}',
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
  final int level;
  final int preset;
  final String? imagePath;

  const _AvatarBadge({
    required this.level,
    required this.preset,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
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
                  : _ProfileAvatarImage(preset: preset),
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

CountrySpec _countryFor(String code) => countryByCode(code);

class _MiniFlag extends StatelessWidget {
  final CountrySpec country;
  final double width;
  final double height;

  const _MiniFlag({
    required this.country,
    this.width = 26,
    this.height = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height * 0.18),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(countryFlagEmoji(country.code)),
      ),
    );
  }
}

List<_FeatureRow> _clubRowsForState(AppState state) {
  final current = state.currentClub;
  final rows = <_FeatureRow>[];
  if (current != null) {
    rows.add(_FeatureRow(
      current.name,
      '${current.memberCount} members - rating ${current.ratingTotal}',
      '${current.contribution} PTS',
      id: current.id,
    ));
  } else {
    rows.add(const _FeatureRow(
      'No club joined',
      'Browse a club that matches your rating',
      'OPEN',
    ));
  }
  rows.addAll(
    state.clubs
        .where((club) => club.id != current?.id)
        .take(2)
        .map((club) => _FeatureRow(
              club.name,
              '${club.memberCount} members - rating ${club.minimumRating}+',
              club.ratingTotal.toString(),
              id: club.id,
            )),
  );
  return rows;
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
  var selectedSoundtrack = state.soundtrackId;
  var musicEnabled = state.musicEnabled;

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
                    DropdownButtonFormField<String>(
                      initialValue: selectedCountry,
                      isExpanded: true,
                      menuMaxHeight: 360,
                      dropdownColor:
                          palette.dark ? const Color(0xFF3B0A48) : Colors.white,
                      iconEnabledColor: palette.stroke,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: palette.dark
                            ? const Color(0x66250A31)
                            : const Color(0xFFFFF4FC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: palette.stroke.withAlpha(130),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: palette.stroke, width: 2),
                        ),
                      ),
                      selectedItemBuilder: (context) => [
                        for (final country in allCountries)
                          Row(
                            children: [
                              _MiniFlag(country: country),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  '${country.name} (${country.code})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                      items: [
                        for (final country in allCountries)
                          DropdownMenuItem<String>(
                            value: country.code,
                            child: Row(
                              children: [
                                _MiniFlag(country: country),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    country.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(country.code),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedCountry = value);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    _SheetLabel('Avatar', palette: palette),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: profileAvatarCatalog.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final avatar = profileAvatarCatalog[i];
                          final unlocked = state.isAvatarUnlocked(i);
                          return _ProfileAvatarChoice(
                            avatar: avatar,
                            selected: selectedAvatar == i &&
                                selectedImagePath == null,
                            unlocked: unlocked,
                            status: state.avatarUnlockLabel(i),
                            palette: palette,
                            onTap: () {
                              if (!unlocked) {
                                unawaited(
                                  _showAvatarUnlockDialog(
                                    sheetContext,
                                    avatar,
                                    state.avatarUnlockLabel(i),
                                  ),
                                );
                                return;
                              }
                              setSheetState(() {
                                selectedAvatar = i;
                                selectedImagePath = null;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _SheetLabel('Soundtrack', palette: palette),
                        ),
                        Text(
                          musicEnabled ? 'Music on' : 'Music off',
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Switch.adaptive(
                          value: musicEnabled,
                          activeTrackColor: goldColor,
                          onChanged: (value) {
                            setSheetState(() => musicEnabled = value);
                            state.setMusicEnabled(value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 8.0;
                        final itemWidth = (constraints.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final option in const [
                              (
                                id: SoundtrackCatalog.victorySpark,
                                label: 'Victory Spark',
                                icon: Icons.military_tech_rounded,
                              ),
                              (
                                id: SoundtrackCatalog.royalAdventure,
                                label: 'Royal',
                                icon: Icons.emoji_events_rounded,
                              ),
                              (
                                id: SoundtrackCatalog.luckyDiceDance,
                                label: 'Lucky Dice',
                                icon: Icons.casino_rounded,
                              ),
                              (
                                id: SoundtrackCatalog.starlightBoardwalk,
                                label: 'Starlight',
                                icon: Icons.auto_awesome_rounded,
                              ),
                              (
                                id: SoundtrackCatalog.diceParade,
                                label: 'Dice Parade',
                                icon: Icons.music_note_rounded,
                              ),
                              (
                                id: SoundtrackCatalog.carnivalCrown,
                                label: 'Carnival Crown',
                                icon: Icons.celebration_rounded,
                              ),
                            ])
                              SizedBox(
                                width: itemWidth,
                                child: _SoundtrackChoice(
                                  label: option.label,
                                  icon: option.icon,
                                  selected: musicEnabled &&
                                      selectedSoundtrack == option.id,
                                  palette: palette,
                                  onTap: () {
                                    setSheetState(() {
                                      selectedSoundtrack = option.id;
                                      musicEnabled = true;
                                    });
                                    state.setSoundtrack(option.id);
                                  },
                                ),
                              ),
                          ],
                        );
                      },
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

Future<void> _showAvatarUnlockDialog(
  BuildContext context,
  ProfileAvatarSpec avatar,
  String status,
) async {
  final openShop = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF3A084A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: goldColor, width: 2),
      ),
      title: Text(
        avatar.label,
        style: const TextStyle(
          color: goldColor,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: ClipOval(child: _ProfileAvatarImage(preset: avatar.preset)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              avatar.rarity == AvatarRarity.premium
                  ? '$status. Premium avatars unlock only after a verified Google Play purchase.'
                  : '$status to unlock this rare avatar.',
              style: const TextStyle(
                color: Colors.white,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Close'),
        ),
        if (avatar.rarity == AvatarRarity.premium)
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.storefront_rounded),
            label: const Text('View Shop'),
          ),
      ],
    ),
  );
  if (openShop == true && context.mounted) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.pushNamed('/shop');
  }
}

class _ProfileAvatarPreview extends StatelessWidget {
  final int preset;
  final String? imagePath;

  const _ProfileAvatarPreview({
    required this.preset,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
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
            : _ProfileAvatarImage(preset: preset),
      ),
    );
  }
}

class _ProfileAvatarChoice extends StatelessWidget {
  final ProfileAvatarSpec avatar;
  final bool selected;
  final bool unlocked;
  final String status;
  final _RushPalette palette;
  final VoidCallback onTap;

  const _ProfileAvatarChoice({
    required this.avatar,
    required this.selected,
    required this.unlocked,
    required this.status,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82,
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: selected
              ? palette.stroke.withAlpha(palette.dark ? 50 : 85)
              : (palette.dark ? const Color(0x55200A2D) : Colors.white70),
          border: Border.all(
              color: selected ? palette.stroke : Colors.white24,
              width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipOval(
                    child: _ProfileAvatarImage(preset: avatar.preset),
                  ),
                  if (!unlocked)
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x99000000),
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
              style: TextStyle(
                color: palette.text,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: avatar.rarity == AvatarRarity.premium
                    ? goldColor
                    : palette.muted,
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

class _ProfileAvatarImage extends StatelessWidget {
  final int preset;

  const _ProfileAvatarImage({required this.preset});

  @override
  Widget build(BuildContext context) {
    final avatar = avatarForPreset(preset);
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

class _SoundtrackChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final _RushPalette palette;
  final VoidCallback onTap;

  const _SoundtrackChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label soundtrack',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: selected
                  ? const [Color(0xFFFFC928), Color(0xFFE06C13)]
                  : const [Color(0xFF711466), Color(0xFF351044)],
            ),
            border: Border.all(
              color: selected ? const Color(0xFFFFF19A) : palette.stroke,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    color: filled ? const Color(0xFF3D1600) : palette.text,
                    size: 18),
                const SizedBox(width: 7),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: filled ? const Color(0xFF3D1600) : palette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
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
  final AppState state;
  final _RushPalette palette;

  const _RewardStrip({required this.state, required this.palette});

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
                    label: state.canClaimDailyReward ? 'Daily +150' : 'Claimed',
                    art: _RewardArt.gift,
                    start: const Color(0xFFE93836),
                    end: const Color(0xFFFFB21C),
                    onTap: () async {
                      final adService = LevelPlayAdService.instance;
                      final earned = await adService.showRewarded(
                        placementName: 'DailyGift',
                      );
                      if (!context.mounted) return;
                      if (adService.isConfigured && !earned) {
                        _showHomeSnack(
                          context,
                          'Bonus ad is loading. Try again soon.',
                        );
                        return;
                      }
                      final claimed = await state.claimDailyReward();
                      if (!context.mounted) return;
                      _showHomeSnack(
                        context,
                        claimed
                            ? 'Daily points claimed. +${state.dailyRewardAmount} coins.'
                            : (state.socialError.isNotEmpty
                                ? state.socialError
                                : 'Daily points already claimed. Come back tomorrow.'),
                      );
                    },
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _RewardTile(
                    palette: palette,
                    label: 'Gift Shop',
                    art: _RewardArt.giftShip,
                    start: const Color(0xFF33D2FF),
                    end: const Color(0xFF1450D4),
                    onTap: () => _showGiftShopSheet(context, state),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: _RewardTile(
                    palette: palette,
                    label: 'Rewards',
                    art: _RewardArt.medal,
                    start: const Color(0xFFFFD426),
                    end: const Color(0xFFE03068),
                    onTap: () => _showRewardsEconomySheet(context, state),
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

enum _RewardArt { gift, giftShip, shield, medal, lock, snakes }

class _RewardTile extends StatelessWidget {
  final _RushPalette palette;
  final String label;
  final _RewardArt art;
  final Color start;
  final Color end;
  final VoidCallback onTap;

  const _RewardTile({
    required this.palette,
    required this.label,
    required this.art,
    required this.start,
    required this.end,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
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
              Positioned.fill(
                  child: CustomPaint(painter: _RewardTilePattern())),
              Align(
                alignment: const Alignment(0, -0.28),
                child: SizedBox(
                  width: 48,
                  height: 44,
                  child: CustomPaint(
                    painter:
                        _RewardIconPainter(art: art, start: start, end: end),
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
      case _RewardArt.giftShip:
        _drawGiftShip(canvas, size, p);
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
      case _RewardArt.snakes:
        _drawSnake(canvas, size, p);
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

  void _drawGiftShip(Canvas canvas, Size size, Paint p) {
    final hull = Path()
      ..moveTo(size.width * 0.13, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.86,
          size.width * 0.87, size.height * 0.62)
      ..lineTo(size.width * 0.78, size.height * 0.45)
      ..lineTo(size.width * 0.22, size.height * 0.45)
      ..close();
    p.shader = LinearGradient(
      colors: [Color.lerp(start, Colors.white, 0.28)!, start, end],
    ).createShader(Offset.zero & size);
    canvas.drawPath(hull, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFF08A);
    canvas.drawPath(hull, p);
    p.style = PaintingStyle.fill;

    final gift = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.34),
      width: size.width * 0.38,
      height: size.height * 0.28,
    );
    p.color = const Color(0xFFFF2E4C);
    canvas.drawRRect(RRect.fromRectXY(gift, 5, 5), p);
    p.color = goldColor;
    canvas.drawRect(
        Rect.fromCenter(
            center: gift.center, width: gift.width * 0.18, height: gift.height),
        p);
    canvas.drawRect(
        Rect.fromCenter(
            center: gift.center, width: gift.width, height: gift.height * 0.18),
        p);
    p.color = const Color(0xFFFFF8C8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.38, size.height * 0.18),
        width: size.width * 0.18,
        height: size.height * 0.12,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.62, size.height * 0.18),
        width: size.width * 0.18,
        height: size.height * 0.12,
      ),
      p,
    );

    for (final dx in [0.28, 0.50, 0.72]) {
      p.color = const Color(0xFFFFF3A6);
      canvas.drawCircle(Offset(size.width * dx, size.height * 0.61),
          size.shortestSide * 0.035, p);
    }
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

  void _drawSnake(Canvas canvas, Size size, Paint p) {
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.66)
      ..cubicTo(size.width * 0.38, size.height * 0.35, size.width * 0.62,
          size.height * 0.82, size.width * 0.76, size.height * 0.28);
    p
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.18
      ..shader = LinearGradient(colors: [start, end])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, p);
    p
      ..shader = null
      ..strokeWidth = size.shortestSide * 0.06
      ..color = const Color(0xFFFFF1A6);
    for (int i = 0; i < 5; i++) {
      final t = i / 4;
      final x = size.width * (0.29 + t * 0.40);
      final y =
          size.height * (0.62 + math.sin(t * math.pi * 2.2) * 0.12 - t * 0.18);
      canvas.drawLine(
        Offset(x - size.width * 0.025, y - size.height * 0.025),
        Offset(x + size.width * 0.025, y + size.height * 0.025),
        p,
      );
    }
    p
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.butt
      ..color = end;
    final head = Offset(size.width * 0.76, size.height * 0.28);
    canvas.drawOval(
      Rect.fromCenter(
          center: head, width: size.width * 0.24, height: size.height * 0.18),
      p,
    );
    p.color = Colors.white;
    canvas.drawCircle(head.translate(-size.width * 0.03, -size.height * 0.025),
        size.shortestSide * 0.025, p);
    p.color = const Color(0xFF280019);
    canvas.drawCircle(head.translate(-size.width * 0.022, -size.height * 0.02),
        size.shortestSide * 0.012, p);
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
        final available = math.max(0.0, box.maxHeight - rowGap - bottomGap);
        final scale = math.min(1.0, available / math.max(1.0, needed - rowGap));
        final bigHeight = baseBigHeight * scale;
        final smallHeight = baseSmallHeight * scale;
        final boardHeight = math.max(
          0.0,
          box.maxHeight - bigHeight - smallHeight - rowGap - bottomGap,
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
                        label: 'Private',
                        headline: '',
                        subtitle: 'Code',
                        start: const Color(0xFF8C35FF),
                        end: const Color(0xFF5010A8),
                        art: _ModeArt.private,
                        onTap: () =>
                            unawaited(_showPrivateRoomSheet(context, state)),
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
                            'assets/images/rush/rush_snakes_ladders_mode_mobile_v1.jpg',
                        onTap: () => _showSnakesBoardSheet(context, state),
                      ),
                    ),
                    SizedBox(width: smallGap),
                    Expanded(
                      child: _ModeTile(
                        palette: palette,
                        pulse: pulse,
                        label: 'Offline',
                        headline: '',
                        subtitle: 'Solo play',
                        start: const Color(0xFFFFC22D),
                        end: const Color(0xFFE47B00),
                        art: _ModeArt.quick,
                        onTap: () => state.startOfflineMatch('classic_2p'),
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
        rows: _friendRowsForState(state),
        actions: const ['Invite', 'Add', 'Gift', 'Chat', 'Remove'],
        onAction: (context, action) => _handleFeatureAction(context, action),
      );
    }
    if (index == 3) {
      return _FeatureTabStage(
        palette: palette,
        title: 'Clubs',
        subtitle: state.currentClub == null
            ? 'Join one persistent club at a time'
            : '${state.currentClub!.tag} - ${state.currentClub!.memberCount} members',
        accent: const Color(0xFFFF5D6C),
        icon: Icons.shield_rounded,
        rows: _clubRowsForState(state),
        actions: state.currentClub == null
            ? const ['Browse', 'Leaders', 'Progress']
            : const ['Browse', 'Leaders', 'Progress', 'Leave'],
        bannerAsset:
            'assets/images/rush/rush_club_rewards_banner_mobile_v1.jpg',
        onAction: (context, action) => _handleFeatureAction(context, action),
      );
    }
    if (index == 4) {
      return _FeatureTabStage(
        palette: palette,
        title: 'Rewards',
        subtitle: 'Verified payouts and unlocks',
        accent: const Color(0xFFFFB22D),
        icon: Icons.inventory_2_rounded,
        rows: [
          _FeatureRow(
            state.canClaimDailyReward ? 'Daily Coins' : 'Daily Claimed',
            'One claim per calendar day',
            '+${state.dailyRewardAmount}',
          ),
          _FeatureRow(
            'Gold Chest',
            state.availableGoldChests > 0
                ? '${state.availableGoldChests} ready now'
                : 'Earn one every 3 online wins',
            '+${GameEconomy.goldChestCoins}',
          ),
          const _FeatureRow(
            'Online Match',
            'Win +${GameEconomy.onlineWinCoins} / finish +${GameEconomy.onlineFinishCoins}',
            'FAIR',
          ),
        ],
        actions: const ['Daily', 'Open Chest', 'Shop'],
        onAction: (context, action) => _handleFeatureAction(context, action),
      );
    }
    return _LobbyStage(state: state, palette: palette, pulse: pulse);
  }

  void _handleFeatureAction(BuildContext context, String action) {
    SoundService.tap();
    switch (action) {
      case 'Invite':
        _showFriendInviteSheet(context, state);
        return;
      case 'Add':
        _showFriendAddSheet(context, state);
        return;
      case 'Gift':
        _showFriendGiftSheet(context, state);
        return;
      case 'Chat':
        _showFriendChatSheet(context, state);
        return;
      case 'Remove':
        _showFriendRemoveSheet(context, state);
        return;
      case 'Browse':
        _showClubJoinSheet(context, state);
        return;
      case 'Leaders':
        _showLeaderboardSheet(context, state);
        return;
      case 'Progress':
        _showClubProgressSheet(context, state);
        return;
      case 'Leave':
        unawaited(_leaveClub(context));
        return;
      case 'Daily':
        unawaited(_claimDailyFromRewards(context));
        return;
      case 'Open Chest':
        unawaited(_showChestOpenSheet(context, state));
        return;
      case 'Shop':
        Navigator.pushNamed(context, '/shop');
        return;
    }
  }

  Future<void> _leaveClub(BuildContext context) async {
    final message = await state.leaveClub();
    if (!context.mounted) return;
    _showFeatureSnack(context, message);
  }

  Future<void> _claimDailyFromRewards(BuildContext context) async {
    final claimed = await state.claimDailyReward();
    if (!context.mounted) return;
    _showFeatureSnack(
      context,
      claimed
          ? '+${state.dailyRewardAmount} daily coins claimed.'
          : (state.socialError.isNotEmpty
              ? state.socialError
              : 'Daily coins are already claimed.'),
    );
  }

  void _showClubProgressSheet(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _HomeActionSheet(
        title: 'Club Progress',
        child: Consumer<AppState>(
          builder: (_, liveState, __) {
            final club = liveState.currentClub;
            if (club == null) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _EconomyHint(
                    icon: Icons.shield_outlined,
                    text:
                        'Join one club to earn contribution points from completed online matches.',
                  ),
                  const SizedBox(height: 12),
                  _HomeSheetButton(
                    label: 'Browse Clubs',
                    icon: Icons.search_rounded,
                    color: boardRed,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showClubJoinSheet(context, liveState);
                    },
                  ),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/rush/rush_club_rewards_banner_mobile_v1.jpg',
                    height: 112,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                _EconomyTierCard(
                  title: '${club.contribution} Contribution Points',
                  subtitle:
                      'Online wins add ${GameEconomy.clubWinContribution}; other completed online matches add ${GameEconomy.clubFinishContribution}.',
                  accent: boardRed,
                  icon: Icons.bolt_rounded,
                ),
                const SizedBox(height: 8),
                _EconomyTierCard(
                  title: '${club.ratingTotal} Combined Rating',
                  subtitle:
                      '${club.memberCount} members currently represent ${club.name} on the club leaderboard.',
                  accent: goldColor,
                  icon: Icons.leaderboard_rounded,
                ),
                const SizedBox(height: 8),
                const _EconomyHint(
                  icon: Icons.info_outline_rounded,
                  text:
                      'Switching clubs resets only club contribution. Personal coins, wins, rating, and cosmetics stay with your account.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFriendInviteSheet(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _HomeActionSheet(
          title: 'Invite Friends',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.friends.isEmpty)
                const _EconomyHint(
                  icon: Icons.person_add_alt_1_rounded,
                  text:
                      'Add a recent opponent first, or create a code and share it outside the app.',
                )
              else
                for (var i = 0; i < state.friends.length; i++) ...[
                  _FeatureListTile(
                    row: _FeatureRow(
                      state.friends[i].displayName,
                      'Invite ready',
                      state.friends[i].rating.toString(),
                      id: state.friends[i].id,
                    ),
                    accent: i.isEven ? boardBlue : boardGreen,
                    index: i,
                  ),
                  if (i != state.friends.length - 1) const SizedBox(height: 8),
                ],
              const SizedBox(height: 10),
              Text(
                'Invites create a private room code so friends land on the same table.',
                style: TextStyle(
                  color: Colors.white.withAlpha(215),
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _HomeSheetButton(
                label: 'Create Private Code',
                icon: Icons.add_link_rounded,
                color: boardBlue,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Future<void>.delayed(
                    const Duration(milliseconds: 280),
                  );
                  if (context.mounted) {
                    await _showPrivateRoomSheet(context, state);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFriendAddSheet(BuildContext context, AppState state) {
    final selected = <String>{};
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return _HomeActionSheet(
            title: 'Recent Opponents',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.incomingFriendRequests.isNotEmpty) ...[
                  const _EconomyHint(
                    icon: Icons.mark_email_unread_rounded,
                    text:
                        'Accept requests before they join your friends circle.',
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0;
                      i < state.incomingFriendRequests.length;
                      i++) ...[
                    _FeatureListTile(
                      row: _FeatureRow(
                        state.incomingFriendRequests[i].displayName,
                        'Incoming request',
                        state.incomingFriendRequests[i].rating.toString(),
                      ),
                      accent: boardGreen,
                      index: i,
                    ),
                    const SizedBox(height: 6),
                    _FeatureActionButton(
                      label:
                          'Accept ${state.incomingFriendRequests[i].displayName}',
                      accent: boardGreen,
                      onTap: () async {
                        final message = await state.acceptFriend(
                          state.incomingFriendRequests[i].id,
                        );
                        if (!sheetContext.mounted) return;
                        _showFeatureSnack(context, message);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                if (state.recentOpponents.isEmpty)
                  const _EconomyHint(
                    icon: Icons.sports_esports_rounded,
                    text:
                        'No recent online opponents yet. Finish an online match and they will appear here.',
                  )
                else
                  for (var i = 0; i < state.recentOpponents.length; i++) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setSheetState(() {
                        final id = state.recentOpponents[i].id;
                        selected.contains(id)
                            ? selected.remove(id)
                            : selected.add(id);
                      }),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                selected.contains(state.recentOpponents[i].id)
                                    ? goldColor
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _FeatureListTile(
                          row: _FeatureRow(
                            state.recentOpponents[i].displayName,
                            selected.contains(state.recentOpponents[i].id)
                                ? 'Selected'
                                : 'Recent opponent',
                            state.recentOpponents[i].rating.toString(),
                          ),
                          accent: i.isEven ? goldColor : boardPurple,
                          index: i,
                        ),
                      ),
                    ),
                    if (i != state.recentOpponents.length - 1)
                      const SizedBox(height: 8),
                  ],
                const SizedBox(height: 12),
                _FeatureActionButton(
                  label: selected.isEmpty
                      ? 'Select Opponents'
                      : 'Send ${selected.length} Request${selected.length == 1 ? '' : 's'}',
                  accent: boardGreen,
                  onTap: () async {
                    if (selected.isEmpty) {
                      _showFeatureSnack(
                        context,
                        'Select at least one recent opponent.',
                      );
                      return;
                    }
                    var message = 'Friend requests sent.';
                    for (final id in selected) {
                      message = await state.requestFriend(id);
                      if (message != 'Friend request sent.') break;
                    }
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    _showFeatureSnack(context, message);
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showFriendGiftSheet(BuildContext context, AppState state) {
    _showGiftShopSheet(context, state);
  }

  Future<void> _showFriendChatSheet(
      BuildContext context, AppState state) async {
    final controller = TextEditingController();
    await state.loadFriendMessages();
    if (!context.mounted) {
      controller.dispose();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<AppState>(builder: (context, liveState, _) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: _HomeActionSheet(
              title: 'Friends Circle Chat',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EconomyHint(
                    icon: liveState.canUseChat
                        ? Icons.forum_rounded
                        : Icons.lock_rounded,
                    text: liveState.canUseChat
                        ? 'You see messages from direct accepted friends only. Friends who do not know each other remain separate.'
                        : 'Chat unlocks for players age 13 and older.',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 210,
                    child: !liveState.canUseChat
                        ? const Center(
                            child: Text(
                              'Chat locked',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : liveState.friendMessages.isEmpty
                            ? const Center(
                                child: Text(
                                  'No messages yet. Say hello to your friends.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                itemCount: liveState.friendMessages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final message =
                                      liveState.friendMessages[index];
                                  final mine =
                                      message.senderId == liveState.playerId;
                                  return Align(
                                    alignment: mine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(maxWidth: 280),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: mine
                                            ? boardBlue.withAlpha(210)
                                            : const Color(0xCC3B0B4B),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: mine ? goldColor : boardPurple,
                                        ),
                                      ),
                                      child: Text(
                                        '${message.senderName}: ${message.message}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    enabled: liveState.canUseChat,
                    maxLength: 160,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Message your friends circle',
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xAA21042C),
                      suffixIcon: IconButton(
                        tooltip: 'Send message',
                        icon: const Icon(Icons.send_rounded, color: goldColor),
                        onPressed: liveState.canUseChat
                            ? () async {
                                final result = await liveState
                                    .sendFriendMessage(controller.text);
                                if (!sheetContext.mounted) return;
                                if (result.isEmpty) {
                                  controller.clear();
                                } else {
                                  _showFeatureSnack(context, result);
                                }
                              }
                            : null,
                      ),
                    ),
                    onSubmitted: liveState.canUseChat
                        ? (value) async {
                            final result =
                                await liveState.sendFriendMessage(value);
                            if (!sheetContext.mounted) return;
                            if (result.isEmpty) controller.clear();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
    controller.dispose();
  }

  void _showFriendRemoveSheet(BuildContext context, AppState state) {
    var selectedFriendId = state.friends.isEmpty ? '' : state.friends.first.id;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return _HomeActionSheet(
            title: 'Remove Friend',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.friends.isEmpty)
                  const _EconomyHint(
                    icon: Icons.group_off_rounded,
                    text: 'There are no accepted friends to remove.',
                  )
                else
                  for (var i = 0; i < state.friends.length; i++) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setSheetState(
                        () => selectedFriendId = state.friends[i].id,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedFriendId == state.friends[i].id
                                ? goldColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _FeatureListTile(
                          row: _FeatureRow(
                            state.friends[i].displayName,
                            selectedFriendId == state.friends[i].id
                                ? 'Selected for removal'
                                : 'Accepted friend',
                            state.friends[i].rating.toString(),
                          ),
                          accent: i.isEven ? boardBlue : boardGreen,
                          index: i,
                        ),
                      ),
                    ),
                    if (i != state.friends.length - 1)
                      const SizedBox(height: 8),
                  ],
                const SizedBox(height: 12),
                _FeatureActionButton(
                  label: 'Remove Selected',
                  accent: boardRed,
                  onTap: () async {
                    if (selectedFriendId.isEmpty) {
                      _showFeatureSnack(context, 'Select a friend first.');
                      return;
                    }
                    final message = await state.removeFriend(selectedFriendId);
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    _showFeatureSnack(context, message);
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _showChestOpenSheet(BuildContext context, AppState state) async {
    final claimed = await state.claimGoldChest();
    if (!context.mounted) return;
    if (!claimed) {
      _showFeatureSnack(
        context,
        state.socialError.isNotEmpty
            ? state.socialError
            : 'No Gold Chest is ready. Earn another after 3 more wins.',
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _HomeActionSheet(
          title: 'Gold Chest',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_rounded, color: goldColor, size: 56),
              const SizedBox(height: 8),
              const Text(
                'Gold Chest opened\n+500 coins added',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 12),
              _FeatureActionButton(
                label: 'Collect',
                accent: boardGreen,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLeaderboardSheet(BuildContext context, AppState state) {
    final rows = [
      _FeatureRow(state.displayName, 'You', state.rating.toString()),
      for (final club in ([...state.clubs]
            ..sort((a, b) => b.ratingTotal.compareTo(a.ratingTotal)))
          .take(3))
        _FeatureRow(
          club.name,
          '${club.memberCount} members',
          club.ratingTotal.toString(),
        ),
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

  void _showClubJoinSheet(BuildContext context, AppState state) {
    var selectedClubId = state.currentClub?.id ??
        (state.clubs.isEmpty ? '' : state.clubs.first.id);
    unawaited(state.refreshSocial());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => Consumer<AppState>(
            builder: (context, liveState, _) {
              final available = liveState.clubs;
              final selected = available
                  .where((club) => club.id == selectedClubId)
                  .firstOrNull;
              return _HomeActionSheet(
                title: liveState.currentClub == null
                    ? 'Join a Club'
                    : 'Switch Club',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/rush/rush_club_rewards_banner_mobile_v1.jpg',
                        height: 104,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _EconomyHint(
                      icon: Icons.shield_rounded,
                      text:
                          'One account can join one club. Switching clubs resets club contribution but never removes personal coins or wins.',
                    ),
                    const SizedBox(height: 10),
                    if (available.isEmpty)
                      _EconomyHint(
                        icon: liveState.socialLoading
                            ? Icons.sync_rounded
                            : Icons.cloud_off_rounded,
                        text: liveState.socialLoading
                            ? 'Loading clubs...'
                            : (liveState.socialError.isNotEmpty
                                ? liveState.socialError
                                : 'No clubs are available right now.'),
                      )
                    else
                      for (var i = 0; i < available.length; i++) ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setSheetState(
                            () => selectedClubId = available[i].id,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: selectedClubId == available[i].id
                                    ? goldColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: _FeatureListTile(
                              row: _FeatureRow(
                                available[i].name,
                                '${available[i].memberCount} members - rating ${available[i].minimumRating}+',
                                available[i].tag,
                              ),
                              accent: i.isEven ? boardRed : boardBlue,
                              index: i,
                            ),
                          ),
                        ),
                        if (i != available.length - 1)
                          const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 12),
                    _FeatureActionButton(
                      label: selected == null
                          ? 'Refresh Clubs'
                          : (liveState.currentClub?.id == selected.id
                              ? 'Current Club'
                              : 'Join ${selected.name}'),
                      accent: selected == null
                          ? boardBlue
                          : const Color(0xFFFF5D6C),
                      onTap: () async {
                        if (selected == null) {
                          await liveState.refreshSocial();
                          return;
                        }
                        if (liveState.currentClub?.id == selected.id) {
                          _showFeatureSnack(
                            sheetContext,
                            'You are already in ${selected.name}.',
                          );
                          return;
                        }
                        final message = await liveState.joinClub(selected.id);
                        if (!sheetContext.mounted) return;
                        if (message == 'Club joined.') {
                          _showFeatureSnack(
                            sheetContext,
                            'Joined ${selected.name}.',
                          );
                          Navigator.pop(sheetContext);
                        } else {
                          _showFeatureSnack(sheetContext, message);
                        }
                      },
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

class _FeatureRow {
  final String? id;
  final String title;
  final String subtitle;
  final String value;

  const _FeatureRow(this.title, this.subtitle, this.value, {this.id});
}

class _FeatureTabStage extends StatelessWidget {
  final _RushPalette palette;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final List<_FeatureRow> rows;
  final List<String> actions;
  final String? bannerAsset;
  final void Function(BuildContext context, String action) onAction;

  const _FeatureTabStage({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.rows,
    required this.actions,
    this.bannerAsset,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 370;
        final dense = box.maxHeight < 430;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            narrow ? 12 : 16,
            dense ? 4 : 10,
            narrow ? 12 : 16,
            dense ? 4 : 8,
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(dense ? 10 : (narrow ? 14 : 18)),
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
                      SizedBox(height: dense ? 8 : 14),
                      if (bannerAsset != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            bannerAsset!,
                            height: dense ? 52 : (narrow ? 82 : 96),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                        SizedBox(height: dense ? 6 : 10),
                      ],
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              for (int i = 0; i < rows.length; i++) ...[
                                _FeatureListTile(
                                  row: rows[i],
                                  accent: accent,
                                  index: i,
                                  compact: dense,
                                ),
                                if (i != rows.length - 1)
                                  SizedBox(height: dense ? 6 : 8),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: dense ? 8 : 14),
                      LayoutBuilder(
                        builder: (context, actionBox) {
                          final columns =
                              actions.length > 3 ? 3 : actions.length;
                          final spacing = columns > 1 ? 8.0 : 0.0;
                          final width = columns == 0
                              ? actionBox.maxWidth
                              : (actionBox.maxWidth - spacing * (columns - 1)) /
                                  columns;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: 8,
                            children: [
                              for (final action in actions)
                                SizedBox(
                                  width: width,
                                  child: _FeatureActionButton(
                                    label: action,
                                    accent: accent,
                                    compact: dense || actions.length > 3,
                                    onTap: () => onAction(context, action),
                                  ),
                                ),
                            ],
                          );
                        },
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
  final bool compact;

  const _FeatureListTile({
    required this.row,
    required this.accent,
    required this.index,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 48 : 58,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0x7A140020),
        border: Border.all(color: Colors.white.withAlpha(35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: compact ? 15 : 19,
            backgroundColor: accent,
            child: Text(
              row.title.isEmpty ? '?' : row.title.substring(0, 1),
              style: const TextStyle(
                color: Color(0xFF3A0430),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 14 : 15,
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
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.emoji_events_rounded,
              color: goldColor, size: compact ? 16 : 18),
          const SizedBox(width: 4),
          Text(
            row.value,
            style: TextStyle(
              color: goldColor,
              fontSize: compact ? 12 : 13,
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
  final bool compact;

  const _FeatureActionButton({
    required this.label,
    required this.accent,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: compact ? 38 : 44,
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
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w900,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
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
                    'assets/images/rush/rush_home_royal_board_cutout_mobile_v1.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    frameBuilder: (context, child, frame, loadedSynchronously) {
                      if (loadedSynchronously || frame != null) return child;
                      return const CustomPaint(
                        painter: _HomeBoardLoadingPainter(),
                      );
                    },
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

class _HomeBoardLoadingPainter extends CustomPainter {
  const _HomeBoardLoadingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final boardWidth = size.width * 0.82;
    final boardHeight = math.min(size.height * 0.86, boardWidth * 0.70);
    final board = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: boardWidth,
      height: boardHeight,
    );
    final paint = Paint()..isAntiAlias = true;

    paint
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectXY(board.shift(const Offset(0, 8)), 18, 18),
      paint,
    );
    paint.maskFilter = null;
    paint.color = const Color(0xFFFFD04B);
    canvas.drawRRect(RRect.fromRectXY(board, 18, 18), paint);

    final inner = board.deflate(math.max(5, boardWidth * 0.014));
    final colors = const [boardRed, boardBlue, boardGreen, boardYellow];
    final quadrants = [
      Rect.fromLTRB(inner.left, inner.top, inner.center.dx, inner.center.dy),
      Rect.fromLTRB(inner.center.dx, inner.top, inner.right, inner.center.dy),
      Rect.fromLTRB(inner.left, inner.center.dy, inner.center.dx, inner.bottom),
      Rect.fromLTRB(
          inner.center.dx, inner.center.dy, inner.right, inner.bottom),
    ];
    for (var i = 0; i < quadrants.length; i++) {
      paint.color = colors[i];
      canvas.drawRect(quadrants[i], paint);
    }

    final lane = inner.width * 0.15;
    paint.color = const Color(0xFFFFF9DC);
    canvas.drawRect(
      Rect.fromCenter(
        center: inner.center,
        width: lane,
        height: inner.height,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: inner.center,
        width: inner.width,
        height: lane,
      ),
      paint,
    );

    final centerSize = lane * 1.35;
    final center = Rect.fromCenter(
      center: inner.center,
      width: centerSize,
      height: centerSize,
    );
    for (var i = 0; i < 4; i++) {
      final start = -math.pi / 4 + i * math.pi / 2;
      paint.color = colors[i];
      canvas.drawArc(center, start, math.pi / 2, true, paint);
    }

    for (var i = 0; i < quadrants.length; i++) {
      final zone = Rect.fromCenter(
        center: quadrants[i].center,
        width: quadrants[i].width * 0.62,
        height: quadrants[i].height * 0.62,
      );
      paint.color = const Color(0x55FFFFFF);
      canvas.drawRRect(RRect.fromRectXY(zone, 12, 12), paint);
      final radius = math.min(zone.width, zone.height) * 0.085;
      for (final dx in const [-0.22, 0.22]) {
        for (final dy in const [-0.22, 0.22]) {
          final center = Offset(
            zone.center.dx + zone.width * dx,
            zone.center.dy + zone.height * dy,
          );
          paint.color = const Color(0x55000000);
          canvas.drawCircle(center.translate(0, radius * 0.35), radius, paint);
          paint.color = Color.lerp(colors[i], Colors.white, 0.18)!;
          canvas.drawCircle(center, radius, paint);
          paint.color = Colors.white.withAlpha(150);
          canvas.drawCircle(
            center.translate(-radius * 0.25, -radius * 0.28),
            radius * 0.24,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HomeBoardLoadingPainter oldDelegate) => false;
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
            child: LayoutBuilder(
              builder: (context, box) {
                final designHeight = widget.large ? 94.0 : 66.0;
                final density =
                    (box.maxHeight / designHeight).clamp(0.66, 1.0).toDouble();
                final showSubtitle =
                    widget.subtitle.isNotEmpty && box.maxHeight >= 58;
                return Container(
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
                                painter:
                                    _ModePatternPainter(widget.palette.dark))),
                        if (widget.imageAsset == null)
                          Positioned(
                            left: (widget.large ? 18 : 10) * density,
                            top: (widget.large ? 13 : 8) * density,
                            width: (widget.large ? 78 : 38) * density,
                            height: (widget.large ? 70 : 38) * density,
                            child: _ModeGlyph(
                              art: widget.art,
                              large: widget.large,
                            ),
                          ),
                        if (widget.headline.isNotEmpty)
                          Positioned(
                            right: (widget.large ? 15 : 10) * density,
                            top: (widget.large ? 8 : 9) * density,
                            child: Text(
                              widget.headline,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (widget.large ? 70 : 25) * density,
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
                          left: (widget.large ? 22 : 8) * density,
                          right: (widget.large ? 86 : 8) * density,
                          bottom: (widget.large ? 10 : 6) * density,
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
                              if (showSubtitle) ...[
                                SizedBox(height: 3 * density),
                                Text(
                                  widget.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: widget.large
                                      ? TextAlign.left
                                      : TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(210),
                                    fontSize:
                                        (widget.large ? 12 : 11) * density,
                                    fontWeight: FontWeight.w800,
                                    shadows: const [
                                      Shadow(
                                          color: Colors.black54, blurRadius: 3)
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
                );
              },
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
      _NavSpec(_NavArt.chest, 'Rewards'),
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
