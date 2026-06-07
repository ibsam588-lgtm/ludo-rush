package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class HomeScreen extends BaseScreen {

    public HomeScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(0xff080B13);
        root.setPadding(dp(18), dp(20), dp(18), dp(18));

        LinearLayout banner = new LinearLayout(activity);
        banner.setOrientation(LinearLayout.HORIZONTAL);
        banner.setGravity(Gravity.CENTER_VERTICAL);
        banner.setPadding(dp(16), dp(14), dp(16), dp(14));
        banner.setBackground(cardGradient(0xff192133, 0xff101827, dp(20)));
        root.addView(banner, lp(-1, -2, 0, 0, 0, dp(20)));

        View avatar = new View(activity);
        avatar.setBackground(card(0xffE8293E, dp(24), 0x44FFFFFF));
        banner.addView(avatar, lp(dp(48), dp(48)));

        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        info.setPadding(dp(12), 0, 0, 0);
        LinearLayout.LayoutParams ip = new LinearLayout.LayoutParams(0, -2, 1);
        banner.addView(info, ip);

        info.addView(text(callback.getDisplayName(), 17, Color.WHITE, Typeface.BOLD));

        LinearLayout stats = new LinearLayout(activity);
        stats.setOrientation(LinearLayout.HORIZONTAL);
        stats.setPadding(0, dp(3), 0, 0);
        info.addView(stats);
        stats.addView(text("Rating " + callback.getRating(), 12, 0xffF9A825, Typeface.BOLD), lp(-2, -2, 0, 0, dp(14), 0));
        stats.addView(text(callback.getCoins() + " Coins", 12, 0xff43A047, Typeface.BOLD));

        TextView title = text("LUDO RUSH", 34, Color.WHITE, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        root.addView(title, lp(-1, -2, 0, dp(12), 0, dp(2)));

        TextView sub = text("Classic board game, online", 14, 0xff6B7A90, Typeface.NORMAL);
        sub.setGravity(Gravity.CENTER);
        root.addView(sub, lp(-1, -2, 0, 0, 0, dp(24)));

        Button playBtn = actionButton("PLAY", 0xffE8293E, 0xffF9A825);
        playBtn.setTextSize(20);
        playBtn.setOnClickListener(v -> callback.navigateTo("lobby"));
        root.addView(playBtn, lp(-1, dp(62), dp(20), 0, dp(20), dp(14)));

        LinearLayout quickRow = new LinearLayout(activity);
        quickRow.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(quickRow, lp(-1, -2, 0, 0, 0, dp(22)));

        addQuick(quickRow, "Bot Match", 0xff1E88E5, v -> callback.startBotMatch("classic_2p"));
        addQuick(quickRow, "Quick Match", 0xff43A047, v -> callback.startQuickMatch("classic_2p"));

        LinearLayout row1 = new LinearLayout(activity);
        row1.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(row1, lp(-1, -2, 0, 0, 0, dp(10)));
        addNav(row1, "Profile", "Stats & history", 0xff1E88E5, "profile");
        addNav(row1, "Leaderboard", "Top players", 0xffF9A825, "leaderboard");

        LinearLayout row2 = new LinearLayout(activity);
        row2.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(row2, lp(-1, -2, 0, 0, 0, dp(10)));
        addNav(row2, "Shop", "Get coins", 0xff43A047, "shop");
        addNav(row2, "Settings", "Preferences", 0xff94A3B8, "settings");

        LinearLayout row3 = new LinearLayout(activity);
        row3.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(row3, lp(-1, -2));
        addNav(row3, "Match History", "Past games", 0xffE8293E, "history");

        View spacer = new View(activity);
        LinearLayout.LayoutParams sp = new LinearLayout.LayoutParams(-1, 0);
        sp.weight = 1;
        root.addView(spacer, sp);

        TextView ver = text("v0.1.0 — Internal Test Build", 11, 0xff3A4556, Typeface.NORMAL);
        ver.setGravity(Gravity.CENTER);
        root.addView(ver, lp(-1, -2, 0, dp(12), 0, 0));

        return root;
    }

    private void addQuick(LinearLayout parent, String label, int color, View.OnClickListener l) {
        Button b = secondaryButton(label);
        b.setTextColor(color);
        b.setOnClickListener(l);
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, dp(48), 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        parent.addView(b, p);
    }

    private void addNav(LinearLayout parent, String title, String sub, int accent, String screen) {
        LinearLayout c = new LinearLayout(activity);
        c.setOrientation(LinearLayout.VERTICAL);
        c.setPadding(dp(14), dp(14), dp(14), dp(14));
        c.setBackground(card(0xff111A2A, dp(16), 0x335D6D86));
        c.setOnClickListener(v -> callback.navigateTo(screen));

        View dot = new View(activity);
        dot.setBackground(card(accent, dp(4), accent));
        c.addView(dot, lp(dp(8), dp(8), 0, 0, 0, dp(8)));

        c.addView(text(title, 14, Color.WHITE, Typeface.BOLD));
        c.addView(text(sub, 11, 0xff6B7A90, Typeface.NORMAL));

        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        parent.addView(c, p);
    }
}
