package com.ludorush.game;

import android.graphics.Color;
import android.graphics.Typeface;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public final class LobbyScreen extends BaseScreen {
    private String selectedMode = "classic_2p";

    public LobbyScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    @Override
    public View createView() {
        LinearLayout content = new LinearLayout(activity);
        content.setOrientation(LinearLayout.VERTICAL);

        // ── Mode selector ─────────────────────────────────────────────────────
        addSectionLabel(content, "SELECT MODE");

        String[] modes  = {"classic_2p", "classic_4p", "rush_2p",  "rush_4p"};
        String[] labels = {"Classic 2P", "Classic 4P", "Rush 2P",  "Rush 4P"};
        String[] descs  = {"30s turns",  "30s turns",  "15s turns","15s turns"};
        String[] icons  = {"♟",          "♟♟",         "⚡",        "⚡⚡"};
        Button[] btns   = new Button[4];

        LinearLayout r1 = new LinearLayout(activity);
        r1.setOrientation(LinearLayout.HORIZONTAL);
        content.addView(r1, lp(-1, -2, 0, 0, 0, dp(10)));

        LinearLayout r2 = new LinearLayout(activity);
        r2.setOrientation(LinearLayout.HORIZONTAL);
        content.addView(r2, lp(-1, -2, 0, 0, 0, dp(20)));

        for (int i = 0; i < 4; i++) {
            int idx = i;
            Button b = new Button(activity);
            b.setAllCaps(false);
            b.setText(icons[i] + "  " + labels[i] + "\n" + descs[i]);
            b.setTextColor(theme.txtPrimary());
            b.setTextSize(13);
            b.setTypeface(Typeface.DEFAULT_BOLD);
            b.setPadding(dp(8), dp(14), dp(8), dp(14));
            btns[i] = b;
            b.setOnClickListener(v -> {
                selectedMode = modes[idx];
                for (int j = 0; j < 4; j++) {
                    btns[j].setBackground(card(
                        j == idx ? theme.bgSel() : theme.bgCard(),
                        dp(14),
                        j == idx ? theme.strokeSel() : theme.strokeCard()));
                }
            });
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
            p.setMargins(dp(4), 0, dp(4), 0);
            (i < 2 ? r1 : r2).addView(b, p);
        }
        // Default selection: classic_2p
        btns[0].setBackground(card(theme.bgSel(), dp(14), theme.strokeSel()));
        for (int i = 1; i < 4; i++)
            btns[i].setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));

        // ── Play options ──────────────────────────────────────────────────────
        addSectionLabel(content, "PLAY OPTIONS");

        Button quick = actionButton("⚡  Quick Match", ThemeManager.GREEN, ThemeManager.GREEN_LIGHT);
        quick.setOnClickListener(v -> callback.startQuickMatch(selectedMode));
        content.addView(quick, lp(-1, dp(56), 0, 0, 0, dp(10)));

        Button bot = actionButton("🤖  Bot Match", ThemeManager.BLUE, ThemeManager.BLUE_LIGHT);
        bot.setOnClickListener(v -> callback.startBotMatch(selectedMode));
        content.addView(bot, lp(-1, dp(56), 0, 0, 0, dp(10)));

        Button create = secondaryButton("🔒  Create Private Room");
        create.setTextSize(14);
        create.setOnClickListener(v ->
            Toast.makeText(activity, "Private rooms — coming soon", Toast.LENGTH_SHORT).show());
        content.addView(create, lp(-1, dp(50), 0, 0, 0, dp(4)));

        // ── Join private room ─────────────────────────────────────────────────
        addSectionLabel(content, "JOIN PRIVATE ROOM");

        LinearLayout joinRow = new LinearLayout(activity);
        joinRow.setOrientation(LinearLayout.HORIZONTAL);
        content.addView(joinRow, lp(-1, dp(54)));

        EditText codeInput = new EditText(activity);
        codeInput.setHint("Enter room code");
        codeInput.setHintTextColor(theme.txtDim());
        codeInput.setTextColor(theme.txtPrimary());
        codeInput.setTextSize(14);
        codeInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS);
        codeInput.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));
        codeInput.setPadding(dp(16), dp(8), dp(16), dp(8));
        joinRow.addView(codeInput, new LinearLayout.LayoutParams(0, -1, 1));

        Button join = secondaryButton("Join");
        join.setTextColor(ThemeManager.YELLOW);
        join.setOnClickListener(v -> {
            String code = codeInput.getText().toString().trim();
            Toast.makeText(activity,
                code.isEmpty() ? "Enter a room code first" : "Private rooms — coming soon",
                Toast.LENGTH_SHORT).show();
        });
        LinearLayout.LayoutParams jp = new LinearLayout.LayoutParams(dp(80), -1);
        jp.setMargins(dp(8), 0, 0, 0);
        joinRow.addView(join, jp);

        // ── Mode info ─────────────────────────────────────────────────────────
        addSectionLabel(content, "MODE INFO");

        LinearLayout infoCard = new LinearLayout(activity);
        infoCard.setOrientation(LinearLayout.VERTICAL);
        infoCard.setPadding(dp(16), dp(16), dp(16), dp(16));
        infoCard.setBackground(card(theme.bgCard(), dp(16), theme.strokeCard()));
        content.addView(infoCard);

        infoCard.addView(text("♟  Classic Mode", 15, theme.txtPrimary(), Typeface.BOLD));
        infoCard.addView(text("30-second turns. Standard Ludo rules. Roll a 6 to enter the board.",
                13, theme.txtMuted(), Typeface.NORMAL), lp(-1, -2, 0, dp(3), 0, dp(8)));
        infoCard.addView(text("⚡  Rush Mode", 15, theme.txtPrimary(), Typeface.BOLD));
        infoCard.addView(text("15-second turns. Faster pace for quick competitive games.",
                13, theme.txtMuted(), Typeface.NORMAL), lp(-1, -2, 0, dp(3), 0, 0));

        return createScreenShell("Lobby", content, true);
    }
}
