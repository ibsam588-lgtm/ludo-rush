# Play review policy and Android version floor

## Review policy

- Requests run only on Android after the current player wins a completed match with a non-empty room ID, a unique result timestamp, and a winner present in the result seats. The existing onboarding choice must have been completed.
- A successful win counts once per app process/session. Duplicate match results are persisted and ignored, and policy operations are serialized before calling the platform.
- The first request waits for four successful sessions. Later requests require four additional successful sessions and at least 30 days since the previous request. An unsafe result screen still counts as a completed winning session, but does not consume an attempt.
- The prompt waits for the results transition and any round-complete full-screen ad to finish. It skips a non-current route, paused app, keyboard, focused field, or active full-screen ad.
- The Play API's completion is recorded only as an attempt. Google does not disclose whether a dialog appeared or a review was submitted; the app stores no `hasReviewed` state.
- Manual **Rate App** opens `https://play.google.com/store/apps/details?id=com.ludorush.game`.

Implementation follows the [Play In-App Reviews guidance](https://developer.android.com/guide/playcore/in-app-review) and its [Kotlin integration guide](https://developer.android.com/guide/playcore/in-app-review/kotlin-java). Google notes that API completion does not disclose whether the prompt appeared or a review was submitted, and recommends opening the Play listing for a user-initiated rate action.

## Version

- Verified release floor supplied for this work: `1.0.69` / code `10069`.
- Source baseline in the cached `origin/main` snapshot: pubspec `1.0.0+1`; Gradle fallback `1.0.0` / code `1`.
- New source version: `1.0.70` / code `10070`.
- The internal workflow continues to upload only to the internal track. Its generated build name/code are clamped to at least this floor when the workflow run number is below 70.

## Forced-update configuration hazard

`backend-cloudflare/src/app-config.ts` computes the production minimum from `MIN_ANDROID_BUILD_NUMBER` and `LATEST_ANDROID_BUILD_NUMBER`. With `FORCE_LATEST_ANDROID_BUILD` not set to `false`, the effective minimum is at least the configured latest build. The internal upload workflow does not modify these backend variables or the production policy. Do not copy the internal build number into `LATEST_ANDROID_BUILD_NUMBER` or raise `MIN_ANDROID_BUILD_NUMBER` as part of an internal build; that can force production users to update before a public release is available. No live policy was changed.

## Scope and verification status

- Flutter 3.44.2 static analysis reports no issues.
- All 93 Flutter tests pass, including policy serialization, cooldown, duplicate-result, Android bridge, valid-win, loss, board-preview, and Snakes gameplay coverage.
- The Android debug APK compiles with the Play Review 2.0.2 dependency and Kotlin method-channel bridge.
- The actual Play review card can only be observed from a Play-distributed test build and remains subject to Google's display quota.
