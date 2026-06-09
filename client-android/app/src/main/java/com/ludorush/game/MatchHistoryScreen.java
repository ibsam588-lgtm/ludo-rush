package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;

public final class MatchHistoryScreen extends BaseScreen {

    public MatchHistoryScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);

        addSectionLabel(content, "SUMMARY");

        LinearLayout summary = new LinearLayout(activity);
        summary.setOrientation(LinearLayout.HORIZONTAL);
        content.addView(summary, lp(-1, -2, 0, 0, 0, dp(8)));

        addStat(summary, String.valueOf(callback.getGamesPlayed()), "Played", 0xff1E88E5);
        addStat(summary, String.valueOf(callback.getWins()), "Won", 0xff43A047);
        int losses = Math.max(0, callback.getGamesPlayed() - callback.getWins());
        addStat(summary, String.valueOf(losses), "Lost", 0xffE8293E);

        addSectionLabel(content, "RECENT MATCHES");

        JSONArray entries = loadHistory();
        if (entries.length() == 0) {
            LinearLayout emptyCard = new LinearLayout(activity);
            emptyCard.setOrientation(LinearLayout.VERTICAL);
            emptyCard.setGravity(Gravity.CENTER);
            emptyCard.setPadding(dp(20), dp(40), dp(20), dp(40));
            emptyCard.setBackground(card(0xff111A2A, dp(16), 0x225D6D86));
            content.addView(emptyCard);

            TextView emptyIcon = text("🎲", 32, 0xff3A4556, Typeface.BOLD);
            emptyIcon.setGravity(Gravity.CENTER);
            emptyCard.addView(emptyIcon);

            TextView emptyText = text("No matches yet", 16, 0xff6B7A90, Typeface.BOLD);
            emptyText.setGravity(Gravity.CENTER);
            emptyCard.addView(emptyText, lp(-1, -2, 0, dp(8), 0, dp(4)));

            TextView emptyHint = text("Play a match to see your history here", 13, 0xff4A5568, Typeface.NORMAL);
            emptyHint.setGravity(Gravity.CENTER);
            emptyCard.addView(emptyHint);
        } else {
            for (int i = 0; i < entries.length(); i++) {
                JSONObject entry = entries.optJSONObject(i);
                if (entry != null) addMatchEntry(content, entry);
            }
        }

        return createScreenShell("Match History", content);
    }

    private JSONArray loadHistory() {
        try {
            String raw = activity.getSharedPreferences("ludo_history", 0).getString("entries", "[]");
            return new JSONArray(raw);
        } catch (Exception e) {
            return new JSONArray();
        }
    }

    private void addStat(LinearLayout parent, String value, String label, int color) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setGravity(Gravity.CENTER);
        card.setPadding(dp(12), dp(14), dp(12), dp(14));
        card.setBackground(card(0xff111A2A, dp(14), 0x225D6D86));

        TextView v = text(value, 22, color, Typeface.BOLD);
        v.setGravity(Gravity.CENTER);
        card.addView(v);

        TextView l = text(label, 12, 0xff6B7A90, Typeface.BOLD);
        l.setGravity(Gravity.CENTER);
        card.addView(l);

        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        parent.addView(card, p);
    }

    private void addMatchEntry(LinearLayout parent, JSONObject entry) {
        boolean won = entry.optBoolean("won", false);
        String mode = prettyMode(entry.optString("mode", "classic_2p"));
        String opponents = entry.optString("opponents", "Unknown");
        boolean forfeit = "Forfeit".equals(opponents);
        int ratingDelta = entry.optInt("ratingDelta", 0);
        int coinsDelta = entry.optInt("coinsDelta", 0);
        long at = entry.optLong("at", 0);

        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(14), dp(14), dp(14), dp(14));
        card.setBackground(card(0xff111A2A, dp(14), won ? 0x2243A047 : 0x22E8293E));
        parent.addView(card, lp(-1, -2, 0, 0, 0, dp(8)));

        TextView result = text(won ? "W" : "L", 18, won ? 0xff43A047 : 0xffE8293E, Typeface.BOLD);
        result.setGravity(Gravity.CENTER);
        result.setPadding(dp(4), 0, dp(12), 0);
        card.addView(result, lp(dp(36), -2));

        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams ip = new LinearLayout.LayoutParams(0, -2, 1);
        card.addView(info, ip);

        String outcome = forfeit ? "Forfeit" : (won ? "Victory" : "Defeat");
        info.addView(text(mode + " — " + outcome, 14, Color.WHITE, Typeface.BOLD));
        info.addView(text(forfeit ? "Left the match" : "vs " + opponents, 12, 0xff6B7A90, Typeface.NORMAL));
        info.addView(text(relativeTime(at), 11, 0xff4A5568, Typeface.NORMAL));

        LinearLayout rewards = new LinearLayout(activity);
        rewards.setOrientation(LinearLayout.VERTICAL);
        rewards.setGravity(Gravity.END);
        card.addView(rewards);

        rewards.addView(text((ratingDelta >= 0 ? "+" : "") + ratingDelta + " rating", 12,
                ratingDelta >= 0 ? 0xff43A047 : 0xffE8293E, Typeface.BOLD));
        rewards.addView(text("+" + coinsDelta + " coins", 12, 0xffF9A825, Typeface.NORMAL));
    }

    private String prettyMode(String mode) {
        switch (mode) {
            case "classic_4p": return "Classic 4P";
            case "rush_2p": return "Rush 2P";
            case "rush_4p": return "Rush 4P";
            default: return "Classic 2P";
        }
    }

    private String relativeTime(long at) {
        if (at <= 0) return "";
        long delta = System.currentTimeMillis() - at;
        if (delta < 60_000L) return "Just now";
        if (delta < 3_600_000L) return (delta / 60_000L) + "m ago";
        if (delta < 86_400_000L) return (delta / 3_600_000L) + "h ago";
        return (delta / 86_400_000L) + "d ago";
    }
}
