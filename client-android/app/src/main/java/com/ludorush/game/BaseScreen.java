package com.ludorush.game;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

/**
 * Royal Rush base screen with premium component helpers.
 * All UI is built programmatically — no XML layouts.
 */
public abstract class BaseScreen {

    protected final Activity activity;
    protected final ScreenCallback callback;
    protected final ThemeManager theme;
    private static final Typeface BODY_FONT = Typeface.create("sans-serif", Typeface.NORMAL);
    private static final Typeface BODY_BOLD = Typeface.create("sans-serif-medium", Typeface.BOLD);
    private static final Typeface DISPLAY_FONT = Typeface.create("sans-serif-medium", Typeface.BOLD);

    public interface ScreenCallback {
        void navigateTo(String screen);
        void navigateTo(String screen, String data);
        void goBack();
        String getPlayerId();
        String getDisplayName();
        int getCoins();
        int getRating();
        int getGamesPlayed();
        int getWins();
        boolean isOnline();
        void addCoins(int amount);
        void startBotMatch(String mode);
        void startQuickMatch(String mode);
        void rollDice();
        void moveBestPiece();
        void movePiece(String pieceId);
        void resign();
        void sendChat(String message);
        String getCountry();
        boolean isUnder13();
    }

    public BaseScreen(Activity activity, ScreenCallback callback) {
        this.activity = activity;
        this.callback = callback;
        this.theme = ThemeManager.get(activity);
    }

    public abstract View createView();

    // ── Unit conversion ───────────────────────────────────────────────────────

    protected int dp(int v) {
        return (int) (v * activity.getResources().getDisplayMetrics().density + 0.5f);
    }

    // ── Text ──────────────────────────────────────────────────────────────────

    protected TextView text(String t, int sp, int color, int style) {
        TextView v = new TextView(activity);
        v.setText(t);
        v.setTextSize(sp);
        v.setTextColor(color);
        v.setTypeface(fontFor(style));
        v.setIncludeFontPadding(false);
        return v;
    }

    protected Typeface fontFor(int style) {
        if (style == Typeface.BOLD) return DISPLAY_FONT;
        if (style == Typeface.BOLD_ITALIC) return BODY_BOLD;
        return BODY_FONT;
    }

    // ── Card drawables ────────────────────────────────────────────────────────

    protected GradientDrawable card(int color, int radius, int strokeColor) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(radius);
        d.setStroke(dp(1), strokeColor);
        return d;
    }

    protected GradientDrawable cardGradient(int start, int end, int radius) {
        GradientDrawable d = new GradientDrawable(
                GradientDrawable.Orientation.TL_BR, new int[]{start, end});
        d.setCornerRadius(radius);
        d.setStroke(dp(1), theme.strokeGrad());
        return d;
    }

    protected GradientDrawable buttonGradient(int start, int end, int radius) {
        GradientDrawable d = new GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT, new int[]{start, end});
        d.setCornerRadius(radius);
        return d;
    }

    protected GradientDrawable circle(int color) {
        GradientDrawable d = new GradientDrawable();
        d.setShape(GradientDrawable.OVAL);
        d.setColor(color);
        return d;
    }

    protected GradientDrawable circleOutline(int color, int strokeColor) {
        GradientDrawable d = new GradientDrawable();
        d.setShape(GradientDrawable.OVAL);
        d.setColor(color);
        d.setStroke(dp(2), strokeColor);
        return d;
    }

    // ── Glowing card ──────────────────────────────────────────────────────────

    protected GradientDrawable glowCard(int color, int radius, int glowColor) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(radius);
        d.setStroke(dp(1), glowColor);
        return d;
    }

    // ── Buttons ───────────────────────────────────────────────────────────────

    protected Button primaryButton(String label) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(0xff1A0800);   // dark brown on gold — high contrast
        b.setTextSize(15);
        b.setTypeface(DISPLAY_FONT);
        b.setIncludeFontPadding(false);
        b.setBackground(buttonGradient(ThemeManager.GOLD, ThemeManager.AMBER, dp(20)));
        b.setElevation(dp(4));
        return b;
    }

    protected Button actionButton(String label, int start, int end) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(Color.WHITE);
        b.setTextSize(15);
        b.setTypeface(DISPLAY_FONT);
        b.setIncludeFontPadding(false);
        b.setBackground(buttonGradient(start, end, dp(20)));
        b.setElevation(dp(2));
        return b;
    }

    protected Button secondaryButton(String label) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(Color.WHITE);
        b.setTextSize(13);
        b.setTypeface(DISPLAY_FONT);
        b.setIncludeFontPadding(false);
        b.setBackground(card(0xff1565C0, dp(20), ThemeManager.GOLD));
        return b;
    }

    protected Button ghostButton(String label, int borderColor) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(borderColor);
        b.setTextSize(13);
        b.setTypeface(DISPLAY_FONT);
        b.setIncludeFontPadding(false);
        b.setBackground(card(0x00000000, dp(20), borderColor));
        return b;
    }

    // ── Layout params ─────────────────────────────────────────────────────────

    protected LinearLayout.LayoutParams lp(int w, int h) {
        return new LinearLayout.LayoutParams(w, h);
    }

    protected LinearLayout.LayoutParams lp(int w, int h, int l, int t, int r, int b) {
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(w, h);
        p.setMargins(l, t, r, b);
        return p;
    }

    // ── Screen shell ──────────────────────────────────────────────────────────

    protected View createScreenShell(String title, View content) {
        return createScreenShell(title, content, false);
    }

    protected View createScreenShell(String title, View content, boolean withBanner) {
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(theme.bgPage());

        root.addView(createHeader(title), lp(-1, -2));

        ScrollView scroll = new ScrollView(activity);
        scroll.setFillViewport(true);
        scroll.setOverScrollMode(View.OVER_SCROLL_NEVER);
        scroll.setVerticalScrollBarEnabled(false);

        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(18), dp(12), dp(18), dp(20));
        body.addView(content, lp(-1, -2));
        scroll.addView(body, new ScrollView.LayoutParams(-1, -2));

        LinearLayout.LayoutParams sp = new LinearLayout.LayoutParams(-1, 0);
        sp.weight = 1;
        root.addView(scroll, sp);

        if (withBanner) {
            LinearLayout adContainer = new LinearLayout(activity);
            adContainer.setOrientation(LinearLayout.VERTICAL);
            adContainer.setGravity(Gravity.CENTER);
            adContainer.setBackgroundColor(theme.bgHeader());
            adContainer.setPadding(0, dp(2), 0, dp(2));
            adContainer.addView(AdManager.get().createBanner(), new LinearLayout.LayoutParams(-2, -2));
            root.addView(adContainer, lp(-1, -2));
        }

        return root;
    }

    /** Top navigation bar used by inner screens. */
    protected LinearLayout createHeader(String title) {
        LinearLayout h = new LinearLayout(activity);
        h.setOrientation(LinearLayout.HORIZONTAL);
        h.setGravity(Gravity.CENTER_VERTICAL);
        h.setPadding(dp(4), dp(14), dp(12), dp(14));
        h.setBackground(card(theme.bgHeader(), 0, theme.strokeCard()));

        Button back = new Button(activity);
        back.setAllCaps(false);
        back.setText("<");
        back.setTextColor(ThemeManager.GOLD);
        back.setTextSize(26);
        back.setTypeface(DISPLAY_FONT);
        back.setIncludeFontPadding(false);
        back.setBackground(null);
        back.setPadding(dp(12), 0, dp(8), 0);
        back.setOnClickListener(v -> callback.goBack());
        h.addView(back, lp(dp(52), dp(52)));

        TextView t = text(title, 18, ThemeManager.GOLD, Typeface.BOLD);
        t.setLetterSpacing(0.01f);
        LinearLayout.LayoutParams tp = new LinearLayout.LayoutParams(0, -2, 1);
        h.addView(t, tp);

        Button themeToggle = new Button(activity);
        themeToggle.setAllCaps(false);
        themeToggle.setText(theme.isDark() ? "LT" : "DK");
        themeToggle.setTextSize(11);
        themeToggle.setTypeface(DISPLAY_FONT);
        themeToggle.setIncludeFontPadding(false);
        themeToggle.setBackground(circle(theme.bgCard()));
        themeToggle.setPadding(dp(4), dp(4), dp(4), dp(4));
        themeToggle.setOnClickListener(v -> {
            theme.setDark(!theme.isDark());
            activity.recreate();
        });
        h.addView(themeToggle, lp(dp(40), dp(40)));

        return h;
    }

    // ── Section label ─────────────────────────────────────────────────────────

    protected void addSectionLabel(LinearLayout parent, String label) {
        TextView t = text(label, 10, theme.txtMuted(), Typeface.BOLD);
        t.setPadding(dp(2), 0, 0, 0);
        t.setLetterSpacing(0.06f);
        parent.addView(t, lp(-1, -2, 0, dp(20), 0, dp(10)));
    }

    // ── Metric chip ───────────────────────────────────────────────────────────

    protected TextView metric(String label, String value) {
        TextView v = new TextView(activity);
        v.setGravity(Gravity.CENTER);
        v.setTextColor(theme.txtPrimary());
        v.setTextSize(13);
        v.setTypeface(DISPLAY_FONT);
        v.setIncludeFontPadding(false);
        v.setText(label + "\n" + value);
        v.setBackground(glowCard(theme.bgCard(), dp(16), theme.strokeCardGlow()));
        v.setPadding(dp(4), dp(12), dp(4), dp(12));
        return v;
    }

    // ── Seat colors ───────────────────────────────────────────────────────────

    protected int seatColor(int seat) {
        int[] c = {ThemeManager.RED, ThemeManager.BLUE, ThemeManager.YELLOW, ThemeManager.GREEN};
        return c[Math.max(0, Math.min(c.length - 1, seat))];
    }

    protected int seatColorSoft(int seat) {
        int[] c = {ThemeManager.RED_SOFT, ThemeManager.BLUE_SOFT,
                   ThemeManager.YELLOW_SOFT, ThemeManager.GREEN_SOFT};
        return c[Math.max(0, Math.min(c.length - 1, seat))];
    }

    // ── Badge / chip ──────────────────────────────────────────────────────────

    protected TextView badge(String badgeText, int bgColor, int textColor) {
        TextView v = new TextView(activity);
        v.setText(badgeText);
        v.setTextColor(textColor);
        v.setTextSize(10);
        v.setTypeface(DISPLAY_FONT);
        v.setIncludeFontPadding(false);
        v.setLetterSpacing(0.02f);
        v.setPadding(dp(8), dp(3), dp(8), dp(3));
        GradientDrawable d = new GradientDrawable();
        d.setColor(bgColor);
        d.setCornerRadius(dp(12));
        v.setBackground(d);
        return v;
    }

    // ── Avatar ────────────────────────────────────────────────────────────────

    protected FrameLayout avatarRing(String initial, int ringColor, int size) {
        FrameLayout frame = new FrameLayout(activity);

        View ring = new View(activity);
        ring.setBackground(circleOutline(ringColor, ringColor));
        frame.addView(ring, new FrameLayout.LayoutParams(size, size));

        int innerSize = (int)(size * 0.82f);
        int offset = (size - innerSize) / 2;
        TextView inner = new TextView(activity);
        inner.setGravity(Gravity.CENTER);
        String letter = (initial != null && !initial.isEmpty())
                ? initial.substring(0, 1).toUpperCase() : "?";
        inner.setText(letter);
        inner.setTextColor(Color.WHITE);
        inner.setTextSize(innerSize * 0.016f);
        inner.setTypeface(DISPLAY_FONT);
        inner.setIncludeFontPadding(false);
        GradientDrawable bg = new GradientDrawable();
        bg.setShape(GradientDrawable.OVAL);
        bg.setColor(ringColor);
        inner.setBackground(bg);
        FrameLayout.LayoutParams ilp = new FrameLayout.LayoutParams(innerSize, innerSize);
        ilp.setMargins(offset, offset, offset, offset);
        frame.addView(inner, ilp);

        return frame;
    }

    // ── Divider ───────────────────────────────────────────────────────────────

    protected View hairline() {
        View v = new View(activity);
        v.setBackgroundColor(theme.strokeCard());
        return v;
    }
}
