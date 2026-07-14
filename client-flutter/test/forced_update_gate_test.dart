import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:ludo_rush/widgets/forced_update_gate.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('update verification has a visible blocking startup state',
      (tester) async {
    final state = AppState(PrefsService());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(
          home: ForcedUpdateGate(child: Text('Game ready')),
        ),
      ),
    );

    expect(find.text('Checking Update'), findsOneWidget);
    expect(find.text('Game ready'), findsNothing);

    state.updateCheckComplete = true;
    state.notifyListeners();
    await tester.pump();

    expect(find.text('Checking Update'), findsNothing);
    expect(find.text('Game ready'), findsOneWidget);
  });
}
