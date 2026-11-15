# Ludo Cheer

Ludo Cheer is a Flutter game for Android and iOS with Ludo, Snakes & Ladders,
online matchmaking, private tables, bots, table voice, cosmetic previews, ads,
and in-app purchases. Online rooms and the persistent economy run on Cloudflare.

## Project Layout

```text
backend-cloudflare/  Cloudflare Workers, Durable Objects, D1, Queues
client-flutter/      Current Flutter mobile client
tools/ios/           Apple signing, isolated beta backend, and native store media
fastlane/            Google Play publishing and Android listing assets
docs/                Product, architecture, and launch notes
```

## Platforms and releases

| Platform | App identity | Automatic release destination |
| --- | --- | --- |
| Android | `com.ludorush.game` | Google Play internal testing |
| iOS | `com.corsairlabs.ludocheer` | TestFlight, using an isolated beta backend by default |

The public name is **Ludo Cheer**. Existing Android package, repository, and
production Worker names retain `ludo-rush` for continuity.

Android host changes run Android only; iOS host changes run iOS only. Shared
Dart, assets, tests, or pubspec changes run both. Documentation changes do not
trigger the Android, iOS, or backend workflows. Public store releases are
separate from automatic tester uploads. See the [CI/CD guide](docs/github-playstore-cicd.md).

Production Android and iOS use the same matchmaking queue when their game mode
and region match. Ordinary TestFlight builds use separate beta rooms, players,
and wallets so Sandbox purchases cannot affect the live economy. See
[architecture](docs/architecture.md) and the [iOS release guide](docs/ios-release.md).

## Backend

Live matches run in Durable Objects, permanent records live in D1, and background
work uses Queues. The backend validates online dice, legal moves, turns, match
rewards, and Google Play / Apple purchase delivery. R2 is not required.

```text
Workers -> API, auth, matchmaking, purchase endpoints
Durable Objects -> live game rooms and voice signaling
D1 -> users, coins, purchases, match history, rewards
Queues -> background work only when needed
```

## Configuration and development

The [GitHub credential inventory](docs/github-secrets.md) lists all stored
repository secret and variable names, their purposes, and their current consumers.
It also distinguishes Cloudflare-only voice secrets and network dashboard
credentials. Secret values and private signing material belong outside Git.

For local checks:

```text
client-flutter/:      flutter pub get; flutter analyze --no-fatal-infos; flutter test
backend-cloudflare/: npm ci; npm run typecheck; npm test
```

Additional guides:

- [LevelPlay production ads and placements](docs/levelplay-production-setup.md)
- [Table voice and moderation](docs/voice-chat-setup.md)
- [Localization](client-flutter/LOCALIZATION.md)
- [Backend endpoints and local setup](backend-cloudflare/README.md)
