# GitHub, Cloudflare, and mobile release workflows

Repository: `ibsam588-lgtm/ludo-rush`. The game is branded **Ludo Cheer**; the
existing repository, Android package `com.ludorush.game`, and production Worker
names remain stable. iOS uses `com.corsairlabs.ludocheer`.

## Automatic workflows

| Workflow | Trigger | Result |
| --- | --- | --- |
| [Mobile Release](../.github/workflows/mobile-release.yml) | A PR targeting main opens/changes, or merges; one release label selects the platform | Selected platform verifies on PRs and uploads only after merge |
| [iOS worker](../.github/workflows/flutter-ios-testflight.yml) | Called only by Mobile Release for `release:ios` | Xcode 27.2 verification; signed TestFlight upload after main merge |
| [Android worker](../.github/workflows/flutter-android-internal.yml) | Called only by Mobile Release for `release:android` | Android verification; signed Google Play internal upload after main merge |
| [backend-ci.yml](../.github/workflows/backend-ci.yml) | Backend files | Typecheck, tests, Workers smoke test and audit |
| [cloudflare-deploy.yml](../.github/workflows/cloudflare-deploy.yml) | Backend files on main | Production migrations/deploy plus isolated beta synchronization |

Use exactly one of `release:ios` and `release:android`. Shared files do not
trigger a second platform. Missing/conflicting labels block mobile selection;
docs-only and backend-only PRs skip both mobile workers. Direct pushes to main
do not upload mobile binaries. Main is the release branch; there is no master
release branch. A manual Mobile Release dispatch can select exactly one
platform from main. Native platform workers cannot be dispatched separately.

The iOS upload worker reads Apple's latest build number before building;
Android numbering uses a baseline above the old workflow's last uploaded code.
Each platform has its own concurrency group. Screenshot generation is local
and absent from GitHub Actions.

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

Mobile Release can be dispatched for one platform on main. The reusable mobile
workers cannot be dispatched independently. These additional workflows run only
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
