package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * Royal Rush Profile Screen.
 *
 * Layout:
 *   • Hero card: large avatar, name, rating, tier badge
 *   • Progress section: level XP bar
 *   • Stats grid: games, wins, losses, win-rate, streak, coins
 *   • Achievements row
 *   • Edit profile button
 */
public final class ProfileScreen extends BaseScreen {

    public ProfileScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);

        body.addView(buildHeroCard(), lp(-1, -2, 0, 0, 0, dp(20)));
        body.addView(buildLevelSection(), lp(-1, -2, 0, 0, 0, dp(20)));

        addSectionLabel(body, "STATS");
        body.addView(buildStatsGrid(), lp(-1, -2, 0, 0, 0, dp(20)));

        addSectionLabel(body, "ACHIEVEMENTS");
        body.addView(buildAchievements(), lp(-1, -2, 0, 0, 0, dp(28)));

        Button edit = primaryButton("✎  Edit Profile");
        edit.setPadding(0, dp(14), 0, dp(14));
        edit.setOnClickListener(v -> callback.navigateTo("editProfile"));
        body.addView(edit, lp(-1, dp(52)));

        return createScreenShell("Profile", body);
    }

    // ── Hero card ─────────────────────────────────────────────────────────────

    private View buildHeroCard() {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setGravity(Gravity.CENTER_HORIZONTAL);
        card.setBackground(cardGradient(theme.bgHeroStart(), theme.bgHeroEnd(), dp(22)));
        card.setPadding(dp(20), dp(28), dp(20), dp(24));

        // Large avatar
        String name = callback.getDisplayName();
        int avatarColor = ThemeManager.VIOLET;
        View av = avatarRing(name, avatarColor, dp(80));
        card.addView(av, lp(dp(80), dp(80), 0, 0, 0, dp(14)));

        // Name
        TextView nameTv = text(name, 22, Color.WHITE, Typeface.BOLD);
        nameTv.setGravity(Gravity.CENTER);
        card.addView(nameTv, lp(-1, -2, 0, 0, 0, dp(6)));

        // Rating + tier badge row
        LinearLayout badgeRow = new LinearLayout(activity);
        badgeRow.setOrientation(LinearLayout.HORIZONTAL);
        badgeRow.setGravity(Gravity.CENTER);

        TextView rating = text("★ " + callback.getRating(), 14,
                ThemeManager.GOLD, Typeface.BOLD);
        badgeRow.addView(rating, lp(-2, -2, 0, 0, dp(12), 0));

        String tier = getTier(callback.getRating());
        View tierBadge = badge(tier, ThemeManager.VIOLET, Color.WHITE);
        badgeRow.addView(tierBadge);
        card.addView(badgeRow, lp(-1, -2, 0, 0, 0, dp(12)));

        // Coins row
        LinearLayout coinsRow = new LinearLayout(activity);
        coinsRow.setOrientation(LinearLayout.HORIZONTAL);
        coinsRow.setGravity(Gravity.CENTER);
        coinsRow.setBackground(glowCard(0x22FFFFFF, dp(20), 0x33FFFFFF));
        coinsRow.setPadding(dp(20), dp(8), dp(20), dp(8));

        TextView coinsIcon = text("◈", 18, ThemeManager.GOLD, Typeface.BOLD);
        coinsRow.addView(coinsIcon, lp(-2, -2, 0, 0, dp(6), 0));

        TextView coinsVal = text(String.valueOf(callback.getCoins()), 16,
                Color.WHITE, Typeface.BOLD);
        coinsRow.addView(coinsVal, lp(-2, -2, 0, 0, dp(10), 0));

        TextView coinsLabel = text("coins", 13, 0xAAFFFFFF, Typeface.NORMAL);
        coinsRow.addView(coinsLabel);
        card.addView(coinsRow, lp(-2, -2));

        return card;
    }

    // ── Level / XP ────────────────────────────────────────────────────────────

    private View buildLevelSection() {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setBackground(glowCard(theme.bgCard(), dp(18), theme.strokeCardGlow()));
        card.setPadding(dp(16), dp(16), dp(16), dp(16));

        int games = callback.getGamesPlayed();
        int level = Math.max(1, games / 10 + 1);
        int xp    = games % 10;
        int xpMax = 10;

        LinearLayout topRow = new LinearLayout(activity);
        topRow.setOrientation(LinearLayout.HORIZONTAL);
        topRow.setGravity(Gravity.CENTER_VERTICAL);

        TextView levelTv = text("Level " + level, 16, theme.txtPrimary(), Typeface.BOLD);
        topRow.addView(levelTv, new LinearLayout.LayoutParams(0, -2, 1));

        TextView xpTv = text(xp + " / " + xpMax + " XP", 12, theme.txtMuted(), Typeface.NORMAL);
        topRow.addView(xpTv);

        card.addView(topRow, lp(-1, -2, 0, 0, 0, dp(10)));

        // XP track
        LinearLayout track = new LinearLayout(activity);
        track.setBackground(glowCard(0x22FFFFFF, dp(6), 0));
        LinearLayout.LayoutParams tp = new LinearLayout.LayoutParams(-1, dp(8));
        card.addView(track, tp);

        // Fill bar — set in post-layout
        View fill = new View(activity);
        fill.setBackground(buttonGradient(ThemeManager.VIOLET, ThemeManager.INDIGO, dp(6)));
        track.post(() -> {
            int tw = track.getWidth();
            if (tw > 0) {
                LinearLayout.LayoutParams flp = new LinearLayout.LayoutParams(
                        (int)(tw * (float)xp / xpMax), -1);
                fill.setLayoutParams(flp);
            }
        });
        track.addView(fill);

        return card;
    }

    // ── Stats grid ────────────────────────────────────────────────────────────

    private View buildStatsGrid() {
        LinearLayout grid = new LinearLayout(activity);
        grid.setOrientation(LinearLayout.VERTICAL);

        int games  = callback.getGamesPlayed();
        int wins   = callback.getWins();
        int losses = Math.max(0, games - wins);
        int wr     = games > 0 ? (int)((float)wins / games * 100) : 0;
        int streak = Math.min(wins, 5);  // placeholder

        String[] labels = {"Games", "Wins", "Losses", "Win Rate", "Best Streak", "Coins"};
        String[] values = {
            String.valueOf(games), String.valueOf(wins), String.valueOf(losses),
            wr + "%", streak + "W", String.valueOf(callback.getCoins())
        };
        int[] colors = {
            theme.txtPrimary(), ThemeManager.GREEN, ThemeManager.RED,
            ThemeManager.GOLD, ThemeManager.TEAL, ThemeManager.GOLD
        };

        LinearLayout row = null;
        for (int i = 0; i < labels.length; i++) {
            if (i % 3 == 0) {
                row = new LinearLayout(activity);
                row.setOrientation(LinearLayout.HORIZONTAL);
                grid.addView(row, lp(-1, -2, 0, 0, 0, i + 3 < labels.length ? dp(10) : 0));
            }

            LinearLayout cell = new LinearLayout(activity);
            cell.setOrientation(LinearLayout.VERTICAL);
            cell.setGravity(Gravity.CENTER);
            cell.setPadding(dp(8), dp(14), dp(8), dp(14));
            cell.setBackground(glowCard(theme.bgCard(), dp(14), theme.strokeCard()));

            TextView val = text(values[i], 18, colors[i], Typeface.BOLD);
            val.setGravity(Gravity.CENTER);
            cell.addView(val, lp(-1, -2, 0, 0, 0, dp(3)));

            TextView lbl = text(labels[i], 9, theme.txtMuted(), Typeface.BOLD);
            lbl.setGravity(Gravity.CENTER);
            lbl.setLetterSpacing(0.04f);
            cell.addView(lbl);

            LinearLayout.LayoutParams cp = new LinearLayout.LayoutParams(0, -2, 1);
            if (i % 3 > 0) cp.setMargins(dp(8), 0, 0, 0);
            row.addView(cell, cp);
        }
        return grid;
    }

    // ── Achievements ──────────────────────────────────────────────────────────

    private View buildAchievements() {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);

        String[] emojis  = {"🎯", "⚡", "🔥", "💎", "🏆"};
        String[] names   = {"First Win", "Speed Demon", "Hot Streak", "Gem Collector", "Champion"};
        boolean[] earned = {true, true, true, false, false};

        for (int i = 0; i < emojis.length; i++) {
            LinearLayout badge = new LinearLayout(activity);
            badge.setOrientation(LinearLayout.VERTICAL);
            badge.setGravity(Gravity.CENTER);
            badge.setPadding(dp(6), dp(12), dp(6), dp(12));
            badge.setBackground(glowCard(
                    earned[i] ? theme.bgCard() : theme.bgPage(),
                    dp(14),
                    earned[i] ? theme.strokeCardGlow() : theme.strokeCard()));

            TextView icon = new TextView(activity);
            icon.setText(emojis[i]);
            icon.setTextSize(22);
            icon.setGravity(Gravity.CENTER);
            icon.setAlpha(earned[i] ? 1.0f : 0.35f);
            badge.addView(icon, lp(-1, -2, 0, 0, 0, dp(4)));

            TextView nm = text(names[i], 9, earned[i] ? theme.txtPrimary() : theme.txtMuted(),
                    Typeface.BOLD);
            nm.setGravity(Gravity.CENTER);
            badge.addView(nm);

            LinearLayout.LayoutParams bp = new LinearLayout.LayoutParams(0, -2, 1);
            if (i > 0) bp.setMargins(dp(8), 0, 0, 0);
            row.addView(badge, bp);
        }
        return row;
    }

    // ── Tier label ────────────────────────────────────────────────────────────

    private String getTier(int rating) {
        if (rating >= 2700) return "MASTER";
        if (rating >= 2400) return "DIAMOND";
        if (rating >= 2100) return "PLATINUM";
        if (rating >= 1800) return "GOLD";
        if (rating >= 1500) return "SILVER";
        return "BRONZE";
    }
}
