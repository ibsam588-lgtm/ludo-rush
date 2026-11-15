// This entry point is only used by the iOS store-media runner. Production main
// never imports it or its sample match state.
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/screens/game_screen.dart';
import 'package:ludo_rush/screens/home_screen.dart';
import 'package:ludo_rush/screens/shop_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/services/app_platform_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:ludo_rush/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Record real animation frames between test actions for the App Preview.
  // The test binding's default only paints pumped frames and pointer fades.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('capture real iOS game screens', (tester) async {
    debugPrint('IOS_STORE_STAGE starting fixture');
    final prefs = PrefsService();
    await prefs.init().timeout(const Duration(seconds: 20));
    debugPrint('IOS_STORE_STAGE preferences ready');
    final version = await AppPlatformService.getVersionInfo();
    expect(
      version.buildNumber,
      greaterThan(0),
      reason: 'The native iOS app channel must be registered.',
    );
    final state = AppState(prefs, random: Random(24))
      ..displayName = 'James'
      ..playerId = 'store_james'
      ..age = 25
      ..coins = 2200
      ..wins = 12
      ..gamesPlayed = 20
      ..startChoiceSeen = true
      ..gameTutorialSeen = true;

    Future<void> show(Widget screen) async {
      debugPrint('IOS_STORE_STAGE showing ${screen.runtimeType}');
      // Dispose the previous navigator, including modal routes. Replacing only
      // MaterialApp.home preserves its navigator and can capture an old dialog.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: state.navigatorKey,
            scaffoldMessengerKey: state.scaffoldMessengerKey,
            theme: AppTheme.dark(),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: screen,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      // Decode the full-resolution assets before the native screenshot.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byType(screen.runtimeType), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      debugPrint('IOS_STORE_STAGE ready ${screen.runtimeType}');
    }

    await show(const HomeScreen());
    debugPrint('IOS_STORE_STAGE capturing home');
    await binding.takeScreenshot('01-home');
    debugPrint('IOS_STORE_STAGE captured home');
    await tester.tap(find.text('Snakes').first);
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await binding.takeScreenshot('02-snakes-boards');
    await show(const ShopScreen());
    await binding.takeScreenshot('03-shop');

    for (final snakes in [false, true]) {
      state.localMatchActive = true;
      state.lastSnapshot = GameSnapshot.fromJson({
        'roomId': 'store-preview',
        'mode': snakes ? 'snakes_ladders' : 'classic_4p',
        'status': 'playing',
        'currentTurnSeat': 0,
        'diceValue': 0,
        'availableMoves': <String>[],
        'seats': [
          for (var seat = 0; seat < 4; seat++)
            {
              'seat': seat,
              'playerId': seat == 0 ? 'store_james' : 'bot_$seat',
              'displayName': ['James', 'Maya', 'Leo', 'Ava'][seat],
              'isBot': seat != 0,
            },
        ],
        'pieces': [
          for (var seat = 0; seat < 4; seat++)
            for (var piece = 0; piece < (snakes ? 1 : 4); piece++)
              {
                'pieceId': '${seat}_$piece',
                'seat': seat,
                'state': snakes || piece == 0 ? 'track' : 'yard',
                'progress': snakes
                    ? 24 + seat * 13
                    : (piece == 0 ? 5 + seat * 3 : -1),
                'trackIndex': snakes
                    ? -1
                    : (piece == 0 ? (5 + seat * 16) % 52 : -1),
              },
        ],
      });
      await show(const GameScreen());
      await binding.takeScreenshot(snakes ? '05-snakes-game' : '04-ludo-game');
      // Exercise the actual local game rules and animated turns in the video.
      for (var turn = 0; turn < 3; turn++) {
        state.rollDice();
        await tester.pump(const Duration(milliseconds: 1400));
        final moves = state.lastSnapshot?.availableMoves ?? <String>[];
        if (moves.isNotEmpty) state.movePiece(moves.first);
        await tester.pump(const Duration(seconds: 2));
      }
    }

    if (const bool.fromEnvironment('IOS_CAPTURE_REVIEWS')) {
      state.localMatchActive = false;
      state.lastSnapshot = null;
      const products = [
        ('dice.ruby', 'Ruby Dice', 'Dice'),
        ('dice.cosmic', 'Cosmic Dice', 'Dice'),
        ('board.neon', 'Neon Board', 'Ludo'),
        ('avatar.premium_cosmic_empress', 'Cosmic Empress', 'Avatars'),
        ('avatar.premium_gold_champion', 'Gold Champion', 'Avatars'),
        ('avatar.premium_neon_heroine', 'Neon Heroine', 'Avatars'),
        ('avatar.premium_emerald_prince', 'Emerald Prince', 'Avatars'),
        ('coins.stack_1200', 'Coin Stack', 'Rewards'),
        ('coins.chest_3500', 'Gem Chest', 'Rewards'),
        ('coins.vault_7500', 'Royal Vault', 'Rewards'),
      ];
      for (final (id, title, category) in products) {
        await show(const ShopScreen());
        final categoryChip = find.byKey(ValueKey('shop-category-$category'));
        await tester.ensureVisible(categoryChip);
        await tester.pump(const Duration(milliseconds: 150));
        await tester.tap(categoryChip);
        await tester.pump(const Duration(milliseconds: 300));
        final scrollable = find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first;
        final product = find.text(title);
        await tester.scrollUntilVisible(
          product,
          240,
          scrollable: scrollable,
          maxScrolls: 40,
        );
        // Re-layout after scrollUntilVisible's final scroll, then keep the tap
        // away from the fixed shop footer. An immediate second ensureVisible
        // otherwise uses the previous frame's coordinates on tall board cards.
        await tester.pump(const Duration(milliseconds: 150));
        await Scrollable.ensureVisible(
          tester.element(product),
          alignment: 0.35,
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(
          product.hitTestable(),
          findsOneWidget,
          reason: '$title must be reachable above the shop footer',
        );
        await tester.tap(product);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(Dialog), findsOneWidget);
        expect(
          find.descendant(of: find.byType(Dialog), matching: product),
          findsOneWidget,
        );
        await binding.takeScreenshot('review-$id');
        await tester.tap(find.byTooltip('Close preview'));
        await tester.pump(const Duration(milliseconds: 300));
        debugPrint('IOS_STORE_STAGE captured product $id');
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  }, timeout: const Timeout(Duration(minutes: 4)));
}
