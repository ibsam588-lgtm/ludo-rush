import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/screens/game_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('private four-player game fits a tall Android phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(411.4, 914.3));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = AppState(PrefsService())
      ..playerId = 'player_me'
      ..privateInviteCode = 'ABC123'
      ..lastSnapshot = GameSnapshot.fromJson({
        'status': 'playing',
        'mode': 'classic_4p',
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
            'playerId': 'player_leo',
            'displayName': 'Leo',
            'isBot': false,
          },
          {
            'seat': 2,
            'playerId': 'player_ava',
            'displayName': 'Ava',
            'isBot': false,
          },
          {
            'seat': 3,
            'playerId': 'player_noah',
            'displayName': 'Noah',
            'isBot': false,
          },
        ],
        'pieces': <Map<String, Object>>[],
      });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Code ABC123'), findsOneWidget);
    expect(find.text('Leo'), findsOneWidget);
    expect(find.text('Ava'), findsOneWidget);
    expect(find.text('Noah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
