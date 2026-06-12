package com.ludorush.game;

import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.content.Intent;
import android.net.Uri;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.Switch;
import android.widget.TextView;

/**
 * Royal Rush Settings Screen.
 *
 * Sections:
 *   • Appearance (dark mode, board style)
 *   • Sound (SFX, music toggles)
 *   • Notifications
 *   • Game preferences (auto-move timer, dice animation)
 *   • Account (log out, delete account danger zone)
 */
public final class SettingsScreen extends BaseScreen {

    private SharedPreferences prefs;

    public SettingsScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
        prefs = activity.getSharedPreferences("ludo_settings", 0);
    }

    @Override
    public View createView() {
        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);

        addSectionLabel(body, "APPEARANCE");
        body.addView(buildToggleRow("Dark Mode", "dark_mode",
                true, ThemeManager.VIOLET));
        body.addView(buildToggleRow("Board Glow Effects", "board_glow",
                true, ThemeManager.TEAL), lp(-1, -2, 0, dp(8), 0, 0));

        addSectionLabel(body, "SOUND");
        body.addView(buildToggleRow("Sound Effects", "sfx_enabled",
                true, ThemeManager.GREEN));
        body.addView(buildToggleRow("Background Music", "music_enabled",
                false, ThemeManager.GREEN), lp(-1, -2, 0, dp(8), 0, 0));

        addSectionLabel(body, "NOTIFICATIONS");
        body.addView(buildToggleRow("Game Invites", "notif_invites",
                true, ThemeManager.GOLD));
        body.addView(buildToggleRow("Friend Challenges", "notif_challenges",
                true, ThemeManager.GOLD), lp(-1, -2, 0, dp(8), 0, 0));

        addSectionLabel(body, "GAMEPLAY");
        body.addView(buildToggleRow("Dice Roll Animation", "dice_anim",
                true, ThemeManager.INDIGO));
        body.addView(buildToggleRow("Auto-move Highlight", "auto_highlight",
                true, ThemeManager.INDIGO), lp(-1, -2, 0, dp(8), 0, 0));

        addSectionLabel(body, "ACCOUNT");
        body.addView(buildAccountSection(), lp(-1, -2));

        return createScreenShell("Settings", body);
    }

    // ── Toggle row ────────────────────────────────────────────────────────────

    private View buildToggleRow(String label, String key, boolean defaultVal, int accentColor) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setBackground(glowCard(theme.bgCard(), dp(14), theme.strokeCard()));
        row.setPadding(dp(16), dp(14), dp(12), dp(14));

        // Accent dot
        View dot = new View(activity);
        dot.setBackground(circle(accentColor));
        row.addView(dot, lp(dp(8), dp(8), 0, 0, dp(12), 0));

        // Label
        TextView labelTv = text(label, 14, theme.txtPrimary(), Typeface.NORMAL);
        row.addView(labelTv, new LinearLayout.LayoutParams(0, -2, 1));

        // Switch
        Switch sw = new Switch(activity);
        boolean current = prefs.getBoolean(key, defaultVal);
        sw.setChecked(current);
        sw.setOnCheckedChangeListener((btn, checked) -> {
            prefs.edit().putBoolean(key, checked).apply();
            if ("dark_mode".equals(key)) {
                theme.setDark(checked);
                activity.recreate();
            }
        });
        row.addView(sw);

        return row;
    }

    // ── Account section ───────────────────────────────────────────────────────

    private View buildAccountSection() {
        LinearLayout col = new LinearLayout(activity);
        col.setOrientation(LinearLayout.VERTICAL);

        // Edit profile
        View editRow = buildLinkRow("Edit Profile", theme.txtPrimary(), "editProfile");
        col.addView(editRow, lp(-1, -2, 0, 0, 0, dp(8)));

        // Restore purchases
        View restoreRow = buildLinkRow("Restore Purchases", ThemeManager.TEAL, null);
        col.addView(restoreRow, lp(-1, -2, 0, 0, 0, dp(8)));

        // Privacy policy
        View privacyRow = buildLinkRow("Privacy Policy", theme.txtMuted(), null);
        privacyRow.setOnClickListener(v -> openUrl("https://corsairlabs.com/ludo-rush-privacy-policy"));
        col.addView(privacyRow, lp(-1, -2, 0, 0, 0, dp(16)));

        // Log out
        Button logout = ghostButton("Log Out", ThemeManager.RED);
        logout.setTextSize(14);
        logout.setPadding(0, dp(14), 0, dp(14));
        col.addView(logout, lp(-1, dp(50)));

        return col;
    }

    private View buildLinkRow(String label, int color, String screen) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setBackground(glowCard(theme.bgCard(), dp(14), theme.strokeCard()));
        row.setPadding(dp(16), dp(14), dp(16), dp(14));
        row.setClickable(true);
        row.setFocusable(true);
        if (screen != null) {
            row.setOnClickListener(v -> callback.navigateTo(screen));
        }

        TextView lbl = text(label, 14, color, Typeface.NORMAL);
        row.addView(lbl, new LinearLayout.LayoutParams(0, -2, 1));

        if (screen != null) {
            TextView arrow = text(">", 20, theme.txtMuted(), Typeface.BOLD);
            row.addView(arrow);
        }
        return row;
    }

    private void openUrl(String url) {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        activity.startActivity(intent);
    }
}
