# Ludo Rush Backend

Cloudflare backend for Ludo Rush.

## Local Setup

```powershell
npm.cmd install
npm.cmd run typecheck
npm.cmd test
npm.cmd run dev
```

The local Worker defaults to:

```text
http://localhost:8787
```

## Main Endpoints

```text
GET  /health
POST /api/v1/auth/guest
POST /api/v1/matchmaking/quick
GET  /api/v1/matchmaking/tickets/:ticketId
POST /api/v1/matchmaking/tickets/:ticketId/cancel
POST /api/v1/matchmaking/bots
POST /api/v1/rooms/private
POST /api/v1/rooms/private/join
GET  /api/v1/rooms/:roomId
WS   /api/v1/rooms/:roomId/socket
```

## WebSocket Messages

Client to server:

```json
{ "type": "join", "playerId": "usr_123", "displayName": "Player" }
```

```json
{ "type": "roll_dice", "playerId": "usr_123" }
```

```json
{ "type": "move_piece", "playerId": "usr_123", "pieceId": "p0" }
```

```json
{ "type": "fill_bots", "playerId": "usr_123" }
```

Server to client:

```json
{ "type": "snapshot", "snapshot": {} }
```

```json
{ "type": "dice_rolled", "playerId": "usr_123", "value": 6, "snapshot": {} }
```

```json
{ "type": "move_accepted", "playerId": "usr_123", "pieceId": "s0_p0", "snapshot": {} }
```

## Notes

- Quick match now uses D1 tickets. First tester waits; second matching tester creates the room.
- The room validates turn order, dice, legal moves, captures, safe tiles, home entry, exact finish, and win state.
- Match completion updates match records, wallets, and ratings for human players.
- R2 is still intentionally excluded.
