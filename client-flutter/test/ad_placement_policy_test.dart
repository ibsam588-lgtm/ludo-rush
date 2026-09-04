import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_rush/config/levelplay_ad_config.dart';
import 'package:ludo_rush/services/ad_placement_policy.dart';
import 'package:ludo_rush/services/prefs_service.dart';
import 'package:ludo_rush/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('completed-round policy starts at round one and repeats every round',
      () {
    expect(LevelPlayAdConfig.firstRoundInterstitial, 1);
    expect(LevelPlayAdConfig.roundInterstitialInterval, 1);
    expect(AdPlacementPolicy.shouldShowAfterCompletedRound(0), isFalse);
    expect(AdPlacementPolicy.shouldShowAfterCompletedRound(1), isTrue);
    expect(AdPlacementPolicy.shouldShowAfterCompletedRound(2), isTrue);
    expect(AdPlacementPolicy.shouldShowAfterCompletedRound(20), isTrue);
  });

  test('rewarded placements persist configured points and energy', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = PrefsService();
    await prefs.init();
    final state = AppState(prefs);

    state.grantRewardedShopPoints(
      amount: LevelPlayAdConfig.shopRewardPoints,
    );
    state.grantRewardedLevelComplete(
      points: LevelPlayAdConfig.levelCompleteRewardPoints,
      energyAmount: LevelPlayAdConfig.levelCompleteRewardEnergy,
    );

    expect(
      state.coins,
      500 +
          LevelPlayAdConfig.shopRewardPoints +
          LevelPlayAdConfig.levelCompleteRewardPoints,
    );
    expect(
      state.energy,
      5 + LevelPlayAdConfig.levelCompleteRewardEnergy,
    );
    expect(prefs.coins, state.coins);
    expect(prefs.energy, state.energy);
  });
}
