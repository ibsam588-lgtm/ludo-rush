package com.ludorush.game;

import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.LinearLayout;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

public final class SettingsScreen extends BaseScreen {

    public SettingsScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);

        SharedPreferences prefs = activity.getSharedPreferences("ludo_settings", 0);

        // ── Appearance ────────────────────────────────────────────────────────
        addSectionLabel(content, "APPEARANCE");

        LinearLayout themeRow = new LinearLayout(activity);
        themeRow.setOrientation(LinearLayout.HORIZONTAL);
        themeRow.setGravity(Gravity.CENTER_VERTICAL);
        themeRow.setPadding(dp(16), dp(14), dp(14), dp(14));
        themeRow.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));
        content.addView(themeRow, lp(-1, -2, 0, 0, 0, dp(8)));

        LinearLayout themeInfo = new LinearLayout(activity);
        themeInfo.setOrientation(LinearLayout.VERTICAL);
        themeRow.addView(themeInfo, new LinearLayout.LayoutParams(0, -2, 1));
        themeInfo.addView(text("Dark Mode", 14, theme.txtPrimary(), Typeface.BOLD));
        themeInfo.addView(text(theme.isDark() ? "Switch to light theme" : "Switch to dark theme",
                12, theme.txtMuted(), Typeface.NORMAL));

        Switch themeSwitch = new Switch(activity);
        themeSwitch.setChecked(theme.isDark());
        themeSwitch.setOnCheckedChangeListener((v, checked) -> {
            theme.setDark(checked);
            // Recreate the activity so every screen gets the new palette
            activity.recreate();
        });
        themeRow.addView(themeSwitch, lp(-2, -2));

        // ── Audio ─────────────────────────────────────────────────────────────
        addSectionLabel(content, "AUDIO");
        addToggleRow(content, "Sound Effects", prefs, "sound_on", true);
        addToggleRow(content, "Music",          prefs, "music_on", true);

        // ── Notifications ─────────────────────────────────────────────────────
        addSectionLabel(content, "NOTIFICATIONS");
        addToggleRow(content, "Push Notifications", prefs, "notifs_on",    true);
        addToggleRow(content, "Match Reminders",    prefs, "reminders_on", false);

        // ── Account ───────────────────────────────────────────────────────────
        addSectionLabel(content, "ACCOUNT");

        addInfoCard(content, "Display Name", callback.getDisplayName());
        addInfoCard(content, "Player ID",
                callback.getPlayerId() != null ? callback.getPlayerId() : "Not signed in");

        // ── About ─────────────────────────────────────────────────────────────
        addSectionLabel(content, "ABOUT");
        addInfoRow(content, "Version", "0.3.0");
        addInfoRow(content, "Build",   "Internal Test");
        addInfoRow(content, "Server",  "Cloudflare Workers");

        // ── Legal ─────────────────────────────────────────────────────────────
        addSectionLabel(content, "LEGAL");

        Button privacy = secondaryButton("Privacy Policy");
        privacy.setTextSize(14);
        privacy.setOnClickListener(v ->
            Toast.makeText(activity, "Privacy Policy — coming soon", Toast.LENGTH_SHORT).show());
        content.addView(privacy, lp(-1, dp(50), 0, 0, 0, dp(8)));

        Button terms = secondaryButton("Terms of Service");
        terms.setTextSize(14);
        terms.setOnClickListener(v ->
            Toast.makeText(activity, "Terms of Service — coming soon", Toast.LENGTH_SHORT).show());
        content.addView(terms, lp(-1, dp(50), 0, 0, 0, dp(16)));

        // Delete account (danger action)
        Button deleteBtn = new Button(activity);
        deleteBtn.setAllCaps(false);
        deleteBtn.setText("Delete Account");
        deleteBtn.setTextColor(ThemeManager.RED);
        deleteBtn.setTextSize(14);
        deleteBtn.setTypeface(Typeface.DEFAULT_BOLD);
        deleteBtn.setBackground(card(theme.bgDanger(), dp(14), theme.strokeDanger()));
        deleteBtn.setOnClickListener(v ->
            Toast.makeText(activity, "Account deletion — coming soon", Toast.LENGTH_SHORT).show());
        content.addView(deleteBtn, lp(-1, dp(50)));

        return createScreenShell("Settings", content);
    }

    private void addToggleRow(LinearLayout parent, String label, SharedPreferences prefs,
                              String key, boolean defVal) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(16), dp(13), dp(13), dp(13));
        row.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(8)));

        TextView t = text(label, 14, theme.txtPrimary(), Typeface.NORMAL);
        row.addView(t, new LinearLayout.LayoutParams(0, -2, 1));

        Switch sw = new Switch(activity);
        sw.setChecked(prefs.getBoolean(key, defVal));
        sw.setOnCheckedChangeListener((v, checked) -> prefs.edit().putBoolean(key, checked).apply());
        row.addView(sw, lp(-2, -2));
    }

    private void addInfoCard(LinearLayout parent, String label, String value) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(14), dp(16), dp(14));
        card.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));
        parent.addView(card, lp(-1, -2, 0, 0, 0, dp(8)));
        card.addView(text(label, 12, theme.txtMuted(), Typeface.BOLD));
        card.addView(text(value, 14, theme.txtPrimary(), Typeface.NORMAL), lp(-1, -2, 0, dp(2), 0, 0));
    }

    private void addInfoRow(LinearLayout parent, String label, String value) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(dp(16), dp(13), dp(16), dp(13));
        row.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(8)));

        row.addView(text(label, 14, theme.txtSecondary(), Typeface.NORMAL),
                new LinearLayout.LayoutParams(0, -2, 1));
        row.addView(text(value, 14, theme.txtPrimary(), Typeface.BOLD));
    }
}
