package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
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

        LinearLayout myRank = new LinearLayout(activity);
        myRank.setOrientation(LinearLayout.HORIZONTAL);
        myRank.setGravity(Gravity.CENTER_VERTICAL);
        myRank.setPadding(dp(16), dp(16), dp(16), dp(16));
        myRank.setBackground(cardGradient(0xff192133, 0xff101827, dp(20)));
        content.addView(myRank, lp(-1, -2, 0, 0, 0, dp(16)));

        View avatar = new View(activity);
        avatar.setBackground(card(0xffE8293E, dp(20), 0x44FFFFFF));
        myRank.addView(avatar, lp(dp(40), dp(40), 0, 0, dp(12), 0));

        LinearLayout myInfo = new LinearLayout(activity);
        myInfo.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams mip = new LinearLayout.LayoutParams(0, -2, 1);
        myRank.addView(myInfo, mip);

        myInfo.addView(text(callback.getDisplayName(), 16, Color.WHITE, Typeface.BOLD));
        myInfo.addView(text("Rating: " + callback.getRating(), 13, 0xffF9A825, Typeface.NORMAL));

        TextView rankBadge = text("—", 20, 0xff6B7A90, Typeface.BOLD);
        rankBadge.setGravity(Gravity.CENTER);
        rankBadge.setPadding(dp(12), dp(4), dp(12), dp(4));
        rankBadge.setBackground(card(0xff1A2638, dp(12), 0x335D6D86));
        myRank.addView(rankBadge);

        addSectionLabel(content, "TOP PLAYERS");

        for (int i = 0; i < SAMPLE_PLAYERS.length; i++) {
            addPlayerRow(content, i + 1, SAMPLE_PLAYERS[i][0], Integer.parseInt(SAMPLE_PLAYERS[i][1]));
        }

        addSectionLabel(content, "");
        TextView note = text("Leaderboard updates when the server is connected.", 12, 0xff4A5568, Typeface.NORMAL);
        note.setGravity(Gravity.CENTER);
        content.addView(note);

        return createScreenShell("Leaderboard", content);
    }

    private void addPlayerRow(LinearLayout parent, int rank, String name, int rating) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(14), dp(12), dp(14), dp(12));

        int bg;
        int rankColor;
        if (rank == 1) { bg = 0x22F9A825; rankColor = 0xffF9A825; }
        else if (rank == 2) { bg = 0x22C0C0C0; rankColor = 0xffC0C0C0; }
        else if (rank == 3) { bg = 0x22CD7F32; rankColor = 0xffCD7F32; }
        else { bg = 0xff111A2A; rankColor = 0xff6B7A90; }

        row.setBackground(card(bg, dp(14), 0x225D6D86));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(6)));

        TextView rankText = text(String.valueOf(rank), 16, rankColor, Typeface.BOLD);
        rankText.setGravity(Gravity.CENTER);
        row.addView(rankText, lp(dp(36), -2, 0, 0, dp(10), 0));

        View dot = new View(activity);
        dot.setBackground(card(seatColor(rank % 4), dp(14), seatColor(rank % 4)));
        row.addView(dot, lp(dp(28), dp(28), 0, 0, dp(10), 0));

        TextView nameText = text(name, 15, Color.WHITE, Typeface.NORMAL);
        LinearLayout.LayoutParams np = new LinearLayout.LayoutParams(0, -2, 1);
        row.addView(nameText, np);

        TextView ratingText = text(String.valueOf(rating), 15, 0xffF9A825, Typeface.BOLD);
        row.addView(ratingText);
    }
}
