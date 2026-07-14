import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/widgets/ludo_board.dart';
import 'package:ludo_rush/widgets/snakes_ladders_board.dart';

void main() {
  testWidgets('generated Ludo themes paint and switch on a phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(411.4, 914.3));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final theme in const ['carnival', 'royal', 'neon', 'classic']) {
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
}
