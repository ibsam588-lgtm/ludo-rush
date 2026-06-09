ALTER TABLE users ADD COLUMN auth_token TEXT;

CREATE INDEX IF NOT EXISTS idx_users_rating ON users(rating DESC);
