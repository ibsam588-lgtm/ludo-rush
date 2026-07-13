import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/data/profile_catalog.dart';
import 'package:ludo_rush/models/game_snapshot.dart';
import 'package:ludo_rush/services/prefs_service.dart';
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

  test('profile catalog contains every ISO country code once', () {
    expect(allCountries, hasLength(249));
    expect(allCountries.map((country) => country.code).toSet(), hasLength(249));
    expect(countryByCode('US').name, 'United States');
    expect(countryFlagEmoji('CA'), isNotEmpty);
  });

  test('avatar catalog separates common, rare, and premium tiers', () {
    expect(profileAvatarCatalog, hasLength(12));
    expect(
      profileAvatarCatalog
          .where((avatar) => avatar.rarity == AvatarRarity.common),
      hasLength(4),
    );
    expect(
      profileAvatarCatalog
          .where((avatar) => avatar.rarity == AvatarRarity.rare),
      hasLength(4),
    );
    expect(
      profileAvatarCatalog
          .where((avatar) => avatar.rarity == AvatarRarity.premium),
      hasLength(4),
    );
    expect(avatarForPreset(8).price, '1.99 USD');
  });

  test('verified purchases unlock premium cosmetics', () {
    final state = AppState(PrefsService())
      ..ownedProductIds = const {
        'dice.ruby',
        'board.neon',
        'avatar.premium_cosmic_empress',
      };

    expect(state.isDiceSkinUnlocked('ruby'), isTrue);
    expect(state.isBoardThemeUnlocked('neon'), isTrue);
    expect(state.isAvatarUnlocked(8), isTrue);
  });

  test('gold chests require three completed online wins', () {
    final state = AppState(PrefsService());

    expect(state.availableGoldChests, 0);
    state.wins = 2;
    expect(state.availableGoldChests, 0);
    state.wins = 3;
    expect(state.availableGoldChests, 1);
  });
}
