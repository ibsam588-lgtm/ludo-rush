import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/screens/shop_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shop lays out on a tall Android phone', (tester) async {
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

    expect(find.text('Dice Shop'), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
