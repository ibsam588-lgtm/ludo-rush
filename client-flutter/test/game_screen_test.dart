import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/screens/game_screen.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('mixed online table offers voice only to age-eligible humans',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(411, 914));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = AppState(PrefsService())
      ..playerId = 'player_me'
      ..age = 13
      ..lastSnapshot = GameSnapshot.fromJson({
        'roomId': 'room_voice',
        'status': 'playing',
        'mode': 'snakes_ladders',
        'diceValue': 0,
        'currentTurnSeat': 0,
        'availableMoves': <String>[],
        'seats': [
          {
            'seat': 0,
            'playerId': 'player_me',
            'displayName': 'Me',
            'isBot': false
          },
          {
            'seat': 1,
            'playerId': 'player_two',
            'displayName': 'Two',
            'isBot': false
          },
          {
            'seat': 2,
            'playerId': 'bot_2',
            'displayName': 'Maya',
            'isBot': true
          },
          {'seat': 3, 'playerId': 'bot_3', 'displayName': 'Leo', 'isBot': true},
        ],
        'pieces': <Map<String, Object>>[],
      });
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(home: GameScreen()),
    ));
    await tester.pump();
    expect(find.byTooltip('Join table voice'), findsOneWidget);
    await tester.tap(find.byTooltip('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Table Voice'), findsOneWidget);
    expect(find.text('Talk with players who join table voice'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chat-table-voice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Your microphone starts only'), findsOneWidget);
    expect(find.textContaining('Bots'), findsNothing);
    expect(find.text('Join voice'), findsOneWidget);
    state.dispose();
  });

  testWidgets('chat explains why voice is unavailable with one human',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(411, 914));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = AppState(PrefsService())
      ..playerId = 'player_me'
      ..age = 13
      ..lastSnapshot = GameSnapshot.fromJson({
        'roomId': 'room_solo',
        'status': 'playing',
        'mode': 'snakes_ladders',
        'diceValue': 0,
        'currentTurnSeat': 0,
        'availableMoves': <String>[],
        'seats': [
          {
            'seat': 0,
            'playerId': 'player_me',
            'displayName': 'Me',
            'isBot': false
          },
          {
            'seat': 1,
            'playerId': 'bot_1',
            'displayName': 'Maya',
            'isBot': true
          },
        ],
        'pieces': <Map<String, Object>>[],
      });
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(home: GameScreen()),
    ));
    await tester.pump();
    await tester.tap(find.byTooltip('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Voice is unavailable at this table'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chat-table-voice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Voice is unavailable at this table'), findsOneWidget);
    expect(find.text('Join voice'), findsNothing);
    state.dispose();
  });

  testWidgets('device-run fallback avoids claiming a live voice room',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(411, 914));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = AppState(PrefsService())
      ..playerId = 'player_me'
      ..age = 13
      ..localMatchActive = true
      ..lastSnapshot = GameSnapshot.fromJson({
        'roomId': 'local_room',
        'status': 'playing',
        'mode': 'classic_4p',
        'diceValue': 0,
        'currentTurnSeat': 0,
        'availableMoves': <String>[],
        'seats': [
          {
            'seat': 0,
            'playerId': 'player_me',
            'displayName': 'Me',
            'isBot': false
          },
          {
            'seat': 1,
            'playerId': 'local_1',
            'displayName': 'Maya',
            'isBot': true
          },
          {
            'seat': 2,
            'playerId': 'local_2',
            'displayName': 'Leo',
            'isBot': true
          },
          {
            'seat': 3,
            'playerId': 'local_3',
            'displayName': 'Ava',
            'isBot': true
          },
        ],
        'pieces': <Map<String, Object>>[],
      });
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(home: GameScreen()),
    ));
    await tester.pump();
    await tester.tap(find.byTooltip('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Voice is unavailable at this table'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chat-table-voice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Voice is unavailable at this table'), findsOneWidget);
    expect(find.text('Join voice'), findsNothing);
    state.dispose();
  });

  testWidgets('game header omits internal connection labels', (tester) async {
    final state = AppState(PrefsService())
      ..playerId = 'player_me'
      ..localMatchActive = true
      ..lastSnapshot = GameSnapshot.fromJson({
        'status': 'playing',
        'mode': 'snakes_ladders',
        'diceValue': 0,
        'currentTurnSeat': 0,
        'availableMoves': <String>[],
        'seats': [
          {
            'seat': 0,
            'playerId': 'player_me',
            'displayName': 'Me',
            'isBot': false,
          },
        ],
        'pieces': <Map<String, Object>>[],
      });

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(home: GameScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Local'), findsNothing);
    expect(find.text('Live'), findsNothing);
    expect(find.text('Reconnecting'), findsNothing);
    expect(find.text('Offline'), findsNothing);
    expect(find.byIcon(Icons.smartphone_rounded), findsNothing);
    state.dispose();
  });

  testWidgets('first live match shows a short interactive guide',
      (tester) async {
    final state = AppState(PrefsService())
      ..playerId = 'player_me'
      ..gameTutorialSeen = false
      ..lastSnapshot = GameSnapshot.fromJson({
        'status': 'playing',
        'mode': 'classic_2p',
        'diceValue': 0,
        'currentTurnSeat': 0,
        'availableMoves': <String>[],
        'seats': [
          {
            'seat': 0,
            'playerId': 'player_me',
            'displayName': 'Me',
            'isBot': false,
          },
          {
            'seat': 1,
            'playerId': 'player_two',
            'displayName': 'Two',
            'isBot': false,
          },
        ],
        'pieces': <Map<String, Object>>[],
      });
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(home: GameScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Your first Ludo match'), findsOneWidget);
    expect(find.text('Let’s play'), findsOneWidget);
    expect(state.gameTutorialSeen, isTrue);
    state.dispose();
  });

  testWidgets(
      'rolling six with multiple legal gotis waits for the player capture choice',
      (tester) async {
    final state = AppState(PrefsService())
      ..playerId = 'player_me'
      ..localMatchActive = true
      ..autoRollEnabled = false
      ..lastSnapshot = GameSnapshot.fromJson({
        'status': 'playing',
        'mode': 'classic_2p',
        'diceValue': 6,
        'currentTurnSeat': 0,
        'availableMoves': <String>['capture_goti', 'yard_goti'],
        'seats': [
          {
            'seat': 0,
            'playerId': 'player_me',
            'displayName': 'Me',
            'isBot': false,
          },
          {
            'seat': 1,
            'playerId': 'player_two',
            'displayName': 'Two',
            'isBot': false,
          },
        ],
        'pieces': [
          {
            'pieceId': 'capture_goti',
            'seat': 0,
            'state': 'track',
            'progress': 4,
            'trackIndex': 5,
          },
          {
            'pieceId': 'yard_goti',
            'seat': 0,
            'state': 'yard',
            'progress': -1,
            'trackIndex': -1,
          },
          {
            'pieceId': 'opponent_goti',
            'seat': 1,
            'state': 'track',
            'progress': 49,
            'trackIndex': 11,
          },
        ],
      });

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(home: GameScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Choose Goti'), findsOneWidget);
    expect(find.text('Move Goti'), findsNothing);
    await tester.tap(find.text('Choose Goti'));
    await tester.pump(const Duration(seconds: 1));
    expect(
        state.lastSnapshot!.pieces
            .firstWhere((piece) => piece.pieceId == 'capture_goti')
            .progress,
        4);

    state.movePiece('capture_goti');
    await tester.pump();
    final captured = state.lastSnapshot!.pieces
        .firstWhere((piece) => piece.pieceId == 'opponent_goti');
    expect(captured.state, 'yard');
    expect(captured.progress, -1);
    expect(state.lastSnapshot!.currentTurnSeat, 0);
    state.dispose();
  });

  for (final size in const [Size(320, 568), Size(411.4, 914.3)]) {
    testWidgets(
        'private four-player game fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = AppState(PrefsService())
        ..playerId = 'player_me'
        ..privateInviteCode = 'ABC123'
        ..lastSnapshot = GameSnapshot.fromJson({
          'status': 'waiting',
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
      expect(find.text('Waiting for players'), findsOneWidget);
      expect(find.text('Tap to Roll'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
