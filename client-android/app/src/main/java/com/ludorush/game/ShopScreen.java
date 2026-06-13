package com.ludorush.game;

import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RadialGradient;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public final class ShopScreen extends BaseScreen {

    private static final String PREF_SKIN = "equipped_skin";

    // {id, displayName, priceLabel, description, cost}
    private static final String[][] SKINS = {
        {"classic", "Classic",  "Free",      "The original Ludo piece look",      "0"},
        {"crystal", "Crystal",  "500 Coins", "Pieces shimmer with icy blue-white", "500"},
        {"flame",   "Flame",    "750 Coins", "Pieces glow with red-orange fire",   "750"},
    };

    private final SharedPreferences prefs;

    public ShopScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
        prefs = activity.getSharedPreferences("ludo_settings", 0);
    }

    @Override
    public View createView() {
        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);

        // Balance hero card
        LinearLayout balCard = new LinearLayout(activity);
        balCard.setOrientation(LinearLayout.VERTICAL);
        balCard.setGravity(Gravity.CENTER);
        balCard.setPadding(dp(20), dp(20), dp(20), dp(20));
        balCard.setBackground(cardGradient(theme.bgGradStart(), theme.bgGradEnd(), dp(20)));
        content.addView(balCard, lp(-1, -2, 0, 0, 0, dp(20)));

        TextView balLabel = text("YOUR COINS", 11, theme.txtMuted(), Typeface.BOLD);
        balLabel.setGravity(Gravity.CENTER);
        balLabel.setLetterSpacing(0.12f);
        balCard.addView(balLabel);

        final TextView coinsVal = text("🪙 " + callback.getCoins(), 36, ThemeManager.YELLOW, Typeface.BOLD);
        coinsVal.setGravity(Gravity.CENTER);
        balCard.addView(coinsVal, lp(-1, -2, 0, dp(4), 0, dp(2)));

        // Piece Skins section
        addSectionLabel(content, "PIECE SKINS");

        String equipped = prefs.getString(PREF_SKIN, "classic");

        for (String[] skin : SKINS) {
            String id    = skin[0];
            String name  = skin[1];
            String price = skin[2];
            String desc  = skin[3];
            int cost     = Integer.parseInt(skin[4]);
            boolean isEquipped  = id.equals(equipped);
            boolean purchased   = prefs.getBoolean("skin_owned_" + id, cost == 0);

            content.addView(buildSkinCard(id, name, price, desc, cost, isEquipped, purchased, coinsVal),
                lp(-1, -2, 0, 0, 0, dp(10)));
        }

        // Earn more coins
        addSectionLabel(content, "EARN MORE COINS");

        LinearLayout watchCard = buildEarnCard("Watch an Ad", "Earn 50 coins per video", ThemeManager.GREEN);
        Button watchBtn = actionButton("+50", ThemeManager.GREEN, 0xff4CAF50);
        watchBtn.setTextSize(14);
        watchBtn.setOnClickListener(v -> {
            if (AdManager.get().isRewardedReady()) {
                AdManager.get().showRewarded(new AdManager.RewardCallback() {
                    @Override public void onRewarded(int c) {
                        callback.addCoins(50);
                        coinsVal.setText("🪙 " + callback.getCoins());
                        Toast.makeText(activity, "You earned 50 coins!", Toast.LENGTH_SHORT).show();
                    }
                    @Override public void onUnavailable() {
                        Toast.makeText(activity, "No ad available right now.", Toast.LENGTH_SHORT).show();
                    }
                });
            } else {
                Toast.makeText(activity, "Loading ad, try again shortly.", Toast.LENGTH_SHORT).show();
            }
        });
        watchCard.addView(watchBtn, lp(dp(80), dp(44)));
        content.addView(watchCard, lp(-1, -2, 0, 0, 0, dp(10)));

        LinearLayout dailyCard = buildEarnCard("Daily Bonus", "Free coins every day", ThemeManager.AMBER);
        Button claimBtn = actionButton("Claim", ThemeManager.AMBER, 0xffFFB14A);
        claimBtn.setTextSize(14);
        claimBtn.setOnClickListener(v ->
            Toast.makeText(activity, "Daily bonus coming soon!", Toast.LENGTH_SHORT).show());
        dailyCard.addView(claimBtn, lp(dp(80), dp(44)));
        content.addView(dailyCard, lp(-1, -2));

        return createScreenShell("Shop", content, true);
    }

    private LinearLayout buildSkinCard(String id, String name, String price, String desc,
                                        int cost, boolean isEquipped, boolean purchased,
                                        TextView coinsVal) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(14), dp(14), dp(12), dp(14));
        card.setBackground(card(theme.bgCard(), dp(16),
            isEquipped ? ThemeManager.GOLD : theme.strokeCard()));

        // Skin preview
        SkinPreviewView preview = new SkinPreviewView(activity, id);
        card.addView(preview, lp(dp(52), dp(52), 0, 0, dp(14), 0));

        // Info column
        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        card.addView(info, new LinearLayout.LayoutParams(0, -2, 1));

        LinearLayout nameRow = new LinearLayout(activity);
        nameRow.setOrientation(LinearLayout.HORIZONTAL);
        nameRow.setGravity(Gravity.CENTER_VERTICAL);
        info.addView(nameRow);
        nameRow.addView(text(name, 16, theme.txtPrimary(), Typeface.BOLD));
        if (isEquipped) {
            TextView equippedBadge = badge("EQUIPPED", ThemeManager.GOLD, 0xff1A0800);
            LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(-2, -2);
            blp.setMargins(dp(8), 0, 0, 0);
            nameRow.addView(equippedBadge, blp);
        }

        info.addView(text(desc, 12, theme.txtMuted(), Typeface.NORMAL),
            lp(-1, -2, 0, dp(3), 0, dp(2)));
        int priceColor = cost == 0 ? ThemeManager.GREEN : ThemeManager.YELLOW;
        String priceLabel = purchased ? (cost == 0 ? "Free" : "Owned") : price;
        info.addView(text(priceLabel, 12, priceColor, Typeface.BOLD));

        // Action button
        Button btn = new Button(activity);
        btn.setAllCaps(false);
        btn.setTextSize(13);
        btn.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
        btn.setIncludeFontPadding(false);

        if (isEquipped) {
            btn.setText("On");
            btn.setTextColor(ThemeManager.GOLD);
            btn.setBackground(card(theme.bgMetric(), dp(14), ThemeManager.GOLD));
        } else if (purchased) {
            btn.setText("Equip");
            btn.setTextColor(Color.WHITE);
            btn.setBackground(buttonGradient(ThemeManager.TEAL, 0xff1A8A80, dp(14)));
            btn.setOnClickListener(v -> {
                prefs.edit().putString(PREF_SKIN, id).apply();
                Toast.makeText(activity, name + " equipped!", Toast.LENGTH_SHORT).show();
                callback.navigateTo("shop");
            });
        } else {
            btn.setText(String.valueOf(cost));
            btn.setTextColor(0xff1A0800);
            btn.setBackground(buttonGradient(ThemeManager.GOLD, ThemeManager.AMBER, dp(14)));
            btn.setOnClickListener(v -> {
                if (callback.getCoins() >= cost) {
                    callback.addCoins(-cost);
                    prefs.edit().putBoolean("skin_owned_" + id, true)
                                .putString(PREF_SKIN, id).apply();
                    coinsVal.setText("🪙 " + callback.getCoins());
                    Toast.makeText(activity, name + " unlocked & equipped!", Toast.LENGTH_SHORT).show();
                    callback.navigateTo("shop");
                } else {
                    Toast.makeText(activity, "Need " + cost + " coins!", Toast.LENGTH_SHORT).show();
                }
            });
        }
        card.addView(btn, lp(dp(72), dp(40)));
        return card;
    }

    private LinearLayout buildEarnCard(String title, String desc, int accent) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(16), dp(16), dp(12), dp(16));
        card.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));
        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        card.addView(info, new LinearLayout.LayoutParams(0, -2, 1));
        info.addView(text(title, 15, accent, Typeface.BOLD));
        info.addView(text(desc, 12, theme.txtMuted(), Typeface.NORMAL),
            lp(-1, -2, 0, dp(2), 0, 0));
        return card;
    }

    // Skin preview canvas showing 4 mini pieces in skin style
    static final class SkinPreviewView extends android.view.View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final String skinId;
        private static final int[] QUAD = {
            ThemeManager.RED, ThemeManager.BLUE, ThemeManager.YELLOW, ThemeManager.GREEN};

        SkinPreviewView(android.app.Activity ctx, String id) {
            super(ctx);
            this.skinId = id;
        }

        @Override protected void onDraw(android.graphics.Canvas canvas) {
            float cx = getWidth() / 2f, cy = getHeight() / 2f;
            float r = Math.min(cx, cy) * 0.82f;
            float[] offX = {-0.45f, 0.45f, -0.45f, 0.45f};
            float[] offY = {-0.45f, -0.45f, 0.45f, 0.45f};
            for (int i = 0; i < 4; i++) {
                float px = cx + offX[i] * r, py = cy + offY[i] * r, pr = r * 0.38f;
                paint.setColor(0x44000000);
                canvas.drawCircle(px + pr*0.1f, py + pr*0.15f, pr, paint);
                switch (skinId) {
                    case "crystal":
                        paint.setShader(new RadialGradient(px-pr*0.3f, py-pr*0.3f, pr*1.1f,
                            new int[]{0xffFFFFFF,0xff87CEEB,0xff1E90FF,0xff00008B},
                            new float[]{0f,0.2f,0.6f,1f}, Shader.TileMode.CLAMP));
                        break;
                    case "flame":
                        paint.setShader(new RadialGradient(px-pr*0.3f, py-pr*0.3f, pr*1.1f,
                            new int[]{0xffFFFFFF,0xffFFE066,0xffFF6600,0xff8B0000},
                            new float[]{0f,0.2f,0.6f,1f}, Shader.TileMode.CLAMP));
                        break;
                    default:
                        int col = QUAD[i];
                        paint.setShader(new RadialGradient(px-pr*0.3f, py-pr*0.3f, pr*1.1f,
                            new int[]{0xffFFFFFF, blend(col,0xffFFFFFF,0.4f), col, blend(col,0xff000000,0.3f)},
                            new float[]{0f,0.2f,0.6f,1f}, Shader.TileMode.CLAMP));
                        break;
                }
                canvas.drawCircle(px, py, pr, paint);
                paint.setShader(null);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(pr * 0.18f);
                paint.setColor(ThemeManager.GOLD);
                canvas.drawCircle(px, py, pr, paint);
                paint.setStyle(Paint.Style.FILL);
                paint.setColor(0xccFFFFFF);
                canvas.drawCircle(px - pr*0.3f, py - pr*0.32f, pr*0.18f, paint);
            }
        }

        private int blend(int a, int b, float t) {
            float ia = 1f - t;
            return (((int)(((a>>>24)&0xff)*ia+((b>>>24)&0xff)*t))<<24)
                 | (((int)(((a>>16)&0xff)*ia+((b>>16)&0xff)*t))<<16)
                 | (((int)(((a>>8 )&0xff)*ia+((b>>8 )&0xff)*t))<< 8)
                 |  ((int)(( a     &0xff)*ia+( b     &0xff)*t));
        }
    }
}
