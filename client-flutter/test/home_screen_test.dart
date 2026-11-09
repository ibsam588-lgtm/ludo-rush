import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/screens/home_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('swiping the large Snakes preview moves to the next board', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = AppState(PrefsService())..startChoiceSeen = true;
    addTearDown(state.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.tap(find.text('Snakes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final preview = find.byType(PageView);
    final pages = tester.widget<PageView>(preview).controller!;
    final drag = await tester.startGesture(tester.getCenter(preview));
    await drag.moveBy(const Offset(-70, 0));
    await tester.pump(const Duration(milliseconds: 16));
    expect(pages.offset, greaterThan(0));
    await drag.moveBy(const Offset(-135, 0));
    await drag.up();
    await tester.pumpAndSettle();

    expect(pages.page, closeTo(1, .01));
    expect(find.text('Locked Board'), findsOneWidget);
    expect(state.snakesBoardTheme, 'carnival');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in const [Size(320, 568), Size(600, 1024)]) {
    testWidgets('home screen fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = AppState(PrefsService());
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('2 Player'), findsOneWidget);
      expect(find.text('4 Player'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      if (size.height >= 700) {
        expect(find.text('Solo play'), findsOneWidget);
      }
      expect(find.textContaining(RegExp('bot', caseSensitive: false)),
          findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('profile soundtrack picker fits a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = AppState(PrefsService());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Sign up'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Soundtrack'), findsOneWidget);
    expect(find.text('Victory Spark'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gift shop assets fit a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = AppState(PrefsService())..startChoiceSeen = true;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Gift Shop'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Lucky Dice'), findsOneWidget);
    expect(find.text('Victory Parade'), findsOneWidget);
    expect(find.text('Add a friend first'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
