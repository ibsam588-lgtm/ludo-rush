# Ludo Rush

Ludo Rush is a mobile-first multiplayer Ludo game built around fast matches, global matchmaking, polished 2D/2.5D presentation, server-authoritative gameplay, ads, and in-app purchases.

## Project Layout

```text
backend-cloudflare/  Cloudflare Workers, Durable Objects, D1, Queues
client-flutter/      Current Flutter mobile client
docs/                Product, architecture, and launch notes
```

## MVP Target

- Guest login
- Quick match
- Private room codes
- 2-4 player Ludo
- Server-authoritative dice, moves, turns, rewards
- Reconnect-ready room model
- Bot fallback hooks
- Basic coins and match history
- Banner ads and rewarded video hooks
- In-app purchase hooks for coins / remove ads

## Backend

The MVP backend intentionally avoids R2. Live matches run in Durable Objects, permanent records live in D1, and background work can move through Queues when needed.

```text
Workers -> API, auth, matchmaking, purchase endpoints
Durable Objects -> live Ludo rooms
D1 -> users, coins, purchases, match history, rewards
Queues -> background work only when needed
```

## Current Status

This repo is in the internal-test foundation phase.

Implemented now:

- Cloudflare Worker API
- D1 user, wallet, purchase, match, ticket, and private-room schema
- Durable Object live room authority
- Quick-match tickets
- Private room codes
- Bot match endpoint
- Server-side Ludo dice, movement, captures, safe tiles, home path, and win detection
- Compact match result and reward persistence
- Flutter Android client
- Local bot table fallback for playable internal builds
- Polished home screen, game board, dice animation, and Android sound effects

Still required before a Play Console internal test:

- Configure release signing for the Flutter Android app.
- Create Cloudflare remote D1/Queue resources and update `wrangler.toml`.
- Deploy the Worker and point the Flutter client at the deployed backend.
- Add real AdMob/IAP credentials when monetization testing starts.

See `docs/internal-testing-checklist.md`.
