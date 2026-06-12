package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public final class ShopScreen extends BaseScreen {

    public ShopScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);

        // ── Balance hero card ─────────────────────────────────────────────────
        LinearLayout balanceCard = new LinearLayout(activity);
        balanceCard.setOrientation(LinearLayout.VERTICAL);
        balanceCard.setGravity(Gravity.CENTER);
        balanceCard.setPadding(dp(20), dp(22), dp(20), dp(22));
        balanceCard.setBackground(cardGradient(theme.bgGradStart(), theme.bgGradEnd(), dp(20)));
        content.addView(balanceCard, lp(-1, -2, 0, 0, 0, dp(20)));

        TextView balLabel = text("YOUR BALANCE", 11, theme.txtMuted(), Typeface.BOLD);
        balLabel.setGravity(Gravity.CENTER);
        balLabel.setLetterSpacing(0.12f);
        balanceCard.addView(balLabel);

        final TextView coinsVal = text(String.valueOf(callback.getCoins()), 40, ThemeManager.YELLOW, Typeface.BOLD);
        coinsVal.setGravity(Gravity.CENTER);
        balanceCard.addView(coinsVal, lp(-1, -2, 0, dp(4), 0, dp(2)));

        balanceCard.addView(text("◈ Coins", 14, theme.txtSecondary(), Typeface.NORMAL));

        // ── Coin packs ────────────────────────────────────────────────────────
        addSectionLabel(content, "COIN PACKS");
        addPack(content, "Starter Pack",  "500 Coins",    "$0.99",  ThemeManager.GREEN);
        addPack(content, "Popular Pack",  "2,000 Coins",  "$3.99",  ThemeManager.BLUE);
        addPack(content, "Value Pack",    "5,500 Coins",  "$7.99",  ThemeManager.YELLOW);
        addPack(content, "Mega Pack",     "15,000 Coins", "$19.99", ThemeManager.RED);

        // ── Free coins ────────────────────────────────────────────────────────
        addSectionLabel(content, "FREE COINS");

        // Rewarded video ad
        LinearLayout watchCard = buildFreeCard(
            "📺  Watch an Ad",
            "Earn 50 coins per rewarded video",
            ThemeManager.GREEN);
        Button watchBtn = actionButton("+50", ThemeManager.GREEN, ThemeManager.GREEN_LIGHT);
        watchBtn.setTextSize(14);
        watchBtn.setOnClickListener(v -> {
            if (AdManager.get().isRewardedReady()) {
                AdManager.get().showRewarded(new AdManager.RewardCallback() {
                    @Override public void onRewarded(int coins) {
                        callback.addCoins(50);
                        coinsVal.setText(String.valueOf(callback.getCoins()));
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

        // Daily bonus
        LinearLayout dailyCard = buildFreeCard(
            "🎁  Daily Bonus",
            "Come back every day for free coins",
            ThemeManager.YELLOW);
        Button claimBtn = actionButton("Claim", ThemeManager.YELLOW, 0xffFFB14A);
        claimBtn.setTextSize(14);
        claimBtn.setOnClickListener(v ->
            Toast.makeText(activity, "Daily bonus — coming soon", Toast.LENGTH_SHORT).show());
        dailyCard.addView(claimBtn, lp(dp(80), dp(44)));
        content.addView(dailyCard, lp(-1, -2));

        return createScreenShell("Shop", content, true);
    }

    private LinearLayout buildFreeCard(String title, String desc, int accent) {
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

    private void addPack(LinearLayout parent, String name, String amount, String price, int accent) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(16), dp(14), dp(12), dp(14));
        card.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));
        parent.addView(card, lp(-1, -2, 0, 0, 0, dp(10)));

        View dot = new View(activity);
        dot.setBackground(circle(accent));
        card.addView(dot, lp(dp(12), dp(12), 0, 0, dp(12), 0));

        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        card.addView(info, new LinearLayout.LayoutParams(0, -2, 1));
        info.addView(text(name, 15, theme.txtPrimary(), Typeface.BOLD));
        info.addView(text(amount, 12, ThemeManager.YELLOW, Typeface.NORMAL),
                lp(-1, -2, 0, dp(2), 0, 0));

        Button buy = actionButton(price, accent, accent);
        buy.setTextSize(13);
        buy.setOnClickListener(v ->
            Toast.makeText(activity, "In-app purchases — coming soon", Toast.LENGTH_SHORT).show());
        card.addView(buy, lp(dp(90), dp(42)));
    }
}
