-- Keep the purchasing player's existing wallet and appAccountToken stable
-- after reinstall or a device change. Only Apple-verified app transactions
-- can establish/recover these mappings; the raw Apple ID is not stored.
CREATE TABLE IF NOT EXISTS app_store_accounts (
  account_hash TEXT PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
