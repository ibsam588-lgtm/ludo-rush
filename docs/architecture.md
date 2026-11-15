# Ludo Cheer Architecture

## Online game flow

```text
Flutter app
  -> Worker REST API
  -> Durable Object room over WebSocket
  -> D1 for permanent user/wallet/match/purchase records
  -> Queue for background settlement
```

## Why This Shape

- Ludo is turn-based, so one Durable Object per live room is enough authority.
- The client only asks to roll or move; the room decides whether the action is legal.
- D1 stores durable facts, not high-frequency live room state.
- R2 is intentionally excluded for now.

## Joining a table

1. App creates a guest profile.
2. App requests quick match or private room.
3. Worker creates or finds a Durable Object room.
4. App opens the room WebSocket.
5. App sends `join`.
6. Room broadcasts snapshots and authoritative dice/move events.

## Android and iOS matchmaking

The server selects waiting tickets by **game mode and region**, without an
Android/iOS filter. Players using the same backend, mode, and region can match
across platforms. Candidate tickets are ordered by arrival; rating is stored
but is not currently used as a pairing filter.

Four-seat public tables reserve two human players and fill the other seats with
bots after both humans join. Ticket expiry is 45 seconds; the client has its own
earlier fallback behavior, so this is not a mandatory 45-second wait.

| Build | Backend | Shares the live Android queue? |
| --- | --- | --- |
| Android release workflow | `https://ludo-rush-backend.ibsam588.workers.dev` | Yes |
| Ordinary iOS TestFlight workflow | `https://ludo-cheer-ios-beta.ibsam588.workers.dev` | No; beta only |
| Public iOS installation with a verified Production app transaction | Production URL above | Yes, for the same mode and region |

The beta environment has separate D1, rooms, queues, players, and wallets.
Keep it isolated: Sandbox purchases must never credit the production economy.
Main/default iOS builds include both URLs. StoreKit's verified installation
environment selects the correct service, allowing App Review to exercise
Sandbox purchases without granting live coins. A forced-beta manual build is
not a public release candidate.

`BACKEND_URL` is a compile-time Dart define. Android uses the production default
in `app_state.dart`; iOS supplies the production base and isolated
`IOS_SANDBOX_BACKEND_URL` in its workflow. The stored GitHub
variable `LUDO_RUSH_BACKEND_URL` is not consumed by these Flutter workflows.

## Purchases and voice

Google Play purchases and signed Apple transactions are verified on the server
before delivery, with transaction IDs preventing duplicate grants. Production
accepts Apple Production transactions; the isolated TestFlight backend accepts
Sandbox transactions. Apple's verified app transaction maps the Apple Account
to its original guest, allowing permanent purchases and wallets to recover
after reinstall or a device change while retaining strict purchase-token
ownership checks. The mapping stores a hash, not the raw Apple identifier.

Opt-in voice uses authenticated room signaling and WebRTC audio. The game
backend does not record audio. Beta voice requests short-lived TURN credentials
through the production Worker's private `VoiceRelay` service binding; it does
not share production rooms, wallets, or long-lived TURN keys.

Implementation: [matchmaking](../backend-cloudflare/src/matchmaking.ts),
[client backend selection](../client-flutter/lib/state/app_state.dart),
[beta provisioning](../tools/ios/deploy_beta_backend.py).
See [iOS release](ios-release.md) and [voice setup](voice-chat-setup.md) for
purchase and physical-device validation requirements.
