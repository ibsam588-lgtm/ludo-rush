package com.ludorush.game;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

public abstract class BaseScreen {

    protected final Activity activity;
    protected final ScreenCallback callback;
    protected final ThemeManager theme;

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
        void resign();
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

    // ── Text ─────────────────────────────────────────────────────────────────

    protected TextView text(String t, int sp, int color, int style) {
        TextView v = new TextView(activity);
        v.setText(t);
        v.setTextSize(sp);
        v.setTextColor(color);
        v.setTypeface(Typeface.DEFAULT, style);
        return v;
    }

    // ── Drawables ─────────────────────────────────────────────────────────────

    protected GradientDrawable card(int color, int radius, int strokeColor) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(radius);
        d.setStroke(dp(1), strokeColor);
        return d;
    }

    protected GradientDrawable cardGradient(int start, int end, int radius) {
        GradientDrawable d = new GradientDrawable(GradientDrawable.Orientation.TL_BR, new int[]{start, end});
        d.setCornerRadius(radius);
        d.setStroke(dp(1), theme.strokeGrad());
        return d;
    }

    protected GradientDrawable buttonGradient(int start, int end, int radius) {
        GradientDrawable d = new GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT, new int[]{start, end});
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

    // ── Buttons ───────────────────────────────────────────────────────────────

    protected Button actionButton(String label, int start, int end) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(Color.WHITE);
        b.setTextSize(16);
        b.setTypeface(Typeface.DEFAULT_BOLD);
        b.setBackground(buttonGradient(start, end, dp(16)));
        b.setElevation(dp(2));
        return b;
    }

    protected Button secondaryButton(String label) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(theme.txtPrimary());
        b.setTextSize(13);
        b.setTypeface(Typeface.DEFAULT_BOLD);
        b.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));
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

    // ── Seat colors ───────────────────────────────────────────────────────────

    protected int seatColor(int seat) {
        int[] c = {ThemeManager.RED, ThemeManager.BLUE, ThemeManager.YELLOW, ThemeManager.GREEN};
        return c[Math.max(0, Math.min(c.length - 1, seat))];
    }

    // ── Common composites ─────────────────────────────────────────────────────

    protected LinearLayout createHeader(String title) {
        LinearLayout h = new LinearLayout(activity);
        h.setOrientation(LinearLayout.HORIZONTAL);
        h.setGravity(Gravity.CENTER_VERTICAL);
        h.setPadding(dp(4), dp(12), dp(16), dp(12));
        h.setBackground(card(theme.bgHeader(), 0, theme.strokeCard()));

        Button back = new Button(activity);
        back.setAllCaps(false);
        back.setText("‹");
        back.setTextColor(theme.txtPrimary());
        back.setTextSize(26);
        back.setTypeface(Typeface.DEFAULT_BOLD);
        back.setBackground(null);
        back.setOnClickListener(v -> callback.goBack());
        h.addView(back, lp(dp(52), dp(52)));

        TextView t = text(title, 20, theme.txtPrimary(), Typeface.BOLD);
        t.setLetterSpacing(0.02f);
        LinearLayout.LayoutParams tp = new LinearLayout.LayoutParams(0, -2, 1);
        h.addView(t, tp);
        return h;
    }

    protected View createScreenShell(String title, View content) {
        return createScreenShell(title, content, false);
    }

    /** @param withBanner append a 320×50 AdMob banner below the scroll area */
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
        body.setPadding(dp(18), dp(12), dp(18), dp(18));
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

    protected TextView metric(String label, String value) {
        TextView v = new TextView(activity);
        v.setGravity(Gravity.CENTER);
        v.setTextColor(theme.txtPrimary());
        v.setTextSize(13);
        v.setTypeface(Typeface.DEFAULT_BOLD);
        v.setText(label + "\n" + value);
        v.setBackground(card(theme.bgMetric(), dp(14), theme.strokeCardAlt()));
        v.setPadding(dp(4), dp(10), dp(4), dp(10));
        return v;
    }

    protected void addSectionLabel(LinearLayout parent, String label) {
        TextView t = text(label, 11, theme.txtMuted(), Typeface.BOLD);
        t.setPadding(dp(2), 0, 0, 0);
        t.setLetterSpacing(0.12f);
        parent.addView(t, lp(-1, -2, 0, dp(16), 0, dp(8)));
    }

    protected View hairline() {
        View v = new View(activity);
        v.setBackgroundColor(theme.strokeCard());
        return v;
    }
}
