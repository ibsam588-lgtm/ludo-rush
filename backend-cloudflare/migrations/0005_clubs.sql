CREATE TABLE IF NOT EXISTS clubs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  tag TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  minimum_rating INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS club_members (
  user_id TEXT PRIMARY KEY,
  club_id TEXT NOT NULL,
  contribution INTEGER NOT NULL DEFAULT 0,
  joined_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (club_id) REFERENCES clubs(id)
);

CREATE INDEX IF NOT EXISTS idx_club_members_club
  ON club_members(club_id, contribution DESC, joined_at ASC);

INSERT OR IGNORE INTO clubs (
  id, name, tag, description, minimum_rating, created_at
) VALUES
  ('club_royal_rollers', 'Royal Rollers', 'ROYAL', 'Competitive tables and weekly chest progress.', 900, 1783800000000),
  ('club_dice_dynasty', 'Dice Dynasty', 'DICE', 'Friendly matches, gifts, and steady progression.', 700, 1783800000000),
  ('club_carnival_kings', 'Carnival Kings', 'FUN', 'Open club for new players and casual events.', 0, 1783800000000);
