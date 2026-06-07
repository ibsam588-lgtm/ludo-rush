package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class ShopScreen extends BaseScreen {

    public ShopScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);

        LinearLayout balanceCard = new LinearLayout(activity);
        balanceCard.setOrientation(LinearLayout.VERTICAL);
        balanceCard.setGravity(Gravity.CENTER);
        balanceCard.setPadding(dp(20), dp(20), dp(20), dp(20));
        balanceCard.setBackground(cardGradient(0xff192133, 0xff101827, dp(20)));
        content.addView(balanceCard, lp(-1, -2, 0, 0, 0, dp(20)));

        balanceCard.addView(text("YOUR BALANCE", 12, 0xff6B7A90, Typeface.BOLD));
        TextView coins = text(String.valueOf(callback.getCoins()), 36, 0xffF9A825, Typeface.BOLD);
        coins.setGravity(Gravity.CENTER);
        balanceCard.addView(coins, lp(-1, -2, 0, dp(4), 0, dp(2)));
        balanceCard.addView(text("Coins", 14, 0xff94A3B8, Typeface.NORMAL));

        addSectionLabel(content, "COIN PACKS");
        addPack(content, "Starter Pack", "500 Coins", "$0.99", 0xff43A047);
        addPack(content, "Popular Pack", "2,000 Coins", "$3.99", 0xff1E88E5);
        addPack(content, "Value Pack", "5,500 Coins", "$7.99", 0xffF9A825);
        addPack(content, "Mega Pack", "15,000 Coins", "$19.99", 0xffE8293E);

        addSectionLabel(content, "FREE COINS");

        LinearLayout freeCard = new LinearLayout(activity);
        freeCard.setOrientation(LinearLayout.HORIZONTAL);
        freeCard.setGravity(Gravity.CENTER_VERTICAL);
        freeCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        freeCard.setBackground(card(0xff111A2A, dp(16), 0x335D6D86));
        content.addView(freeCard, lp(-1, -2, 0, 0, 0, dp(10)));

        LinearLayout freeInfo = new LinearLayout(activity);
        freeInfo.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams fip = new LinearLayout.LayoutParams(0, -2, 1);
        freeCard.addView(freeInfo, fip);
        freeInfo.addView(text("Watch an Ad", 15, Color.WHITE, Typeface.BOLD));
        freeInfo.addView(text("Earn 50 coins per video", 12, 0xff6B7A90, Typeface.NORMAL));

        Button watchBtn = actionButton("+50", 0xff43A047, 0xff66BB6A);
        watchBtn.setTextSize(14);
        freeCard.addView(watchBtn, lp(dp(80), dp(42)));

        LinearLayout dailyCard = new LinearLayout(activity);
        dailyCard.setOrientation(LinearLayout.HORIZONTAL);
        dailyCard.setGravity(Gravity.CENTER_VERTICAL);
        dailyCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        dailyCard.setBackground(card(0xff111A2A, dp(16), 0x335D6D86));
        content.addView(dailyCard, lp(-1, -2));

        LinearLayout dailyInfo = new LinearLayout(activity);
        dailyInfo.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams dip = new LinearLayout.LayoutParams(0, -2, 1);
        dailyCard.addView(dailyInfo, dip);
        dailyInfo.addView(text("Daily Bonus", 15, Color.WHITE, Typeface.BOLD));
        dailyInfo.addView(text("Come back daily for coins", 12, 0xff6B7A90, Typeface.NORMAL));

        Button claimBtn = actionButton("Claim", 0xffF9A825, 0xffFFB14A);
        claimBtn.setTextSize(14);
        dailyCard.addView(claimBtn, lp(dp(80), dp(42)));

        return createScreenShell("Shop", content);
    }

    private void addPack(LinearLayout parent, String name, String amount, String price, int accent) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(16), dp(14), dp(12), dp(14));
        card.setBackground(card(0xff111A2A, dp(16), 0x335D6D86));
        parent.addView(card, lp(-1, -2, 0, 0, 0, dp(10)));

        View dot = new View(activity);
        dot.setBackground(card(accent, dp(6), accent));
        card.addView(dot, lp(dp(12), dp(12), 0, 0, dp(12), 0));

        LinearLayout info = new LinearLayout(activity);
        info.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams infop = new LinearLayout.LayoutParams(0, -2, 1);
        card.addView(info, infop);

        info.addView(text(name, 15, Color.WHITE, Typeface.BOLD));
        info.addView(text(amount, 12, 0xffF9A825, Typeface.NORMAL));

        Button buy = actionButton(price, accent, accent);
        buy.setTextSize(13);
        card.addView(buy, lp(dp(90), dp(40)));
    }
}
