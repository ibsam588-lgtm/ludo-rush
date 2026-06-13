package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 * Royal Rush Match History Screen.
 *
 * Layout:
 *   • Summary bar: W/L/D and win-rate pill
 *   • Filter chips: All / Win / Loss / This week
 *   • Scrollable list of match result cards
 */
public final class MatchHistoryScreen extends BaseScreen {

    private static final int FILTER_ALL = 0, FILTER_WIN = 1, FILTER_LOSS = 2, FILTER_WEEK = 3;
    private int activeFilter = FILTER_ALL;

    // Simulated match history
    private static final String[] OPPONENTS = {
        "DiceKing", "FireRoller", "NeonAce", "SlickSix", "QuickCap",
        "LudoLord", "BoardBoss", "SixBlitz"
    };
    private static final boolean[] WON = {true, false, true, true, false, true, false, true};
    private static final int[] DURATION_MIN = {7, 12, 5, 9, 15, 8, 11, 6};
    private static final int[] COINS_EARNED = {75, 0, 60, 80, 0, 70, 0, 65};
    private static final String[] DATES = {
        "Today, 14:32", "Today, 11:05", "Yesterday", "Yesterday", "Mon",
        "Mon", "Sun", "Sun"
    };

    public MatchHistoryScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout body = new LinearLayout(activity);
        body.setOrientation(LinearLayout.VERTICAL);

        body.addView(buildSummaryBar(), lp(-1, -2, 0, 0, 0, dp(16)));
        body.addView(buildFilterChips(), lp(-1, -2, 0, 0, 0, dp(20)));

        int wins   = countWins();
        int losses = WON.length - wins;
        addSectionLabel(body, "RECENT MATCHES  (" + WON.length + " total)");

        for (int i = 0; i < OPPONENTS.length; i++) {
            if (!matchesFilter(i)) continue;
            body.addView(buildMatchCard(i), lp(-1, -2, 0, 0, 0, dp(10)));
        }

        return createScreenShell("Match History", body);
    }

    // ── Summary bar ───────────────────────────────────────────────────────────

    private View buildSummaryBar() {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setBackground(cardGradient(theme.bgGradStart(), theme.bgGradEnd(), dp(18)));
        row.setPadding(dp(16), dp(16), dp(16), dp(16));
        row.setGravity(Gravity.CENTER_VERTICAL);

        int wins   = countWins();
        int losses = WON.length - wins;
        int wr     = WON.length > 0 ? (int)((float)wins / WON.length * 100) : 0;

        String[] labels = {"WINS", "LOSSES", "WIN RATE"};
        String[] vals   = {String.valueOf(wins), String.valueOf(losses), wr + "%"};
        int[] colors    = {ThemeManager.GREEN, ThemeManager.RED, ThemeManager.GOLD};

        for (int i = 0; i < 3; i++) {
            LinearLayout cell = new LinearLayout(activity);
            cell.setOrientation(LinearLayout.VERTICAL);
            cell.setGravity(Gravity.CENTER);

            TextView v = text(vals[i], 20, colors[i], Typeface.BOLD);
            v.setGravity(Gravity.CENTER);
            cell.addView(v, lp(-1, -2, 0, 0, 0, dp(2)));

            TextView l = text(labels[i], 9, theme.txtMuted(), Typeface.BOLD);
            l.setGravity(Gravity.CENTER);
            l.setLetterSpacing(0.04f);
            cell.addView(l);

            row.addView(cell, new LinearLayout.LayoutParams(0, -2, 1));

            if (i < 2) {
                View div = new View(activity);
                div.setBackgroundColor(theme.strokeCard());
                row.addView(div, lp(dp(1), dp(32)));
            }
        }
        return row;
    }

    // ── Filter chips ──────────────────────────────────────────────────────────

    private View buildFilterChips() {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);

        String[] labels = {"All", "Wins", "Losses", "This week"};
        int[] filterIds = {FILTER_ALL, FILTER_WIN, FILTER_LOSS, FILTER_WEEK};

        for (int i = 0; i < labels.length; i++) {
            boolean active = (filterIds[i] == activeFilter);
            TextView chip = badge(labels[i],
                    active ? ThemeManager.VIOLET : theme.bgCard(),
                    active ? Color.WHITE : theme.txtMuted());
            chip.setTextSize(12);
            chip.setPadding(dp(14), dp(8), dp(14), dp(8));
            chip.setBackground(glowCard(
                    active ? ThemeManager.VIOLET : theme.bgCard(),
                    dp(20),
                    active ? ThemeManager.INDIGO : theme.strokeCard()));
            chip.setTextColor(active ? Color.WHITE : theme.txtMuted());

            int finalId = filterIds[i];
            chip.setClickable(true);
            chip.setFocusable(true);
            chip.setOnClickListener(v -> {
                activeFilter = finalId;
                callback.navigateTo("history");
            });

            LinearLayout.LayoutParams cp = new LinearLayout.LayoutParams(-2, -2);
            if (i > 0) cp.setMargins(dp(8), 0, 0, 0);
            row.addView(chip, cp);
        }
        return row;
    }

    // ── Match card ────────────────────────────────────────────────────────────

    private View buildMatchCard(int i) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);

        boolean won = WON[i];
        int resultColor = won ? ThemeManager.GREEN : ThemeManager.RED;
        card.setBackground(glowCard(theme.bgCard(), dp(16),
                won ? 0x33_00C853 : 0x33_FF3B5C));
        card.setPadding(dp(14), dp(14), dp(14), dp(14));

        // Result indicator stripe
        View stripe = new View(activity);
        stripe.setBackground(glowCard(resultColor, dp(3), resultColor));
        card.addView(stripe, lp(dp(4), dp(44), 0, 0, dp(12), 0));

        // Avatar
        View av = avatarRing(OPPONENTS[i], resultColor, dp(38));
        card.addView(av, lp(dp(38), dp(38), 0, 0, dp(12), 0));

        // Text col
        LinearLayout textCol = new LinearLayout(activity);
        textCol.setOrientation(LinearLayout.VERTICAL);

        LinearLayout topRow = new LinearLayout(activity);
        topRow.setOrientation(LinearLayout.HORIZONTAL);
        topRow.setGravity(Gravity.CENTER_VERTICAL);
        topRow.addView(text("vs " + OPPONENTS[i], 14, theme.txtPrimary(), Typeface.BOLD),
                new LinearLayout.LayoutParams(0, -2, 1));
        topRow.addView(text(DATES[i], 11, theme.txtMuted(), Typeface.NORMAL));
        textCol.addView(topRow, lp(-1, -2, 0, 0, 0, dp(4)));

        LinearLayout bottomRow = new LinearLayout(activity);
        bottomRow.setOrientation(LinearLayout.HORIZONTAL);
        bottomRow.setGravity(Gravity.CENTER_VERTICAL);
        bottomRow.addView(text("⏱ " + DURATION_MIN[i] + " min", 11,
                theme.txtMuted(), Typeface.NORMAL),
                new LinearLayout.LayoutParams(0, -2, 1));
        if (won && COINS_EARNED[i] > 0) {
            bottomRow.addView(badge("◈ +" + COINS_EARNED[i], 0x22F5B700, ThemeManager.GOLD));
        }
        textCol.addView(bottomRow);
        card.addView(textCol, new LinearLayout.LayoutParams(0, -2, 1));

        // Result badge
        card.addView(badge(won ? "WIN" : "LOSS",
                won ? 0x2200C853 : 0x22FF3B5C,
                resultColor),
                lp(-2, -2, dp(10), 0, 0, 0));

        return card;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private boolean matchesFilter(int i) {
        switch (activeFilter) {
            case FILTER_WIN:  return WON[i];
            case FILTER_LOSS: return !WON[i];
            case FILTER_WEEK: return i < 5;  // first 5 rows = this week (simulated)
            default:          return true;
        }
    }

    private int countWins() {
        int count = 0;
        for (boolean w : WON) if (w) count++;
        return count;
    }
}
