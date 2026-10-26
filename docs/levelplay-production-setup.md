# Unity LevelPlay production setup

The Flutter client is wired for Unity LevelPlay mediation on Android. Debug builds use Unity's demo LevelPlay IDs so engineers can verify the SDK integration without production inventory. Release builds must provide real LevelPlay values.

## Release build inputs

Pass the LevelPlay app key and ad-unit IDs through Dart defines:

```powershell
flutter build appbundle --release `
  --dart-define=LEVELPLAY_PRODUCTION=true `
  --dart-define=LEVELPLAY_ANDROID_APP_KEY=<levelplay-app-key> `
  --dart-define=LEVELPLAY_ANDROID_BANNER_AD_UNIT=<levelplay-banner-ad-unit> `
  --dart-define=LEVELPLAY_ANDROID_INTERSTITIAL_AD_UNIT=<levelplay-interstitial-ad-unit> `
  --dart-define=LEVELPLAY_ANDROID_REWARDED_AD_UNIT=<levelplay-rewarded-ad-unit>
```

Placement behavior and reward amounts can also be changed without editing Dart:

```text
LEVELPLAY_FIRST_ROUND_INTERSTITIAL=1
LEVELPLAY_ROUND_INTERSTITIAL_INTERVAL=1
LEVELPLAY_SHOP_REWARD_POINTS=300
LEVELPLAY_LEVEL_REWARD_POINTS=150
LEVELPLAY_LEVEL_REWARD_ENERGY=1
```

## Android networks included

The Android app includes adapter and SDK dependencies for:

- ironSource Ads (through the LevelPlay plugin)
- Unity Ads
- Liftoff Monetize / Vungle
- InMobi
- Chartboost (Android adapter 5.10.0, SDK 9.14.1)

Each mediated network still needs to be activated in the Unity LevelPlay dashboard with that network's app IDs, placement IDs, reporting API credentials, and payout/account approval. Code dependencies alone do not make a network serve ads.

For production, create or connect each network in the Unity LevelPlay dashboard, map the network-specific Android app and placement IDs to the LevelPlay ad units, and publish the waterfall or bidding setup. The app ships the Android adapters, but Unity's dashboard decides which networks are live, test-mode, capped, blocked by COPPA/GDPR settings, or excluded by geo.

For Ludo Rush, the Chartboost bidding locations are
`ludo_interstitial`, `ludo_rewarded`, and `ludo_banner`. Map each location to
the matching LevelPlay ad unit, verify the Chartboost reporting API, and
confirm that Chartboost has received an SDK ad request before treating the
network as live. Keep the Chartboost app signature in the dashboards, never
in source control. The developer website's root `app-ads.txt` contains the
Chartboost seller declarations.

## In-app placements

- `LobbyBanner`
- `ShopBanner`
- `MatchmakingBanner`
- `ResultsBanner`
- `DailyGift`
- `RoundComplete`
- `ShopPoints300`
- `LevelCompleteBonus`

Use matching placement names in LevelPlay reporting so waterfalls, caps, and A/B tests are easy to read.

`RoundComplete` is eligible only after a win. A loss, match quit, and app exit never open a video ad. The optional `LevelCompleteBonus` video appears only on the victory screen and grants its balance from LevelPlay's reward callback.

## QA flow

For internal QA, build with `--dart-define=LEVELPLAY_TEST_SUITE=true` and open the LevelPlay integration helper from a temporary debug entry point or debugger call to `LevelPlayAdService.instance.launchTestSuite()`. Keep adapter debug logs and the test suite disabled for production builds.
