CREATE TABLE IF NOT EXISTS user_blocks (
  user_id TEXT NOT NULL,
  blocked_user_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, blocked_user_id)
);

CREATE TABLE IF NOT EXISTS user_reports (
  id TEXT PRIMARY KEY,
  reporter_user_id TEXT NOT NULL,
  reported_user_id TEXT NOT NULL,
  room_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_user_reports_status ON user_reports(status, created_at);
