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

        LinearLayout profileCard = new LinearLayout(activity);
        profileCard.setOrientation(LinearLayout.HORIZONTAL);
        profileCard.setGravity(Gravity.CENTER_VERTICAL);
        profileCard.setPadding(dp(20), dp(20), dp(20), dp(20));
        profileCard.setBackground(cardGradient(0xff192133, 0xff101827, dp(20)));
        content.addView(profileCard, lp(-1, -2, 0, 0, 0, dp(16)));

        View avatar = new View(activity);
        avatar.setBackground(card(0xffE8293E, dp(30), 0x44FFFFFF));
        profileCard.addView(avatar, lp(dp(60), dp(60), 0, 0, dp(16), 0));

        LinearLayout nameCol = new LinearLayout(activity);
        nameCol.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams ncp = new LinearLayout.LayoutParams(0, -2, 1);
        profileCard.addView(nameCol, ncp);

        nameCol.addView(text(callback.getDisplayName(), 20, Color.WHITE, Typeface.BOLD));
        nameCol.addView(text("Guest Player", 13, 0xff6B7A90, Typeface.NORMAL));

        addSectionLabel(content, "STATISTICS");

        LinearLayout statsRow = new LinearLayout(activity);
        statsRow.setOrientation(LinearLayout.HORIZONTAL);
        content.addView(statsRow, lp(-1, -2, 0, 0, 0, dp(8)));

        addStatCard(statsRow, "RATING", String.valueOf(callback.getRating()), 0xffF9A825);
        addStatCard(statsRow, "WINS", String.valueOf(callback.getWins()), 0xff43A047);
        addStatCard(statsRow, "GAMES", String.valueOf(callback.getGamesPlayed()), 0xff1E88E5);

        addSectionLabel(content, "DETAILS");

        addDetail(content, "Win Rate", callback.getGamesPlayed() > 0
                ? (callback.getWins() * 100 / callback.getGamesPlayed()) + "%"
                : "No games yet");
        addDetail(content, "Coins", String.valueOf(callback.getCoins()));
        addDetail(content, "Region", "us-east");
        addDetail(content, "Account Type", "Guest");
        addDetail(content, "Player ID", shortId(callback.getPlayerId()));

        addSectionLabel(content, "ACHIEVEMENTS");

        addAchievement(content, "First Win", "Win your first match", callback.getWins() > 0);
        addAchievement(content, "Veteran", "Play 10 matches", callback.getGamesPlayed() >= 10);
        addAchievement(content, "Champion", "Reach 1200 rating", callback.getRating() >= 1200);
        addAchievement(content, "Rich", "Collect 5000 coins", callback.getCoins() >= 5000);

        return createScreenShell("Profile", content);
    }

    private void addStatCard(LinearLayout parent, String label, String value, int accent) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setGravity(Gravity.CENTER);
        card.setPadding(dp(12), dp(16), dp(12), dp(16));
        card.setBackground(card(0xff111A2A, dp(16), 0x335D6D86));

        TextView val = text(value, 24, accent, Typeface.BOLD);
        val.setGravity(Gravity.CENTER);
        card.addView(val);

        TextView lbl = text(label, 11, 0xff6B7A90, Typeface.BOLD);
        lbl.setGravity(Gravity.CENTER);
        card.addView(lbl);

        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        parent.addView(card, p);
    }

    private void addDetail(LinearLayout parent, String label, String value) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(dp(16), dp(13), dp(16), dp(13));
        row.setBackground(card(0xff111A2A, dp(14), 0x225D6D86));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(6)));

        TextView l = text(label, 14, 0xff94A3B8, Typeface.NORMAL);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, -2, 1);
        row.addView(l, lp);
        row.addView(text(value, 14, Color.WHITE, Typeface.BOLD));
    }

    private void addAchievement(LinearLayout parent, String title, String desc, boolean unlocked) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(14), dp(12), dp(14), dp(12));
        row.setBackground(card(unlocked ? 0xff152030 : 0xff0E1420, dp(14), unlocked ? 0x44F9A825 : 0x22333D50));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(6)));

        TextView icon = text(unlocked ? "★" : "☆", 20, unlocked ? 0xffF9A825 : 0xff3A4556, Typeface.BOLD);
        row.addView(icon, lp(dp(32), -2, 0, 0, dp(8), 0));

        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams ip = new LinearLayout.LayoutParams(0, -2, 1);
        row.addView(info, ip);
        info.addView(text(title, 14, unlocked ? Color.WHITE : 0xff6B7A90, Typeface.BOLD));
        info.addView(text(desc, 12, unlocked ? 0xff94A3B8 : 0xff3A4556, Typeface.NORMAL));
    }

    private String shortId(String id) {
        if (id == null) return "—";
        return id.length() > 12 ? id.substring(0, 6) + "..." + id.substring(id.length() - 4) : id;
    }
}
