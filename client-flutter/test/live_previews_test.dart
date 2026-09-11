import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ludo_rush/data/profile_catalog.dart';
import 'package:ludo_rush/data/table_reactions.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/screens/shop_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:ludo_rush/theme/app_theme.dart';
import 'package:ludo_rush/widgets/live_board_preview.dart';
import 'package:ludo_rush/widgets/live_item_preview.dart';
import 'package:ludo_rush/widgets/profile_avatar.dart';
import 'package:ludo_rush/widgets/six_celebration.dart';

final captureKey = GlobalKey();
Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_QA')) return;
  final boundary =
      captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/qa/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppState state;
  setUp(() async {
    state = AppState(PrefsService());
    if (const bool.fromEnvironment('CAPTURE_QA')) {
      final file = File('C:/Windows/Fonts/arial.ttf');
      if (await file.exists()) {
        for (final family in ['Roboto', 'sans-serif', 'Ahem']) {
          await (FontLoader(family)
                ..addFont(file
                    .readAsBytes()
                    .then((value) => ByteData.sublistView(value))))
              .load();
        }
      }
    }
  });
  tearDown(() => state.dispose());
  Widget app(Widget child) => RepaintBoundary(
      key: captureKey,
      child: ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: state.navigatorKey,
              theme: AppTheme.dark(),
              home: child,
              routes: {
                '/game': (_) => const Scaffold(body: Text('Match started'))
              })));

  testWidgets(
      'all fifteen board designs render differently with isolated demo state',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final signatures = <String>{};
    for (final snakes in [false, true]) {
      for (final theme in [
        'carnival',
        'royal',
        'neon',
        'classic',
        'ocean',
        'astral',
        'volcano',
        if (snakes) 'jungle'
      ]) {
        await tester.pumpWidget(app(Scaffold(
            body: LiveBoardPreview(
                key: ValueKey('$snakes-$theme'),
                theme: theme,
                snakes: snakes,
                live: false))));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        final boundary = captureKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final pixels = (await image.toByteData())!.buffer.asUint8List();
          final signature = [
            for (var i = 0; i < pixels.length; i += 101) pixels[i]
          ].join(',');
          expect(signatures.add(signature), isTrue,
              reason: '$snakes/$theme duplicates another board');
          image.dispose();
        });
        expect(state.coins, 500);
        expect(state.lastSnapshot, isNull);
        await capture(tester, '${snakes ? 'snakes' : 'ludo'}-$theme');
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('avatar opens motion preview before equipping on a compact phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const ShopScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.scrollUntilVisible(find.text('Teal Spark'), 350,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text('Teal Spark'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('LIVE PREVIEW'), findsOneWidget);
    expect(state.avatarPreset, 0);
    await capture(tester, 'avatar-preview');
    await tester.ensureVisible(find.text('Equip avatar'));
    await tester.pump();
    await tester.tap(find.text('Equip avatar'));
    await tester.pump();
    expect(state.avatarPreset, 1);
    expect(state.coins, 500);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'new snake boards render in the shop strip and preview before equip',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const ShopScreen()));
    final picker = find.byKey(const ValueKey('snakes-theme-picker'));
    await tester.scrollUntilVisible(picker, 300,
        scrollable: find.byType(Scrollable).first);
    final strip =
        find.descendant(of: picker, matching: find.byType(Scrollable));
    final ocean = find.byKey(const ValueKey('snakes-theme-ocean'));
    await tester.scrollUntilVisible(ocean, 160, scrollable: strip);
    await tester.pump();
    expect(find.descendant(of: ocean, matching: find.byType(LiveBoardPreview)),
        findsOneWidget);
    await tester.tap(ocean);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ocean Voyage Snakes & Ladders'), findsOneWidget);
    expect(state.snakesBoardTheme, 'carnival');
    await tester.tap(find.text('Equip board'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.snakesBoardTheme, 'ocean');
    final volcano = find.byKey(const ValueKey('snakes-theme-volcano'));
    await tester.scrollUntilVisible(volcano, 150, scrollable: strip);
    await tester.tap(volcano);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Lava Citadel Snakes & Ladders'), findsOneWidget);
    expect(find.text('Equip board'), findsNothing);
    expect(state.snakesBoardTheme, 'ocean');
    expect(state.coins, 500);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('locked snake skin and dice can be previewed without unlocking',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(Builder(
        builder: (context) => Scaffold(
            body: TextButton(
                onPressed: () => showLiveItemPreview(context,
                    title: 'Neon Snakes',
                    preview:
                        const LiveBoardPreview(theme: 'neon', snakes: true),
                    description: 'Locked preview',
                    actionLabel: 'Premium'),
                child: const Text('Preview'))))));
    await tester.tap(find.text('Preview'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(state.isBoardThemeUnlocked('neon'), isFalse);
    expect(state.coins, 500);
    await capture(tester, 'locked-snake-preview');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rules precede actual offline match startup and can be cancelled',
      (tester) async {
    await tester.pumpWidget(app(Scaffold(
        body: TextButton(
            onPressed: () => state.startOfflineMatch('snakes_ladders'),
            child: const Text('Play')))));
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(state.lastSnapshot, isNull);
    expect(find.textContaining('no extra roll'), findsOneWidget);
    expect(find.textContaining('practice'), findsOneWidget);
    await capture(tester, 'rules');
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(state.lastSnapshot, isNull);
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it — start match'));
    await tester.pumpAndSettle();
    expect(state.lastSnapshot?.mode, 'snakes_ladders');
    expect(state.coins, 500);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('six celebration expires and a later six can replay it',
      (tester) async {
    var sequence = 0;
    late StateSetter update;
    await tester.pumpWidget(app(StatefulBuilder(builder: (context, setState) {
      update = setState;
      return Stack(children: [
        SixCelebration(sequence: sequence),
        Positioned(
            width: 80,
            height: 80,
            child: ProfileAvatarView(preset: 23, celebration: sequence))
      ]);
    })));
    for (var i = 0; i < 2; i++) {
      update(() => sequence++);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('🎲 SIX!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('🎲 SIX!'), findsNothing);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
      'all six possible local dice values survive with every token in the yard',
      () {
    for (var value = 1; value <= 6; value++) {
      final game = AppState(PrefsService(), random: FixedDice(value))
        ..playerId = 'me'
        ..localMatchActive = true
        ..lastSnapshot = GameSnapshot(
            seats: const [
              SeatState(
                  seat: 0, playerId: 'me', displayName: 'Me', isBot: false),
              SeatState(
                  seat: 1, playerId: 'op', displayName: 'Other', isBot: true)
            ],
            pieces: [
              for (var seat = 0; seat < 2; seat++)
                for (var token = 0; token < 4; token++)
                  PieceState(
                      pieceId: 's${seat}_p$token',
                      seat: seat,
                      state: 'yard',
                      progress: -1,
                      trackIndex: -1)
            ],
            diceValue: 0,
            currentTurnSeat: 0,
            status: 'playing',
            availableMoves: const [],
            winnerPlayerId: '',
            mode: 'classic_2p');
      game.rollDice();
      expect(game.lastRollValue, value);
      game.dispose();
    }
  });

  test(
      'expanded catalog preserves purchases and adds unique free avatar identities',
      () {
    expect(profileAvatarCatalog.length, 24);
    expect(profileAvatarCatalog.map((avatar) => avatar.id).toSet().length, 24);
    expect(profileAvatarCatalog.where((avatar) => avatar.emoji != null).length,
        12);
    expect(state.isAvatarUnlocked(23), isTrue);
    expect(state.isAvatarUnlocked(8), isFalse);
    expect(tableEmojis.toSet().length, 32);
    expect(tablePhrases.toSet().length, 24);
  });
}

class FixedDice implements math.Random {
  final int value;
  FixedDice(this.value);
  @override
  int nextInt(int max) => value - 1;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}
