# Match voice rollout

Ludo Cheer uses opt-in WebRTC audio between human seats. Signaling runs over the authenticated room socket. The microphone is requested only after a player taps **Join voice**, and voice is restricted to age-13+ human players in active matches. A server-hosted table allows its only human player to join voice; the microphone stays ready if another player joins. In a device-run fallback match, **Join voice** enables the microphone locally, with no room or remote listener. The UI says when only that player is in voice. Bots and spectators cannot receive voice. Finishing or leaving the match and backgrounding the app stop capture. Audio is not recorded by the game backend.

Configure Cloudflare Realtime TURN before a production release so players behind restrictive mobile networks can connect. Create a TURN key in Cloudflare Realtime, then set its ID and API token as Worker secrets:

```sh
cd backend-cloudflare
npx wrangler secret put TURN_KEY_ID
npx wrangler secret put TURN_KEY_API_TOKEN
```

The authenticated `/api/v1/voice/ice?roomId=...` endpoint issues four-hour ICE credentials only to an active human seat. If these secrets are absent, it returns Cloudflare STUN only; voice can fail when peer-to-peer connectivity is blocked. Do not put the long-lived TURN token in the Flutter app or Git.

Apply D1 migration `0006_voice_moderation.sql` before deploying the updated Worker. Players must accept the table voice rules before joining. The voice sheet offers self-mute, per-player mute, block, and report. A block is stored in D1 and the room rejects WebRTC signaling between either side. Reports store the reporter, reported player, room, reason, time, and review status; no audio is recorded. Review open reports regularly with `SELECT * FROM user_reports WHERE status = 'open' ORDER BY created_at` and document action taken by updating `status` after review. Escalate urgent threats promptly and restrict abusive accounts where appropriate.

Before publishing the Android build, verify the Google Play Data safety form for optional live voice audio and update the content-rating questionnaire for player voice communication. Confirm that the [Corsair Labs privacy policy](https://corsairlabs.com/ludo-rush-privacy-policy) includes voice and moderation records. Test two real Android devices on separate mobile/Wi-Fi networks, including per-player mute, block, report, leave, reconnect, backgrounding, and microphone denial.
