package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

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

        if (callback.getGamesPlayed() == 0) {
            LinearLayout emptyCard = new LinearLayout(activity);
            emptyCard.setOrientation(LinearLayout.VERTICAL);
            emptyCard.setGravity(Gravity.CENTER);
            emptyCard.setPadding(dp(20), dp(40), dp(20), dp(40));
            emptyCard.setBackground(card(0xff111A2A, dp(16), 0x225D6D86));
            content.addView(emptyCard);

            TextView emptyIcon = text("—", 32, 0xff3A4556, Typeface.BOLD);
            emptyIcon.setGravity(Gravity.CENTER);
            emptyCard.addView(emptyIcon);

            TextView emptyText = text("No matches yet", 16, 0xff6B7A90, Typeface.BOLD);
            emptyText.setGravity(Gravity.CENTER);
            emptyCard.addView(emptyText, lp(-1, -2, 0, dp(8), 0, dp(4)));

            TextView emptyHint = text("Play a match to see your history here", 13, 0xff4A5568, Typeface.NORMAL);
            emptyHint.setGravity(Gravity.CENTER);
            emptyCard.addView(emptyHint);
        } else {
            for (int i = 0; i < Math.min(callback.getGamesPlayed(), 10); i++) {
                boolean won = i < callback.getWins();
                addMatchEntry(content, won, i);
            }
        }

        return createScreenShell("Match History", content);
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

    private void addMatchEntry(LinearLayout parent, boolean won, int index) {
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

        info.addView(text("Classic 2P — " + (won ? "Victory" : "Defeat"), 14, Color.WHITE, Typeface.BOLD));
        info.addView(text("vs Rush Bot", 12, 0xff6B7A90, Typeface.NORMAL));

        LinearLayout rewards = new LinearLayout(activity);
        rewards.setOrientation(LinearLayout.VERTICAL);
        rewards.setGravity(Gravity.END);
        card.addView(rewards);

        rewards.addView(text((won ? "+12" : "-6") + " rating", 12, won ? 0xff43A047 : 0xffE8293E, Typeface.BOLD));
        rewards.addView(text((won ? "+100" : "+15") + " coins", 12, 0xffF9A825, Typeface.NORMAL));
    }
}
