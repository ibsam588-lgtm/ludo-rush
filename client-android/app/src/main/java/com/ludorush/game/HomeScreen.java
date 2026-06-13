package com.ludorush.game;

import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.view.ViewTreeObserver;
import android.view.animation.DecelerateInterpolator;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class HomeScreen extends BaseScreen {
    private static final Typeface DISPLAY = Typeface.create("sans-serif-black", Typeface.BOLD);
    private static final Typeface BODY    = Typeface.create("sans-serif-medium", Typeface.BOLD);

    public HomeScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        FrameLayout shell = new FrameLayout(activity);
        shell.setBackgroundColor(theme.isDark() ? 0xff08011E : 0xffF9E6FF);
        shell.addView(new CosmicParkBackdrop(activity, theme.isDark()), new FrameLayout.LayoutParams(-1, -1));

        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(10), dp(8), dp(10), dp(8));
        root.setClipChildren(false);

        root.addView(buildTopBar(), lp(-1, dp(74)));
        root.addView(buildHero(), lp(-1, dp(188), 0, dp(8), 0, dp(2)));
        root.addView(buildModes(), new LinearLayout.LayoutParams(-1, 0, 1));
        root.addView(buildBottomNav(), lp(-1, dp(80), 0, dp(8), 0, 0));

        shell.addView(root, new FrameLayout.LayoutParams(-1, -1));
        return shell;
    }

    private View buildTopBar() {
        LinearLayout bar = new LinearLayout(activity);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setPadding(dp(8), dp(7), dp(8), dp(7));
        bar.setClipChildren(false);
        bar.setBackground(gradient(0xff25105C, 0xff10042E, dp(22), 0xff8D51FF, 2));

        FrameLayout avatar = new FrameLayout(activity);
        avatar.addView(new AvatarView(activity), new FrameLayout.LayoutParams(-1, -1));
        TextView level = label("12", 12, Color.WHITE, DISPLAY);
        level.setGravity(Gravity.CENTER);
        level.setBackground(circle(0xffE29B00, 0xffFFF0A8, 2));
        FrameLayout.LayoutParams levelLp = new FrameLayout.LayoutParams(dp(22), dp(22), Gravity.RIGHT | Gravity.BOTTOM);
        levelLp.setMargins(0, 0, -dp(2), -dp(2));
        avatar.addView(level, levelLp);
        LinearLayout.LayoutParams avatarLp = new LinearLayout.LayoutParams(dp(54), dp(54));
        avatarLp.setMargins(0, 0, dp(6), 0);
        bar.addView(avatar, avatarLp);

        LinearLayout identity = new LinearLayout(activity);
        identity.setOrientation(LinearLayout.VERTICAL);
        identity.setGravity(Gravity.CENTER_VERTICAL);
        TextView name = label(displayName(), 16, Color.WHITE, DISPLAY);
        name.setSingleLine(true);
        identity.addView(name, lp(-1, -2));
        TextView trophies = label("T  " + callback.getRating(), 12, 0xffFFD426, BODY);
        trophies.setSingleLine(true);
        identity.addView(trophies, lp(-1, -2, 0, dp(5), 0, 0));
        bar.addView(identity, new LinearLayout.LayoutParams(0, -1, 0.45f));

        // Coin balance pill (shows real balance from callback)
        String coinStr = formatCoins(callback.getCoins());
        bar.addView(coinPill(coinStr), new LinearLayout.LayoutParams(0, dp(44), 1.1f));
        addGap(bar, 4);
        bar.addView(currency("D", "1.3K", 0xff35D9FF, true), new LinearLayout.LayoutParams(0, dp(44), 1.0f));
        addGap(bar, 4);

        TextView vip = label("VIP", 16, 0xff4C103F, DISPLAY);
        vip.setGravity(Gravity.CENTER);
        vip.setBackground(gradient(0xffFFE15A, 0xffFF8A00, dp(16), 0xffFFEE98, 2));
        bar.addView(vip, new LinearLayout.LayoutParams(dp(48), dp(52)));
        return bar;
    }

    private View coinPill(String coinStr) {
        LinearLayout pill = new LinearLayout(activity);
        pill.setGravity(Gravity.CENTER_VERTICAL);
        pill.setPadding(dp(4), dp(4), dp(4), dp(4));
        pill.setBackground(gradient(0xff321271, 0xff180737, dp(22), 0x88FFFFFF, 1));

        TextView icon = label("🪙", 14, 0xff5B2500, DISPLAY);
        icon.setGravity(Gravity.CENTER);
        icon.setBackground(circle(0xffFFD426, 0xffFF9D00, 2));
        LinearLayout.LayoutParams iconLp = new LinearLayout.LayoutParams(dp(28), dp(28));
        iconLp.setMargins(0, 0, dp(3), 0);
        pill.addView(icon, iconLp);

        TextView amount = label(coinStr, 13, Color.WHITE, DISPLAY);
        amount.setSingleLine(true);
        pill.addView(amount, new LinearLayout.LayoutParams(0, -1, 1));

        TextView add = label("+", 15, Color.WHITE, DISPLAY);
        add.setGravity(Gravity.CENTER);
        add.setBackground(circle(0xff3CCC43, Color.WHITE, 1));
        add.setOnClickListener(v -> callback.navigateTo("shop"));
        pill.addView(add, new LinearLayout.LayoutParams(dp(22), dp(22)));
        return pill;
    }

    private String formatCoins(int coins) {
        if (coins >= 1000) return (coins / 1000) + "." + ((coins % 1000) / 100) + "K";
        return String.valueOf(coins);
    }

    private View currency(String icon, String value, int color, boolean plus) {
        LinearLayout pill = new LinearLayout(activity);
        pill.setGravity(Gravity.CENTER_VERTICAL);
        pill.setPadding(dp(4), dp(4), dp(4), dp(4));
        pill.setBackground(gradient(0xff321271, 0xff180737, dp(22), 0x88FFFFFF, 1));

        TextView coin = label(icon, 15, icon.equals("D") ? Color.WHITE : 0xff5B2500, DISPLAY);
        coin.setGravity(Gravity.CENTER);
        coin.setBackground(icon.equals("D") ? diamondDrawable() : circle(color, 0xffFF9D00, 2));
        LinearLayout.LayoutParams coinLp = new LinearLayout.LayoutParams(dp(28), dp(28));
        coinLp.setMargins(0, 0, dp(3), 0);
        pill.addView(coin, coinLp);

        TextView amount = label(value, 13, Color.WHITE, DISPLAY);
        amount.setSingleLine(true);
        pill.addView(amount, new LinearLayout.LayoutParams(0, -1, 1));

        if (plus) {
            TextView addV = label("+", 15, Color.WHITE, DISPLAY);
            addV.setGravity(Gravity.CENTER);
            addV.setBackground(circle(0xff3CCC43, Color.WHITE, 1));
            pill.addView(addV, new LinearLayout.LayoutParams(dp(22), dp(22)));
        }
        return pill;
    }

    private View buildHero() {
        FrameLayout hero = new FrameLayout(activity);
        hero.setClipChildren(false);

        TextView toggle = label(theme.isDark() ? "SUN   MOON" : "SUN   MOON", 13, Color.WHITE, BODY);
        toggle.setGravity(Gravity.CENTER);
        toggle.setBackground(gradient(0xff7A21DF, 0xff321080, dp(21), 0xffB97AFF, 2));
        toggle.setOnClickListener(v -> { theme.setDark(!theme.isDark()); activity.recreate(); });
        FrameLayout.LayoutParams toggleLp = new FrameLayout.LayoutParams(dp(124), dp(44), Gravity.RIGHT | Gravity.TOP);
        toggleLp.setMargins(0, dp(6), dp(4), 0);
        hero.addView(toggle, toggleLp);

        hero.addView(new LogoSceneView(activity, theme.isDark()), new FrameLayout.LayoutParams(-1, -1));
        hero.addView(new LogoTextView(activity), new FrameLayout.LayoutParams(-1, -1));
        return hero;
    }

    private View buildModes() {
        LinearLayout list = new LinearLayout(activity);
        list.setOrientation(LinearLayout.VERTICAL);
        list.setPadding(dp(8), 0, dp(8), 0);
        list.setClipChildren(false);

        // Active modes
        list.addView(modeRow("QUICK MATCH", "Find players online\nand play now!", 0xffD238F5, 0xff7010B8,
                "dice", false, () -> callback.startQuickMatch("classic_2p")), rowLp());
        list.addView(modeRow("1 ON 1", "Challenge a player\nin a duel", 0xffFFB60A, 0xffCA6800,
                "duel", false, () -> callback.startQuickMatch("classic_2p")), rowLp());
        list.addView(modeRow("4 PLAYER", "Classic Ludo with\n4 players", 0xff1DCF39, 0xff006A18,
                "four", false, () -> callback.startQuickMatch("classic_4p")), rowLp());
        list.addView(modeRow("PLAY OFFLINE", "Play against smart\nAI opponents", 0xffDB2CCB, 0xff701070,
                "bot", false, () -> callback.startBotMatch("classic_2p")), rowLp());

        // Greyed out — not yet implemented
        list.addView(modeRow("PRIVATE ROOM", "Coming soon — invite\nyour friends", 0xff5a5a7a, 0xff333350,
                "lock", true, null), rowLp());
        list.addView(modeRow("TEAM UP", "Coming soon — team\nmode", 0xff5a5a7a, 0xff333350,
                "team", true, null), rowLp());

        // Entrance animation: cards slide in from right one by one
        list.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
            @Override public void onGlobalLayout() {
                list.getViewTreeObserver().removeOnGlobalLayoutListener(this);
                for (int i = 0; i < list.getChildCount(); i++) {
                    View child = list.getChildAt(i);
                    child.setTranslationX(dp(380));
                    child.setAlpha(0f);
                    child.animate()
                        .translationX(0).alpha(child.getAlpha() >= 0.5f ? child.getAlpha() : 1f)
                        .setDuration(360)
                        .setStartDelay(i * 70L)
                        .setInterpolator(new DecelerateInterpolator(1.6f))
                        .start();
                }
            }
        });

        return list;
    }

    private LinearLayout.LayoutParams rowLp() {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(-1, 0, 1);
        lp.setMargins(0, dp(3), 0, dp(3));
        return lp;
    }

    private View modeRow(String title, String sub, int start, int end, String art,
                         boolean comingSoon, Runnable click) {
        LinearLayout row = new LinearLayout(activity);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(10), dp(7), dp(9), dp(7));
        row.setClipChildren(false);

        if (!comingSoon && click != null) {
            row.setClickable(true);
            row.setOnClickListener(v -> click.run());
            row.setBackground(gradient(start, end, dp(22), 0xffFFEB75, 3));
            row.setElevation(dp(7));
        } else {
            // Greyed out appearance
            row.setBackground(gradient(start, end, dp(22), 0x55FFEB75, 2));
            row.setAlpha(0.48f);
        }

        ModeIconView icon = new ModeIconView(activity, art);
        LinearLayout.LayoutParams iconLp = new LinearLayout.LayoutParams(dp(88), -1);
        iconLp.setMargins(0, 0, dp(10), 0);
        row.addView(icon, iconLp);

        LinearLayout copy = new LinearLayout(activity);
        copy.setOrientation(LinearLayout.VERTICAL);
        copy.setGravity(Gravity.CENTER_VERTICAL);

        TextView headline = label(title, 22, Color.WHITE, DISPLAY);
        headline.setSingleLine(false);
        headline.setShadowLayer(dp(3), 0, dp(3), 0xcc000000);
        copy.addView(headline, lp(-1, -2));

        String subText = comingSoon ? "Coming soon" : sub;
        TextView desc = label(subText, 12, 0xffFFE0FF, BODY);
        desc.setMaxLines(2);
        desc.setLineSpacing(dp(1), 1.0f);
        desc.setShadowLayer(dp(2), 0, dp(2), 0xaa000000);
        copy.addView(desc, lp(-1, -2, 0, dp(3), 0, 0));
        row.addView(copy, new LinearLayout.LayoutParams(0, -1, 1));

        ArrowView arrow = new ArrowView(activity);
        row.addView(arrow, new LinearLayout.LayoutParams(dp(34), -1));
        return row;
    }

    private View buildBottomNav() {
        LinearLayout nav = new LinearLayout(activity);
        nav.setGravity(Gravity.CENTER);
        nav.setPadding(dp(8), dp(7), dp(8), dp(7));
        nav.setBackground(gradient(0xff21106B, 0xff100636, dp(22), 0xff6648FF, 2));

        addNav(nav, "SHOP",       "shop",        "cart",    false, true);
        addNav(nav, "FRIENDS",    "profile",     "friends", false, true);
        addNav(nav, "HOME",       "home",        "home",    true,  false);
        addNav(nav, "COLLECTION", "history",     "cards",   false, false);
        addNav(nav, "EVENTS",     "shop",        "calendar",false, false);
        return nav;
    }

    private void addNav(LinearLayout nav, String label, String route, String icon,
                        boolean active, boolean badge) {
        FrameLayout slot = new FrameLayout(activity);
        LinearLayout item = new LinearLayout(activity);
        item.setOrientation(LinearLayout.VERTICAL);
        item.setGravity(Gravity.CENTER);
        item.setPadding(0, dp(3), 0, dp(2));
        if (active) {
            item.setBackground(gradient(0xff9C22F4, 0xff32037A, dp(20), 0xffFFD426, 3));
            item.setElevation(dp(8));
        }

        NavIconView navIcon = new NavIconView(activity, icon, active);
        item.addView(navIcon, new LinearLayout.LayoutParams(dp(42), dp(38)));

        TextView tv = label(label, active ? 12 : 11, Color.WHITE, DISPLAY);
        tv.setGravity(Gravity.CENTER);
        tv.setSingleLine(true);
        tv.setShadowLayer(dp(2), 0, dp(2), 0xaa000000);
        item.addView(tv, lp(-1, -2, 0, dp(2), 0, 0));
        item.setOnClickListener(v -> {
            if (!"home".equals(route)) callback.navigateTo(route);
        });
        slot.addView(item, new FrameLayout.LayoutParams(-1, -1));

        if (badge) {
            TextView b = label(icon.equals("cart") ? "!" : "12", 11, Color.WHITE, DISPLAY);
            b.setGravity(Gravity.CENTER);
            b.setBackground(circle(icon.equals("cart") ? 0xffF42525 : 0xff4DDE31, Color.WHITE, 1));
            FrameLayout.LayoutParams bLp = new FrameLayout.LayoutParams(dp(24), dp(24), Gravity.RIGHT | Gravity.TOP);
            bLp.setMargins(0, 0, dp(10), -dp(1));
            slot.addView(b, bLp);
        }

        LinearLayout.LayoutParams slotLp = new LinearLayout.LayoutParams(0, -1, 1);
        slotLp.setMargins(dp(2), 0, dp(2), 0);
        nav.addView(slot, slotLp);
    }

    // ── Helper methods ─────────────────────────────────────────────────────────

    private TextView label(String text, int sp, int color, Typeface typeface) {
        TextView v = new TextView(activity);
        v.setText(text); v.setTextSize(sp);
        v.setTextColor(color); v.setTypeface(typeface);
        v.setIncludeFontPadding(false);
        return v;
    }

    private String displayName() {
        String name = callback.getDisplayName();
        if (name == null || name.trim().isEmpty() || "Rush Tester".equals(name)) return "Ibsam";
        return name.trim();
    }

    private GradientDrawable gradient(int start, int end, int radius, int stroke, int strokeDp) {
        GradientDrawable d = new GradientDrawable(GradientDrawable.Orientation.TL_BR, new int[]{start, end});
        d.setCornerRadius(radius);
        d.setStroke(dp(strokeDp), stroke);
        return d;
    }

    private GradientDrawable circle(int color, int strokeColor, int strokeDp) {
        GradientDrawable d = new GradientDrawable();
        d.setShape(GradientDrawable.OVAL);
        d.setColor(color);
        d.setStroke(dp(strokeDp), strokeColor);
        return d;
    }

    private GradientDrawable diamondDrawable() {
        GradientDrawable d = new GradientDrawable(GradientDrawable.Orientation.TL_BR,
                new int[]{0xff9DFFFF, 0xff18C9FF, 0xff0A5DDF});
        d.setCornerRadius(dp(8));
        d.setStroke(dp(1), 0xffD9FFFF);
        return d;
    }

    private void addGap(LinearLayout parent, int widthDp) {
        View gap = new View(activity);
        parent.addView(gap, new LinearLayout.LayoutParams(dp(widthDp), 1));
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Inner canvas views (unchanged from original)
    // ══════════════════════════════════════════════════════════════════════════

    private static final class CosmicParkBackdrop extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path path = new Path();
        private final boolean dark;

        CosmicParkBackdrop(android.app.Activity activity, boolean dark) {
            super(activity); this.dark = dark;
        }

        @Override protected void onDraw(Canvas canvas) {
            float w = getWidth(), h = getHeight();
            int[] colors = dark
                    ? new int[]{0xff050027, 0xff35128B, 0xff9B1FE0, 0xff120022}
                    : new int[]{0xff3B14A7, 0xffF04FD5, 0xff47D9FF, 0xffFFF0B4};
            paint.setShader(new LinearGradient(0, 0, w, h, colors, null, Shader.TileMode.CLAMP));
            canvas.drawRect(0, 0, w, h, paint);
            paint.setShader(null);
            paint.setColor(0x44FFFFFF);
            canvas.drawCircle(w*0.74f, h*0.10f, w*0.10f, paint);
            paint.setColor(0x20FFFFFF);
            canvas.drawCircle(w*0.55f, h*0.47f, w*0.38f, paint);
            for (int i = 0; i < 74; i++) {
                float x = ((i*71+19)%1000)/1000f*w, y = ((i*127+43)%1000)/1000f*h;
                int color = new int[]{0xffFFFFFF,0xffFFD426,0xff32E9FF,0xffFF4FD8,0xff58FF3B}[i%5];
                paint.setColor(color);
                if (i%3==0) canvas.drawCircle(x, y, 2.2f+(i%4), paint);
                else {
                    canvas.save(); canvas.rotate((i*23)%180, x, y);
                    canvas.drawRoundRect(new RectF(x,y,x+w*0.018f,y+h*0.004f), 5f, 5f, paint);
                    canvas.restore();
                }
            }
            drawBalloon(canvas, w*0.10f, h*0.13f, w*0.06f);
            drawWheel(canvas, w*0.90f, h*0.24f, w*0.11f);
            drawCoaster(canvas, w, h);
            drawCoin(canvas, w*0.95f, h*0.42f, w*0.055f);
            drawCoin(canvas, w*0.08f, h*0.70f, w*0.052f);
            drawGem(canvas, w*0.06f, h*0.52f, w*0.045f, 0xff22D8FF);
            drawGem(canvas, w*0.93f, h*0.54f, w*0.044f, 0xff51FF36);
            drawGem(canvas, w*0.08f, h*0.36f, w*0.036f, 0xffFF5EE7);
        }

        private void drawBalloon(Canvas canvas, float cx, float cy, float r) {
            paint.setStyle(Paint.Style.FILL); paint.setColor(0xffE63A70);
            canvas.drawOval(new RectF(cx-r, cy-r*1.25f, cx+r, cy+r*1.1f), paint);
            paint.setColor(0x88FFFFFF);
            canvas.drawArc(new RectF(cx-r, cy-r*1.25f, cx+r, cy+r*1.1f), -80, 30, true, paint);
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(3f); paint.setColor(0x99FFFFFF);
            canvas.drawLine(cx, cy+r*1.1f, cx-r*0.3f, cy+r*2.3f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawWheel(Canvas canvas, float cx, float cy, float r) {
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(r*0.10f); paint.setColor(0xff26D7FF);
            canvas.drawCircle(cx, cy, r, paint);
            paint.setStrokeWidth(r*0.035f); paint.setColor(0xaaFFFFFF);
            for (int i=0; i<10; i++) {
                double a = Math.PI*2*i/10.0;
                canvas.drawLine(cx, cy, cx+(float)Math.cos(a)*r, cy+(float)Math.sin(a)*r, paint);
            }
            paint.setStyle(Paint.Style.FILL);
            for (int i=0; i<10; i++) {
                double a = Math.PI*2*i/10.0;
                paint.setColor(i%2==0 ? 0xffFFD426 : 0xffFF4FD8);
                canvas.drawCircle(cx+(float)Math.cos(a)*r, cy+(float)Math.sin(a)*r, r*0.10f, paint);
            }
        }

        private void drawCoaster(Canvas canvas, float w, float h) {
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(w*0.013f); paint.setColor(0xAAFF4FD8);
            path.reset();
            path.moveTo(-w*0.05f, h*0.31f);
            path.cubicTo(w*0.12f, h*0.22f, w*0.18f, h*0.45f, w*0.30f, h*0.34f);
            path.cubicTo(w*0.43f, h*0.22f, w*0.55f, h*0.46f, w*0.68f, h*0.34f);
            path.cubicTo(w*0.80f, h*0.24f, w*0.88f, h*0.35f, w*1.05f, h*0.31f);
            canvas.drawPath(path, paint); paint.setStyle(Paint.Style.FILL);
        }

        private void drawCoin(Canvas canvas, float cx, float cy, float r) {
            paint.setColor(0x66000000); canvas.drawCircle(cx+r*0.16f, cy+r*0.20f, r, paint);
            paint.setColor(0xffFFD426); canvas.drawCircle(cx, cy, r, paint);
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(r*0.15f); paint.setColor(0xffFF8A00);
            canvas.drawCircle(cx, cy, r*0.68f, paint); paint.setStyle(Paint.Style.FILL);
        }

        private void drawGem(Canvas canvas, float cx, float cy, float r, int color) {
            path.reset();
            path.moveTo(cx, cy-r); path.lineTo(cx+r, cy);
            path.lineTo(cx, cy+r); path.lineTo(cx-r, cy); path.close();
            paint.setColor(color); canvas.drawPath(path, paint);
            paint.setColor(0x88FFFFFF); canvas.drawCircle(cx-r*0.22f, cy-r*0.22f, r*0.22f, paint);
        }
    }

    private static final class AvatarView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        AvatarView(android.app.Activity activity) { super(activity); }
        @Override protected void onDraw(Canvas canvas) {
            float w=getWidth(), h=getHeight(), r=Math.min(w,h)/2f, cx=w/2f, cy=h/2f;
            paint.setColor(0xffFFD426); canvas.drawCircle(cx,cy,r,paint);
            paint.setColor(0xff262066); canvas.drawCircle(cx,cy,r*0.84f,paint);
            paint.setColor(0xffF5B16B); canvas.drawCircle(cx,cy+r*0.08f,r*0.43f,paint);
            paint.setColor(0xff2A1307);
            for (int i=0; i<8; i++) {
                float x=cx-r*0.52f+i*r*0.15f;
                canvas.drawCircle(x, cy-r*0.31f-(i%3)*r*0.05f, r*0.18f, paint);
            }
            paint.setColor(Color.WHITE);
            canvas.drawCircle(cx-r*0.18f, cy+r*0.02f, r*0.07f, paint);
            canvas.drawCircle(cx+r*0.18f, cy+r*0.02f, r*0.07f, paint);
            paint.setColor(0xff281006);
            canvas.drawCircle(cx-r*0.18f, cy+r*0.03f, r*0.035f, paint);
            canvas.drawCircle(cx+r*0.18f, cy+r*0.03f, r*0.035f, paint);
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(r*0.06f); paint.setColor(Color.WHITE);
            canvas.drawArc(new RectF(cx-r*0.25f,cy+r*0.11f,cx+r*0.25f,cy+r*0.40f), 15, 150, false, paint);
            paint.setStyle(Paint.Style.FILL);
        }
    }

    private static final class LogoSceneView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path path = new Path();
        private final boolean dark;
        LogoSceneView(android.app.Activity activity, boolean dark) { super(activity); this.dark=dark; }
        @Override protected void onDraw(Canvas canvas) {
            float w=getWidth(), h=getHeight();
            drawCrown(canvas, w*0.50f, h*0.24f, w*0.16f);
            drawDice(canvas, w*0.23f, h*0.54f, w*0.12f, 4, 0xffFFFFFF);
            drawDice(canvas, w*0.77f, h*0.54f, w*0.12f, 5, 0xffFFFFFF);
            paint.setColor(dark ? 0x33000000 : 0x22FFFFFF);
            canvas.drawOval(new RectF(w*0.18f, h*0.76f, w*0.82f, h*0.92f), paint);
        }
        private void drawCrown(Canvas canvas, float cx, float cy, float s) {
            path.reset();
            path.moveTo(cx-s, cy+s*0.60f); path.lineTo(cx-s*0.72f, cy-s*0.28f);
            path.lineTo(cx-s*0.28f, cy+s*0.16f); path.lineTo(cx, cy-s*0.64f);
            path.lineTo(cx+s*0.28f, cy+s*0.16f); path.lineTo(cx+s*0.72f, cy-s*0.28f);
            path.lineTo(cx+s, cy+s*0.60f); path.close();
            paint.setShader(new LinearGradient(cx, cy-s, cx, cy+s, 0xffFFF49A, 0xffF49300, Shader.TileMode.CLAMP));
            canvas.drawPath(path, paint); paint.setShader(null);
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(s*0.08f); paint.setColor(0xffFFF2A1);
            canvas.drawPath(path, paint); paint.setStyle(Paint.Style.FILL);
        }
        private void drawDice(Canvas canvas, float cx, float cy, float s, int value, int fill) {
            RectF r = new RectF(cx-s/2f, cy-s/2f, cx+s/2f, cy+s/2f);
            paint.setColor(0x77000000);
            canvas.drawRoundRect(new RectF(r.left+8,r.top+9,r.right+8,r.bottom+9), s*0.18f, s*0.18f, paint);
            paint.setColor(fill); canvas.drawRoundRect(r, s*0.18f, s*0.18f, paint);
            paint.setColor(0xff221022);
            float dot=s*0.07f, left=r.left+s*0.30f, midX=r.centerX(), right2=r.right-s*0.30f;
            float top=r.top+s*0.30f, midY=r.centerY(), bottom=r.bottom-s*0.30f;
            if (value==1||value==3||value==5) canvas.drawCircle(midX,midY,dot,paint);
            if (value>=2) { canvas.drawCircle(left,top,dot,paint); canvas.drawCircle(right2,bottom,dot,paint); }
            if (value>=4) { canvas.drawCircle(right2,top,dot,paint); canvas.drawCircle(left,bottom,dot,paint); }
        }
    }

    private static final class LogoTextView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final int[] letterColors = {0xffF22F22, 0xff23D627, 0xffFFD426, 0xff0D9BFF};
        LogoTextView(android.app.Activity activity) { super(activity); }
        @Override protected void onDraw(Canvas canvas) {
            float w=getWidth(), h=getHeight();
            paint.setTypeface(DISPLAY); paint.setTextAlign(Paint.Align.CENTER);
            float ludoSize=Math.min(w*0.19f,h*0.31f), rushSize=Math.min(w*0.17f,h*0.26f);
            float y1=h*0.53f, y2=h*0.78f;
            paint.setShadowLayer(12f, 0, 9f, 0xdd000000);
            drawOutlined(canvas, "LUDO", w/2f, y1, ludoSize, letterColors);
            paint.setTextSize(rushSize);
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(Math.max(8f,rushSize*0.16f));
            paint.setColor(0xff511074); canvas.drawText("RUSH", w/2f, y2, paint);
            paint.setStyle(Paint.Style.FILL);
            paint.setShader(new LinearGradient(0,y2-rushSize,0,y2+rushSize*0.2f,0xffffffff,0xffF7B3FF,Shader.TileMode.CLAMP));
            canvas.drawText("RUSH", w/2f, y2, paint); paint.setShader(null); paint.clearShadowLayer();
            paint.setColor(0xffFFD426); drawStar(canvas, w*0.73f, y2-rushSize*0.14f, rushSize*0.16f);
            paint.setStyle(Paint.Style.FILL);
        }
        private void drawOutlined(Canvas canvas, String text, float cx, float baseline, float sz, int[] cols) {
            paint.setTextSize(sz);
            float total=paint.measureText(text), x=cx-total/2f;
            for (int i=0; i<text.length(); i++) {
                String l=text.substring(i,i+1); float lw=paint.measureText(l), dx=x+lw/2f;
                paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(Math.max(7f,sz*0.10f));
                paint.setColor(0xfffff6cf); canvas.drawText(l, dx, baseline, paint);
                paint.setStyle(Paint.Style.FILL);
                paint.setShader(new LinearGradient(0,baseline-sz,0,baseline+sz*0.15f,0xffffffff,cols[i%cols.length],Shader.TileMode.CLAMP));
                canvas.drawText(l, dx, baseline, paint); paint.setShader(null); x+=lw;
            }
        }
        private void drawStar(Canvas canvas, float cx, float cy, float r) {
            Path star=new Path();
            for (int i=0; i<5; i++) {
                double a=-Math.PI/2+i*2*Math.PI/5;
                float x=cx+(float)Math.cos(a)*r, y=cy+(float)Math.sin(a)*r;
                if (i==0) star.moveTo(x,y); else star.lineTo(x,y);
                double inner=a+Math.PI/5;
                star.lineTo(cx+(float)Math.cos(inner)*r*0.45f, cy+(float)Math.sin(inner)*r*0.45f);
            }
            star.close(); canvas.drawPath(star, paint);
        }
    }

    private static final class ModeIconView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final String type;
        ModeIconView(android.app.Activity activity, String type) { super(activity); this.type=type; }
        @Override protected void onDraw(Canvas canvas) {
            float w=getWidth(), h=getHeight(), cx=w/2f, cy=h/2f, s=Math.min(w,h);
            if ("dice".equals(type)) drawDice(canvas,cx,cy,s*0.78f,5,0xffFFFFFF);
            else if ("lock".equals(type)) drawLock(canvas,cx,cy,s*0.78f);
            else if ("bot".equals(type)) drawBot(canvas,cx,cy,s*0.78f);
            else {
                drawBoard(canvas,cx,cy,s*0.66f);
                if ("duel".equals(type)) {
                    drawPawn(canvas,cx-s*0.20f,cy+s*0.16f,s*0.23f,0xffE82A22);
                    drawPawn(canvas,cx+s*0.22f,cy+s*0.16f,s*0.23f,0xff1C73FF);
                    drawVersus(canvas,cx,cy+s*0.10f,s*0.22f);
                } else if ("four".equals(type)) {
                    drawPawn(canvas,cx-s*0.23f,cy-s*0.07f,s*0.17f,0xffE82A22);
                    drawPawn(canvas,cx+s*0.23f,cy-s*0.07f,s*0.17f,0xff1C73FF);
                    drawPawn(canvas,cx-s*0.10f,cy+s*0.25f,s*0.17f,0xffFFD426);
                    drawPawn(canvas,cx+s*0.13f,cy+s*0.25f,s*0.17f,0xff2FD449);
                } else {
                    drawPawn(canvas,cx-s*0.16f,cy+s*0.18f,s*0.20f,0xffE82A22);
                    drawPawn(canvas,cx+s*0.16f,cy+s*0.18f,s*0.20f,0xff1C73FF);
                }
            }
        }
        private void drawBoard(Canvas canvas, float cx, float cy, float s) {
            RectF b=new RectF(cx-s/2f,cy-s/2f,cx+s/2f,cy+s/2f);
            paint.setColor(0xffFFF6D0); canvas.drawRoundRect(b,s*0.08f,s*0.08f,paint);
            paint.setColor(0xffF32B2B); canvas.drawRect(b.left,b.top,cx,cy,paint);
            paint.setColor(0xffFFD426); canvas.drawRect(cx,b.top,b.right,cy,paint);
            paint.setColor(0xff1565E0); canvas.drawRect(b.left,cy,cx,b.bottom,paint);
            paint.setColor(0xff2DB34A); canvas.drawRect(cx,cy,b.right,b.bottom,paint);
            paint.setColor(0xffFFF6D0);
            canvas.drawRect(cx-s*0.08f,b.top,cx+s*0.08f,b.bottom,paint);
            canvas.drawRect(b.left,cy-s*0.08f,b.right,cy+s*0.08f,paint);
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(s*0.035f); paint.setColor(0xCCFFFFFF);
            canvas.drawRoundRect(b,s*0.08f,s*0.08f,paint); paint.setStyle(Paint.Style.FILL);
        }
        private void drawPawn(Canvas canvas, float cx, float cy, float s, int color) {
            paint.setColor(0x66000000);
            canvas.drawOval(new RectF(cx-s*0.58f,cy+s*0.50f,cx+s*0.58f,cy+s*0.76f),paint);
            paint.setColor(color);
            canvas.drawCircle(cx,cy-s*0.20f,s*0.45f,paint);
            canvas.drawRoundRect(new RectF(cx-s*0.32f,cy+s*0.05f,cx+s*0.32f,cy+s*0.58f),s*0.20f,s*0.20f,paint);
            paint.setColor(0x88FFFFFF); canvas.drawCircle(cx-s*0.13f,cy-s*0.33f,s*0.12f,paint);
        }
        private void drawVersus(Canvas canvas, float cx, float cy, float s) {
            paint.setTextAlign(Paint.Align.CENTER); paint.setTypeface(DISPLAY); paint.setTextSize(s);
            paint.setColor(0xffFFD426); paint.setShadowLayer(6f,0,4f,0xaa000000);
            canvas.drawText("VS",cx,cy,paint); paint.clearShadowLayer();
        }
        private void drawDice(Canvas canvas, float cx, float cy, float s, int value, int fill) {
            RectF r=new RectF(cx-s/2f,cy-s/2f,cx+s/2f,cy+s/2f);
            paint.setColor(0x77000000);
            canvas.drawRoundRect(new RectF(r.left+7,r.top+8,r.right+7,r.bottom+8),s*0.18f,s*0.18f,paint);
            paint.setColor(fill); canvas.drawRoundRect(r,s*0.18f,s*0.18f,paint);
            paint.setColor(0xff261226);
            float dot=s*0.07f,left=r.left+s*0.30f,midX=r.centerX(),right2=r.right-s*0.30f;
            float top=r.top+s*0.30f,midY=r.centerY(),bottom=r.bottom-s*0.30f;
            if (value==1||value==3||value==5) canvas.drawCircle(midX,midY,dot,paint);
            if (value>=2) { canvas.drawCircle(left,top,dot,paint); canvas.drawCircle(right2,bottom,dot,paint); }
            if (value>=4) { canvas.drawCircle(right2,top,dot,paint); canvas.drawCircle(left,bottom,dot,paint); }
        }
        private void drawLock(Canvas canvas, float cx, float cy, float s) {
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(s*0.13f);
            paint.setStrokeCap(Paint.Cap.ROUND); paint.setColor(0xffFFE57A);
            canvas.drawArc(new RectF(cx-s*0.30f,cy-s*0.42f,cx+s*0.30f,cy+s*0.18f),190,160,false,paint);
            paint.setStyle(Paint.Style.FILL); paint.setStrokeCap(Paint.Cap.BUTT);
            paint.setColor(0x77000000);
            canvas.drawRoundRect(new RectF(cx-s*0.36f+6,cy-s*0.05f+8,cx+s*0.36f+6,cy+s*0.44f+8),s*0.12f,s*0.12f,paint);
            paint.setShader(new LinearGradient(cx,cy-s*0.1f,cx,cy+s*0.44f,0xffFFF491,0xffE58A00,Shader.TileMode.CLAMP));
            canvas.drawRoundRect(new RectF(cx-s*0.36f,cy-s*0.05f,cx+s*0.36f,cy+s*0.44f),s*0.12f,s*0.12f,paint);
            paint.setShader(null); paint.setColor(0xff5B2700);
            canvas.drawCircle(cx,cy+s*0.14f,s*0.08f,paint);
            canvas.drawRect(cx-s*0.035f,cy+s*0.17f,cx+s*0.035f,cy+s*0.32f,paint);
        }
        private void drawBot(Canvas canvas, float cx, float cy, float s) {
            paint.setColor(0x77000000);
            canvas.drawRoundRect(new RectF(cx-s*0.44f+6,cy-s*0.29f+7,cx+s*0.44f+6,cy+s*0.34f+7),s*0.22f,s*0.22f,paint);
            paint.setShader(new LinearGradient(cx-s*0.4f,cy-s*0.3f,cx+s*0.4f,cy+s*0.35f,0xffFFFFFF,0xff8EDCFF,Shader.TileMode.CLAMP));
            canvas.drawRoundRect(new RectF(cx-s*0.44f,cy-s*0.29f,cx+s*0.44f,cy+s*0.34f),s*0.22f,s*0.22f,paint);
            paint.setShader(null); paint.setColor(0xff00356B);
            canvas.drawCircle(cx-s*0.18f,cy,s*0.09f,paint); canvas.drawCircle(cx+s*0.18f,cy,s*0.09f,paint);
            paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(s*0.05f); paint.setColor(0xff26D7FF);
            canvas.drawArc(new RectF(cx-s*0.18f,cy+s*0.02f,cx+s*0.18f,cy+s*0.23f),15,150,false,paint);
            paint.setStyle(Paint.Style.FILL);
        }
    }

    private static final class ArrowView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        ArrowView(android.app.Activity activity) { super(activity); }
        @Override protected void onDraw(Canvas canvas) {
            float w=getWidth(), h=getHeight();
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(8f, w*0.18f));
            paint.setStrokeCap(Paint.Cap.ROUND); paint.setStrokeJoin(Paint.Join.ROUND);
            paint.setColor(Color.WHITE);
            Path p=new Path();
            p.moveTo(w*0.30f, h*0.32f); p.lineTo(w*0.70f, h*0.50f); p.lineTo(w*0.30f, h*0.68f);
            canvas.drawPath(p, paint); paint.setStyle(Paint.Style.FILL);
        }
    }

    private static final class NavIconView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final String icon; private final boolean active;
        NavIconView(android.app.Activity activity, String icon, boolean active) {
            super(activity); this.icon=icon; this.active=active;
        }
        @Override protected void onDraw(Canvas canvas) {
            float w=getWidth(), h=getHeight(), cx=w/2f, cy=h/2f;
            int fill = active ? 0xffFFD426 : 0xffFFFFFF;
            paint.setColor(fill); paint.setStyle(Paint.Style.FILL);
            if ("home".equals(icon)) {
                Path p=new Path();
                p.moveTo(cx,h*0.10f); p.lineTo(w*0.86f,h*0.45f); p.lineTo(w*0.76f,h*0.88f);
                p.lineTo(w*0.24f,h*0.88f); p.lineTo(w*0.14f,h*0.45f); p.close();
                canvas.drawPath(p,paint);
            } else if ("cart".equals(icon)) {
                paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(5f); paint.setStrokeCap(Paint.Cap.ROUND);
                canvas.drawLine(w*0.18f,h*0.22f,w*0.28f,h*0.22f,paint);
                canvas.drawLine(w*0.28f,h*0.22f,w*0.38f,h*0.66f,paint);
                canvas.drawLine(w*0.38f,h*0.66f,w*0.76f,h*0.66f,paint);
                canvas.drawLine(w*0.44f,h*0.36f,w*0.82f,h*0.36f,paint);
                paint.setStyle(Paint.Style.FILL);
                canvas.drawCircle(w*0.43f,h*0.82f,4.8f,paint); canvas.drawCircle(w*0.72f,h*0.82f,4.8f,paint);
            } else if ("friends".equals(icon)) {
                canvas.drawCircle(w*0.38f,h*0.34f,w*0.13f,paint);
                canvas.drawCircle(w*0.62f,h*0.34f,w*0.13f,paint);
                canvas.drawRoundRect(new RectF(w*0.20f,h*0.54f,w*0.80f,h*0.84f),12f,12f,paint);
            } else if ("cards".equals(icon)) {
                canvas.save(); canvas.rotate(-13,cx,cy);
                canvas.drawRoundRect(new RectF(w*0.18f,h*0.20f,w*0.60f,h*0.82f),8f,8f,paint);
                canvas.restore();
                canvas.drawRoundRect(new RectF(w*0.36f,h*0.14f,w*0.80f,h*0.78f),8f,8f,paint);
            } else {
                canvas.drawRoundRect(new RectF(w*0.20f,h*0.22f,w*0.80f,h*0.84f),8f,8f,paint);
                paint.setColor(active ? 0xff6C1561 : 0xff21106B);
                canvas.drawCircle(cx,h*0.54f,w*0.12f,paint);
            }
        }
    }
}
