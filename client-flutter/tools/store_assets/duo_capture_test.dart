// Run locally with Flutter's renderer. Never run store capture on Actions.
// This renders the real production widgets at each Duo viewport; it does not
// resize a phone screenshot or invent a replacement interface.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/screens/game_screen.dart';
import 'package:ludo_rush/screens/home_screen.dart';
import 'package:ludo_rush/screens/shop_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:ludo_rush/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  if (!const bool.fromEnvironment('LEVELPLAY_PRODUCTION')) {
    throw StateError(
      'Pass --dart-define=LEVELPLAY_PRODUCTION=true without ad IDs for store capture.',
    );
  }
  if (Platform.environment['GITHUB_ACTIONS'] == 'true') {
    throw StateError(
      'Capture store screenshots locally, never on GitHub runners.',
    );
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'render real game UI for both Duo displays',
    (tester) async {
      final sdk = Platform.environment['FLUTTER_ROOT']!;
      await tester.runAsync(() async {
        final font = FontLoader('sans-serif');
        for (final file in [
          'roboto-regular.ttf',
          'roboto-bold.ttf',
          'roboto-black.ttf',
        ]) {
          font.addFont(
            Future.value(
              ByteData.sublistView(
                File(
                  '$sdk/bin/cache/artifacts/material_fonts/$file',
                ).readAsBytesSync(),
              ),
            ),
          );
        }
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                File(
                  '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
                ).readAsBytesSync(),
              ),
            ),
          );
        await icons.load();
        final emojiPath = Platform.environment['STORE_EMOJI_FONT'];
        if (emojiPath != null) {
          final emoji = FontLoader('Store Emoji')
            ..addFont(
              Future.value(
                ByteData.sublistView(File(emojiPath).readAsBytesSync()),
              ),
            );
          await emoji.load();
        }
      });
      debugPrint('DUO_CAPTURE fonts ready');
      // This executable fixture lives outside test/ to keep media out of CI.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      final prefs = PrefsService();
      await tester.runAsync(prefs.init);
      debugPrint('DUO_CAPTURE preferences ready');
      final state = AppState(prefs, random: Random(24))
        ..displayName = 'James'
        ..playerId = 'store_james'
        ..age = 25
        ..coins = 2200
        ..wins = 12
        ..gamesPlayed = 20
        ..startChoiceSeen = true
        ..gameTutorialSeen = true;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() {
        state.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        debugDefaultTargetPlatformOverride = null;
      });
      final boundaryKey = GlobalKey();
      Future<void> show(Widget screen) async {
        debugPrint('DUO_CAPTURE showing ${screen.runtimeType}');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: ChangeNotifierProvider.value(
              value: state,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.dark().copyWith(
                  textTheme: AppTheme.dark().textTheme.apply(
                    fontFamilyFallback: const ['Store Emoji'],
                  ),
                ),
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: screen,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }

      Future<void> capture(Directory folder, String name) async {
        debugPrint('DUO_CAPTURE saving ${folder.path}/$name');
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 3);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${folder.path}/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }

      for (final (format, width, height) in [
        ('iphone-duo-outer', 1398.0, 2034.0),
        ('iphone-duo-inner', 2007.0, 2853.0),
      ]) {
        tester.view.devicePixelRatio = 3;
        tester.view.physicalSize = Size(width, height);
        final output = Directory('build/ios-store/$format')
          ..createSync(recursive: true);
        state.localMatchActive = false;
        state.lastSnapshot = null;
        await show(const HomeScreen());
        await capture(output, '01-home');
        await tester.tap(find.text('Snakes').first);
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await capture(output, '02-snakes-boards');
        await show(const ShopScreen());
        await capture(output, '03-shop');
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
          await capture(output, snakes ? '05-snakes-game' : '04-ludo-game');
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
