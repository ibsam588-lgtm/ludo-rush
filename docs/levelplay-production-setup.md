# Unity LevelPlay production setup

The Flutter client uses Unity LevelPlay mediation on Android and iOS. Without
explicit IDs, non-production builds can use Unity's demo inventory. Production
builds require real platform-specific values and never fall back to demo IDs.
The signed GitHub workflows explicitly enable production mode and validate the
four required secrets for their platform. See the [credential inventory](github-secrets.md).

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

iOS uses `LEVELPLAY_IOS_APP_KEY`, `LEVELPLAY_IOS_BANNER_AD_UNIT`,
`LEVELPLAY_IOS_INTERSTITIAL_AD_UNIT`, and `LEVELPLAY_IOS_REWARDED_AD_UNIT`,
with `LEVELPLAY_PRODUCTION=true`. Test-suite and adapter debug logging stay
disabled for production. Changing GitHub IDs requires a new build; changing
network mappings or placement activation in LevelPlay does not.

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
- Meta Audience Network (Android adapter 5.6.0, SDK 6.22.0)

Each mediated network still needs to be activated in the Unity LevelPlay dashboard with that network's app IDs, placement IDs, reporting API credentials, and payout/account approval. Code dependencies alone do not make a network serve ads.

For production, create or connect each network in the Unity LevelPlay dashboard, map the network-specific Android app and placement IDs to the LevelPlay ad units, and publish the waterfall or bidding setup. The app ships the Android adapters, but Unity's dashboard decides which networks are live, test-mode, capped, blocked by COPPA/GDPR settings, or excluded by geo.

The iOS [Podfile](../client-flutter/ios/Podfile) includes the corresponding Unity
Ads, Liftoff, InMobi, Chartboost, and Meta adapters alongside ironSource from
the LevelPlay plugin. iOS uses separate network app/placement mappings; do not
reuse Android IDs for the iOS app.

For the Android app, the Chartboost bidding locations are
`ludo_interstitial`, `ludo_rewarded`, and `ludo_banner`. Map each location to
the matching LevelPlay ad unit, verify the Chartboost reporting API, and
confirm that Chartboost has received an SDK ad request before treating the
network as live. Keep the Chartboost app signature in the dashboards, never
in source control. The developer website's root `app-ads.txt` contains the
Chartboost seller declarations.

## In-app placements

| Format | Exact placement names | Reward |
| --- | --- | --- |
| Banner | `LobbyBanner`, `ShopBanner`, `MatchmakingBanner`, `ResultsBanner` | None |
| Interstitial | `RoundComplete`, `DefaultInterstitial` | None |
| Rewarded | `ShopPoints300`, `DefaultRewarded` | 300 coins/points |
| Rewarded | `DailyGift` | 150 coins/points |
| Rewarded | `LevelCompleteBonus` | 150 coins/points; the app also grants one energy |

Use matching placement names in LevelPlay reporting so waterfalls, caps, and A/B tests are easy to read.

`RoundComplete` is eligible only after a win. A loss, match quit, and app exit never open a video ad. The optional `LevelCompleteBonus` video appears only on the victory screen and grants its balance from LevelPlay's reward callback.

## iOS dashboard checkpoint: November 15, 2026

The iOS LevelPlay app has all six bidding networks mapped: ironSource, Unity
Ads, Chartboost, InMobi, Liftoff Monetize, and Meta. All ten placements above
were saved with ad delivery On. The Liftoff mapping uses a distinct iOS app
and separate banner, interstitial, and rewarded placements.

This is a configuration checkpoint, not proof that every network can serve paid
ads. Liftoff still reports the iOS app as inactive/unconnected: its store search
does not find the unpublished App Store listing. Connect the public listing and
complete network activation when available. Recheck each partner's approval,
test/production status, and real impressions before calling it live. Do not
publish a Sandbox-backend build just to activate an ad network.

The developer domain's [app-ads.txt](https://corsairlabs.com/app-ads.txt) was
verified reachable with DIRECT seller entries for all six networks. Keep that
file in the Corsair Labs website repository. Store/developer website links
must use that domain so ad-network crawlers can discover it.

## QA flow

For internal QA, explicitly build with
`--dart-define=LEVELPLAY_PRODUCTION=false` and
`--dart-define=LEVELPLAY_TEST_SUITE=true`, using demo IDs or vendor-registered
test devices. Open the integration helper from a temporary debug entry point
or debugger call to `LevelPlayAdService.instance.launchTestSuite()`. The launcher
refuses production mode. Keep adapter debug logs and the test suite disabled
for production builds.
