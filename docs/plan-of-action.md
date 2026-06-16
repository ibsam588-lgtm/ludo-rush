# Ludo Rush Plan Of Action

## Phase 1: Foundation

- Set up Flutter mobile project structure.
- Set up Cloudflare Worker API with Durable Object room authority.
- Add D1 schema for users, wallets, purchases, and match history.
- Define shared gameplay message contracts.
- Implement guest auth and basic player profile.

## Phase 2: Core Ludo

- Build local game rules: board path, safe tiles, captures, home entry, turn order, dice rules, and win conditions.
- Add bot decision logic for disconnected or empty seats.
- Build first playable UI: board, tokens, dice, player panels, timer, and match result.

## Phase 3: Online Multiplayer

- Add quick match by region, mode, rating band, and wait time.
- Add private room creation and join codes.
- Add WebSocket room join/rejoin flow.
- Make the Durable Object validate all dice rolls, moves, captures, turn timers, and winners.
- Save only compact final match results to D1.

## Phase 4: Monetization

- Add AdMob banner placements on lobby/results screens.
- Add rewarded video placement for optional coin rewards.
- Add platform IAP hooks for coin packs and remove-ads.
- Add server-side purchase ledger and idempotent reward grants.

## Phase 5: Polish And Launch

- Add Ludo Rush visual identity: themed boards, animated dice, expressive tokens, capture effects, home-run celebrations, and quick-session mode.
- Add privacy policy, terms, consent flow, age rating, and store assets.
- Launch Android closed test, tune retention and match quality, then prepare iOS.

## Cost Guardrails

- Use Durable Object WebSocket hibernation.
- Avoid polling.
- Send compact room events.
- Save match results, not every move.
- Bundle MVP graphics in the app.
- Add R2 later only if downloadable assets or large file storage become necessary.
