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
import 'package:ludo_rush/state/app_state.dart';
import 'package:ludo_rush/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture real iOS game screens', (tester) async {
    debugPrint('IOS_STORE_STAGE starting fixture');
    final prefs = PrefsService();
    await prefs.init().timeout(const Duration(seconds: 20));
    debugPrint('IOS_STORE_STAGE preferences ready');
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
      debugPrint('IOS_STORE_STAGE ready ${screen.runtimeType}');
    }

    await show(const HomeScreen());
    debugPrint('IOS_STORE_STAGE capturing home');
    await binding.takeScreenshot('01-home');
    debugPrint('IOS_STORE_STAGE captured home');
    await tester.tap(find.text('Snakes').first);
    await tester.pump(const Duration(seconds: 1));
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
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
