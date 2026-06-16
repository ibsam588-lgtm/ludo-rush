# Internal Testing Checklist

This checklist targets an Android internal test first.

## Backend

1. Install dependencies:

   ```powershell
   cd "C:\Users\ibsam\Documents\Ludo Star\backend-cloudflare"
   npm.cmd install
   ```

2. Log in to Cloudflare:

   ```powershell
   npx.cmd wrangler login
   ```

3. Create remote resources:

   ```powershell
   npx.cmd wrangler d1 create ludo-rush-db
   npx.cmd wrangler queues create ludo-rush-background
   ```

4. Copy the real D1 `database_id` into `backend-cloudflare/wrangler.toml`.

5. Apply remote migrations:

   ```powershell
   npm.cmd run db:migrate:remote
   ```

6. Deploy:

   ```powershell
   npm.cmd run deploy
   ```

7. Test the deployed health URL:

   ```text
   https://<your-worker>.<your-account>.workers.dev/health
   ```

## Flutter Client

Open `client-flutter` for app work. The current Android client is Flutter and uses package name:

```text
com.ludorush.game
```

For local backend testing, use:

```text
http://localhost:8787
```

For tester builds, point the Flutter backend URL at the deployed Cloudflare Worker URL.

## Android Build

1. Create a release upload keystore and keep it private.
2. Build an Android App Bundle (`.aab`) from `client-flutter`.
3. Upload the bundle to Play Console internal testing.

Google says internal testing supports up to 100 testers and new internal-test Android App Bundles are typically available to testers within minutes.

## Current Test Flows

- `Quick`: waits for another tester in same mode/region.
- `Bots`: creates a room and fills the empty seat with a bot.
- `Private`: creates a code; share it manually with another tester.
- `Roll`: asks the server to roll dice.
- `Move`: moves the first legal piece from the server-provided available move list.

## Not Yet Final

- Final graphics and animations
- Real AdMob plugin and ad-unit IDs
- Real Google Play Billing / Apple StoreKit integration
- Privacy policy and store listing
- Automated Flutter build pipeline
- Production monitoring dashboards

## Official References

- Google Play internal testing: https://support.google.com/googleplay/android-developer/answer/9845334
- Android app signing: https://developer.android.com/studio/publish/app-signing
- Android release builds: https://developer.android.com/build/build-for-release
- Google Mobile Ads Flutter plugin: https://developers.google.com/admob/flutter/quick-start
