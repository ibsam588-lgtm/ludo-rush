CREATE TABLE IF NOT EXISTS app_release_config (
  platform TEXT PRIMARY KEY,
  minimum_build_number INTEGER NOT NULL,
  latest_build_number INTEGER NOT NULL,
  latest_version_name TEXT NOT NULL,
  force_latest INTEGER NOT NULL DEFAULT 1,
  update_url TEXT NOT NULL,
  message TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

INSERT OR IGNORE INTO app_release_config (
  platform,
  minimum_build_number,
  latest_build_number,
  latest_version_name,
  force_latest,
  update_url,
  message,
  updated_at
) VALUES (
  'android',
  10042,
  10042,
  '1.0.42',
  1,
  'https://play.google.com/store/apps/details?id=com.ludorush.game',
  'A newer version of Ludo Rush is required to keep matchmaking, rewards, and game rules in sync.',
  1783760400000
);
