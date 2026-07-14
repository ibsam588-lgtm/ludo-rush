import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/screens/home_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
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
