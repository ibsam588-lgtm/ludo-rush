import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/screens/results_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const platformChannel = MethodChannel('ludo_rush/app');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platformChannel, null);
  });

  testWidgets('results sharing works and replay preserves offline mode',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(411, 914));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    MethodCall? shareCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platformChannel, (call) async {
      if (call.method == 'shareText') shareCall = call;
      return true;
    });

    final state = _ReplayState(PrefsService())
      ..playerId = 'player_me'
      ..currentMatchIsBot = true
      ..lastSnapshot = GameSnapshot.fromJson({
        'status': 'finished',
        'mode': AppState.snakesLaddersMode,
        'winnerPlayerId': 'player_me',
        'diceValue': 0,
        'currentTurnSeat': 0,
        'availableMoves': <String>[],
        'seats': [
          {
            'seat': 0,
            'playerId': 'player_me',
            'displayName': 'Ibsam',
            'isBot': false,
          },
          {
            'seat': 1,
            'playerId': 'bot_1',
            'displayName': 'Maya',
            'isBot': true,
          },
        ],
        'pieces': <Map<String, Object>>[],
      });

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const MaterialApp(home: ResultsScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    await tester.ensureVisible(find.text('Share Result'));
    await tester.tap(find.text('Share Result'));
    await tester.pump();

    expect(shareCall?.method, 'shareText');
    expect(
      (shareCall?.arguments as Map<Object?, Object?>)['text'],
      contains('I won a Ludo Rush match'),
    );

    await tester.ensureVisible(find.text('Play Again'));
    await tester.tap(find.text('Play Again'));
    await tester.pump();

    expect(state.replayedOfflineMode, AppState.snakesLaddersMode);
    expect(state.replayedOnlineMode, isNull);
    expect(tester.takeException(), isNull);
  });
}

class _ReplayState extends AppState {
  String? replayedOnlineMode;
  String? replayedOfflineMode;

  _ReplayState(PrefsService prefs) : super(prefs);

  @override
  void startQuickMatch(String mode) {
    replayedOnlineMode = mode;
  }

  @override
  void startOfflineMatch(String mode) {
    replayedOfflineMode = mode;
  }
}
