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

        // ── Summary stats ─────────────────────────────────────────────────────
        addSectionLabel(content, "SUMMARY");

        LinearLayout summary = new LinearLayout(activity);
        summary.setOrientation(LinearLayout.HORIZONTAL);
        content.addView(summary, lp(-1, -2, 0, 0, 0, dp(8)));

        int losses = Math.max(0, callback.getGamesPlayed() - callback.getWins());
        addStatCard(summary, String.valueOf(callback.getGamesPlayed()), "Played", ThemeManager.BLUE);
        addStatCard(summary, String.valueOf(callback.getWins()),        "Won",    ThemeManager.GREEN);
        addStatCard(summary, String.valueOf(losses),                    "Lost",   ThemeManager.RED);

        // Win rate bar
        if (callback.getGamesPlayed() > 0) {
            int pct = callback.getWins() * 100 / callback.getGamesPlayed();
            LinearLayout barBg = new LinearLayout(activity);
            barBg.setOrientation(LinearLayout.HORIZONTAL);
            barBg.setBackground(card(theme.bgCard(), dp(8), theme.strokeCard()));
            content.addView(barBg, lp(-1, dp(8), 0, dp(6), 0, dp(4)));

            View filled = new View(activity);
            filled.setBackground(card(ThemeManager.GREEN, dp(8), 0));
            barBg.addView(filled, new LinearLayout.LayoutParams(0, -1, pct));
            View empty = new View(activity);
            barBg.addView(empty, new LinearLayout.LayoutParams(0, -1, 100 - pct));

            TextView pctLabel = text(pct + "% win rate", 11, theme.txtMuted(), Typeface.BOLD);
            pctLabel.setGravity(Gravity.CENTER);
            content.addView(pctLabel, lp(-1, -2, 0, 0, 0, dp(8)));
        }

        // ── Recent matches ────────────────────────────────────────────────────
        addSectionLabel(content, "RECENT MATCHES");

        if (callback.getGamesPlayed() == 0) {
            // Empty state
            LinearLayout emptyCard = new LinearLayout(activity);
            emptyCard.setOrientation(LinearLayout.VERTICAL);
            emptyCard.setGravity(Gravity.CENTER);
            emptyCard.setPadding(dp(20), dp(40), dp(20), dp(40));
            emptyCard.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));
            content.addView(emptyCard);

            TextView emptyIcon = text("🎲", 36, theme.txtDim(), Typeface.NORMAL);
            emptyIcon.setGravity(Gravity.CENTER);
            emptyCard.addView(emptyIcon);

            TextView emptyTitle = text("No matches yet", 16, theme.txtMuted(), Typeface.BOLD);
            emptyTitle.setGravity(Gravity.CENTER);
            emptyCard.addView(emptyTitle, lp(-1, -2, 0, dp(8), 0, dp(4)));

            TextView emptyHint = text("Play a match to see your history here",
                    13, theme.txtDim(), Typeface.NORMAL);
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

    private void addStatCard(LinearLayout parent, String value, String label, int color) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setGravity(Gravity.CENTER);
        card.setPadding(dp(12), dp(16), dp(12), dp(16));
        card.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));

        TextView v = text(value, 24, color, Typeface.BOLD);
        v.setGravity(Gravity.CENTER);
        card.addView(v);

        TextView l = text(label, 12, theme.txtMuted(), Typeface.BOLD);
        l.setGravity(Gravity.CENTER);
        l.setLetterSpacing(0.08f);
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
        card.setBackground(card(theme.bgCard(), dp(14),
            won ? 0x2243A047 : 0x22E8293E));
        parent.addView(card, lp(-1, -2, 0, 0, 0, dp(8)));

        // W/L badge
        TextView result = text(won ? "W" : "L", 18,
                won ? ThemeManager.GREEN : ThemeManager.RED, Typeface.BOLD);
        result.setGravity(Gravity.CENTER);
        result.setPadding(dp(4), 0, dp(12), 0);
        card.addView(result, lp(dp(36), -2));

        // Match info
        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        card.addView(info, new LinearLayout.LayoutParams(0, -2, 1));
        info.addView(text("Classic 2P — " + (won ? "Victory" : "Defeat"),
                14, theme.txtPrimary(), Typeface.BOLD));
        info.addView(text("vs Rush Bot", 12, theme.txtMuted(), Typeface.NORMAL),
                lp(-1, -2, 0, dp(2), 0, 0));

        // Rewards
        LinearLayout rewards = new LinearLayout(activity);
        rewards.setOrientation(LinearLayout.VERTICAL);
        rewards.setGravity(Gravity.END);
        card.addView(rewards);
        rewards.addView(text((won ? "+12" : "−6") + " rating",
                12, won ? ThemeManager.GREEN : ThemeManager.RED, Typeface.BOLD));
        rewards.addView(text((won ? "+100" : "+15") + " coins",
                12, ThemeManager.YELLOW, Typeface.NORMAL),
                lp(-1, -2, 0, dp(2), 0, 0));
    }
}
