import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/models/match_moment.dart';
import 'package:ludo_rush/models/match_rewards.dart';
import 'package:ludo_rush/screens/game_screen.dart';
import 'package:ludo_rush/screens/results_screen.dart';
import 'package:ludo_rush/screens/shop_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:ludo_rush/theme/app_theme.dart';
import 'package:ludo_rush/widgets/board_motion.dart';
import 'package:ludo_rush/widgets/dice_widget.dart';
import 'package:ludo_rush/widgets/ludo_board.dart';
import 'package:ludo_rush/widgets/snakes_ladders_board.dart';

PieceState piece(int progress) => PieceState(
    pieceId: 's0_p0',
    seat: 0,
    state: progress < 0
        ? 'yard'
        : progress >= 57
            ? 'finished'
            : progress >= 52
                ? 'home'
                : 'track',
    progress: progress,
    trackIndex: -1);

GameSnapshot boardSnapshot(int progress,
        {bool snakes = false, int dice = 0, bool finished = false}) =>
    GameSnapshot(
        seats: const [
          SeatState(seat: 0, playerId: 'me', displayName: 'Alex', isBot: false),
          SeatState(
              seat: 1, playerId: 'other', displayName: 'Maya', isBot: true)
        ],
        pieces: [
          piece(progress),
          PieceState(
              pieceId: 's1_p0',
              seat: 1,
              state: 'track',
              progress: snakes ? 23 : 14,
              trackIndex: -1)
        ],
        diceValue: dice,
        currentTurnSeat: 0,
        status: finished ? 'finished' : 'playing',
        availableMoves: dice > 0 ? ['s0_p0'] : [],
        winnerPlayerId: finished ? 'me' : '',
        mode: snakes ? 'snakes_ladders' : 'classic_2p');

final captureKey = GlobalKey();
Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_QA')) return;
  await tester.runAsync(() async {
    final boundary =
        captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/qa/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(() async {
    if (const bool.fromEnvironment('CAPTURE_QA')) {
      const flutterRoot = String.fromEnvironment('QA_FLUTTER_ROOT');
      final icons = File(
          '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
      if (await icons.exists())
        await (FontLoader('MaterialIcons')
              ..addFont(icons.readAsBytes().then(ByteData.sublistView)))
            .load();
      final file = File('C:/Windows/Fonts/arial.ttf');
      if (await file.exists()) {
        for (final family in ['sans-serif', 'Roboto']) {
          await (FontLoader(family)
                ..addFont(file.readAsBytes().then(ByteData.sublistView)))
              .load();
        }
      }
    }
  });

  test('Ludo hops across track and home lane, enters yard and handles captures',
      () {
    final journey =
        PieceJourney.between(piece(49), piece(55), snakes: false, dice: 6)!;
    expect(journey.legs.map((leg) => leg.to), [50, 51, 52, 53, 54, 55]);
    expect(journey.sample(1).leg.to, 55);
    expect(
        PieceJourney.between(piece(-1), piece(0), snakes: false, dice: 6)!
            .legs
            .single
            .kind,
        TravelKind.hop);
    expect(
        PieceJourney.between(piece(24), piece(-1), snakes: false, dice: 2)!
            .legs
            .single
            .kind,
        TravelKind.capture);
    expect(
        PieceJourney.between(piece(56), piece(57), snakes: false, dice: 1)!
            .sample(1)
            .at(57)
            .state,
        'finished');
  });

  test('Snakes travel visits the trigger before a climb or slide', () {
    final climb =
        PieceJourney.between(piece(5), piece(26), snakes: true, dice: 1)!;
    expect(climb.legs.map((leg) => leg.to), [6, 26]);
    expect(climb.legs.last.kind, TravelKind.climb);
    final slide =
        PieceJourney.between(piece(42), piece(13), snakes: true, dice: 5)!;
    expect(slide.legs.map((leg) => leg.to), [43, 44, 45, 46, 47, 13]);
    expect(slide.legs.last.kind, TravelKind.slide);
    expect(PieceJourney.between(piece(99), piece(99), snakes: true, dice: 6),
        isNull);
  });

  test('avatar moments distinguish climbs, slides and wins', () {
    expect(
        MatchMoment.between(boardSnapshot(5, snakes: true, dice: 1),
                boardSnapshot(26, snakes: true))!
            .mood,
        AvatarMood.climb);
    expect(
        MatchMoment.between(boardSnapshot(42, snakes: true, dice: 5),
                boardSnapshot(13, snakes: true))!
            .mood,
        AvatarMood.slide);
    expect(
        MatchMoment.between(boardSnapshot(99, snakes: true, dice: 1),
                boardSnapshot(100, snakes: true, finished: true))!
            .mood,
        AvatarMood.winner);
    expect(MatchMoment.between(boardSnapshot(4), boardSnapshot(4)), isNull);
  });

  for (final snakes in [false, true]) {
    testWidgets(
        '${snakes ? 'Snakes' : 'Ludo'} animates updates and cancels travel for reduced motion',
        (tester) async {
      final changes = <bool>[];
      Widget app(int progress, {bool reduced = false}) => MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Center(
                  child: SizedBox.square(
                      dimension: 350,
                      child: snakes
                          ? SnakesLaddersBoard(
                              snapshot: boardSnapshot(progress,
                                  snakes: true, dice: 1),
                              mySeat: 0,
                              boardTheme: 'ocean',
                              onMotionChanged: changes.add,
                              onPieceTap: (_) {})
                          : LudoBoard(
                              snapshot: boardSnapshot(progress, dice: 3),
                              mySeat: 0,
                              boardTheme: 'astral',
                              onMotionChanged: changes.add,
                              onPieceTap: (_) {})))));
      await tester.pumpWidget(app(snakes ? 5 : 0));
      await tester.pumpWidget(app(snakes ? 26 : 3));
      await tester.pump(const Duration(milliseconds: 120));
      expect(changes, contains(true));
      await tester.pump(const Duration(seconds: 2));
      expect(changes.last, isFalse);
      await tester.pumpWidget(app(snakes ? 27 : 6));
      await tester.pump(const Duration(milliseconds: 30));
      expect(changes.last, isTrue);
      await tester.pumpWidget(app(snakes ? 27 : 6, reduced: true));
      await tester.pump();
      expect(changes.last, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
      'dice settles at original size and reduced motion reveals the result immediately',
      (tester) async {
    final key = GlobalKey<DiceWidgetState>();
    Widget app(bool reduced) => MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Center(child: DiceWidget(key: key))));
    await tester.pumpWidget(app(false));
    var completed = 0;
    key.currentState!.startRoll(4, () => completed++);
    await tester.pump(const Duration(milliseconds: 660));
    await tester.pump(const Duration(milliseconds: 400));
    expect(completed, 1);
    expect(
        tester
            .widget<ScaleTransition>(find.byType(ScaleTransition).last)
            .scale
            .value,
        1);
    await tester.pumpWidget(app(true));
    key.currentState!.startRoll(6, () => completed++);
    expect(completed, 2);
    expect(key.currentState!.displayValue, 6);
  });

  Widget app(AppState state, Widget child) => RepaintBoundary(
      key: captureKey,
      child: ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark(),
              home: child)));

  for (final (theme, size) in [
    ('ocean', const Size(390, 844)),
    ('astral', const Size(390, 844)),
    ('volcano', const Size(390, 844)),
    ('ocean', const Size(320, 568)),
    ('astral', const Size(320, 568)),
  ]) {
    testWidgets('$theme surroundings fit at $size and show the active turn',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = AppState(PrefsService())
        ..playerId = 'me'
        ..displayName = 'Alex'
        ..avatarPreset = 0
        ..ludoBoardTheme = theme
        ..snakesBoardTheme = theme
        ..lastSnapshot = boardSnapshot(5, snakes: theme == 'ocean');
      await tester.pumpWidget(app(state, const GameScreen()));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump();
      expect(find.text('Your turn'), findsOneWidget);
      await capture(tester, 'match-$theme-${size.width.toInt()}');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    });
  }

  testWidgets(
      'shop categories isolate larger boards and retain equipped badges',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = AppState(PrefsService());
    await tester.pumpWidget(app(state, const ShopScreen()));
    await tester.tap(find.byKey(const ValueKey('shop-category-Ludo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(SnakesLaddersBoard), findsNothing);
    expect(find.byType(LudoBoard), findsWidgets);
    expect(
        tester.getSize(find.byType(LudoBoard).first).width, greaterThan(220));
    expect(find.text('Equipped'), findsOneWidget);
    await capture(tester, 'shop-ludo-category');
    await tester.tap(find.byKey(const ValueKey('shop-category-Snakes')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(LudoBoard), findsNothing);
    expect(find.byType(SnakesLaddersBoard), findsWidgets);
    await capture(tester, 'shop-snakes-category');
    await tester
        .ensureVisible(find.byKey(const ValueKey('shop-category-Avatars')));
    await tester.tap(find.byKey(const ValueKey('shop-category-Avatars')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('avatar-gallery')), findsOneWidget);
    expect(find.text('Equipped'), findsOneWidget);
    await capture(tester, 'shop-avatar-category');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  for (final practice in [false, true]) {
    testWidgets(
        '${practice ? 'practice' : 'online'} victory shows exact match rewards without invented XP',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = AppState(PrefsService())
        ..playerId = 'me'
        ..displayName = 'Alex'
        ..avatarPreset = 0
        ..currentMatchIsBot = practice
        ..ludoBoardTheme = 'astral'
        ..lastSnapshot = boardSnapshot(57, finished: true)
        ..lastMatchRewards = MatchRewards(
            coins: practice ? 0 : 100,
            rating: practice ? 0 : 2,
            practice: practice);
      await tester.pumpWidget(app(state, const ResultsScreen()));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('XP'), findsNothing);
      expect(find.text('+150'), findsNothing);
      expect(
          find.text(
              practice ? 'Practice match · no coins or rating changes' : '+2'),
          findsOneWidget);
      await capture(tester, practice ? 'results-practice' : 'results-win');
      state.coins += 300;
      state.notifyListeners();
      await tester.pump();
      if (!practice) expect(find.text('+100'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    });
  }
}
