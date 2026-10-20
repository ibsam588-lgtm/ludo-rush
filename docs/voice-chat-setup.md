# Match voice rollout

Ludo Rush uses opt-in WebRTC audio between human seats. Signaling runs over the authenticated room socket. The microphone is requested only after a player taps **Join voice**, and voice is restricted to age-13+ human players in active matches. A server-hosted table allows its only human player to join voice; the microphone stays ready if another player joins. In a device-run fallback match, **Join voice** enables the microphone locally, with no room or remote listener. The UI says when only that player is in voice. Bots and spectators cannot receive voice. Finishing or leaving the match and backgrounding the app stop capture. Audio is not recorded by the game backend.

Configure Cloudflare Realtime TURN before a production release so players behind restrictive mobile networks can connect. Create a TURN key in Cloudflare Realtime, then set its ID and API token as Worker secrets:

```sh
cd backend-cloudflare
npx wrangler secret put TURN_KEY_ID
npx wrangler secret put TURN_KEY_API_TOKEN
```

The authenticated `/api/v1/voice/ice?roomId=...` endpoint issues four-hour ICE credentials only to an active human seat. If these secrets are absent, it returns Cloudflare STUN only; voice can fail when peer-to-peer connectivity is blocked. Do not put the long-lived TURN token in the Flutter app or Git.

Before publishing the Android build, update the Google Play Data safety form for optional live voice audio and verify that the [Corsair Labs privacy policy](https://corsairlabs.com/ludo-rush-privacy-policy) includes voice sharing and the Cloudflare TURN relay. Test two real Android devices on separate mobile/Wi-Fi networks, including mute, leave, reconnect, backgrounding, and microphone denial.
