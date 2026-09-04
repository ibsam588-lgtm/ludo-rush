import '../config/levelplay_ad_config.dart';

abstract final class AdPlacementPolicy {
  static bool shouldShowAfterCompletedRound(int completedRounds) {
    if (completedRounds < LevelPlayAdConfig.firstRoundInterstitial) {
      return false;
    }

    final interval = LevelPlayAdConfig.roundInterstitialInterval;
    if (interval <= 0) return false;
    return (completedRounds - LevelPlayAdConfig.firstRoundInterstitial) %
            interval ==
        0;
  }
}
