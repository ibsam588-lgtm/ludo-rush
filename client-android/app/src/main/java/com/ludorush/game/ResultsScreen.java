package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Royal Rush Results Screen.
 *
 * Uses the real game snapshot (JSONObject) from the server to show:
 *   • Win / Loss headline with trophy/dash icon
 *   • Rewards card (rating delta + coins)
 *   • Player ranking list from snapshot seats array
 *   • Play Again (via interstitial) + Home buttons
 */
public final class ResultsScreen extends BaseScreen {

    private final JSONObject snapshot;

    public ResultsScreen(android.app.Activity activity, ScreenCallback callback,
                         JSONObject snapshot) {
        super(activity, callback);
        this.snapshot = snapshot;
    }

    @Override
    public View createView() {
        // ── Resolve winner from snapshot ────────────────────────────────────────
        boolean won = false;
        String winnerName = "Unknown";
        if (snapshot != null) {
            String winnerId = snapshot.optString("winnerPlayerId", "");
            String myId = callback.getPlayerId();
            won = myId != null && myId.equals(winnerId);
            JSONArray seats = snapshot.optJSONArray("seats");
            if (seats != null) {
                for (int i = 0; i < seats.length(); i++) {
                    JSONObject s = seats.optJSONObject(i);
                    if (s != null && winnerId.equals(s.optString("playerId"))) {
                        winnerName = s.optString("displayName", "Player");
                        break;
                    }
                }
            }
        }
        final boolean didWin = won;

        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setGravity(Gravity.CENTER_HORIZONTAL);

        // ── Hero banner ──────────────────────────────────────────────────────
        body.addView(buildHeroBanner(didWin, winnerName), lp(-1, -2, 0, 0, 0, dp(20)));

        // ── Rewards card ─────────────────────────────────────────────────────
        body.addView(buildRewardsCard(didWin), lp(-1, -2, 0, 0, 0, dp(20)));

        // ── Mode pill ────────────────────────────────────────────────────────
        String mode = snapshot != null
                ? snapshot.optString("mode", "classic_2p").replace("_", " ")
                          .toUpperCase(java.util.Locale.US)
                : "CLASSIC";
        TextView modePill = badge("Mode: " + mode, theme.bgCard(), theme.txtMuted());
        modePill.setGravity(Gravity.CENTER);
        body.addView(modePill, lp(-2, -2, 0, 0, 0, dp(20)));

        // ── Player rows ──────────────────────────────────────────────────────
        addSectionLabel(body, "PLAYERS");
        body.addView(buildPlayerList(), lp(-1, -2, 0, 0, 0, dp(28)));

        // ── Action buttons ───────────────────────────────────────────────────
        body.addView(buildActionButtons());

        return createScreenShell("Match Over", body);
    }

    // ── Hero banner ───────────────────────────────────────────────────────────

    private View buildHeroBanner(boolean won, String winnerName) {
        LinearLayout banner = new LinearLayout(activity);
        banner.setOrientation(LinearLayout.VERTICAL);
        banner.setGravity(Gravity.CENTER);
        banner.setBackground(cardGradient(theme.bgHeroStart(), theme.bgHeroEnd(), dp(22)));
        banner.setPadding(dp(20), dp(28), dp(20), dp(24));

        // Icon
        TextView icon = new TextView(activity);
        icon.setText(won ? "🏆" : "😞");
        icon.setTextSize(52);
        icon.setGravity(Gravity.CENTER);
        banner.addView(icon, lp(-1, -2, 0, 0, 0, dp(10)));

        // Headline
        TextView headline = text(won ? "Victory!" : "Defeat",
                28, Color.WHITE, Typeface.BOLD);
        headline.setGravity(Gravity.CENTER);
        headline.setLetterSpacing(0f);
        banner.addView(headline, lp(-1, -2, 0, 0, 0, dp(4)));

        // Subline
        String sub = won
                ? callback.getDisplayName() + " wins this match"
                : winnerName + " won the match";
        TextView subTv = text(sub, 13, 0xCCFFFFFF, Typeface.NORMAL);
        subTv.setGravity(Gravity.CENTER);
        banner.addView(subTv);

        return banner;
    }

    // ── Rewards card ──────────────────────────────────────────────────────────

    private View buildRewardsCard(boolean won) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER);
        card.setBackground(glowCard(theme.bgCard(), dp(18), theme.strokeCardGlow()));
        card.setPadding(dp(16), dp(20), dp(16), dp(20));

        addRewardCol(card, "RATING", won ? "+12" : "−6",
                won ? ThemeManager.GREEN : ThemeManager.RED);

        View divider = new View(activity);
        divider.setBackgroundColor(theme.strokeCard());
        card.addView(divider, lp(dp(1), dp(44)));

        addRewardCol(card, "COINS", won ? "+100" : "+15", ThemeManager.GOLD);

        return card;
    }

    private void addRewardCol(LinearLayout parent, String label, String value, int color) {
        LinearLayout col = new LinearLayout(activity);
        col.setOrientation(LinearLayout.VERTICAL);
        col.setGravity(Gravity.CENTER);
        col.setPadding(dp(24), 0, dp(24), 0);

        TextView v = text(value, 24, color, Typeface.BOLD);
        v.setGravity(Gravity.CENTER);
        col.addView(v, lp(-1, -2, 0, 0, 0, dp(3)));

        TextView l = text(label, 10, theme.txtMuted(), Typeface.BOLD);
        l.setGravity(Gravity.CENTER);
        l.setLetterSpacing(0.04f);
        col.addView(l);

        parent.addView(col, new LinearLayout.LayoutParams(0, -2, 1));
    }

    // ── Player list ───────────────────────────────────────────────────────────

    private View buildPlayerList() {
        LinearLayout list = new LinearLayout(activity);
        list.setOrientation(LinearLayout.VERTICAL);

        JSONArray seats = snapshot != null ? snapshot.optJSONArray("seats") : null;
        String winnerId = snapshot != null ? snapshot.optString("winnerPlayerId", "") : "";

        if (seats != null && seats.length() > 0) {
            for (int i = 0; i < seats.length(); i++) {
                JSONObject s = seats.optJSONObject(i);
                if (s == null) continue;
                String name    = s.optString("displayName", "Player " + (i + 1));
                boolean isWinner = winnerId.equals(s.optString("playerId", ""));
                boolean isMe   = callback.getPlayerId() != null
                        && callback.getPlayerId().equals(s.optString("playerId"));
                boolean isBot  = s.optBoolean("isBot", false);
                int seat       = s.optInt("seat", i);

                list.addView(buildPlayerRow(name, seat, isWinner, isMe, isBot),
                        lp(-1, -2, 0, 0, 0, i < seats.length() - 1 ? dp(8) : 0));
            }
        } else {
            // Fallback when no snapshot: show a single placeholder row
            list.addView(buildPlayerRow(callback.getDisplayName(), 0, true, true, false));
        }

        return list;
    }

    private View buildPlayerRow(String name, int seat, boolean isWinner,
                                 boolean isMe, boolean isBot) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);

        int bgColor     = isWinner ? theme.bgSel() : theme.bgCard();
        int borderColor = isWinner ? 0x44F5B700 : theme.strokeCard();
        row.setBackground(glowCard(bgColor, dp(16), borderColor));
        row.setPadding(dp(14), dp(13), dp(14), dp(13));

        // Seat color dot
        View dot = new View(activity);
        dot.setBackground(circle(seatColor(seat)));
        row.addView(dot, lp(dp(12), dp(12), 0, 0, dp(12), 0));

        // Name
        String displayName = (isMe ? "You" : name) + (isBot ? " (Bot)" : "");
        row.addView(text(displayName, 14, theme.txtPrimary(), Typeface.BOLD),
                new LinearLayout.LayoutParams(0, -2, 1));

        // Winner badge or rank
        if (isWinner) {
            row.addView(badge("★ Winner", 0x22F5B700, ThemeManager.GOLD));
        } else {
            row.addView(text("-", 13, theme.txtMuted(), Typeface.NORMAL));
        }

        return row;
    }

    // ── Action buttons ────────────────────────────────────────────────────────

    private View buildActionButtons() {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);

        Button again = primaryButton("⚡  Play Again");
        again.setPadding(0, dp(14), 0, dp(14));
        again.setOnClickListener(v ->
                AdManager.get().showInterstitial(() -> callback.startBotMatch("classic_2p")));
        LinearLayout.LayoutParams ap = new LinearLayout.LayoutParams(0, dp(52), 1);
        ap.setMargins(0, 0, dp(10), 0);
        row.addView(again, ap);

        Button home = secondaryButton("⌂  Home");
        home.setPadding(0, dp(14), 0, dp(14));
        home.setOnClickListener(v -> callback.navigateTo("home"));
        row.addView(home, new LinearLayout.LayoutParams(0, dp(52), 1));

        return row;
    }
}
