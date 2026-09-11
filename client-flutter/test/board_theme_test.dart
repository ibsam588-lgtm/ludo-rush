import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/widgets/ludo_board.dart';
import 'package:ludo_rush/widgets/snakes_ladders_board.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('new boards enforce win unlocks and persist both selections',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PrefsService();
    await prefs.init();
    final state = AppState(prefs);
    state.setLudoBoardTheme(' OCEAN ');
    state.setSnakesBoardTheme('ocean');
    expect(state.ludoBoardTheme, 'ocean');
    expect(prefs.snakesBoardTheme, 'ocean');
    state.setLudoBoardTheme('astral');
    state.setSnakesBoardTheme('volcano');
    expect(state.ludoBoardTheme, 'ocean');
    expect(state.snakesBoardTheme, 'ocean');
    state.wins = 4;
    state.setLudoBoardTheme('astral');
    expect(prefs.ludoBoardTheme, 'astral');
    expect(state.isBoardThemeUnlocked('volcano'), isFalse);
    state.wins = 8;
    state.setSnakesBoardTheme(' VOLCANO ');
    expect(prefs.snakesBoardTheme, 'volcano');
    expect(state.coins, 500);
    expect(state.isBoardThemeUnlocked('neon'), isFalse);
    state.dispose();
  });

  testWidgets('generated Ludo themes paint and switch on a phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(411.4, 914.3));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final theme in const [
      'carnival',
      'royal',
      'neon',
      'classic',
      'ocean',
      'astral',
      'volcano'
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.square(
              dimension: 390,
              child: LudoBoard(
                snapshot: null,
                mySeat: null,
                boardTheme: theme,
                showWaitingOverlay: false,
                onPieceTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull, reason: 'Theme: $theme');
    }
  });

  testWidgets('Jungle Snakes board paints on a phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(411.4, 914.3));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 390,
            child: SnakesLaddersBoard(
              snapshot: null,
              mySeat: null,
              boardTheme: 'jungle',
              onPieceTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
  });

  testWidgets('static Ludo previews settle without a continuous ticker',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 180,
            child: LudoBoard(
              snapshot: null,
              mySeat: null,
              boardTheme: 'royal',
              showWaitingOverlay: false,
              animate: false,
              onPieceTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('static Snakes previews paint all eight board themes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final theme in const [
      'carnival',
      'royal',
      'neon',
      'classic',
      'jungle',
      'ocean',
      'astral',
      'volcano'
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.square(
              dimension: 320,
              child: SnakesLaddersBoard(
                snapshot: null,
                mySeat: null,
                boardTheme: theme,
                showTitle: false,
                showPieces: false,
                animate: false,
                onPieceTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final board = tester.widget<SnakesLaddersBoard>(
        find.byType(SnakesLaddersBoard),
      );
      expect(board.boardTheme, theme);
      expect(board.showPieces, isFalse);
      expect(board.animate, isFalse);
      expect(tester.takeException(), isNull, reason: 'Theme: $theme');
    }
  });
}
