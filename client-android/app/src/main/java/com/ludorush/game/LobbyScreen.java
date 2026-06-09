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

        addSectionLabel(content, "SELECT MODE");

        LinearLayout r1 = new LinearLayout(activity);
        r1.setOrientation(LinearLayout.HORIZONTAL);
        content.addView(r1, lp(-1, -2, 0, 0, 0, dp(8)));

        LinearLayout r2 = new LinearLayout(activity);
        r2.setOrientation(LinearLayout.HORIZONTAL);
        content.addView(r2, lp(-1, -2, 0, 0, 0, dp(16)));

        String[] modes = {"classic_2p", "classic_4p", "rush_2p", "rush_4p"};
        String[] labels = {"🎲 Classic 2P", "🎲 Classic 4P", "⚡ Rush 2P", "⚡ Rush 4P"};
        String[] descs = {"30s turns", "30s turns", "15s turns", "15s turns"};
        Button[] btns = new Button[4];

        for (int i = 0; i < 4; i++) {
            int idx = i;
            Button b = new Button(activity);
            b.setAllCaps(false);
            b.setText(labels[i] + "\n" + descs[i]);
            b.setTextColor(Color.WHITE);
            b.setTextSize(13);
            b.setTypeface(Typeface.DEFAULT_BOLD);
            b.setPadding(dp(8), dp(14), dp(8), dp(14));
            btns[i] = b;
            b.setOnClickListener(v -> {
                selectedMode = modes[idx];
                for (int j = 0; j < 4; j++)
                    btns[j].setBackground(pressable(card(j == idx ? 0xff17386B : 0xff141E34, dp(16), j == idx ? ACCENT_BLUE : STROKE_SOFT)));
                btns[idx].setElevation(dp(6));
            });
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, -2, 1);
            p.setMargins(dp(4), 0, dp(4), 0);
            (i < 2 ? r1 : r2).addView(b, p);
        }
        btns[0].setBackground(pressable(card(0xff17386B, dp(16), ACCENT_BLUE)));
        for (int i = 1; i < 4; i++) btns[i].setBackground(pressable(card(0xff141E34, dp(16), STROKE_SOFT)));

        addSectionLabel(content, "PLAY OPTIONS");

        Button quick = actionButton("Quick Match", 0xff43A047, 0xff66BB6A);
        quick.setOnClickListener(v -> callback.startQuickMatch(selectedMode));
        content.addView(quick, lp(-1, dp(54), 0, 0, 0, dp(10)));

        Button bot = actionButton("Bot Match", 0xff1E88E5, 0xff42A5F5);
        bot.setOnClickListener(v -> callback.startBotMatch(selectedMode));
        content.addView(bot, lp(-1, dp(54), 0, 0, 0, dp(10)));

        Button create = secondaryButton("Create Private Room");
        create.setTextSize(15);
        create.setOnClickListener(v -> callback.startPrivateRoom(selectedMode));
        content.addView(create, lp(-1, dp(54), 0, 0, 0, dp(4)));

        addSectionLabel(content, "JOIN PRIVATE ROOM");

        LinearLayout joinRow = new LinearLayout(activity);
        joinRow.setOrientation(LinearLayout.HORIZONTAL);
        content.addView(joinRow, lp(-1, dp(54)));

        EditText codeInput = new EditText(activity);
        codeInput.setHint("Enter room code");
        codeInput.setHintTextColor(0xff4A5568);
        codeInput.setTextColor(Color.WHITE);
        codeInput.setTextSize(14);
        codeInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS);
        codeInput.setBackground(card(0xff1A2638, dp(14), 0x335D6D86));
        codeInput.setPadding(dp(16), dp(8), dp(16), dp(8));
        LinearLayout.LayoutParams cp = new LinearLayout.LayoutParams(0, -1, 1);
        joinRow.addView(codeInput, cp);

        Button join = secondaryButton("Join");
        join.setTextColor(0xffF9A825);
        join.setOnClickListener(v -> {
            String code = codeInput.getText().toString().trim();
            if (code.isEmpty()) {
                Toast.makeText(activity, "Enter a room code first", Toast.LENGTH_SHORT).show();
            } else {
                callback.joinPrivateRoom(code);
            }
        });
        LinearLayout.LayoutParams jp = new LinearLayout.LayoutParams(dp(80), -1);
        jp.setMargins(dp(8), 0, 0, 0);
        joinRow.addView(join, jp);

        addSectionLabel(content, "MODE INFO");

        LinearLayout infoCard = new LinearLayout(activity);
        infoCard.setOrientation(LinearLayout.VERTICAL);
        infoCard.setPadding(dp(16), dp(14), dp(16), dp(14));
        infoCard.setBackground(card(0xff111A2A, dp(16), 0x225D6D86));
        content.addView(infoCard);

        infoCard.addView(text("Classic Mode", 15, Color.WHITE, Typeface.BOLD));
        infoCard.addView(text("30-second turns. Standard Ludo rules. Roll a 6 to enter the board from your yard.", 13, 0xff6B7A90, Typeface.NORMAL));
        TextView rush = text("\nRush Mode", 15, Color.WHITE, Typeface.BOLD);
        infoCard.addView(rush);
        infoCard.addView(text("15-second turns. Faster pace for quick games.", 13, 0xff6B7A90, Typeface.NORMAL));

        return createScreenShell("Lobby", content);
    }
}
