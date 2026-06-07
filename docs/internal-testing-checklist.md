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

## Unity Scene Wiring

Open `client-unity` in Unity Hub.

Create an internal test scene with:

- `LudoRushConfig` asset
- `Network` GameObject with `LudoRushApiClient` and `RealtimeRoomClient`
- `Game` GameObject with `LudoGameController`, `LudoBoardPresenter`, and `InternalTestHud`

Set `LudoRushConfig.BackendBaseUrl` to either:

```text
http://localhost:8787
```

for local testing, or your deployed Cloudflare Worker URL for tester builds.

Wire serialized fields:

- `LudoRushApiClient.config`
- `LudoGameController.apiClient`
- `LudoGameController.realtimeClient`
- `LudoGameController.config`
- `LudoGameController.boardPresenter`
- `InternalTestHud.controller`

## Android Build

1. Set package name, for example:

   ```text
   com.ludorush.game
   ```

2. Switch platform to Android.
3. Create a release upload keystore and keep it private.
4. Build an Android App Bundle (`.aab`).
5. Upload the bundle to Play Console internal testing.

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
- Automated Unity build pipeline
- Production monitoring dashboards

## Official References

- Google Play internal testing: https://support.google.com/googleplay/android-developer/answer/9845334
- Android app signing: https://developer.android.com/studio/publish/app-signing
- Android release builds: https://developer.android.com/build/build-for-release
- Google Mobile Ads Unity plugin: https://developers.google.com/admob/unity/quick-start
