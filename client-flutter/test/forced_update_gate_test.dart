import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:ludo_rush/widgets/forced_update_gate.dart';
import 'package:provider/provider.dart';

void main() {
  for (final (store, url) in [
    ('App Store', 'https://apps.apple.com/app/id6834993861'),
    ('TestFlight', 'https://apps.apple.com/app/testflight/id899247664'),
  ]) {
    testWidgets('iOS update gate directs players to $store', (tester) async {
      final state = AppState(PrefsService())
        ..forceUpdateRequired = true
        ..forceUpdateUrl = url;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(
            home: ForcedUpdateGate(child: Text('Game ready')),
          ),
        ),
      );
      expect(
        find.text(
          store == 'TestFlight'
              ? 'Update in TestFlight'
              : 'Update on App Store',
        ),
        findsOneWidget,
      );
      expect(find.text('Update on Play Store'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
      state.dispose();
    });
  }

  test('forced updates only block builds below the configured minimum', () {
    expect(
      AppState.shouldForceUpdate(
        forceEnabled: true,
        buildNumber: 10047,
        minimumBuildNumber: 10048,
      ),
      isTrue,
    );
    expect(
      AppState.shouldForceUpdate(
        forceEnabled: true,
        buildNumber: 10048,
        minimumBuildNumber: 10048,
      ),
      isFalse,
    );
    expect(
      AppState.shouldForceUpdate(
        forceEnabled: true,
        buildNumber: 10049,
        minimumBuildNumber: 10048,
      ),
      isFalse,
    );
  });

  testWidgets('update verification has a visible blocking startup state', (
    tester,
  ) async {
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
