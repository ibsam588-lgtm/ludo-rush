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
        void startBotMatch(String mode);
        void startQuickMatch(String mode);
        void rollDice();
        void moveBestPiece();
        void resign();
    }

    public BaseScreen(Activity activity, ScreenCallback callback) {
        this.activity = activity;
        this.callback = callback;
    }

    public abstract View createView();

    protected int dp(int value) {
        return (int) (value * activity.getResources().getDisplayMetrics().density + 0.5f);
    }

    protected TextView text(String t, int sp, int color, int style) {
        TextView v = new TextView(activity);
        v.setText(t);
        v.setTextSize(sp);
        v.setTextColor(color);
        v.setTypeface(Typeface.DEFAULT, style);
        return v;
    }

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
        d.setStroke(dp(1), 0x334B5D78);
        return d;
    }

    protected GradientDrawable buttonGradient(int start, int end, int radius) {
        GradientDrawable d = new GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT, new int[]{start, end});
        d.setCornerRadius(radius);
        return d;
    }

    protected Button actionButton(String label, int start, int end) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(Color.WHITE);
        b.setTextSize(16);
        b.setTypeface(Typeface.DEFAULT_BOLD);
        b.setBackground(buttonGradient(start, end, dp(16)));
        return b;
    }

    protected Button secondaryButton(String label) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(Color.WHITE);
        b.setTextSize(13);
        b.setTypeface(Typeface.DEFAULT_BOLD);
        b.setBackground(card(0xff1A2638, dp(16), 0x335D6D86));
        return b;
    }

    protected LinearLayout.LayoutParams lp(int w, int h) {
        return new LinearLayout.LayoutParams(w, h);
    }

    protected LinearLayout.LayoutParams lp(int w, int h, int l, int t, int r, int b) {
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(w, h);
        p.setMargins(l, t, r, b);
        return p;
    }

    protected int seatColor(int seat) {
        int[] c = {0xffE8293E, 0xff1E88E5, 0xffF9A825, 0xff43A047};
        return c[Math.max(0, Math.min(c.length - 1, seat))];
    }

    protected LinearLayout createHeader(String title) {
        LinearLayout h = new LinearLayout(activity);
        h.setOrientation(LinearLayout.HORIZONTAL);
        h.setGravity(Gravity.CENTER_VERTICAL);
        h.setPadding(dp(4), dp(12), dp(16), dp(12));
        h.setBackgroundColor(0xff0D1320);

        Button back = new Button(activity);
        back.setAllCaps(false);
        back.setText("<");
        back.setTextColor(Color.WHITE);
        back.setTextSize(18);
        back.setTypeface(Typeface.DEFAULT_BOLD);
        back.setBackground(null);
        back.setOnClickListener(v -> callback.goBack());
        h.addView(back, lp(dp(48), dp(48)));

        TextView t = text(title, 20, Color.WHITE, Typeface.BOLD);
        LinearLayout.LayoutParams tp = new LinearLayout.LayoutParams(0, -2, 1);
        h.addView(t, tp);
        return h;
    }

    protected View createScreenShell(String title, View content) {
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(0xff080B13);

        root.addView(createHeader(title), lp(-1, -2));

        ScrollView scroll = new ScrollView(activity);
        scroll.setFillViewport(true);
        scroll.setOverScrollMode(View.OVER_SCROLL_NEVER);

        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(18), dp(12), dp(18), dp(18));
        body.addView(content, lp(-1, -2));
        scroll.addView(body, new ScrollView.LayoutParams(-1, -2));

        LinearLayout.LayoutParams sp = new LinearLayout.LayoutParams(-1, 0);
        sp.weight = 1;
        root.addView(scroll, sp);
        return root;
    }

    protected TextView metric(String label, String value) {
        TextView v = new TextView(activity);
        v.setGravity(Gravity.CENTER);
        v.setTextColor(Color.WHITE);
        v.setTextSize(14);
        v.setTypeface(Typeface.DEFAULT_BOLD);
        v.setText(label.toUpperCase(java.util.Locale.US) + "\n" + value);
        v.setBackground(card(0x331C2A3F, dp(14), 0x226C7A96));
        v.setPadding(dp(4), dp(10), dp(4), dp(10));
        return v;
    }

    protected void addSectionLabel(LinearLayout parent, String label) {
        TextView t = text(label, 12, 0xff6B7A90, Typeface.BOLD);
        t.setPadding(dp(2), 0, 0, 0);
        parent.addView(t, lp(-1, -2, 0, dp(16), 0, dp(8)));
    }
}
