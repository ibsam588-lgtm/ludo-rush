package com.ludorush.game;

import android.app.Activity;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.RippleDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

public abstract class BaseScreen {
    protected final Activity activity;
    protected final ScreenCallback callback;

    // Shared palette
    protected static final int BG_DEEP = 0xff070B14;
    protected static final int CARD_BG = 0xff131C2E;
    protected static final int CARD_BG_SOFT = 0xff0F1626;
    protected static final int STROKE_SOFT = 0x335D6D86;
    protected static final int TEXT_DIM = 0xff8B9BB4;
    protected static final int TEXT_FAINT = 0xff5A6B85;
    protected static final int ACCENT_RED = 0xffFF3D5A;
    protected static final int ACCENT_GOLD = 0xffFFB300;
    protected static final int ACCENT_BLUE = 0xff2E9BFF;
    protected static final int ACCENT_GREEN = 0xff35C75A;
    protected static final int ACCENT_PURPLE = 0xff9C6BFF;

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
        void startPrivateRoom(String mode);
        void joinPrivateRoom(String code);
        void rollDice();
        void moveBestPiece();
        void resign();
        boolean isMatchActive();
        void addCoins(int amount);
        void resetAccount();
        String getAppVersion();
        void fetchJson(String path, JsonResult handler);

        interface JsonResult {
            void onSuccess(org.json.JSONObject body);
            void onError(String message);
        }
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
        d.setStroke(dp(1), 0x447A8CAB);
        return d;
    }

    protected GradientDrawable buttonGradient(int start, int end, int radius) {
        GradientDrawable d = new GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT, new int[]{start, end});
        d.setCornerRadius(radius);
        return d;
    }

    protected GradientDrawable circle(int color, int strokeColor, int strokeDp) {
        GradientDrawable d = new GradientDrawable();
        d.setShape(GradientDrawable.OVAL);
        d.setColor(color);
        if (strokeDp > 0) d.setStroke(dp(strokeDp), strokeColor);
        return d;
    }

    protected GradientDrawable circleGradient(int start, int end, int strokeColor, int strokeDp) {
        GradientDrawable d = new GradientDrawable(GradientDrawable.Orientation.TL_BR, new int[]{start, end});
        d.setShape(GradientDrawable.OVAL);
        if (strokeDp > 0) d.setStroke(dp(strokeDp), strokeColor);
        return d;
    }

    protected Drawable pressable(Drawable bg) {
        return new RippleDrawable(ColorStateList.valueOf(0x33FFFFFF), bg, null);
    }

    protected Button actionButton(String label, int start, int end) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(Color.WHITE);
        b.setTextSize(16);
        b.setTypeface(Typeface.DEFAULT_BOLD);
        GradientDrawable bg = buttonGradient(start, end, dp(18));
        bg.setStroke(dp(1), 0x55FFFFFF);
        b.setBackground(pressable(bg));
        b.setElevation(dp(6));
        return b;
    }

    protected Button secondaryButton(String label) {
        Button b = new Button(activity);
        b.setAllCaps(false);
        b.setText(label);
        b.setTextColor(Color.WHITE);
        b.setTextSize(13);
        b.setTypeface(Typeface.DEFAULT_BOLD);
        b.setBackground(pressable(card(0xff1B2740, dp(18), 0x446F84A8)));
        return b;
    }

    protected TextView iconChip(String emoji, int sizeDp, int bgStart, int bgEnd) {
        TextView v = new TextView(activity);
        v.setText(emoji);
        v.setTextSize(sizeDp / 2.4f);
        v.setGravity(Gravity.CENTER);
        v.setBackground(cardGradient(bgStart, bgEnd, dp(sizeDp / 3)));
        return v;
    }

    /** Round avatar showing the first letter of the player name on a colored gradient. */
    protected TextView avatarView(String name, int sizeDp) {
        TextView v = new TextView(activity);
        String letter = (name == null || name.isEmpty()) ? "?" : name.substring(0, 1).toUpperCase(java.util.Locale.US);
        v.setText(letter);
        v.setTextColor(Color.WHITE);
        v.setTextSize(sizeDp / 2.6f);
        v.setTypeface(Typeface.DEFAULT_BOLD);
        v.setGravity(Gravity.CENTER);
        v.setBackground(circleGradient(0xffFF5470, 0xffC2183A, 0x66FFFFFF, 2));
        v.setElevation(dp(4));
        return v;
    }

    /** Small rounded stat pill, e.g. coins or rating, with an emoji icon. */
    protected LinearLayout statPill(String emoji, String value, int valueColor) {
        LinearLayout pill = new LinearLayout(activity);
        pill.setOrientation(LinearLayout.HORIZONTAL);
        pill.setGravity(Gravity.CENTER_VERTICAL);
        pill.setPadding(dp(10), dp(5), dp(12), dp(5));
        pill.setBackground(card(0xCC101A2C, dp(16), 0x44708AB0));

        TextView ic = text(emoji, 13, Color.WHITE, Typeface.NORMAL);
        pill.addView(ic, lp(-2, -2, 0, 0, dp(5), 0));
        pill.addView(text(value, 13, valueColor, Typeface.BOLD));
        return pill;
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
        h.setPadding(dp(14), dp(12), dp(16), dp(12));

        Button back = new Button(activity);
        back.setAllCaps(false);
        back.setText("‹");
        back.setTextColor(Color.WHITE);
        back.setTextSize(24);
        back.setTypeface(Typeface.DEFAULT_BOLD);
        back.setPadding(0, 0, 0, dp(3));
        back.setBackground(pressable(card(0xff18233A, dp(14), 0x447A8CAB)));
        back.setOnClickListener(v -> callback.goBack());
        h.addView(back, lp(dp(42), dp(42), 0, 0, dp(14), 0));

        TextView t = text(title, 21, Color.WHITE, Typeface.BOLD);
        LinearLayout.LayoutParams tp = new LinearLayout.LayoutParams(0, -2, 1);
        h.addView(t, tp);
        return h;
    }

    protected View createScreenShell(String title, View content) {
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);

        root.addView(createHeader(title), lp(-1, -2));

        ScrollView scroll = new ScrollView(activity);
        scroll.setFillViewport(true);
        scroll.setOverScrollMode(View.OVER_SCROLL_NEVER);
        scroll.setVerticalScrollBarEnabled(false);

        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(18), dp(8), dp(18), dp(24));
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
        v.setBackground(card(0x331C2A3F, dp(14), 0x336C7A96));
        v.setPadding(dp(4), dp(10), dp(4), dp(10));
        return v;
    }

    protected void addSectionLabel(LinearLayout parent, String label) {
        if (label == null || label.isEmpty()) {
            View gap = new View(activity);
            parent.addView(gap, lp(-1, dp(14)));
            return;
        }
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);

        View bar = new View(activity);
        bar.setBackground(buttonGradient(ACCENT_GOLD, ACCENT_RED, dp(2)));
        row.addView(bar, lp(dp(4), dp(14), 0, 0, dp(8), 0));

        TextView t = text(label, 12, TEXT_DIM, Typeface.BOLD);
        t.setLetterSpacing(0.12f);
        row.addView(t);

        parent.addView(row, lp(-1, -2, 0, dp(18), 0, dp(10)));
    }
}
