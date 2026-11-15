-- 1901 is the first iOS 16 release with verified purchasing-account recovery.
-- Earlier iOS builds were beta-only; there is no older public iOS release.
-- Sandbox update links are selected by the Worker environment, not shared with
-- the production App Store policy. Android's release floor is unchanged.
INSERT INTO app_release_config (
  platform, minimum_build_number, latest_build_number, latest_version_name,
  force_latest, update_url, message, updated_at
) VALUES (
  'ios', 1901, 1901, '1.0.0', 1,
  'https://apps.apple.com/app/id6834993861',
  'Update Ludo Cheer from the App Store to keep playing.',
  CAST(strftime('%s', 'now') AS INTEGER) * 1000
)
ON CONFLICT(platform) DO UPDATE SET
  minimum_build_number = MAX(app_release_config.minimum_build_number, excluded.minimum_build_number),
  latest_build_number = MAX(app_release_config.latest_build_number, excluded.latest_build_number),
  latest_version_name = CASE
    WHEN app_release_config.latest_build_number <= excluded.latest_build_number THEN excluded.latest_version_name
    ELSE app_release_config.latest_version_name END,
  force_latest = 1,
  updated_at = excluded.updated_at;

-- Preserve Android's published build policy while fixing its legacy name.
UPDATE app_release_config
SET message = REPLACE(message, 'Ludo Rush', 'Ludo Cheer')
WHERE INSTR(message, 'Ludo Rush') > 0;
