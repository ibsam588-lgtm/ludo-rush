package com.ludorush.game;

import android.app.Activity;
import android.app.Dialog;
import android.content.SharedPreferences;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

public final class HomeScreen extends BaseScreen {

    private static final String[][] NOTIFICATIONS = {
            {"🎁", "Daily bonus ready", "Claim your free coins in the Shop.", "Just now"},
            {"🏆", "Season 1 is live", "Climb the leaderboard to earn rewards.", "2h ago"},
            {"⚡", "Rush mode tip", "15-second turns. Think fast, move faster!", "1d ago"},
            {"👋", "Welcome to Ludo Rush", "Play your first match to earn 100 coins.", "2d ago"},
    };

    private TextView badgeView;

    public HomeScreen(Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        ScrollView scroll = new ScrollView(activity);
        scroll.setFillViewport(true);
        scroll.setOverScrollMode(View.OVER_SCROLL_NEVER);
        scroll.setVerticalScrollBarEnabled(false);

        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(18), dp(16), dp(18), dp(18));
        scroll.addView(root, new ScrollView.LayoutParams(-1, -2));

        root.addView(buildTopBar(), lp(-1, -2, 0, 0, 0, dp(18)));
        root.addView(buildHeroCard(), lp(-1, -2, 0, 0, 0, dp(16)));

        LinearLayout quickRow = new LinearLayout(activity);
        quickRow.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(quickRow, lp(-1, -2, 0, 0, 0, dp(6)));
        addQuickCard(quickRow, "🤖", "Bot Match", "Instant game", 0xff174A8C, 0xff0F2B52,
                v -> callback.startBotMatch("classic_2p"));
        addQuickCard(quickRow, "⚡", "Quick Match", "Find players", 0xff14633A, 0xff0C3A23,
                v -> callback.startQuickMatch("classic_2p"));

        addSectionLabel(root, "EXPLORE");

        LinearLayout grid1 = new LinearLayout(activity);
        grid1.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(grid1, lp(-1, -2, 0, 0, 0, dp(10)));
        addNavTile(grid1, "👤", "Profile", "Stats & badges", ACCENT_BLUE, "profile");
        addNavTile(grid1, "🏆", "Leaderboard", "Top players", ACCENT_GOLD, "leaderboard");

        LinearLayout grid2 = new LinearLayout(activity);
        grid2.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(grid2, lp(-1, -2, 0, 0, 0, dp(10)));
        addNavTile(grid2, "🛒", "Shop", "Coins & packs", ACCENT_GREEN, "shop");
        addNavTile(grid2, "📜", "History", "Past games", ACCENT_PURPLE, "history");

        LinearLayout grid3 = new LinearLayout(activity);
        grid3.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(grid3, lp(-1, -2));
        addNavTile(grid3, "⚙️", "Settings", "Preferences", 0xff94A3B8, "settings");
        addNavTile(grid3, "🎁", "Daily Bonus", "Free coins", ACCENT_RED, "shop");

        View spacer = new View(activity);
        LinearLayout.LayoutParams sp = new LinearLayout.LayoutParams(-1, 0);
        sp.weight = 1;
        root.addView(spacer, sp);

        TextView ver = text("v0.2.0 — Internal Test Build", 11, 0xff3A4556, Typeface.NORMAL);
        ver.setGravity(Gravity.CENTER);
        root.addView(ver, lp(-1, -2, 0, dp(16), 0, 0));

        return scroll;
    }

    private View buildTopBar() {
        LinearLayout bar = new LinearLayout(activity);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setGravity(Gravity.CENTER_VERTICAL);

        bar.addView(avatarView(callback.getDisplayName(), 46), lp(dp(46), dp(46), 0, 0, dp(10), 0));

        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams ip = new LinearLayout.LayoutParams(0, -2, 1);
        bar.addView(info, ip);

        info.addView(text(callback.getDisplayName(), 16, Color.WHITE, Typeface.BOLD));
        TextView status = text(callback.isOnline() ? "● Online" : "● Offline", 11,
                callback.isOnline() ? ACCENT_GREEN : TEXT_FAINT, Typeface.BOLD);
        info.addView(status);

        bar.addView(statPill("🪙", String.valueOf(callback.getCoins()), ACCENT_GOLD),
                lp(-2, -2, 0, 0, dp(8), 0));
        bar.addView(statPill("⭐", String.valueOf(callback.getRating()), ACCENT_BLUE),
                lp(-2, -2, 0, 0, dp(8), 0));
        bar.addView(buildBellButton(), lp(dp(42), dp(42)));
        return bar;
    }

    private View buildBellButton() {
        FrameLayout holder = new FrameLayout(activity);

        TextView bell = new TextView(activity);
        bell.setText("🔔");
        bell.setTextSize(17);
        bell.setGravity(Gravity.CENTER);
        bell.setBackground(pressable(card(0xff18233A, dp(14), 0x447A8CAB)));
        bell.setOnClickListener(v -> showNotifications());
        holder.addView(bell, new FrameLayout.LayoutParams(-1, -1));

        badgeView = new TextView(activity);
        badgeView.setTextSize(9);
        badgeView.setTextColor(Color.WHITE);
        badgeView.setTypeface(Typeface.DEFAULT_BOLD);
        badgeView.setGravity(Gravity.CENTER);
        badgeView.setBackground(circle(ACCENT_RED, 0xff070B14, 1));
        FrameLayout.LayoutParams bp = new FrameLayout.LayoutParams(dp(16), dp(16), Gravity.TOP | Gravity.END);
        bp.setMargins(0, dp(-3), dp(-3), 0);
        holder.addView(badgeView, bp);
        updateBadge();
        return holder;
    }

    private void updateBadge() {
        SharedPreferences prefs = activity.getSharedPreferences("ludo_settings", 0);
        boolean read = prefs.getBoolean("notifications_seen", false);
        badgeView.setText(String.valueOf(NOTIFICATIONS.length));
        badgeView.setVisibility(read ? View.GONE : View.VISIBLE);
    }

    private View buildHeroCard() {
        LinearLayout hero = new LinearLayout(activity);
        hero.setOrientation(LinearLayout.VERTICAL);
        hero.setGravity(Gravity.CENTER_HORIZONTAL);
        hero.setPadding(dp(20), dp(22), dp(20), dp(20));
        GradientDrawable bg = new GradientDrawable(GradientDrawable.Orientation.TL_BR,
                new int[]{0xff1C2A48, 0xff121A30, 0xff0E1424});
        bg.setCornerRadius(dp(26));
        bg.setStroke(dp(1), 0x55809BC8);
        hero.setBackground(bg);
        hero.setElevation(dp(8));

        hero.addView(new DicePairView(activity, dp(64)), lp(dp(150), dp(84), 0, 0, 0, dp(6)));

        TextView title = text("LUDO RUSH", 34, Color.WHITE, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        title.setLetterSpacing(0.08f);
        title.setShadowLayer(dp(10), 0, dp(2), 0xAAFF3D5A);
        hero.addView(title);

        TextView sub = text("Classic board battles, online", 13, TEXT_DIM, Typeface.NORMAL);
        sub.setGravity(Gravity.CENTER);
        hero.addView(sub, lp(-1, -2, 0, dp(2), 0, dp(18)));

        Button play = new Button(activity);
        play.setAllCaps(false);
        play.setText("▶  PLAY NOW");
        play.setTextColor(Color.WHITE);
        play.setTextSize(19);
        play.setTypeface(Typeface.DEFAULT_BOLD);
        GradientDrawable pbg = buttonGradient(0xffFF3D5A, 0xffFF9F1C, dp(20));
        pbg.setStroke(dp(2), 0x66FFFFFF);
        play.setBackground(pressable(pbg));
        play.setElevation(dp(10));
        play.setOnClickListener(v -> callback.navigateTo("lobby"));
        hero.addView(play, lp(-1, dp(60), dp(8), 0, dp(8), 0));

        return hero;
    }

    private void addQuickCard(LinearLayout parent, String emoji, String title, String sub,
                              int gradStart, int gradEnd, View.OnClickListener l) {
        LinearLayout c = new LinearLayout(activity);
        c.setOrientation(LinearLayout.HORIZONTAL);
        c.setGravity(Gravity.CENTER_VERTICAL);
        c.setPadding(dp(12), dp(12), dp(12), dp(12));
        GradientDrawable bg = new GradientDrawable(GradientDrawable.Orientation.TL_BR,
                new int[]{gradStart, gradEnd});
        bg.setCornerRadius(dp(18));
        bg.setStroke(dp(1), 0x44FFFFFF);
        c.setBackground(pressable(bg));
        c.setOnClickListener(l);

        TextView ic = text(emoji, 20, Color.WHITE, Typeface.NORMAL);
        c.addView(ic, lp(-2, -2, 0, 0, dp(10), 0));

        LinearLayout col = new LinearLayout(activity);
        col.setOrientation(LinearLayout.VERTICAL);
        c.addView(col, new LinearLayout.LayoutParams(0, -2, 1));
        col.addView(text(title, 14, Color.WHITE, Typeface.BOLD));
        col.addView(text(sub, 11, 0xBBE2E8F0, Typeface.NORMAL));

        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        parent.addView(c, p);
    }

    private void addNavTile(LinearLayout parent, String emoji, String title, String sub,
                            int accent, String screen) {
        LinearLayout c = new LinearLayout(activity);
        c.setOrientation(LinearLayout.HORIZONTAL);
        c.setGravity(Gravity.CENTER_VERTICAL);
        c.setPadding(dp(12), dp(12), dp(12), dp(12));
        GradientDrawable bg = cardGradient(0xff15203A, 0xff0F1626, dp(18));
        c.setBackground(pressable(bg));
        c.setOnClickListener(v -> callback.navigateTo(screen));

        TextView ic = text(emoji, 18, Color.WHITE, Typeface.NORMAL);
        ic.setGravity(Gravity.CENTER);
        GradientDrawable chipBg = new GradientDrawable();
        chipBg.setColor((accent & 0x00FFFFFF) | 0x26000000);
        chipBg.setCornerRadius(dp(12));
        chipBg.setStroke(dp(1), (accent & 0x00FFFFFF) | 0x55000000);
        ic.setBackground(chipBg);
        c.addView(ic, lp(dp(40), dp(40), 0, 0, dp(10), 0));

        LinearLayout col = new LinearLayout(activity);
        col.setOrientation(LinearLayout.VERTICAL);
        c.addView(col, new LinearLayout.LayoutParams(0, -2, 1));
        col.addView(text(title, 14, Color.WHITE, Typeface.BOLD));
        col.addView(text(sub, 11, TEXT_DIM, Typeface.NORMAL));

        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        parent.addView(c, p);
    }

    private void showNotifications() {
        SharedPreferences prefs = activity.getSharedPreferences("ludo_settings", 0);
        prefs.edit().putBoolean("notifications_seen", true).apply();
        updateBadge();

        Dialog dialog = new Dialog(activity);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);

        LinearLayout panel = new LinearLayout(activity);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setPadding(dp(20), dp(20), dp(20), dp(16));
        panel.setBackground(cardGradient(0xff1A2440, 0xff0F1626, dp(24)));

        LinearLayout head = new LinearLayout(activity);
        head.setOrientation(LinearLayout.HORIZONTAL);
        head.setGravity(Gravity.CENTER_VERTICAL);
        panel.addView(head, lp(-1, -2, 0, 0, 0, dp(14)));
        head.addView(text("🔔", 18, Color.WHITE, Typeface.NORMAL), lp(-2, -2, 0, 0, dp(8), 0));
        TextView ht = text("Notifications", 18, Color.WHITE, Typeface.BOLD);
        head.addView(ht, new LinearLayout.LayoutParams(0, -2, 1));

        for (String[] n : NOTIFICATIONS) {
            LinearLayout row = new LinearLayout(activity);
            row.setOrientation(LinearLayout.HORIZONTAL);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(dp(12), dp(11), dp(12), dp(11));
            row.setBackground(card(0xff141E34, dp(16), 0x33607498));
            panel.addView(row, lp(-1, -2, 0, 0, 0, dp(8)));

            row.addView(text(n[0], 18, Color.WHITE, Typeface.NORMAL), lp(-2, -2, 0, 0, dp(12), 0));

            LinearLayout col = new LinearLayout(activity);
            col.setOrientation(LinearLayout.VERTICAL);
            row.addView(col, new LinearLayout.LayoutParams(0, -2, 1));
            col.addView(text(n[1], 14, Color.WHITE, Typeface.BOLD));
            col.addView(text(n[2], 12, TEXT_DIM, Typeface.NORMAL));

            col.addView(text(n[3], 10, TEXT_FAINT, Typeface.NORMAL), lp(-2, -2, 0, dp(2), 0, 0));
        }

        Button close = secondaryButton("Close");
        close.setOnClickListener(v -> dialog.dismiss());
        panel.addView(close, lp(-1, dp(46), 0, dp(8), 0, 0));

        ScrollView wrap = new ScrollView(activity);
        wrap.setVerticalScrollBarEnabled(false);
        wrap.addView(panel, new ViewGroup.LayoutParams(-1, -2));

        dialog.setContentView(wrap);
        Window w = dialog.getWindow();
        if (w != null) {
            w.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
            w.setLayout((int) (activity.getResources().getDisplayMetrics().widthPixels * 0.9f), -2);
        }
        dialog.show();
    }

    /** Two tilted dice drawn on canvas for the hero banner. */
    static final class DicePairView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF rect = new RectF();
        private final int dieSize;

        DicePairView(Activity activity, int dieSize) {
            super(activity);
            this.dieSize = dieSize;
        }

        @Override
        protected void onDraw(Canvas canvas) {
            int w = getWidth(), h = getHeight();
            float s = dieSize;

            // Back die (gold, showing 3)
            canvas.save();
            canvas.translate(w * 0.62f, h * 0.46f);
            canvas.rotate(14);
            drawDie(canvas, s * 0.86f, 0xffFFB300, 0xffD98E00, 3);
            canvas.restore();

            // Front die (red, showing 6)
            canvas.save();
            canvas.translate(w * 0.36f, h * 0.52f);
            canvas.rotate(-12);
            drawDie(canvas, s, 0xffFF3D5A, 0xffC2183A, 6);
            canvas.restore();
        }

        private void drawDie(Canvas canvas, float size, int color, int edge, int value) {
            float half = size / 2f;
            float r = size * 0.22f;

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0x55000000);
            rect.set(-half + size * 0.06f, -half + size * 0.1f, half + size * 0.06f, half + size * 0.1f);
            canvas.drawRoundRect(rect, r, r, paint);

            paint.setColor(color);
            rect.set(-half, -half, half, half);
            canvas.drawRoundRect(rect, r, r, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(size * 0.05f);
            paint.setColor(edge);
            canvas.drawRoundRect(rect, r, r, paint);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(Color.WHITE);
            float p = size * 0.24f;
            float dot = size * 0.085f;
            switch (value) {
                case 3:
                    canvas.drawCircle(-p, -p, dot, paint);
                    canvas.drawCircle(0, 0, dot, paint);
                    canvas.drawCircle(p, p, dot, paint);
                    break;
                case 6:
                default:
                    canvas.drawCircle(-p, -p, dot, paint);
                    canvas.drawCircle(-p, 0, dot, paint);
                    canvas.drawCircle(-p, p, dot, paint);
                    canvas.drawCircle(p, -p, dot, paint);
                    canvas.drawCircle(p, 0, dot, paint);
                    canvas.drawCircle(p, p, dot, paint);
                    break;
            }
        }
    }
}
