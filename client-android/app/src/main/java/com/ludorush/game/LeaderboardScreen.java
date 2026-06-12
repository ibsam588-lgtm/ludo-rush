package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class LeaderboardScreen extends BaseScreen {

    private static final String[][] SAMPLE_PLAYERS = {
        {"LudoKing99",   "1580"}, {"BoardMaster",  "1520"}, {"DiceRoller",   "1490"},
        {"RushChamp",    "1450"}, {"TokenPro",     "1410"}, {"StarPlayer",   "1380"},
        {"FastMover",    "1350"}, {"GreenMachine", "1320"}, {"RedBaron",     "1290"},
        {"BlueStar",     "1260"}
    };

    public LeaderboardScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);

        // ── My rank card ──────────────────────────────────────────────────────
        LinearLayout myRank = new LinearLayout(activity);
        myRank.setOrientation(LinearLayout.HORIZONTAL);
        myRank.setGravity(Gravity.CENTER_VERTICAL);
        myRank.setPadding(dp(16), dp(16), dp(16), dp(16));
        myRank.setBackground(cardGradient(theme.bgGradStart(), theme.bgGradEnd(), dp(20)));
        content.addView(myRank, lp(-1, -2, 0, 0, 0, dp(16)));

        View avatar = new View(activity);
        avatar.setBackground(circleOutline(ThemeManager.RED, 0x55FFFFFF));
        myRank.addView(avatar, lp(dp(44), dp(44), 0, 0, dp(12), 0));

        LinearLayout myInfo = new LinearLayout(activity);
        myInfo.setOrientation(LinearLayout.VERTICAL);
        myRank.addView(myInfo, new LinearLayout.LayoutParams(0, -2, 1));
        myInfo.addView(text(callback.getDisplayName(), 16, theme.txtPrimary(), Typeface.BOLD));
        myInfo.addView(text("Rating: " + callback.getRating(), 13, ThemeManager.YELLOW, Typeface.NORMAL),
                lp(-1, -2, 0, dp(2), 0, 0));

        TextView rankBadge = text("—", 20, theme.txtMuted(), Typeface.BOLD);
        rankBadge.setGravity(Gravity.CENTER);
        rankBadge.setPadding(dp(14), dp(6), dp(14), dp(6));
        rankBadge.setBackground(card(theme.bgCard(), dp(12), theme.strokeCard()));
        myRank.addView(rankBadge);

        // ── Top players ───────────────────────────────────────────────────────
        addSectionLabel(content, "TOP PLAYERS");

        for (int i = 0; i < SAMPLE_PLAYERS.length; i++) {
            addPlayerRow(content, i + 1,
                SAMPLE_PLAYERS[i][0],
                Integer.parseInt(SAMPLE_PLAYERS[i][1]));
        }

        // Footer note
        addSectionLabel(content, "");
        TextView note = text("Live rankings update when the server is connected.",
                12, theme.txtDim(), Typeface.NORMAL);
        note.setGravity(Gravity.CENTER);
        content.addView(note);

        return createScreenShell("Leaderboard", content, true);
    }

    private void addPlayerRow(LinearLayout parent, int rank, String name, int rating) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(14), dp(12), dp(14), dp(12));

        int bgColor, rankColor;
        if (rank == 1) {
            bgColor = 0x22F9A825; rankColor = ThemeManager.YELLOW;
        } else if (rank == 2) {
            bgColor = 0x22C0C0C0; rankColor = 0xffC0C0C0;
        } else if (rank == 3) {
            bgColor = 0x22CD7F32; rankColor = 0xffCD7F32;
        } else {
            bgColor = theme.bgCard(); rankColor = theme.txtMuted();
        }

        row.setBackground(card(bgColor, dp(14), theme.strokeCardAlt()));
        parent.addView(row, lp(-1, -2, 0, 0, 0, dp(6)));

        // Rank number
        TextView rankText = text(rank <= 3 ? rankMedal(rank) : String.valueOf(rank),
                rank <= 3 ? 20 : 16, rankColor, Typeface.BOLD);
        rankText.setGravity(Gravity.CENTER);
        row.addView(rankText, lp(dp(40), -2, 0, 0, dp(8), 0));

        // Colour dot
        View dot = new View(activity);
        dot.setBackground(circle(seatColor(rank % 4)));
        row.addView(dot, lp(dp(28), dp(28), 0, 0, dp(10), 0));

        // Name
        row.addView(text(name, 15, theme.txtPrimary(), Typeface.NORMAL),
                new LinearLayout.LayoutParams(0, -2, 1));

        // Rating
        row.addView(text(String.valueOf(rating), 15, ThemeManager.YELLOW, Typeface.BOLD));
    }

    private String rankMedal(int rank) {
        if (rank == 1) return "🥇";
        if (rank == 2) return "🥈";
        return "🥉";
    }
}
