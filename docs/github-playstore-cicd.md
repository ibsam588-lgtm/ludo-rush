# GitHub, Cloudflare, And Play Store CI/CD

## Repository

The repo should stay private until the first production release.

Default repository name:

```text
ludo-rush
```

## GitHub Secrets

Add these in GitHub:

```text
CLOUDFLARE_API_TOKEN
CLOUDFLARE_ACCOUNT_ID
CLOUDFLARE_D1_DATABASE_ID
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASS
ANDROID_KEYALIAS_NAME
ANDROID_KEYALIAS_PASS
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
LEVELPLAY_ANDROID_APP_KEY
LEVELPLAY_ANDROID_BANNER_AD_UNIT
LEVELPLAY_ANDROID_INTERSTITIAL_AD_UNIT
LEVELPLAY_ANDROID_REWARDED_AD_UNIT
```

## Workflows

```text
Backend CI
  Runs backend install, typecheck, tests, and audit.

Bootstrap Cloudflare Resources
  Creates the D1 database and queue after Cloudflare secrets are configured.

Deploy Backend To Cloudflare
  Applies D1 migrations and deploys the Worker.

Flutter Android Internal Build
  Builds an Android App Bundle and can upload it to Google Play internal testing.

Upload Play Store Metadata
  Uploads Play listing text, changelog, icon, feature graphic, and screenshots after the Play Console app exists.

```

## Android Signing

Create a Flutter Android upload keystore and store it in GitHub secrets as `ANDROID_KEYSTORE_BASE64`, along with the store password, key alias, and key password.

## Play Store Notes

Fastlane can upload app metadata and the `.aab` to the internal track, but Google Play does not let CI create the first Play Console app listing from scratch. The first app record must be created in Play Console with:

```text
App name: Ludo Rush
Default language: English (United States)
App/game: Game
Free/paid: Free
Package name: com.ludorush.game
```

After that, the `Flutter Android Internal Build` workflow can upload builds when the Google service account and production ad secrets are configured.

## Internal Testers

Google Play internal testing supports up to 100 testers. Add tester emails in Play Console under:

```text
Testing -> Internal testing -> Testers
```

Then run the GitHub workflow:

```text
Flutter Android Internal Build
upload_to_play = true
```

When the workflow succeeds, testers use the Play Console opt-in link to install the app.
