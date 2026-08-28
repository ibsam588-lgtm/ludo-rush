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

## Android networks included

The Android app includes adapter and SDK dependencies for:

- ironSource Ads (through the LevelPlay plugin)
- Unity Ads
- Liftoff Monetize / Vungle
- InMobi

Each mediated network still needs to be activated in the Unity LevelPlay dashboard with that network's app IDs, placement IDs, reporting API credentials, and payout/account approval. Code dependencies alone do not make a network serve ads.

For production, create or connect each network in the Unity LevelPlay dashboard, map the network-specific Android app and placement IDs to the LevelPlay ad units, and publish the waterfall or bidding setup. The app ships the Android adapters, but Unity's dashboard decides which networks are live, test-mode, capped, blocked by COPPA/GDPR settings, or excluded by geo.

## In-app placements

- `LobbyBanner`
- `ShopBanner`
- `ResultsBanner`
- `DailyGift`
- `ResultPlayAgain`
- `ResultBackToLobby`

Use matching placement names in LevelPlay reporting so waterfalls, caps, and A/B tests are easy to read.

## QA flow

For internal QA, build with `--dart-define=LEVELPLAY_TEST_SUITE=true` and open the LevelPlay integration helper from a temporary debug entry point or debugger call to `LevelPlayAdService.instance.launchTestSuite()`. Keep adapter debug logs and the test suite disabled for production builds.
