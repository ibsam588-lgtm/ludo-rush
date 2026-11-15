import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_platform_service.dart';

/// The Play Games account is optional; Ludo Cheer remains playable without it.
class PlayGamesService {
  PlayGamesService._();

  static final instance = PlayGamesService._();
  static const _channel = MethodChannel('ludo_rush/play_games');
  static String get onlineWinsLeaderboardId => AppPlatformService.isIOS
      ? 'ludo_cheer_online_wins'
      : 'CgkI06r50uYMEAIQAA';
  static String get firstOnlineWinAchievementId => AppPlatformService.isIOS
      ? 'ludo_cheer_first_online_win'
      : 'CgkI06r50uYMEAIQAQ';
  static String get leaderboardLabel =>
      AppPlatformService.isIOS ? 'Game Center leaders' : 'Play Games leaders';
  static String get unavailableMessage => AppPlatformService.isIOS
      ? 'Game Center is unavailable. Check your connection and Game Center sign-in.'
      : 'Google Play Games is unavailable. Check your connection and Play Games sign-in.';

  Future<bool> _invoke(String method, [Map<String, Object>? arguments]) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>(method, arguments) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> _authenticate({bool interactive = false}) async {
    if (await _invoke('isAuthenticated')) return true;
    return interactive && await _invoke('signIn');
  }

  /// Only call after a completed, economy-eligible online win.
  Future<void> reportOnlineWin(int totalWins) async {
    if (totalWins < 1 || !await _authenticate()) return;
    await _invoke('submitScore', {
      'id': onlineWinsLeaderboardId,
      'score': totalWins,
    });
    await _invoke('unlockAchievement', {'id': firstOnlineWinAchievementId});
  }

  Future<bool> showLeaderboard(int totalWins) async {
    if (!await _authenticate(interactive: true)) return false;
    if (totalWins > 0) await reportOnlineWin(totalWins);
    return _invoke('showLeaderboard', {'id': onlineWinsLeaderboardId});
  }

  Future<bool> showAchievements(int totalWins) async {
    if (!await _authenticate(interactive: true)) return false;
    if (totalWins > 0) await reportOnlineWin(totalWins);
    return _invoke('showAchievements');
  }
}
