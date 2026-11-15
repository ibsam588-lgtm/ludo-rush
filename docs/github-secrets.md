# GitHub credential inventory

Verified November 15, 2026 against `ibsam588-lgtm/ludo-rush` Actions settings and
current workflow references: **26 repository secrets, four repository variables**,
and no additional secrets in the `github-pages` environment.

This inventory records names and purposes only. GitHub does not return stored
secret values when listing secrets. Base64 is packaging, not encryption; signing
keys, service-account JSON, `.p8`, `.p12`, and provisioning files stay outside Git.

## Apple signing and App Store Connect: six secrets

Consumed by [the iOS workflow](../.github/workflows/flutter-ios-testflight.yml),
[signing helper](../tools/ios/prepare_signing.py), and
[TestFlight lane](../client-flutter/ios/fastlane/Fastfile).

| Stored secret | Purpose |
| --- | --- |
| `IOS_DISTRIBUTION_P12_BASE64` | Existing shared Apple Distribution certificate and private key, packaged as base64 PKCS#12, for signing the iOS release. |
| `IOS_DISTRIBUTION_P12_PASSWORD` | Decrypts/imports that PKCS#12 signing identity into the temporary CI keychain. |
| `IOS_PROVISION_PROFILE_BASE64` | App-specific App Store provisioning profile authorizing the bundle, team, distribution identity, and Game Center entitlement. |
| `ASC_KEY_ID` | Identifies the App Store Connect API key used by the TestFlight uploader. |
| `ASC_ISSUER_ID` | Identifies the App Store Connect issuer for that API key. |
| `ASC_KEY_P8_BASE64` | Base64 private `.p8` API key that signs App Store Connect authentication tokens. The current CI key has Developer-role upload access. |

The distribution identity is Apple Distribution: IBSAM SHAHZAD, team
`5MST9WC27Z`, expiring November 14, 2027. CI removes its temporary keychain and
profile even after a failed upload. The uploader does not submit a public review
or attempt App Manager-only metadata/tester changes. Local store-setup tools use
an `ASC_KEY_PATH` input; it is not a stored GitHub secret in this inventory.

## Android signing and Google Play: five secrets

Consumed by [Android CI](../.github/workflows/flutter-android-internal.yml) and
the manual Play publishing workflows. The Google credential is also used by
[backend deployment](../.github/workflows/cloudflare-deploy.yml).

| Stored secret | Purpose |
| --- | --- |
| `UNITY_ANDROID_KEYSTORE_BASE64` | Existing Android upload keystore, decoded to sign Flutter release bundles. Active despite the historical `UNITY_` prefix. |
| `UNITY_ANDROID_KEYSTORE_PASS` | Password for opening that upload keystore. |
| `UNITY_ANDROID_KEYALIAS_NAME` | Selects the signing key inside that keystore. |
| `UNITY_ANDROID_KEYALIAS_PASS` | Password for that signing key. |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Authenticates Play internal uploads, production promotion, metadata/contact updates, and server-side Google Play purchase verification. Backend deployment copies it into the production Worker's secret store. |

The Android workflow first checks `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASS`, `ANDROID_KEYALIAS_NAME`, and `ANDROID_KEYALIAS_PASS`,
then falls back to the four stored `UNITY_ANDROID_*` entries. The preferred
`ANDROID_*` aliases are **not currently stored**. Do not replace the existing
upload key just to rename a secret.

## Cloudflare deployment: three secrets

Used by production deployment/resource bootstrap and the iOS beta provisioning
job. See [deployment](../.github/workflows/cloudflare-deploy.yml) and
[beta provisioning](../tools/ios/deploy_beta_backend.py).

| Stored secret | Purpose |
| --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | Selects the Cloudflare account for Workers, D1, Queues, and beta resources. |
| `CLOUDFLARE_API_TOKEN` | Authorizes the deployment and resource-management API calls used by those workflows. |
| `CLOUDFLARE_D1_DATABASE_ID` | Required by production deployment's resource-ID patch step. It replaces the template placeholder only; the current `wrangler.toml` already contains a concrete production D1 binding. Changing this secret alone does not redirect that binding. |

The isolated iOS beta database is discovered/created by name, with its own ID
written into a generated beta config. It does not reuse the production D1 ID.

## LevelPlay production configuration: eight secrets

These app/ad-unit identifiers are supplied to the appropriate platform build as
Dart defines. They select the LevelPlay app and inventory; they are not vendor
dashboard login or payout credentials. Both signed workflows explicitly set
`LEVELPLAY_PRODUCTION=true` and fail if required platform values are absent.
Production configuration does not fall back to demo IDs.

| Stored secret | Purpose |
| --- | --- |
| `LEVELPLAY_ANDROID_APP_KEY` | Initializes the Android LevelPlay app. |
| `LEVELPLAY_ANDROID_BANNER_AD_UNIT` | Android banner ad-unit ID. |
| `LEVELPLAY_ANDROID_INTERSTITIAL_AD_UNIT` | Android interstitial video ad-unit ID. |
| `LEVELPLAY_ANDROID_REWARDED_AD_UNIT` | Android opt-in rewarded video ad-unit ID. |
| `LEVELPLAY_IOS_APP_KEY` | Initializes the iOS LevelPlay app. |
| `LEVELPLAY_IOS_BANNER_AD_UNIT` | iOS banner ad-unit ID. |
| `LEVELPLAY_IOS_INTERSTITIAL_AD_UNIT` | iOS interstitial video ad-unit ID. |
| `LEVELPLAY_IOS_REWARDED_AD_UNIT` | iOS opt-in rewarded video ad-unit ID. |

Code configuration is separate from network approval, app activation, bidding,
fill, consent, and payout eligibility. See [ads setup](levelplay-production-setup.md).

## Retained Unity credentials: four secrets

These remain stored from the former Unity build setup. None is referenced by
the current workflow files. Their presence does not prove the credentials are
still valid; leave removal/rotation to a separate reviewed change.

| Stored secret | Historical purpose |
| --- | --- |
| `UNITY_ACCESS_TOKEN` | Unity account/service access for the former Unity pipeline. |
| `UNITY_EMAIL` | Unity account email used by the former Unity pipeline. |
| `UNITY_ENTITLEMENT_LICENSE` | Unity entitlement/license material retained from that setup. |
| `UNITY_LICENSE` | Unity editor activation/license material retained from that setup. |

The four Android signing secrets above are still active and do **not** belong
to this unused group.

## Repository variables: four entries

Variables are configuration, not encrypted secrets. Values are omitted here.

| Stored variable | Current use |
| --- | --- |
| `LEVELPLAY_CHILD_DIRECTED` | Android build COPPA/child-directed flag; workflow fallback is `false`. iOS uses the Dart default `false`. |
| `LEVELPLAY_TEST_SUITE` | Android build test-suite flag; workflow fallback is `false`. iOS uses the Dart default `false`. Keep disabled for production; the in-app test-suite launcher also refuses production mode. |
| `LEVELPLAY_TEST_DEVICE_ID` | Retained configuration; no reference in current workflow files. It does not currently register a test device for these Flutter builds. |
| `LUDO_RUSH_BACKEND_URL` | Retained configuration; no reference in current workflow files. Android uses the Dart production default and iOS explicitly supplies `BACKEND_URL`. Changing this variable does not move either app's queue. |

## Credentials stored elsewhere

- `TURN_KEY_ID` and `TURN_KEY_API_TOKEN` are production Cloudflare Worker secrets
  for issuing short-lived voice relay credentials. They are not GitHub secrets
  or client build inputs. Beta voice uses the private `VoiceRelay` binding.
- Network-specific Chartboost signatures, publisher/reporting credentials, and
  other mediation account credentials belong in LevelPlay/network dashboards;
  they are not among these 26 GitHub secrets.
- GitHub provides `GITHUB_TOKEN` automatically for each Actions job. It is not a
  manually stored secret and is separate from a developer's local Git login.

When updating credentials, use repository **Settings → Secrets and variables →
Actions**, then update this name/purpose inventory if its shape changes. Changes
to build-time IDs affect newly built binaries, not already installed copies.
Keep signing identity, provisioning profile, API-key role, and platform ad IDs
consistent with the workflows that consume them.
