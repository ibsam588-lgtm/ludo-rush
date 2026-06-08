package com.ludorush.game;

import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.Switch;
import android.widget.TextView;

public final class SettingsScreen extends BaseScreen {

    public SettingsScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);

        SharedPreferences prefs = activity.getSharedPreferences("ludo_settings", 0);

        addSectionLabel(content, "AUDIO");
        addToggle(content, "Sound Effects", prefs, "sound_on", true);
        addToggle(content, "Music", prefs, "music_on", true);

        addSectionLabel(content, "NOTIFICATIONS");
        addToggle(content, "Push Notifications", prefs, "notifs_on", true);
        addToggle(content, "Match Reminders", prefs, "reminders_on", false);

        addSectionLabel(content, "ACCOUNT");

        LinearLayout nameRow = new LinearLayout(activity);
        nameRow.setOrientation(LinearLayout.HORIZONTAL);
        nameRow.setGravity(Gravity.CENTER_VERTICAL);
        nameRow.setPadding(dp(16), dp(14), dp(16), dp(14));
        nameRow.setBackground(card(0xff111A2A, dp(14), 0x225D6D86));
        content.addView(nameRow, lp(-1, -2, 0, 0, 0, dp(8)));

        LinearLayout nameCol = new LinearLayout(activity);
        nameCol.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams ncp = new LinearLayout.LayoutParams(0, -2, 1);
        nameRow.addView(nameCol, ncp);
        nameCol.addView(text("Display Name", 14, Color.WHITE, Typeface.BOLD));
        nameCol.addView(text(callback.getDisplayName(), 12, 0xff6B7A90, Typeface.NORMAL));

        LinearLayout idRow = new LinearLayout(activity);
        idRow.setOrientation(LinearLayout.VERTICAL);
        idRow.setPadding(dp(16), dp(14), dp(16), dp(14));
        idRow.setBackground(card(0xff111A2A, dp(14), 0x225D6D86));
        content.addView(idRow, lp(-1, -2, 0, 0, 0, dp(8)));
        idRow.addView(text("Player ID", 14, Color.WHITE, Typeface.BOLD));
        String pid = callback.getPlayerId();
        idRow.addView(text(pid != null ? pid : "Not signed in", 12, 0xff6B7A90, Typeface.NORMAL));

        addSectionLabel(content, "ABOUT");

        addInfoRow(content, "Version", "0.2.0");
        addInfoRow(content, "Build", "Internal Test");
        addInfoRow(content, "Server", "Cloudflare Workers");

        addSectionLabel(content, "LEGAL");

        Button privacy = secondaryButton("Privacy Policy");
        privacy.setTextSize(14);
        content.addView(privacy, lp(-1, dp(48), 0, 0, 0, dp(8)));

        Button terms = secondaryButton("Terms of Service");
        terms.setTextSize(14);
        content.addView(terms, lp(-1, dp(48), 0, 0, 0, dp(16)));

        Button deleteBtn = new Button(activity);
        deleteBtn.setAllCaps(false);
        deleteBtn.setText("Delete Account");
        deleteBtn.setTextColor(0xffE8293E);
        deleteBtn.setTextSize(14);
        deleteBtn.setTypeface(Typeface.DEFAULT_BOLD);
        deleteBtn.setBackground(card(0xff1A1A1A, dp(14), 0x44E8293E));
        content.addView(deleteBtn, lp(-1, dp(48)));

        return createScreenShell("Settings", content);
    }

    private void addToggle(LinearLayout parent, String label, SharedPreferences prefs, String key, boolean defVal) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(16), dp(12), dp(12), dp(12));
        row.setBackground(card(0xff111A2A, dp(14), 0x225D6D86));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(8)));

        TextView t = text(label, 14, Color.WHITE, Typeface.NORMAL);
        LinearLayout.LayoutParams tp = new LinearLayout.LayoutParams(0, -2, 1);
        row.addView(t, tp);

        Switch sw = new Switch(activity);
        sw.setChecked(prefs.getBoolean(key, defVal));
        sw.setOnCheckedChangeListener((v, checked) -> prefs.edit().putBoolean(key, checked).apply());
        row.addView(sw, lp(-2, -2));
    }

    private void addInfoRow(LinearLayout parent, String label, String value) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(dp(16), dp(12), dp(16), dp(12));
        row.setBackground(card(0xff111A2A, dp(14), 0x225D6D86));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(8)));

        TextView l = text(label, 14, Color.WHITE, Typeface.NORMAL);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, -2, 1);
        row.addView(l, lp);

        row.addView(text(value, 14, 0xff6B7A90, Typeface.NORMAL));
    }
}
