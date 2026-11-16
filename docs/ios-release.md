# Ludo Cheer iOS

The iOS bundle is `com.corsairlabs.ludocheer`, App Store Connect app
`6834993861`, Apple team `5MST9WC27Z`, with iOS 16 as the minimum version for
Apple-signed account recovery. The Android identity remains
`com.ludorush.game`. The iOS app uses the existing shared Apple Distribution
certificate expiring November 14, 2027, with an app-specific Game Center App
Store provisioning profile. Never commit signing keys or provisioning profiles.

## Platform workflows

The default branch is `main`. **Mobile Release** is the only mobile release
entry point. Add exactly one PR label before merging:

- `release:ios`: verify iOS, then build/sign/upload only iOS after merge.
- `release:android`: verify Android, then build/sign/upload only Android after merge.

Shared Dart, assets, tests, and pubspec changes follow the selected label; they
never select both builds. Documentation and backend-only changes do not build
mobile apps. Missing/conflicting labels fail selection for mobile changes.
Closing an unmerged PR never uploads. Manual dispatch selects one platform and
is restricted to main. The two platform YAML files are reusable workers and
have no independent push, PR, or manual triggers.

The iOS worker uses Xcode 27.2 on `xcode-27`, verifies SDK major 27 or later,
and retains iOS 16 as its deployment target. This meets [Apple's announced April 2027 requirements](https://developer.apple.com/app-store/submitting/)
for the SDK and iOS 15-or-later deployment target. Internal and public
builds reuse the existing certificate. Uploads do not publish a public release.
The next iOS build number is read from processed TestFlight builds under a
serialized iOS release group; changing the workflow does not reset numbering.
Android uses an explicit baseline above build 10105 plus the new workflow run
and attempt, so its first upload and retries remain newer than existing builds.

The minimum supported iOS protocol build is 1901. The API reports the effective
minimum, and the client rechecks on foreground. Sandbox update gates direct
testers to TestFlight. Public Production installs additionally check Apple's
public catalog for a newer marketing version in the player's storefront.
An unpublished TestFlight build cannot trigger a public update requirement;
lookup failures retain the server policy. The UI names the correct store.

Backend pushes also synchronize the isolated beta Worker and migrations.
This keeps server fixes current without rebuilding either mobile client.
A manual backend deployment with migrations disabled skips beta synchronization.

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

Store screenshots are generated locally, never by a GitHub runner. Both
capture entry points reject `GITHUB_ACTIONS=true`; the release workflow has no
capture job or capture input.

On a local Mac, `tools/ios/capture_store_assets.py` runs the real Flutter UI on
a 6.9-inch iPhone and 13-inch iPad simulator. It captures five native screenshots per device and
records actual gameplay, using James as the sample player. Ten additional iPhone
images show each paid product's real preview for Apple's purchase review. Each
screen switch disposes the previous navigator so an old modal cannot contaminate
the next capture. The fixture is an
isolated entry point and is never imported by production main. Keep its native recording and capture manifest as local release evidence.

For Duo, run `flutter test tools/store_assets/duo_capture_test.dart
--dart-define=LEVELPLAY_PRODUCTION=true` locally
from `client-flutter`, with `FLUTTER_ROOT` pointing to the SDK. Optional
`STORE_EMOJI_FONT` points to a local emoji font used only during capture.
The actual production widgets render independently at 1398x2034 (outer) and
2007x2853 (inner), with James as the sample player. These are Flutter renderer
captures on the local machine, not iOS simulator or physical-device evidence.
Check all ten images before uploading; do not stretch existing phone images.
Apple uses `IPHONE_DUO_PROFILE` for both screens. Its accepted App Preview size
is 886x1920 portrait, the same standard as other iPhone previews; reuse the
reviewed native gameplay edit in that profile instead of stretching it to a
screen's hardware dimensions. The upload helper accepts `--formats
iphone-duo-outer iphone-duo-inner` and preserves other display placements.

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

## Go-live gates

Before the first public release, verify the App Store build is processed and
attached, the app plus its ten products and Game Center components are accepted
into App Review, privacy and age-rating forms match the shipped optional voice
and advertising SDKs, and regional availability is correct. The listing keeps
manual release so review approval alone does not publish it.

Perform physical-device microphone/mute/leave checks and real Sandbox purchase,
reinstall and second-device restore checks. Automated source/render/signaling
checks cannot establish that microphone audio or Apple billing succeeds on a
phone. An internal TestFlight invitation does not require external Beta App
Review when the tester is already an eligible App Store Connect user.

After the public App Store listing is reachable, connect it in Liftoff and
finish any pending partner app approval. Recheck production fill/impressions
and payout status; configured bidding mappings do not guarantee paid inventory.
Production Android and iOS share rooms/queues for the same mode and region.
TestFlight/App Review keep separate wallets and matchmaking to prevent Sandbox
purchases affecting public players.
