import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/screens/shop_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:ludo_rush/widgets/ludo_board.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shop navigation stays separate and products open previews',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(411.4, 914.3));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = AppState(PrefsService());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: ShopScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.bottomNavigationBar, isNotNull);

    await tester.scrollUntilVisible(
      find.text('Daily Coins'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Daily Coins'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byTooltip('Close preview'), findsOneWidget);
    expect(find.text('Daily Coins'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 568), Size(411.4, 914.3)]) {
    testWidgets('shop lays out at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = AppState(PrefsService());
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(home: ShopScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Dice Shop'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Carnival Board'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(LudoBoard), findsWidgets);
      final previewSize = tester.getSize(find.byType(LudoBoard).first);
      expect(previewSize.width, greaterThan(40));
      expect(previewSize.height, greaterThan(40));
      expect(tester.takeException(), isNull);
    });
  }
}
