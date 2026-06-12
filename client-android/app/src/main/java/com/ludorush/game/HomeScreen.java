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
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class HomeScreen extends BaseScreen {
    private static final Typeface DISPLAY = Typeface.create("sans-serif-medium", Typeface.BOLD);
    private static final Typeface HEAVY = Typeface.create("sans-serif-black", Typeface.BOLD);

    public HomeScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        FrameLayout shell = new FrameLayout(activity);
        shell.setBackgroundColor(theme.bgPage());
        shell.addView(new LobbyBackdropView(activity, theme.isDark()), new FrameLayout.LayoutParams(-1, -1));

        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setClipChildren(false);

        root.addView(buildTopBar(), lp(-1, dp(66)));

        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(14), dp(8), dp(14), dp(8));
        body.setClipChildren(false);

        body.addView(buildHero(), lp(-1, dp(244), 0, 0, 0, dp(8)));
        body.addView(sectionLabel("CHOOSE MODE"), lp(-1, dp(26), dp(3), 0, dp(3), 0));
        body.addView(buildModeDeck(), lp(-1, dp(214), 0, 0, 0, dp(8)));
        body.addView(buildFeatureStrip(), lp(-1, dp(68)));

        LinearLayout.LayoutParams bodyLp = new LinearLayout.LayoutParams(-1, 0);
        bodyLp.weight = 1;
        root.addView(body, bodyLp);

        root.addView(buildBottomNav(), lp(-1, dp(76)));
        shell.addView(root, new FrameLayout.LayoutParams(-1, -1));
        return shell;
    }

    private View buildTopBar() {
        LinearLayout bar = new LinearLayout(activity);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setPadding(dp(10), dp(7), dp(10), dp(7));
        bar.setBackgroundColor(theme.isDark() ? 0xdd40104F : 0xeeFF4FA3);

        LinearLayout.LayoutParams starLp = new LinearLayout.LayoutParams(0, dp(42), 1);
        starLp.setMargins(0, 0, dp(5), 0);
        bar.addView(resourcePill("XP", "343/500", 0xffFFD426), starLp);

        LinearLayout.LayoutParams coinLp = new LinearLayout.LayoutParams(0, dp(42), 1);
        coinLp.setMargins(dp(5), 0, dp(5), 0);
        bar.addView(resourcePill("$", formatCoins(callback.getCoins()), 0xffFFB928), coinLp);

        LinearLayout.LayoutParams gemLp = new LinearLayout.LayoutParams(0, dp(42), 1);
        gemLp.setMargins(dp(5), 0, 0, 0);
        bar.addView(resourcePill("+", "34", 0xff5AF24D), gemLp);

        Button settings = new Button(activity);
        settings.setAllCaps(false);
        settings.setText("SET");
        settings.setTextSize(10);
        settings.setIncludeFontPadding(false);
        settings.setTypeface(DISPLAY);
        settings.setTextColor(Color.WHITE);
        settings.setBackground(card(theme.isDark() ? 0xff2A0A36 : 0xff6738E8, dp(16), ThemeManager.GOLD));
        settings.setOnClickListener(v -> callback.navigateTo("settings"));
        LinearLayout.LayoutParams setLp = new LinearLayout.LayoutParams(dp(54), dp(42));
        setLp.setMargins(dp(8), 0, 0, 0);
        bar.addView(settings, setLp);
        return bar;
    }

    private View resourcePill(String icon, String value, int accent) {
        LinearLayout pill = new LinearLayout(activity);
        pill.setOrientation(LinearLayout.HORIZONTAL);
        pill.setGravity(Gravity.CENTER);
        pill.setPadding(dp(8), 0, dp(8), 0);
        pill.setBackground(card(theme.isDark() ? 0xff2B0B38 : 0xEEFFFFFF,
                dp(16), theme.isDark() ? 0x66FFFFFF : 0xaa7C4DFF));

        TextView iconView = gameText(icon, 12, accent, DISPLAY);
        iconView.setGravity(Gravity.CENTER);
        pill.addView(iconView, lp(dp(26), -1));

        TextView valueView = gameText(value, 13, theme.isDark() ? Color.WHITE : theme.txtPrimary(), DISPLAY);
        valueView.setGravity(Gravity.CENTER_VERTICAL);
        valueView.setSingleLine(true);
        pill.addView(valueView, new LinearLayout.LayoutParams(0, -1, 1));
        return pill;
    }

    private View buildHero() {
        FrameLayout hero = new FrameLayout(activity);
        hero.setClipChildren(false);
        hero.addView(new HeroArtView(activity, theme.isDark()), new FrameLayout.LayoutParams(-1, -1));

        LinearLayout titleBlock = new LinearLayout(activity);
        titleBlock.setOrientation(LinearLayout.VERTICAL);
        titleBlock.setGravity(Gravity.CENTER);
        titleBlock.setPadding(0, dp(5), 0, 0);

        TextView title = gameText("LUDO RUSH", 36, ThemeManager.GOLD, HEAVY);
        title.setGravity(Gravity.CENTER);
        title.setShadowLayer(dp(3), 0, dp(2), 0xaa000000);
        titleBlock.addView(title, lp(-1, -2));

        TextView sub = gameText("GLOBAL MULTIPLAYER MODES", 13, theme.isDark() ? Color.WHITE : 0xffFFFFFF, DISPLAY);
        sub.setGravity(Gravity.CENTER);
        sub.setLetterSpacing(0.02f);
        sub.setShadowLayer(dp(2), 0, dp(1), 0x88000000);
        titleBlock.addView(sub, lp(-1, -2, 0, dp(2), 0, 0));

        FrameLayout.LayoutParams titleLp = new FrameLayout.LayoutParams(-1, dp(78), Gravity.TOP);
        hero.addView(titleBlock, titleLp);
        return hero;
    }

    private View sectionLabel(String label) {
        TextView section = gameText(label, 15, theme.isDark() ? ThemeManager.GOLD : 0xff451448, DISPLAY);
        section.setGravity(Gravity.CENTER_VERTICAL);
        section.setLetterSpacing(0.02f);
        section.setShadowLayer(dp(2), 0, dp(1), theme.isDark() ? 0x99000000 : 0x44FFFFFF);
        return section;
    }

    private View buildModeDeck() {
        ModeDeckLayout deck = new ModeDeckLayout(activity);
        deck.setClipChildren(false);
        deck.setClipToPadding(false);

        deck.addView(new ModeCard(activity, 0, "PVT", "PRIVATE\nTABLE", 0xff2098E8, false,
                () -> callback.navigateTo("lobby")));
        deck.addView(new ModeCard(activity, 4, "AI", "PLAY\nOFFLINE", 0xffF2F0F7, false,
                () -> callback.startBotMatch("classic_2p")));
        deck.addView(new ModeCard(activity, 1, "VS", "TEAM\nUP", 0xffF3322C, false,
                () -> callback.navigateTo("lobby")));
        deck.addView(new ModeCard(activity, 3, "4", "4 PLAYER", 0xff27B64B, false,
                () -> callback.startQuickMatch("classic_4p")));
        deck.addView(new ModeCard(activity, 2, "2", "1 ON 1", 0xffFFD12A, true,
                () -> callback.startQuickMatch("classic_2p")));
        return deck;
    }

    private View buildFeatureStrip() {
        LinearLayout strip = new LinearLayout(activity);
        strip.setOrientation(LinearLayout.HORIZONTAL);
        strip.setGravity(Gravity.CENTER);
        strip.setPadding(0, dp(4), 0, dp(4));

        strip.addView(featureChip("GLOBAL", "MATCHES", 0xff32D3C8), new LinearLayout.LayoutParams(0, -1, 1));
        LinearLayout.LayoutParams mid = new LinearLayout.LayoutParams(0, -1, 1);
        mid.setMargins(dp(8), 0, dp(8), 0);
        strip.addView(featureChip("PRIVATE", "ROOMS", ThemeManager.GOLD), mid);
        strip.addView(featureChip("VOICE", "READY", 0xffFF5BC8), new LinearLayout.LayoutParams(0, -1, 1));
        return strip;
    }

    private View featureChip(String top, String bottom, int accent) {
        LinearLayout chip = new LinearLayout(activity);
        chip.setOrientation(LinearLayout.VERTICAL);
        chip.setGravity(Gravity.CENTER);
        chip.setPadding(dp(6), dp(5), dp(6), dp(5));
        chip.setBackground(card(theme.isDark() ? 0xaa2B0B38 : 0xddFFFFFF,
                dp(14), theme.isDark() ? 0x66FFFFFF : 0xaa7C4DFF));

        TextView a = gameText(top, 12, accent, DISPLAY);
        a.setGravity(Gravity.CENTER);
        chip.addView(a, lp(-1, -2));

        TextView b = gameText(bottom, 10, theme.isDark() ? Color.WHITE : theme.txtPrimary(), DISPLAY);
        b.setGravity(Gravity.CENTER);
        b.setLetterSpacing(0.01f);
        chip.addView(b, lp(-1, -2, 0, dp(2), 0, 0));
        return chip;
    }

    private View buildBottomNav() {
        LinearLayout nav = new LinearLayout(activity);
        nav.setOrientation(LinearLayout.HORIZONTAL);
        nav.setPadding(dp(8), dp(7), dp(8), dp(7));
        nav.setBackgroundColor(theme.isDark() ? 0xee6B255F : 0xee6738E8);

        addNav(nav, "Shop", "shop", "$", false);
        addNav(nav, "Friends", "profile", "FR", false);
        addNav(nav, "Home", "home", "H", true);
        addNav(nav, "Collect", "history", "CL", false);
        addNav(nav, "Chest", "shop", "C", false);
        return nav;
    }

    private void addNav(LinearLayout nav, String label, String route, String icon, boolean active) {
        LinearLayout item = new LinearLayout(activity);
        item.setOrientation(LinearLayout.VERTICAL);
        item.setGravity(Gravity.CENTER);
        item.setPadding(0, dp(2), 0, dp(2));
        if (active) item.setBackground(card(0xffF9CA24, dp(16), 0xffFFF4A3));

        TextView iconView = gameText(icon, active ? 18 : 14,
                active ? 0xff6E1839 : Color.WHITE, DISPLAY);
        iconView.setGravity(Gravity.CENTER);
        item.addView(iconView, lp(-1, -2));

        TextView labelView = gameText(label, 10, active ? 0xff6E1839 : Color.WHITE, DISPLAY);
        labelView.setGravity(Gravity.CENTER);
        labelView.setSingleLine(true);
        item.addView(labelView, lp(-1, -2, 0, dp(2), 0, 0));

        item.setOnClickListener(v -> {
            if (!"home".equals(route)) callback.navigateTo(route);
        });
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, -1, 1);
        lp.setMargins(dp(3), 0, dp(3), 0);
        nav.addView(item, lp);
    }

    private TextView gameText(String t, int sp, int color, Typeface typeface) {
        TextView v = new TextView(activity);
        v.setText(t);
        v.setTextSize(sp);
        v.setTextColor(color);
        v.setTypeface(typeface);
        v.setIncludeFontPadding(false);
        return v;
    }

    private String formatCoins(int amount) {
        if (amount >= 1000) return (amount / 1000) + "K";
        return String.valueOf(amount);
    }

    private static final class ModeDeckLayout extends FrameLayout {
        private final RectF[] slots = new RectF[5];

        ModeDeckLayout(android.app.Activity activity) {
            super(activity);
            for (int i = 0; i < slots.length; i++) slots[i] = new RectF();
        }

        @Override
        protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
            int w = MeasureSpec.getSize(widthMeasureSpec);
            int h = MeasureSpec.getSize(heightMeasureSpec);
            setMeasuredDimension(w, h);
            computeSlots(w, h);

            for (int i = 0; i < getChildCount(); i++) {
                View child = getChildAt(i);
                int slot = child instanceof ModeCard ? ((ModeCard) child).slot : i;
                RectF r = slots[Math.max(0, Math.min(4, slot))];
                int childW = Math.max(1, Math.round(r.width()));
                int childH = Math.max(1, Math.round(r.height()));
                child.measure(MeasureSpec.makeMeasureSpec(childW, MeasureSpec.EXACTLY),
                        MeasureSpec.makeMeasureSpec(childH, MeasureSpec.EXACTLY));
            }
        }

        @Override
        protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
            computeSlots(right - left, bottom - top);
            for (int i = 0; i < getChildCount(); i++) {
                View child = getChildAt(i);
                int slot = child instanceof ModeCard ? ((ModeCard) child).slot : i;
                RectF r = slots[Math.max(0, Math.min(4, slot))];
                child.layout(Math.round(r.left), Math.round(r.top), Math.round(r.right), Math.round(r.bottom));
            }
        }

        private void computeSlots(int w, int h) {
            float mainW = w * 0.31f;
            float mainH = h * 0.94f;
            float sideW = w * 0.20f;
            float sideH = h * 0.73f;
            float[] centers = {w * 0.18f, w * 0.32f, w * 0.50f, w * 0.68f, w * 0.82f};
            float[] top = {h * 0.22f, h * 0.13f, h * 0.03f, h * 0.13f, h * 0.22f};
            for (int i = 0; i < slots.length; i++) {
                boolean main = i == 2;
                float cw = main ? mainW : sideW;
                float ch = main ? mainH : sideH;
                slots[i].set(centers[i] - cw / 2f, top[i], centers[i] + cw / 2f, top[i] + ch);
            }
        }
    }

    private static final class ModeCard extends LinearLayout {
        final int slot;

        ModeCard(android.app.Activity activity, int slot, String symbol, String label, int color,
                 boolean featured, Runnable onClick) {
            super(activity);
            this.slot = slot;
            setOrientation(VERTICAL);
            setGravity(Gravity.CENTER);
            int pad = Math.round(8 * activity.getResources().getDisplayMetrics().density);
            setPadding(pad, pad, pad, pad);
            setClickable(true);
            setOnClickListener(v -> onClick.run());
            setElevation(featured ? 11f : 5f);

            GradientDrawable bg = new GradientDrawable(
                    GradientDrawable.Orientation.TOP_BOTTOM,
                    new int[]{brighten(color, 1.08f), darken(color, 0.72f)});
            bg.setCornerRadius(pad * (featured ? 2.4f : 1.9f));
            bg.setStroke(Math.max(2, pad / 3), featured ? 0xffFFF4A3 : 0xccFFD426);
            setBackground(bg);

            MiniModeArtView art = new MiniModeArtView(activity, color);
            addView(art, new LinearLayout.LayoutParams(-1, 0, featured ? 1.03f : 0.95f));

            TextView mark = new TextView(activity);
            mark.setGravity(Gravity.CENTER);
            mark.setText(symbol);
            mark.setTextColor(featured || color == 0xffF2F0F7 ? 0xff9D115B : Color.WHITE);
            mark.setTextSize(featured ? 50 : 24);
            mark.setTypeface(HEAVY);
            mark.setIncludeFontPadding(false);
            mark.setShadowLayer(2.5f, 0, 2f, 0x99000000);
            addView(mark, new LinearLayout.LayoutParams(-1, -2));

            TextView name = new TextView(activity);
            name.setGravity(Gravity.CENTER);
            name.setText(label);
            name.setTextColor(featured || color == 0xffF2F0F7 ? 0xff35122B : Color.WHITE);
            name.setTextSize(featured ? 15 : 11);
            name.setTypeface(DISPLAY);
            name.setIncludeFontPadding(false);
            name.setLineSpacing(0, 0.92f);
            name.setShadowLayer(featured ? 0 : 2f, 0, 1f, 0x99000000);
            addView(name, new LinearLayout.LayoutParams(-1, -2));
        }

        private static int brighten(int color, float factor) {
            return Color.rgb(
                    Math.min(255, (int) (Color.red(color) * factor)),
                    Math.min(255, (int) (Color.green(color) * factor)),
                    Math.min(255, (int) (Color.blue(color) * factor)));
        }

        private static int darken(int color, float factor) {
            return Color.rgb(
                    Math.max(0, (int) (Color.red(color) * factor)),
                    Math.max(0, (int) (Color.green(color) * factor)),
                    Math.max(0, (int) (Color.blue(color) * factor)));
        }
    }

    private static final class LobbyBackdropView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path path = new Path();
        private final boolean dark;

        LobbyBackdropView(android.app.Activity activity, boolean dark) {
            super(activity);
            this.dark = dark;
        }

        @Override
        protected void onDraw(Canvas canvas) {
            float w = getWidth();
            float h = getHeight();
            int[] bg = dark
                    ? new int[]{0xff28063E, 0xff9A24D4, 0xff32104B, 0xff13001C}
                    : new int[]{0xffFF4FA3, 0xffFFD95A, 0xff40D8FF, 0xff8D4CFF};
            paint.setShader(new LinearGradient(0, 0, w, h, bg, null, Shader.TileMode.CLAMP));
            canvas.drawRect(0, 0, w, h, paint);
            paint.setShader(null);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(dark ? 0x16FFFFFF : 0x22FFFFFF);
            canvas.drawCircle(w * 0.48f, h * 0.23f, w * 0.30f, paint);
            canvas.drawCircle(w * 0.98f, h * 0.58f, w * 0.22f, paint);

            int[] confetti = dark
                    ? new int[]{0xffFFD100, 0xff55FF4D, 0xff32D3C8, 0xffFF5BC8, 0xffFFFFFF}
                    : new int[]{0xff7C4DFF, 0xffFF2F7E, 0xff18BFF5, 0xff20D86B, 0xffFFD426};
            for (int i = 0; i < 56; i++) {
                float x = ((i * 97 + 41) % 1000) / 1000f * w;
                float y = ((i * 61 + 87) % 1000) / 1000f * h;
                paint.setColor(confetti[i % confetti.length]);
                canvas.save();
                canvas.rotate((i * 31) % 180, x, y);
                canvas.drawRoundRect(new RectF(x, y, x + w * 0.018f, y + h * 0.0045f), 4f, 4f, paint);
                canvas.restore();
            }

            drawCoin(canvas, w * 0.12f, h * 0.17f, w * 0.036f);
            drawCoin(canvas, w * 0.88f, h * 0.25f, w * 0.032f);
            drawGem(canvas, w * 0.08f, h * 0.43f, w * 0.045f, 0xff56FF32);
            drawGem(canvas, w * 0.93f, h * 0.58f, w * 0.040f, 0xff00E5FF);
        }

        private void drawCoin(Canvas canvas, float cx, float cy, float r) {
            paint.setColor(0x55000000);
            canvas.drawCircle(cx + r * 0.18f, cy + r * 0.20f, r, paint);
            paint.setColor(0xffFFD426);
            canvas.drawCircle(cx, cy, r, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(r * 0.16f);
            paint.setColor(0xffFF9A00);
            canvas.drawCircle(cx, cy, r * 0.70f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawGem(Canvas canvas, float cx, float cy, float r, int color) {
            path.reset();
            path.moveTo(cx, cy - r);
            path.lineTo(cx + r, cy);
            path.lineTo(cx, cy + r);
            path.lineTo(cx - r, cy);
            path.close();
            paint.setColor(color);
            canvas.drawPath(path, paint);
            paint.setColor(0x77FFFFFF);
            canvas.drawCircle(cx - r * 0.22f, cy - r * 0.24f, r * 0.22f, paint);
        }
    }

    private static final class HeroArtView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final boolean dark;

        HeroArtView(android.app.Activity activity, boolean dark) {
            super(activity);
            this.dark = dark;
        }

        @Override
        protected void onDraw(Canvas canvas) {
            float w = getWidth();
            float h = getHeight();
            drawPhone(canvas, w, h);
            drawMascot(canvas, w * 0.50f, h * 0.46f, Math.min(w, h) * 0.17f);
            drawDice(canvas, w * 0.73f, h * 0.35f, w * 0.075f, 5, 0xffFFD426);
            drawDice(canvas, w * 0.30f, h * 0.56f, w * 0.060f, 3, 0xffF3322C);
        }

        private void drawPhone(Canvas canvas, float w, float h) {
            float pw = w * 0.40f;
            float ph = h * 0.66f;
            float x = (w - pw) / 2f;
            float y = h * 0.27f;
            RectF phone = new RectF(x, y, x + pw, y + ph);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(dark ? 0xaa000000 : 0x44000000);
            canvas.drawRoundRect(new RectF(phone.left + 8, phone.top + 10, phone.right + 8, phone.bottom + 10),
                    pw * 0.10f, pw * 0.10f, paint);
            paint.setColor(dark ? 0xff101018 : 0xff31204A);
            canvas.drawRoundRect(phone, pw * 0.11f, pw * 0.11f, paint);
            paint.setColor(dark ? 0xff7A255F : 0xffFF6FB8);
            RectF screen = new RectF(phone.left + pw * 0.07f, phone.top + pw * 0.10f,
                    phone.right - pw * 0.07f, phone.bottom - pw * 0.07f);
            canvas.drawRoundRect(screen, pw * 0.06f, pw * 0.06f, paint);
            drawTinyBoard(canvas, phone.centerX(), phone.top + ph * 0.55f, pw * 0.32f);
        }

        private void drawMascot(Canvas canvas, float cx, float cy, float r) {
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0x25FFFFFF);
            canvas.drawCircle(cx, cy, r * 1.85f, paint);
            paint.setColor(0xffff355F);
            canvas.drawRoundRect(new RectF(cx - r, cy - r * 0.55f, cx + r, cy + r * 0.72f),
                    r * 0.34f, r * 0.34f, paint);
            paint.setColor(0xffff8226);
            canvas.drawCircle(cx - r * 0.85f, cy - r * 0.05f, r * 0.26f, paint);
            paint.setColor(Color.WHITE);
            canvas.drawCircle(cx - r * 0.34f, cy - r * 0.06f, r * 0.21f, paint);
            canvas.drawCircle(cx + r * 0.34f, cy - r * 0.06f, r * 0.21f, paint);
            paint.setColor(0xff35122B);
            canvas.drawCircle(cx - r * 0.30f, cy - r * 0.04f, r * 0.09f, paint);
            canvas.drawCircle(cx + r * 0.30f, cy - r * 0.04f, r * 0.09f, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(r * 0.08f);
            paint.setColor(Color.WHITE);
            canvas.drawArc(new RectF(cx - r * 0.42f, cy + r * 0.05f, cx + r * 0.42f, cy + r * 0.52f),
                    15, 150, false, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawTinyBoard(Canvas canvas, float cx, float cy, float s) {
            RectF board = new RectF(cx - s, cy - s, cx + s, cy + s);
            paint.setColor(0xffFFF6D0);
            canvas.drawRoundRect(board, s * 0.08f, s * 0.08f, paint);
            paint.setColor(ThemeManager.RED);
            canvas.drawRect(board.left, board.top, cx, cy, paint);
            paint.setColor(ThemeManager.YELLOW);
            canvas.drawRect(cx, board.top, board.right, cy, paint);
            paint.setColor(ThemeManager.BLUE);
            canvas.drawRect(board.left, cy, cx, board.bottom, paint);
            paint.setColor(ThemeManager.GREEN);
            canvas.drawRect(cx, cy, board.right, board.bottom, paint);
            paint.setColor(0xffFFF6D0);
            canvas.drawRect(cx - s * 0.18f, board.top, cx + s * 0.18f, board.bottom, paint);
            canvas.drawRect(board.left, cy - s * 0.18f, board.right, cy + s * 0.18f, paint);
        }

        private void drawDice(Canvas canvas, float cx, float cy, float s, int value, int fill) {
            RectF r = new RectF(cx - s / 2f, cy - s / 2f, cx + s / 2f, cy + s / 2f);
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0x55000000);
            canvas.drawRoundRect(new RectF(r.left + 4f, r.top + 5f, r.right + 4f, r.bottom + 5f),
                    s * 0.16f, s * 0.16f, paint);
            paint.setColor(fill);
            canvas.drawRoundRect(r, s * 0.16f, s * 0.16f, paint);
            paint.setColor(fill == 0xffFFD426 ? 0xff35122B : Color.WHITE);
            float dot = s * 0.055f;
            float left = r.left + s * 0.30f, midX = r.centerX(), right = r.right - s * 0.30f;
            float top = r.top + s * 0.30f, midY = r.centerY(), bottom = r.bottom - s * 0.30f;
            if (value == 1 || value == 3 || value == 5) canvas.drawCircle(midX, midY, dot, paint);
            if (value >= 2) {
                canvas.drawCircle(left, top, dot, paint);
                canvas.drawCircle(right, bottom, dot, paint);
            }
            if (value >= 4) {
                canvas.drawCircle(right, top, dot, paint);
                canvas.drawCircle(left, bottom, dot, paint);
            }
            if (value == 6) {
                canvas.drawCircle(left, midY, dot, paint);
                canvas.drawCircle(right, midY, dot, paint);
            }
        }
    }

    private static final class MiniModeArtView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final int color;

        MiniModeArtView(android.app.Activity activity, int color) {
            super(activity);
            this.color = color;
        }

        @Override
        protected void onDraw(Canvas canvas) {
            float w = getWidth();
            float h = getHeight();
            float s = Math.min(w, h) * 0.50f;
            float cx = w / 2f;
            float cy = h * 0.44f;

            RectF board = new RectF(cx - s * 0.72f, cy - s * 0.72f, cx + s * 0.72f, cy + s * 0.72f);
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0xeeFFF6D0);
            canvas.drawRoundRect(board, s * 0.09f, s * 0.09f, paint);
            paint.setColor(ThemeManager.RED);
            canvas.drawRect(board.left, board.top, cx, cy, paint);
            paint.setColor(ThemeManager.YELLOW);
            canvas.drawRect(cx, board.top, board.right, cy, paint);
            paint.setColor(ThemeManager.BLUE);
            canvas.drawRect(board.left, cy, cx, board.bottom, paint);
            paint.setColor(ThemeManager.GREEN);
            canvas.drawRect(cx, cy, board.right, board.bottom, paint);
            paint.setColor(0xeeFFF6D0);
            canvas.drawRect(cx - s * 0.14f, board.top, cx + s * 0.14f, board.bottom, paint);
            canvas.drawRect(board.left, cy - s * 0.14f, board.right, cy + s * 0.14f, paint);

            drawDice(canvas, cx - s * 0.50f, h * 0.78f, s * 0.35f, 3, 0xffE92E2E);
            drawDice(canvas, cx + s * 0.26f, h * 0.76f, s * 0.32f, 6, 0xffFFD426);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, s * 0.035f));
            paint.setColor(color == 0xffF2F0F7 ? 0xaa35122B : 0xbbFFFFFF);
            canvas.drawRoundRect(board, s * 0.09f, s * 0.09f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawDice(Canvas canvas, float cx, float cy, float s, int value, int fill) {
            RectF r = new RectF(cx - s / 2f, cy - s / 2f, cx + s / 2f, cy + s / 2f);
            paint.setColor(0x44000000);
            canvas.drawRoundRect(new RectF(r.left + 3f, r.top + 3f, r.right + 3f, r.bottom + 3f),
                    s * 0.16f, s * 0.16f, paint);
            paint.setColor(fill);
            canvas.drawRoundRect(r, s * 0.16f, s * 0.16f, paint);
            paint.setColor(fill == 0xffFFD426 ? 0xff35122B : Color.WHITE);
            float dot = s * 0.06f;
            float left = r.left + s * 0.30f, midX = r.centerX(), right = r.right - s * 0.30f;
            float top = r.top + s * 0.30f, midY = r.centerY(), bottom = r.bottom - s * 0.30f;
            if (value == 1 || value == 3 || value == 5) canvas.drawCircle(midX, midY, dot, paint);
            if (value >= 2) {
                canvas.drawCircle(left, top, dot, paint);
                canvas.drawCircle(right, bottom, dot, paint);
            }
            if (value >= 4) {
                canvas.drawCircle(right, top, dot, paint);
                canvas.drawCircle(left, bottom, dot, paint);
            }
            if (value == 6) {
                canvas.drawCircle(left, midY, dot, paint);
                canvas.drawCircle(right, midY, dot, paint);
            }
        }
    }
}
