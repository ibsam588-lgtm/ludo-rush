import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/services/app_platform_service.dart';
import 'package:ludo_rush/services/play_games_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const gameChannel = MethodChannel('ludo_rush/play_games');
  final calls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gameChannel, (call) async {
      calls.add(call);
      return true;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gameChannel, null);
  });

  test('iOS shares its App Store listing and routes results to Game Center', () async {
    expect(AppPlatformService.storeListing, 'https://apps.apple.com/app/id6834993861');
    expect(AppPlatformService.storeName, 'App Store');
    expect(await PlayGamesService.instance.showLeaderboard(4), isTrue);
    expect(calls.singleWhere((c) => c.method == 'submitScore').arguments,
        {'id': 'ludo_cheer_online_wins', 'score': 4});
    expect(calls.singleWhere((c) => c.method == 'unlockAchievement').arguments,
        {'id': 'ludo_cheer_first_online_win'});
  });

  test('a Game Center failure does not crash or award an achievement', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gameChannel, (call) async {
      calls.add(call);
      throw PlatformException(code: 'not_available');
    });
    expect(await PlayGamesService.instance.showLeaderboard(4), isFalse);
    expect(calls.any((call) => call.method == 'unlockAchievement'), isFalse);
  });
}
