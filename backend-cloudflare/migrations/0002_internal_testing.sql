CREATE TABLE IF NOT EXISTS matchmaking_tickets (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  mode TEXT NOT NULL,
  region TEXT NOT NULL,
  rating INTEGER NOT NULL,
  latency_ms INTEGER,
  status TEXT NOT NULL,
  room_id TEXT,
  requested_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  FOREIGN KEY (player_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_matchmaking_waiting
  ON matchmaking_tickets(status, mode, region, requested_at);

CREATE INDEX IF NOT EXISTS idx_matchmaking_player
  ON matchmaking_tickets(player_id, updated_at);

CREATE TABLE IF NOT EXISTS private_rooms (
  code TEXT PRIMARY KEY,
  room_id TEXT NOT NULL UNIQUE,
  mode TEXT NOT NULL,
  region TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_private_rooms_expires_at
  ON private_rooms(expires_at);
