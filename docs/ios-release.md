# Ludo Cheer iOS

The iOS bundle is `com.corsairlabs.ludocheer`, App Store Connect app
`6834993861`, Apple team `5MST9WC27Z`, with iOS 16 as the minimum version for
Apple-signed account recovery. The Android identity remains
`com.ludorush.game`. The iOS app uses the existing shared Apple Distribution
certificate expiring November 14, 2027, with an app-specific Game Center App
Store provisioning profile. Never commit signing keys or provisioning profiles.

## Platform workflows

`flutter-android-internal.yml` verifies Android pull requests and uploads main
changes to Google Play internal testing. Its existing filename and run-number
history are retained so Android version codes keep increasing.

`flutter-ios-testflight.yml` verifies an unsigned iOS release on macOS and uploads
signed main builds to TestFlight. A manual run with `capture_store_assets` also
launches the actual iPhone and iPad UI to refresh store media. Ordinary pull
requests and uploads compile and test the app, reusing visually reviewed media
instead of recapturing the full store listing after every code change. Neither
workflow submits a public store release.

The minimum supported iOS build is 1901, the first iOS 16 build with purchasing
account recovery. Migration `0008_ios_minimum_release.sql` applies the same
protocol floor to the production and isolated beta databases without changing
Android's minimum. The API reports the effective minimum when latest-only
enforcement is enabled, matching the client's comparison. Sandbox update gates
direct testers to TestFlight and explain how to select Ludo Cheer and update;
the download page can open/install TestFlight without exposing a public beta
invitation link. Production uses the Ludo Cheer App Store listing.

Backend pushes now also synchronize the isolated beta Worker and migrations.
This keeps update policies and server fixes current without rebuilding either
mobile client. A manual backend deployment with migrations disabled skips this
beta synchronization. Public links remain disabled for private external groups;
external testers receive Apple invitations and need beta-review approval.

Android host changes trigger Android only; iOS host, signing, Fastlane and store
capture changes trigger iOS only. Shared Dart, assets, tests and pubspec changes
trigger both platforms because they affect both apps. Each platform has an
independent concurrency group.

Required iOS Actions secrets:

- `IOS_DISTRIBUTION_P12_BASE64`, `IOS_DISTRIBUTION_P12_PASSWORD`
- `IOS_PROVISION_PROFILE_BASE64`
- `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`
- `LEVELPLAY_IOS_APP_KEY`, `LEVELPLAY_IOS_BANNER_AD_UNIT`
- `LEVELPLAY_IOS_INTERSTITIAL_AD_UNIT`, `LEVELPLAY_IOS_REWARDED_AD_UNIT`

The [credential inventory](github-secrets.md) explains every stored GitHub
secret and variable, including the Cloudflare credentials used for beta setup.
Documentation-only changes do not trigger the platform build workflows; see
the [CI/CD guide](github-playstore-cicd.md).

Signing secrets are used only by the main-branch upload job. The temporary
keychain and provisioning profile are removed on success or failure. The export
method is `app-store-connect`; bitcode is disabled. Build numbers include both
the workflow run and attempt, allowing a failed upload to be retried safely.
The TestFlight lane is discovered from `client-flutter/ios/fastlane/Fastfile`;
CI validates lane discovery before building and retains signed artifacts even
when the upload fails.
The Developer-role API key only uploads builds. Internal TestFlight access is
configured in App Store Connect, with the internal group receiving all builds;
the upload lane does not attempt App Manager-only tester or changelog changes.

## Native services

The existing optional game-service buttons use Game Center on iOS:

- Leaderboard `ludo_cheer_online_wins`, integer, best score, descending.
- Achievement `ludo_cheer_first_online_win`.

Activate these resources in App Store Connect and attach them to the first app
version. A player can continue playing when Game Center sign-in is unavailable.
Voice remains opt-in and age-gated; the microphone permission explains table
voice. Share sheets support iPad popovers. Reviews use StoreKit's scene-based
review API. Ads request ATT permission and continue without tracking when the
user declines; ATT is not treated as GDPR consent.

## Purchases and environment isolation

iOS uses StoreKit 2 and the same ten immutable catalog IDs as Android. Three
coin packs are consumable; dice, board and premium-avatar products are permanent.
Checkout first confirms the delivery account with the server, then supplies a
UUIDv5 app-account token bound to that authenticated guest ID. A checkout lock
prevents duplicate taps while products or sign-in are loading. If StoreKit's
final confirmation fails after delivery, the unfinished transaction can retry
without granting the purchase twice.
The backend verifies Apple's signed transaction and certificate chain with the
official Apple server library before updating the wallet. Product, bundle,
account, quantity, type, environment and revocation checks precede the grant;
the unique transaction ID prevents duplicate grants.

Production accepts Production transactions only. The iOS workflow always
prepares a separate Sandbox backend with its own D1 wallet, rooms and queue.
Main uploads and the default manual run include the live `BACKEND_URL` plus
`IOS_SANDBOX_BACKEND_URL`. Before authenticating, the app obtains a verified
StoreKit `AppTransaction`: Sandbox installations, including TestFlight and
App Review, use the isolated backend; public Production installations use the
live backend and share Android's queue by mode and region. Unverified store
context cannot open paid checkout and stays outside the live economy; free
beta/offline play remains available. A manual run with `production_backend=false` can still
force the beta base URL; do not use that build for public release.
Never enable Sandbox purchase grants against the live economy. Sharing the
voice relay does not share the live player queue. Beta voice uses the
production worker's private `VoiceRelay` RPC entrypoint for short-lived TURN
credentials, after authenticating an age-eligible player in an active beta room.
The production TURN secrets are never copied into the beta environment.
Apple transactions are completed only after successful server verification.
Account recovery uses Apple's signed `appTransactionId`, which is stable for
the same Apple Account and app across reinstalls and devices. The server
verifies the JWS, bundle, app ID and environment, then maps a hash of this
identity to the original player. Checkout and Restore Purchases recover that
player before using the existing app-account token. Wallets are not merged,
raw Apple IDs are not stored, and another player's purchase token remains
invalid. Apply migration `0007_app_store_accounts.sql` in both environments.
Physical-device Sandbox purchase, reinstall/second-device restore, and voice
audio checks remain necessary; automated HTTP/signaling checks do not establish
that hardware audio or a real StoreKit purchase succeeded.

## Store media

`tools/ios/capture_store_assets.py` runs the real Flutter UI on a 6.9-inch iPhone
and 13-inch iPad simulator. It captures five native screenshots per device and
records actual gameplay, using James as the sample player. Ten additional iPhone
images show each paid product's real preview for Apple's purchase review. Each
screen switch disposes the previous navigator so an old modal cannot contaminate
the next capture. The fixture is an
isolated entry point and is never imported by production main. The workflow
uploads the screenshots, original video recording and a capture manifest as
`ludo-cheer-ios-evidence`.

After visual review, `tools/ios/upload_store_assets.py` uploads the media to the
draft localization through Apple's current asset-library API and attaches the
purchase-review images. It requires Pillow plus the Apple API dependencies and
environment documented in `tools/ios/app_store_api.py`. Native screenshots keep
their dimensions and RGB pixels; only an entirely opaque alpha channel is
removed in separate upload copies, as required by Apple's image specifications.
The uploader never submits an App Store review or deletes existing placements.
Product review images are reused by checksum because Apple renames processed
files. Replacing a different product review image requires the explicit
`--replace-purchase-reviews` option after visual review.
Screenshots and App Previews are ordered separately within each device format,
as required by Apple's asset-library API.

App Store Connect requires a native App Preview file, rather than a YouTube URL.
Use an edited 15–30 second gameplay clip at an Apple-supported device resolution
and upload it to the App Previews slot. Keep the YouTube link on the marketing
website. Review simulator evidence, upload validation and SDK warnings before
calling the iOS build release-ready.
