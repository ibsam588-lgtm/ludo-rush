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

public final class ResultsScreen extends BaseScreen {
    private final JSONObject snapshot;

    public ResultsScreen(android.app.Activity activity, ScreenCallback callback, JSONObject snapshot) {
        super(activity, callback);
        this.snapshot = snapshot;
    }

    @Override
    public View createView() {
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(0xff080B13);
        root.setPadding(dp(18), dp(30), dp(18), dp(18));
        root.setGravity(Gravity.CENTER_HORIZONTAL);

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

        TextView header = text("MATCH COMPLETE", 14, 0xff6B7A90, Typeface.BOLD);
        header.setGravity(Gravity.CENTER);
        root.addView(header, lp(-1, -2, 0, 0, 0, dp(20)));

        TextView trophy = text(won ? "★" : "—", 56, won ? 0xffF9A825 : 0xff3A4556, Typeface.BOLD);
        trophy.setGravity(Gravity.CENTER);
        root.addView(trophy, lp(-1, -2, 0, 0, 0, dp(8)));

        TextView result = text(won ? "VICTORY!" : "DEFEAT", 28, won ? 0xff43A047 : 0xffE8293E, Typeface.BOLD);
        result.setGravity(Gravity.CENTER);
        root.addView(result, lp(-1, -2, 0, 0, 0, dp(4)));

        if (!won) {
            TextView winBy = text(winnerName + " won the match", 14, 0xff6B7A90, Typeface.NORMAL);
            winBy.setGravity(Gravity.CENTER);
            root.addView(winBy, lp(-1, -2, 0, 0, 0, dp(4)));
        }

        LinearLayout rewardsCard = new LinearLayout(activity);
        rewardsCard.setOrientation(LinearLayout.HORIZONTAL);
        rewardsCard.setGravity(Gravity.CENTER);
        rewardsCard.setPadding(dp(20), dp(18), dp(20), dp(18));
        rewardsCard.setBackground(cardGradient(0xff192133, 0xff101827, dp(20)));
        root.addView(rewardsCard, lp(-1, -2, dp(16), dp(24), dp(16), dp(8)));

        addReward(rewardsCard, "RATING", won ? "+12" : "-6", won ? 0xff43A047 : 0xffE8293E);
        addReward(rewardsCard, "COINS", won ? "+100" : "+15", 0xffF9A825);

        String mode = snapshot != null ? snapshot.optString("mode", "classic_2p").replace("_", " ").toUpperCase(java.util.Locale.US) : "—";
        TextView modeText = text(mode, 13, 0xff6B7A90, Typeface.NORMAL);
        modeText.setGravity(Gravity.CENTER);
        root.addView(modeText, lp(-1, -2, 0, dp(12), 0, dp(16)));

        addSectionLabel(root, "PLAYERS");

        JSONArray seats = snapshot != null ? snapshot.optJSONArray("seats") : null;
        if (seats != null) {
            for (int i = 0; i < seats.length(); i++) {
                JSONObject s = seats.optJSONObject(i);
                if (s == null) continue;
                String name = s.optString("displayName", "Player");
                boolean isWinner = s.optString("playerId", "").equals(snapshot.optString("winnerPlayerId", ""));
                int seat = s.optInt("seat", 0);
                boolean isMe = callback.getPlayerId() != null && callback.getPlayerId().equals(s.optString("playerId"));

                LinearLayout row = new LinearLayout(activity);
                row.setOrientation(LinearLayout.HORIZONTAL);
                row.setGravity(Gravity.CENTER_VERTICAL);
                row.setPadding(dp(14), dp(12), dp(14), dp(12));
                row.setBackground(card(isWinner ? 0xff152030 : 0xff111A2A, dp(14), isWinner ? 0x44F9A825 : 0x225D6D86));
                root.addView(row, lp(-1, -2, 0, 0, 0, dp(6)));

                View dot = new View(activity);
                dot.setBackground(card(seatColor(seat), dp(12), seatColor(seat)));
                row.addView(dot, lp(dp(24), dp(24), 0, 0, dp(10), 0));

                TextView nameView = text((isMe ? "You" : name) + (s.optBoolean("isBot") ? " (Bot)" : ""), 15, Color.WHITE, Typeface.BOLD);
                LinearLayout.LayoutParams np = new LinearLayout.LayoutParams(0, -2, 1);
                row.addView(nameView, np);

                if (isWinner) {
                    row.addView(text("★ Winner", 13, 0xffF9A825, Typeface.BOLD));
                }
            }
        }

        View spacer = new View(activity);
        LinearLayout.LayoutParams sp = new LinearLayout.LayoutParams(-1, 0);
        sp.weight = 1;
        root.addView(spacer, sp);

        LinearLayout btnRow = new LinearLayout(activity);
        btnRow.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(btnRow, lp(-1, dp(54), 0, dp(16), 0, 0));

        Button again = actionButton("Play Again", 0xff1E88E5, 0xff42A5F5);
        String playedMode = snapshot != null ? snapshot.optString("mode", "classic_2p") : "classic_2p";
        again.setOnClickListener(v -> callback.startBotMatch(playedMode));
        LinearLayout.LayoutParams ap = new LinearLayout.LayoutParams(0, -1, 1);
        ap.setMargins(0, 0, dp(6), 0);
        btnRow.addView(again, ap);

        Button home = secondaryButton("Home");
        home.setTextSize(15);
        home.setOnClickListener(v -> callback.navigateTo("home"));
        LinearLayout.LayoutParams hp = new LinearLayout.LayoutParams(0, -1, 1);
        hp.setMargins(dp(6), 0, 0, 0);
        btnRow.addView(home, hp);

        return root;
    }

    private void addReward(LinearLayout parent, String label, String value, int color) {
        LinearLayout col = new LinearLayout(activity);
        col.setOrientation(LinearLayout.VERTICAL);
        col.setGravity(Gravity.CENTER);
        col.setPadding(dp(20), dp(4), dp(20), dp(4));

        TextView v = text(value, 24, color, Typeface.BOLD);
        v.setGravity(Gravity.CENTER);
        col.addView(v);

        TextView l = text(label, 11, 0xff6B7A90, Typeface.BOLD);
        l.setGravity(Gravity.CENTER);
        col.addView(l);

        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
        parent.addView(col, p);
    }
}
