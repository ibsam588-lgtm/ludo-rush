package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;

public final class ResultsScreen extends BaseScreen {
    private final JSONObject snapshot;

    public ResultsScreen(android.app.Activity activity, ScreenCallback callback, JSONObject snapshot) {
        super(activity, callback);
        this.snapshot = snapshot;
    }

    @Override
    public View createView() {
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

        // Show interstitial after defeat with a short delay
        if (!won) {
            new Handler(Looper.getMainLooper()).postDelayed(
                () -> AdManager.get().showInterstitial(null), 1800);
        }

        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(theme.bgPage());
        root.setPadding(dp(18), dp(30), dp(18), dp(18));
        root.setGravity(Gravity.CENTER_HORIZONTAL);

        // ── Top label ────────────────────────────────────────────────────────
        TextView headerLabel = text("MATCH COMPLETE", 12, theme.txtMuted(), Typeface.BOLD);
        headerLabel.setGravity(Gravity.CENTER);
        headerLabel.setLetterSpacing(0.14f);
        root.addView(headerLabel, lp(-1, -2, 0, 0, 0, dp(20)));

        // ── Trophy / dash icon ────────────────────────────────────────────────
        TextView trophy = text(won ? "🏆" : "😞", 56, won ? ThemeManager.YELLOW : theme.txtDim(), Typeface.BOLD);
        trophy.setGravity(Gravity.CENTER);
        root.addView(trophy, lp(-1, -2, 0, 0, 0, dp(8)));

        // ── Result heading ────────────────────────────────────────────────────
        TextView result = text(won ? "VICTORY!" : "DEFEAT", 30,
                won ? ThemeManager.GREEN : ThemeManager.RED, Typeface.BOLD);
        result.setGravity(Gravity.CENTER);
        result.setLetterSpacing(0.05f);
        root.addView(result, lp(-1, -2, 0, 0, 0, dp(4)));

        if (!won) {
            TextView winBy = text(winnerName + " won the match", 14, theme.txtMuted(), Typeface.NORMAL);
            winBy.setGravity(Gravity.CENTER);
            root.addView(winBy, lp(-1, -2, 0, 0, 0, dp(4)));
        }

        // ── Rewards card ──────────────────────────────────────────────────────
        LinearLayout rewardsCard = new LinearLayout(activity);
        rewardsCard.setOrientation(LinearLayout.HORIZONTAL);
        rewardsCard.setGravity(Gravity.CENTER);
        rewardsCard.setPadding(dp(20), dp(18), dp(20), dp(18));
        rewardsCard.setBackground(cardGradient(theme.bgGradStart(), theme.bgGradEnd(), dp(20)));
        root.addView(rewardsCard, lp(-1, -2, dp(16), dp(24), dp(16), dp(8)));

        addRewardCol(rewardsCard, "RATING", won ? "+12" : "−6",
                won ? ThemeManager.GREEN : ThemeManager.RED);
        addDividerV(rewardsCard);
        addRewardCol(rewardsCard, "COINS", won ? "+100" : "+15", ThemeManager.YELLOW);

        // Mode tag
        String mode = snapshot != null
            ? snapshot.optString("mode", "classic_2p").replace("_", " ").toUpperCase(java.util.Locale.US)
            : "—";
        TextView modeText = text("Mode: " + mode, 13, theme.txtMuted(), Typeface.NORMAL);
        modeText.setGravity(Gravity.CENTER);
        root.addView(modeText, lp(-1, -2, 0, dp(12), 0, dp(16)));

        // ── Players list ──────────────────────────────────────────────────────
        addSectionLabel(root, "PLAYERS");

        JSONArray seats = snapshot != null ? snapshot.optJSONArray("seats") : null;
        if (seats != null) {
            for (int i = 0; i < seats.length(); i++) {
                JSONObject s = seats.optJSONObject(i);
                if (s == null) continue;
                String name = s.optString("displayName", "Player");
                boolean isWinner = s.optString("playerId", "")
                        .equals(snapshot.optString("winnerPlayerId", ""));
                int seat = s.optInt("seat", 0);
                boolean isMe = callback.getPlayerId() != null
                        && callback.getPlayerId().equals(s.optString("playerId"));

                LinearLayout row = new LinearLayout(activity);
                row.setOrientation(LinearLayout.HORIZONTAL);
                row.setGravity(Gravity.CENTER_VERTICAL);
                row.setPadding(dp(14), dp(12), dp(14), dp(12));
                row.setBackground(card(
                    isWinner ? theme.bgSel() : theme.bgCard(),
                    dp(14),
                    isWinner ? 0x44F9A825 : theme.strokeCardAlt()));
                root.addView(row, lp(-1, -2, 0, 0, 0, dp(6)));

                View dot = new View(activity);
                dot.setBackground(circle(seatColor(seat)));
                row.addView(dot, lp(dp(24), dp(24), 0, 0, dp(10), 0));

                String displayName = (isMe ? "You" : name) + (s.optBoolean("isBot") ? " (Bot)" : "");
                LinearLayout.LayoutParams np = new LinearLayout.LayoutParams(0, -2, 1);
                row.addView(text(displayName, 15, theme.txtPrimary(), Typeface.BOLD), np);

                if (isWinner) {
                    row.addView(text("★ Winner", 13, ThemeManager.YELLOW, Typeface.BOLD));
                }
            }
        }

        // Spacer
        LinearLayout.LayoutParams sp = new LinearLayout.LayoutParams(-1, 0);
        sp.weight = 1;
        root.addView(new View(activity), sp);

        // ── Action buttons ────────────────────────────────────────────────────
        LinearLayout btnRow = new LinearLayout(activity);
        btnRow.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(btnRow, lp(-1, dp(56), 0, dp(16), 0, 0));

        Button again = actionButton("🎲  Play Again", ThemeManager.BLUE, ThemeManager.BLUE_LIGHT);
        again.setOnClickListener(v -> callback.startBotMatch("classic_2p"));
        LinearLayout.LayoutParams ap = new LinearLayout.LayoutParams(0, -1, 1);
        ap.setMargins(0, 0, dp(6), 0);
        btnRow.addView(again, ap);

        Button home = secondaryButton("Home");
        home.setTextSize(14);
        home.setOnClickListener(v -> callback.navigateTo("home"));
        LinearLayout.LayoutParams hp = new LinearLayout.LayoutParams(0, -1, 1);
        hp.setMargins(dp(6), 0, 0, 0);
        btnRow.addView(home, hp);

        return root;
    }

    private void addRewardCol(LinearLayout parent, String label, String value, int color) {
        LinearLayout col = new LinearLayout(activity);
        col.setOrientation(LinearLayout.VERTICAL);
        col.setGravity(Gravity.CENTER);
        col.setPadding(dp(20), dp(4), dp(20), dp(4));

        TextView v = text(value, 26, color, Typeface.BOLD);
        v.setGravity(Gravity.CENTER);
        col.addView(v);

        TextView l = text(label, 11, theme.txtMuted(), Typeface.BOLD);
        l.setGravity(Gravity.CENTER);
        l.setLetterSpacing(0.10f);
        col.addView(l);

        parent.addView(col, new LinearLayout.LayoutParams(0, -2, 1));
    }

    private void addDividerV(LinearLayout parent) {
        View v = new View(activity);
        v.setBackgroundColor(theme.strokeCard());
        parent.addView(v, lp(dp(1), dp(48)));
    }
}
