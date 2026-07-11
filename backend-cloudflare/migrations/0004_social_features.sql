ALTER TABLE users ADD COLUMN age INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN country_code TEXT NOT NULL DEFAULT 'US';
ALTER TABLE users ADD COLUMN avatar_key TEXT;

CREATE TABLE IF NOT EXISTS auth_sessions (
  token_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_auth_sessions_user_id
  ON auth_sessions(user_id, expires_at);

CREATE TABLE IF NOT EXISTS friendships (
  user_a TEXT NOT NULL,
  user_b TEXT NOT NULL,
  requested_by TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted')),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (user_a, user_b),
  FOREIGN KEY (user_a) REFERENCES users(id),
  FOREIGN KEY (user_b) REFERENCES users(id),
  FOREIGN KEY (requested_by) REFERENCES users(id),
  CHECK (user_a < user_b)
);

CREATE INDEX IF NOT EXISTS idx_friendships_user_a ON friendships(user_a, status);
CREATE INDEX IF NOT EXISTS idx_friendships_user_b ON friendships(user_b, status);

CREATE TABLE IF NOT EXISTS friend_gifts (
  id TEXT PRIMARY KEY,
  sender_user_id TEXT NOT NULL,
  recipient_user_id TEXT NOT NULL,
  gift_id TEXT NOT NULL,
  coin_cost INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (sender_user_id) REFERENCES users(id),
  FOREIGN KEY (recipient_user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_friend_gifts_recipient
  ON friend_gifts(recipient_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS friend_messages (
  id TEXT PRIMARY KEY,
  sender_user_id TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (sender_user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_friend_messages_created_at
  ON friend_messages(created_at DESC);

CREATE TABLE IF NOT EXISTS reward_claims (
  user_id TEXT NOT NULL,
  reward_id TEXT NOT NULL,
  period_key TEXT NOT NULL,
  claimed_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, reward_id, period_key),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_reward_claims_user
  ON reward_claims(user_id, reward_id, claimed_at);
