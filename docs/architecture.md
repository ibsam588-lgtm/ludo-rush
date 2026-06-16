# Ludo Rush Architecture

## MVP Backend Flow

```text
Flutter app
  -> Worker REST API
  -> Durable Object room over WebSocket
  -> D1 for permanent user/wallet/match/purchase records
  -> Queue for background settlement and purchase validation
```

## Why This Shape

- Ludo is turn-based, so one Durable Object per live room is enough authority.
- The client only asks to roll or move; the room decides whether the action is legal.
- D1 stores durable facts, not high-frequency live room state.
- R2 is intentionally excluded for now.

## First Multiplayer Slice

1. App creates a guest profile.
2. App requests quick match or private room.
3. Worker creates or finds a Durable Object room.
4. App opens the room WebSocket.
5. App sends `join`.
6. Room broadcasts snapshots and authoritative dice/move events.

## Next Backend Slices

- Rating-band expansion for quick match after the first wait window.
- Reconnect token and active-match lookup.
- Disconnect replacement timer.
- Anti-abuse analytics and fraud review.
- Purchase validation.
- Production observability.
