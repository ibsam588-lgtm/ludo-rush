package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class ProfileScreen extends BaseScreen {

    public ProfileScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);

        // ── Profile hero card ─────────────────────────────────────────────────
        LinearLayout heroCard = new LinearLayout(activity);
        heroCard.setOrientation(LinearLayout.HORIZONTAL);
        heroCard.setGravity(Gravity.CENTER_VERTICAL);
        heroCard.setPadding(dp(20), dp(22), dp(20), dp(22));
        heroCard.setBackground(cardGradient(theme.bgGradStart(), theme.bgGradEnd(), dp(20)));
        content.addView(heroCard, lp(-1, -2, 0, 0, 0, dp(16)));

        View avatar = new View(activity);
        avatar.setBackground(circleOutline(ThemeManager.RED, 0x55FFFFFF));
        heroCard.addView(avatar, lp(dp(64), dp(64), 0, 0, dp(16), 0));

        LinearLayout nameCol = new LinearLayout(activity);
        nameCol.setOrientation(LinearLayout.VERTICAL);
        heroCard.addView(nameCol, new LinearLayout.LayoutParams(0, -2, 1));

        nameCol.addView(text(callback.getDisplayName(), 20, theme.txtPrimary(), Typeface.BOLD));
        nameCol.addView(text("Guest Player  ·  us-east", 13, theme.txtMuted(), Typeface.NORMAL),
                lp(-1, -2, 0, dp(2), 0, 0));

        int winRate = callback.getGamesPlayed() > 0
            ? callback.getWins() * 100 / callback.getGamesPlayed() : 0;
        nameCol.addView(text(winRate + "% win rate", 12, ThemeManager.GREEN, Typeface.BOLD),
                lp(-1, -2, 0, dp(4), 0, 0));

        // ── Statistics ────────────────────────────────────────────────────────
        addSectionLabel(content, "STATISTICS");

        LinearLayout statsRow = new LinearLayout(activity);
        statsRow.setOrientation(LinearLayout.HORIZONTAL);
        content.addView(statsRow, lp(-1, -2, 0, 0, 0, dp(8)));

        addStatCard(statsRow, "RATING", String.valueOf(callback.getRating()), ThemeManager.YELLOW);
        addStatCard(statsRow, "WINS",   String.valueOf(callback.getWins()),   ThemeManager.GREEN);
        addStatCard(statsRow, "GAMES",  String.valueOf(callback.getGamesPlayed()), ThemeManager.BLUE);

        // ── Details ───────────────────────────────────────────────────────────
        addSectionLabel(content, "DETAILS");

        addDetailRow(content, "Coins",        String.valueOf(callback.getCoins()));
        addDetailRow(content, "Win Rate",     callback.getGamesPlayed() > 0
            ? (callback.getWins() * 100 / callback.getGamesPlayed()) + "%" : "No games yet");
        addDetailRow(content, "Region",       "us-east");
        addDetailRow(content, "Account Type", "Guest");
        addDetailRow(content, "Player ID",    shortId(callback.getPlayerId()));

        // ── Achievements ──────────────────────────────────────────────────────
        addSectionLabel(content, "ACHIEVEMENTS");

        addAchievement(content, "First Win",  "Win your first match",    callback.getWins() > 0);
        addAchievement(content, "Veteran",    "Play 10 matches",         callback.getGamesPlayed() >= 10);
        addAchievement(content, "Champion",   "Reach 1200 rating",       callback.getRating() >= 1200);
        addAchievement(content, "Rich",       "Collect 5000 coins",      callback.getCoins() >= 5000);

        return createScreenShell("Profile", content);
    }

    private void addStatCard(LinearLayout parent, String label, String value, int accent) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setGravity(Gravity.CENTER);
        card.setPadding(dp(12), dp(18), dp(12), dp(18));
        card.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));

        TextView val = text(value, 26, accent, Typeface.BOLD);
        val.setGravity(Gravity.CENTER);
        card.addView(val);

        TextView lbl = text(label, 11, theme.txtMuted(), Typeface.BOLD);
        lbl.setGravity(Gravity.CENTER);
        lbl.setLetterSpacing(0.1f);
        card.addView(lbl);

        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        parent.addView(card, p);
    }

    private void addDetailRow(LinearLayout parent, String label, String value) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(dp(16), dp(13), dp(16), dp(13));
        row.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(6)));

        row.addView(text(label, 14, theme.txtSecondary(), Typeface.NORMAL),
                new LinearLayout.LayoutParams(0, -2, 1));
        row.addView(text(value, 14, theme.txtPrimary(), Typeface.BOLD));
    }

    private void addAchievement(LinearLayout parent, String title, String desc, boolean unlocked) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(14), dp(12), dp(14), dp(12));
        row.setBackground(card(
            unlocked ? theme.bgSel() : theme.bgCard(),
            dp(14),
            unlocked ? 0x44F9A825 : theme.strokeCard()));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(6)));

        TextView icon = text(unlocked ? "★" : "☆", 22,
                unlocked ? ThemeManager.YELLOW : theme.txtDim(), Typeface.BOLD);
        row.addView(icon, lp(dp(32), -2, 0, 0, dp(8), 0));

        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        row.addView(info, new LinearLayout.LayoutParams(0, -2, 1));
        info.addView(text(title, 14,
                unlocked ? theme.txtPrimary() : theme.txtMuted(), Typeface.BOLD));
        info.addView(text(desc, 12,
                unlocked ? theme.txtSecondary() : theme.txtDim(), Typeface.NORMAL));
    }

    private String shortId(String id) {
        if (id == null) return "—";
        return id.length() > 12 ? id.substring(0, 6) + "..." + id.substring(id.length() - 4) : id;
    }
}
