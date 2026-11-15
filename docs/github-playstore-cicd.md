# GitHub, Cloudflare, and mobile release workflows

Repository: `ibsam588-lgtm/ludo-rush`. The game is branded **Ludo Cheer**; the
existing repository, Android package `com.ludorush.game`, and production Worker
names remain stable. iOS uses `com.corsairlabs.ludocheer`.

## Automatic workflows

| Workflow file | Automatic trigger | Result |
| --- | --- | --- |
| [flutter-android-internal.yml](../.github/workflows/flutter-android-internal.yml) | Android host, shared Dart/assets/tests/pubspec, or this workflow | PR verification; signed main build uploaded to Google Play internal testing |
| [flutter-ios-testflight.yml](../.github/workflows/flutter-ios-testflight.yml) | iOS host, shared Dart/assets/tests/pubspec, `tools/ios`, `fastlane/ios`, or this workflow | PR verification; signed main build uploaded to TestFlight; Apple-verified Sandbox installations use the isolated beta backend |
| [backend-ci.yml](../.github/workflows/backend-ci.yml) | Backend files or this workflow | Typecheck, tests, real Workers smoke test, and dependency audit |
| [cloudflare-deploy.yml](../.github/workflows/cloudflare-deploy.yml) | Backend files on main or this workflow | Apply production D1 migrations, configure the Google Play verifier, and deploy the Worker |

Android-only host changes do not trigger iOS, and iOS-only host changes do not
trigger Android. Shared client changes intentionally verify both platforms.
Platform workflow filenames and histories are retained for increasing build
numbers. Each platform has a separate concurrency group.

## Documentation-only updates

`README.md` and `docs/**` are outside all app/backend automatic trigger paths.
Keep documentation updates separate from source, assets, manifests, version
bumps, and workflow edits. Use `[skip ci]` in the commit and squash-merge title
as an additional safeguard for push/pull-request workflows. Do not manually
dispatch a release workflow for a docs update.

GitHub Pages is configured separately to publish `main:/docs`. Its generated
Pages deployment can refresh the documentation website on a main commit; it
does not build a mobile binary, deploy the backend, or upload to either store.

## Manual operations

All workflows can be dispatched manually. These additional workflows run only
when explicitly dispatched:

| Workflow | Purpose |
| --- | --- |
| [cloudflare-bootstrap.yml](../.github/workflows/cloudflare-bootstrap.yml) | Initial production D1/Queue resource creation |
| [playstore-production.yml](../.github/workflows/playstore-production.yml) | Promote the newest eligible build from the selected Play test track to production |
| [playstore-metadata.yml](../.github/workflows/playstore-metadata.yml) | Upload listing text and artwork; excludes changelogs from this listing-only operation |
| [playstore-app-details.yml](../.github/workflows/playstore-app-details.yml) | Update public Play support contact details |

Automatic main uploads target testers. Neither platform build workflow submits
a public store release. Main builds and the default manual iOS run include the
production base URL plus an isolated Sandbox URL. The verified StoreKit
environment keeps TestFlight/App Review separate from public players. A manual
`production_backend=false` forces a beta-only base and is unsuitable for public
release. See [iOS release](ios-release.md).

## Credentials and signing

The verified [GitHub credential inventory](github-secrets.md) describes all
stored secret/variable names and their purposes. Current Android signing uses
the existing `UNITY_ANDROID_*` secret names as the workflow's supported fallback;
the preferred `ANDROID_*` aliases are not currently stored. Preserve the
existing upload-key identity when updating secrets.

iOS reuses the shared Apple Distribution certificate, an app-specific
provisioning profile, and the Developer-role App Store Connect upload API key.
The CI key uploads builds; it does not manage store metadata or public review.
Production ad IDs are injected separately for each platform and are required
before its signed release build.

The repository's `github-pages` environment has no additional stored secrets
as of November 15, 2026. GitHub's automatic `GITHUB_TOKEN` is a per-job token,
not a manually stored repository credential.
