package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class LeaderboardScreen extends BaseScreen {

    private static final String[][] SAMPLE_PLAYERS = {
            {"LudoKing99", "1580"}, {"BoardMaster", "1520"}, {"DiceRoller", "1490"},
            {"RushChamp", "1450"}, {"TokenPro", "1410"}, {"StarPlayer", "1380"},
            {"FastMover", "1350"}, {"GreenMachine", "1320"}, {"RedBaron", "1290"},
            {"BlueStar", "1260"}
    };

    public LeaderboardScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);

        addSectionLabel(content, "TOP 3 CHAMPIONS");
        content.addView(buildPodium(), lp(-1, -2, 0, 0, 0, dp(6)));

        content.addView(buildMyRankCard(), lp(-1, -2, 0, dp(10), 0, dp(4)));

        addSectionLabel(content, "RANKINGS");
        int maxRating = Integer.parseInt(SAMPLE_PLAYERS[0][1]);
        for (int i = 3; i < SAMPLE_PLAYERS.length; i++) {
            addPlayerRow(content, i + 1, SAMPLE_PLAYERS[i][0],
                    Integer.parseInt(SAMPLE_PLAYERS[i][1]), maxRating);
        }

        TextView note = text("Leaderboard updates when the server is connected.", 12, TEXT_FAINT, Typeface.NORMAL);
        note.setGravity(Gravity.CENTER);
        content.addView(note, lp(-1, -2, 0, dp(16), 0, 0));

        return createScreenShell("Leaderboard", content);
    }

    private View buildPodium() {
        LinearLayout podium = new LinearLayout(activity);
        podium.setOrientation(LinearLayout.HORIZONTAL);
        podium.setGravity(Gravity.BOTTOM);
        podium.setPadding(dp(8), dp(8), dp(8), 0);

        // Order on screen: 2nd, 1st, 3rd
        podium.addView(podiumColumn(2, SAMPLE_PLAYERS[1][0], SAMPLE_PLAYERS[1][1],
                0xffC0C8D4, 0xff8C97A8, dp(54), dp(46)), columnParams());
        podium.addView(podiumColumn(1, SAMPLE_PLAYERS[0][0], SAMPLE_PLAYERS[0][1],
                0xffFFB300, 0xffD98E00, dp(78), dp(58)), columnParams());
        podium.addView(podiumColumn(3, SAMPLE_PLAYERS[2][0], SAMPLE_PLAYERS[2][1],
                0xffD98A4B, 0xffA8632C, dp(40), dp(46)), columnParams());
        return podium;
    }

    private LinearLayout.LayoutParams columnParams() {
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
        p.setMargins(dp(4), 0, dp(4), 0);
        return p;
    }

    private View podiumColumn(int rank, String name, String rating,
                              int medalColor, int medalEdge, int blockHeight, int avatarSize) {
        LinearLayout col = new LinearLayout(activity);
        col.setOrientation(LinearLayout.VERTICAL);
        col.setGravity(Gravity.CENTER_HORIZONTAL);

        if (rank == 1) {
            TextView crown = text("👑", 22, Color.WHITE, Typeface.NORMAL);
            crown.setGravity(Gravity.CENTER);
            col.addView(crown, lp(-2, -2, 0, 0, 0, dp(2)));
        }

        FrameLayout avatarHolder = new FrameLayout(activity);
        col.addView(avatarHolder, lp(avatarSize + dp(8), avatarSize + dp(8)));

        TextView avatar = new TextView(activity);
        avatar.setText(name.substring(0, 1).toUpperCase(java.util.Locale.US));
        avatar.setTextColor(Color.WHITE);
        avatar.setTextSize(avatarSize / 2.8f);
        avatar.setTypeface(Typeface.DEFAULT_BOLD);
        avatar.setGravity(Gravity.CENTER);
        avatar.setBackground(circleGradient(seatColor(rank % 4), 0xff0F1626, medalColor, 2));
        FrameLayout.LayoutParams ap = new FrameLayout.LayoutParams(avatarSize, avatarSize, Gravity.CENTER);
        avatarHolder.addView(avatar, ap);

        TextView medal = new TextView(activity);
        medal.setText(String.valueOf(rank));
        medal.setTextColor(0xff10182B);
        medal.setTextSize(11);
        medal.setTypeface(Typeface.DEFAULT_BOLD);
        medal.setGravity(Gravity.CENTER);
        medal.setBackground(circle(medalColor, medalEdge, 1));
        FrameLayout.LayoutParams mp = new FrameLayout.LayoutParams(dp(20), dp(20), Gravity.BOTTOM | Gravity.END);
        avatarHolder.addView(medal, mp);

        TextView nameText = text(name, 12, Color.WHITE, Typeface.BOLD);
        nameText.setGravity(Gravity.CENTER);
        nameText.setSingleLine(true);
        col.addView(nameText, lp(-1, -2, 0, dp(6), 0, 0));

        TextView ratingText = text("⭐ " + rating, 11, ACCENT_GOLD, Typeface.BOLD);
        ratingText.setGravity(Gravity.CENTER);
        col.addView(ratingText, lp(-1, -2, 0, 0, 0, dp(8)));

        View block = new View(activity);
        GradientDrawable bg = new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,
                new int[]{(medalColor & 0x00FFFFFF) | 0x66000000, (medalColor & 0x00FFFFFF) | 0x14000000});
        bg.setCornerRadii(new float[]{dp(12), dp(12), dp(12), dp(12), 0, 0, 0, 0});
        bg.setStroke(dp(1), (medalColor & 0x00FFFFFF) | 0x55000000);
        block.setBackground(bg);
        col.addView(block, lp(-1, blockHeight));

        return col;
    }

    private View buildMyRankCard() {
        LinearLayout myRank = new LinearLayout(activity);
        myRank.setOrientation(LinearLayout.HORIZONTAL);
        myRank.setGravity(Gravity.CENTER_VERTICAL);
        myRank.setPadding(dp(16), dp(14), dp(16), dp(14));
        myRank.setBackground(cardGradient(0xff1C2A48, 0xff121A30, dp(20)));
        myRank.setElevation(dp(4));

        myRank.addView(avatarView(callback.getDisplayName(), 42), lp(dp(42), dp(42), 0, 0, dp(12), 0));

        LinearLayout myInfo = new LinearLayout(activity);
        myInfo.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams mip = new LinearLayout.LayoutParams(0, -2, 1);
        myRank.addView(myInfo, mip);

        myInfo.addView(text(callback.getDisplayName() + " (You)", 15, Color.WHITE, Typeface.BOLD));
        myInfo.addView(text("⭐ " + callback.getRating() + " rating", 12, ACCENT_GOLD, Typeface.NORMAL));

        TextView rankBadge = text("Unranked", 12, TEXT_DIM, Typeface.BOLD);
        rankBadge.setGravity(Gravity.CENTER);
        rankBadge.setPadding(dp(12), dp(6), dp(12), dp(6));
        rankBadge.setBackground(card(0xff1B2740, dp(12), 0x446F84A8));
        myRank.addView(rankBadge);
        return myRank;
    }

    private void addPlayerRow(LinearLayout parent, int rank, String name, int rating, int maxRating) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.VERTICAL);
        row.setPadding(dp(14), dp(11), dp(14), dp(11));
        row.setBackground(cardGradient(0xff141E34, 0xff0F1626, dp(16)));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(8)));

        LinearLayout top = new LinearLayout(activity);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        row.addView(top, lp(-1, -2));

        TextView rankText = text("#" + rank, 13, TEXT_DIM, Typeface.BOLD);
        rankText.setGravity(Gravity.CENTER);
        rankText.setBackground(card(0xff1B2740, dp(10), 0x336F84A8));
        rankText.setPadding(0, dp(4), 0, dp(4));
        top.addView(rankText, lp(dp(38), -2, 0, 0, dp(10), 0));

        TextView avatar = new TextView(activity);
        avatar.setText(name.substring(0, 1).toUpperCase(java.util.Locale.US));
        avatar.setTextColor(Color.WHITE);
        avatar.setTextSize(13);
        avatar.setTypeface(Typeface.DEFAULT_BOLD);
        avatar.setGravity(Gravity.CENTER);
        avatar.setBackground(circle(seatColor(rank % 4), 0x44FFFFFF, 1));
        top.addView(avatar, lp(dp(30), dp(30), 0, 0, dp(10), 0));

        TextView nameText = text(name, 14, Color.WHITE, Typeface.BOLD);
        LinearLayout.LayoutParams np = new LinearLayout.LayoutParams(0, -2, 1);
        top.addView(nameText, np);

        top.addView(text("⭐ " + rating, 14, ACCENT_GOLD, Typeface.BOLD));

        // Rating bar relative to #1 player
        FrameLayout barHolder = new FrameLayout(activity);
        LinearLayout.LayoutParams bp = lp(-1, dp(5), dp(48), dp(8), 0, 0);
        row.addView(barHolder, bp);

        View track = new View(activity);
        track.setBackground(card(0xff1B2740, dp(3), 0x00000000));
        barHolder.addView(track, new FrameLayout.LayoutParams(-1, -1));

        View fill = new View(activity);
        fill.setBackground(buttonGradient(ACCENT_BLUE, ACCENT_PURPLE, dp(3)));
        FrameLayout.LayoutParams fp = new FrameLayout.LayoutParams(-1, -1);
        barHolder.addView(fill, fp);
        final float fraction = Math.max(0.15f, rating / (float) maxRating);
        barHolder.post(() -> {
            fp.width = (int) (barHolder.getWidth() * fraction);
            fill.setLayoutParams(fp);
        });
    }
}
