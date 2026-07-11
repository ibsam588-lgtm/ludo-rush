import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/state/app_state.dart';

void main() {
  test('game snapshot handles a waiting room without a dice value', () {
    final snapshot = GameSnapshot.fromJson({
      'status': 'waiting',
      'mode': 'classic_2p',
      'currentTurnSeat': 0,
      'seats': <Object>[],
      'pieces': <Object>[],
      'availableMoves': <Object>[],
    });

    expect(snapshot.diceValue, 0);
    expect(snapshot.status, 'waiting');
    expect(snapshot.availableMoves, isEmpty);
  });

  test('social player parses numeric ratings safely', () {
    final player = SocialPlayer.fromJson({
      'id': 'usr_test',
      'displayName': 'Maya',
      'rating': 1120.0,
    });

    expect(player.id, 'usr_test');
    expect(player.displayName, 'Maya');
    expect(player.rating, 1120);
  });

  test('friends chat message defaults missing display data', () {
    final message = FriendChatMessage.fromJson({
      'id': 'msg_test',
      'senderId': 'usr_test',
      'message': 'Hello',
      'createdAt': 123,
    });

    expect(message.senderName, 'Player');
    expect(message.message, 'Hello');
    expect(message.createdAt, 123);
  });
}
