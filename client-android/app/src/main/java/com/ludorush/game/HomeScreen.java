package com.ludorush.game;

import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

public final class HomeScreen extends BaseScreen {

    public HomeScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(theme.bgPage());

        // ── Scrollable body ───────────────────────────────────────────────────
        ScrollView scroll = new ScrollView(activity);
        scroll.setFillViewport(true);
        scroll.setOverScrollMode(View.OVER_SCROLL_NEVER);
        scroll.setVerticalScrollBarEnabled(false);

        LinearLayout inner = new LinearLayout(activity);
        inner.setOrientation(LinearLayout.VERTICAL);
        inner.setPadding(dp(18), dp(20), dp(18), dp(12));

        // ── Player banner card ────────────────────────────────────────────────
        LinearLayout banner = new LinearLayout(activity);
        banner.setOrientation(LinearLayout.HORIZONTAL);
        banner.setGravity(Gravity.CENTER_VERTICAL);
        banner.setPadding(dp(16), dp(14), dp(16), dp(14));
        banner.setBackground(cardGradient(theme.bgGradStart(), theme.bgGradEnd(), dp(20)));
        inner.addView(banner, lp(-1, -2, 0, 0, 0, dp(20)));

        // Avatar circle with coloured ring
        View avatar = new View(activity);
        avatar.setBackground(circleOutline(ThemeManager.RED, 0x55FFFFFF));
        banner.addView(avatar, lp(dp(52), dp(52)));

        // Name + stats
        LinearLayout playerInfo = new LinearLayout(activity);
        playerInfo.setOrientation(LinearLayout.VERTICAL);
        playerInfo.setPadding(dp(12), 0, 0, 0);
        banner.addView(playerInfo, new LinearLayout.LayoutParams(0, -2, 1));

        playerInfo.addView(text(callback.getDisplayName(), 17, theme.txtPrimary(), Typeface.BOLD));

        LinearLayout statsRow = new LinearLayout(activity);
        statsRow.setOrientation(LinearLayout.HORIZONTAL);
        statsRow.setPadding(0, dp(3), 0, 0);
        playerInfo.addView(statsRow);
        statsRow.addView(
            text("★ " + callback.getRating(), 12, ThemeManager.YELLOW, Typeface.BOLD),
            lp(-2, -2, 0, 0, dp(14), 0));
        statsRow.addView(
            text("◈ " + callback.getCoins(), 12, ThemeManager.GREEN, Typeface.BOLD));

        // Online / offline pill badge
        TextView badge = text(callback.isOnline() ? "LIVE" : "OFFLINE", 10, Color.WHITE, Typeface.BOLD);
        badge.setLetterSpacing(0.08f);
        badge.setPadding(dp(8), dp(3), dp(8), dp(3));
        GradientDrawable badgeBg = new GradientDrawable();
        badgeBg.setColor(callback.isOnline() ? ThemeManager.GREEN : 0xff6B7A90);
        badgeBg.setCornerRadius(dp(10));
        badge.setBackground(badgeBg);
        banner.addView(badge);

        // Quick theme toggle button in the banner header
        Button bannerTheme = new Button(activity);
        bannerTheme.setAllCaps(false);
        bannerTheme.setText(theme.isDark() ? "☀️" : "🌙");
        bannerTheme.setTextSize(18);
        bannerTheme.setBackground(null);
        bannerTheme.setOnClickListener(v -> {
            theme.setDark(!theme.isDark());
            activity.recreate();
        });
        banner.addView(bannerTheme, lp(dp(42), dp(42), dp(4), 0, 0, 0));

        // ── App title — gradient shader RED→YELLOW→BLUE ───────────────────────
        TextView titleText = new TextView(activity) {
            @Override
            protected void onDraw(android.graphics.Canvas canvas) {
                android.graphics.Paint p = getPaint();
                if (getMeasuredWidth() > 0) {
                    p.setShader(new LinearGradient(
                        0, 0, getMeasuredWidth(), 0,
                        new int[]{ThemeManager.GOLD_LIGHT, ThemeManager.GOLD, ThemeManager.GOLD_LIGHT},
                        null, Shader.TileMode.CLAMP));
                }
                super.onDraw(canvas);
            }
        };
        titleText.setText("LUDO RUSH");
        titleText.setTextSize(38);
        titleText.setTextColor(ThemeManager.GOLD);
        titleText.setTypeface(Typeface.DEFAULT_BOLD);
        titleText.setGravity(Gravity.CENTER);
        titleText.setLetterSpacing(0.06f);
        inner.addView(titleText, lp(-1, -2, 0, dp(4), 0, dp(2)));

        TextView subText = text("Roll. Move. Conquer.", 14, theme.txtMuted(), Typeface.NORMAL);
        subText.setGravity(Gravity.CENTER);
        inner.addView(subText, lp(-1, -2, 0, 0, 0, dp(24)));

        // ── Primary play button (with pulse animation) ────────────────────────
        Button playBtn = actionButton("⚡  PLAY NOW", ThemeManager.RED, ThemeManager.YELLOW);
        playBtn.setTextSize(20);
        playBtn.setOnClickListener(v -> callback.navigateTo("lobby"));
        inner.addView(playBtn, lp(-1, dp(64), dp(6), 0, dp(6), dp(14)));

        // Subtle alpha pulse: 0.75 → 1.0, repeating forever
        ObjectAnimator pulse = ObjectAnimator.ofFloat(playBtn, "alpha", 0.78f, 1f);
        pulse.setDuration(900);
        pulse.setRepeatMode(ValueAnimator.REVERSE);
        pulse.setRepeatCount(ValueAnimator.INFINITE);
        pulse.start();

        // ── Quick-action row (Bot / Quick match) ──────────────────────────────
        LinearLayout quickRow = new LinearLayout(activity);
        quickRow.setOrientation(LinearLayout.HORIZONTAL);
        inner.addView(quickRow, lp(-1, -2, 0, 0, 0, dp(24)));

        addQuickBtn(quickRow, "🤖  Bot Match",   ThemeManager.BLUE,  v -> callback.startBotMatch("classic_2p"));
        addQuickBtn(quickRow, "⚡  Quick Match", ThemeManager.GREEN, v -> callback.startQuickMatch("classic_2p"));

        // ── Navigation grid ───────────────────────────────────────────────────
        addSectionLabel(inner, "EXPLORE");

        LinearLayout row1 = new LinearLayout(activity);
        row1.setOrientation(LinearLayout.HORIZONTAL);
        inner.addView(row1, lp(-1, -2, 0, 0, 0, dp(10)));
        addNavCard(row1, "Profile",     "Stats & history", ThemeManager.BLUE,   "profile",     "👤");
        addNavCard(row1, "Leaderboard", "Top players",     ThemeManager.YELLOW, "leaderboard", "🏆");

        LinearLayout row2 = new LinearLayout(activity);
        row2.setOrientation(LinearLayout.HORIZONTAL);
        inner.addView(row2, lp(-1, -2, 0, 0, 0, dp(10)));
        addNavCard(row2, "Shop",     "Get coins",    ThemeManager.GREEN, "shop",     "🛒");
        addNavCard(row2, "Settings", "Preferences",  0xff94A3B8,         "settings", "⚙️");

        LinearLayout row3 = new LinearLayout(activity);
        row3.setOrientation(LinearLayout.HORIZONTAL);
        inner.addView(row3, lp(-1, -2, 0, 0, 0, dp(12)));
        addNavCard(row3, "Match History", "Past games", ThemeManager.RED, "history", "📜");

        // Version tag
        TextView ver = text("v0.3.0 — Ludo Rush", 11, theme.txtVer(), Typeface.NORMAL);
        ver.setGravity(Gravity.CENTER);
        inner.addView(ver, lp(-1, -2, 0, dp(4), 0, dp(4)));

        scroll.addView(inner, new ScrollView.LayoutParams(-1, -2));

        LinearLayout.LayoutParams scrollLp = new LinearLayout.LayoutParams(-1, 0);
        scrollLp.weight = 1;
        root.addView(scroll, scrollLp);

        // ── Banner ad at the bottom ───────────────────────────────────────────
        LinearLayout adBar = new LinearLayout(activity);
        adBar.setOrientation(LinearLayout.VERTICAL);
        adBar.setGravity(Gravity.CENTER);
        adBar.setBackgroundColor(theme.bgHeader());
        adBar.setPadding(0, dp(3), 0, dp(3));
        adBar.addView(AdManager.get().createBanner(), new LinearLayout.LayoutParams(-2, -2));
        root.addView(adBar, lp(-1, -2));

        return root;
    }

    private void addQuickBtn(LinearLayout parent, String label, int textColor, View.OnClickListener l) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(textColor);
        b.setTextSize(14);
        b.setTypeface(Typeface.DEFAULT_BOLD);
        b.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));
        b.setOnClickListener(l);
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, dp(52), 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        parent.addView(b, p);
    }

    private void addNavCard(LinearLayout parent, String title, String sub, int accent, String screen, String emoji) {
        LinearLayout c = new LinearLayout(activity);
        c.setOrientation(LinearLayout.VERTICAL);
        c.setBackground(card(theme.bgCard(), dp(18), theme.strokeCard()));
        c.setOnClickListener(v -> callback.navigateTo(screen));
        c.setClipToOutline(true);

        // Colored gradient top bar
        View topBar = new View(activity);
        GradientDrawable barBg = new GradientDrawable(
            GradientDrawable.Orientation.LEFT_RIGHT, new int[]{accent, 0x00000000});
        topBar.setBackground(barBg);
        c.addView(topBar, lp(-1, dp(4)));

        // Card body with padding
        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(14), dp(10), dp(14), dp(14));
        c.addView(body, lp(-1, -2));

        // Emoji header
        body.addView(text(emoji, 24, Color.WHITE, Typeface.NORMAL),
            lp(-2, -2, 0, 0, 0, dp(6)));

        body.addView(text(title, 14, theme.txtPrimary(), Typeface.BOLD));
        body.addView(text(sub, 11, theme.txtMuted(), Typeface.NORMAL),
            lp(-1, -2, 0, dp(2), 0, 0));

        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        parent.addView(c, p);
    }
}
