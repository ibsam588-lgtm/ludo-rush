package com.ludorush.game;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.animation.ValueAnimator;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RadialGradient;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.InputFilter;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.OvershootInterpolator;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class GameScreen extends BaseScreen {

    private TextView statusText;
    private DiceView diceView;
    private DiceOverlayView diceOverlay;
    private LinearLayout opponentStrip;
    private LinearLayout myRow;
    private View myColorDot;
    private TextView myNameText;
    private TextView movesText;
    private BoardView board;
    private Button rollButton;
    private Button moveButton;
    private JSONObject snapshot;
    private int prevDiceValue = -1;
    private boolean diceAnimating = false;
    private boolean coinRewardShown = false;

    // Chat drawer state
    private FrameLayout chatDrawer;
    private LinearLayout chatMessages;
    private boolean chatOpen = false;

    public GameScreen(Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    public void updateSnapshot(JSONObject snap, String playerId) {
        this.snapshot = snap;
        if (board != null) board.setSnapshot(snap, playerId);
        if (statusText != null) refreshUi();
    }

    public void setStatus(String t) {
        if (statusText != null) statusText.setText(t);
    }

    public void setLastRoll(int value, boolean myRoll) { /* driven by snapshot */ }

    @Override
    public View createView() {
        FrameLayout root = new FrameLayout(activity);
        root.setBackgroundColor(theme.bgPage());

        LinearLayout main = new LinearLayout(activity);
        main.setOrientation(LinearLayout.VERTICAL);
        main.setPadding(dp(10), dp(8), dp(10), dp(8));
        root.addView(main, new FrameLayout.LayoutParams(-1, -1));

        // ── Header ────────────────────────────────────────────────────────────
        LinearLayout header = new LinearLayout(activity);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        main.addView(header, lp(-1, dp(48), 0, 0, 0, 0));

        Button back = new Button(activity);
        back.setAllCaps(false); back.setText("‹");
        back.setTextColor(ThemeManager.GOLD); back.setTextSize(26);
        back.setTypeface(Typeface.DEFAULT_BOLD); back.setBackground(null);
        back.setOnClickListener(v -> showLeaveConfirmation());
        header.addView(back, lp(dp(48), dp(48)));

        TextView title = text("LIVE MATCH", 15, ThemeManager.GOLD, Typeface.BOLD);
        title.setLetterSpacing(0.1f);
        header.addView(title, new LinearLayout.LayoutParams(0, -2, 1));

        Button themeBtn = new Button(activity);
        themeBtn.setAllCaps(false); themeBtn.setText("◑");
        themeBtn.setTextColor(ThemeManager.GOLD); themeBtn.setTextSize(18);
        themeBtn.setBackground(card(theme.bgCard(), dp(12), theme.strokeCard()));
        themeBtn.setPadding(dp(4), dp(4), dp(4), dp(4));
        themeBtn.setOnClickListener(v -> { theme.setDark(!theme.isDark()); activity.recreate(); });
        LinearLayout.LayoutParams tmLp = new LinearLayout.LayoutParams(dp(40), dp(40));
        tmLp.setMargins(0, 0, dp(6), 0);
        header.addView(themeBtn, tmLp);

        Button resignBtn = new Button(activity);
        resignBtn.setAllCaps(false); resignBtn.setText("Resign");
        resignBtn.setTextColor(ThemeManager.RED); resignBtn.setTextSize(12);
        resignBtn.setTypeface(Typeface.DEFAULT_BOLD);
        resignBtn.setBackground(card(theme.bgDanger(), dp(12), theme.strokeDanger()));
        resignBtn.setPadding(dp(10), dp(4), dp(10), dp(4));
        resignBtn.setOnClickListener(v -> showResignConfirmation());
        header.addView(resignBtn);

        // ── Opponent strip ─────────────────────────────────────────────────────
        opponentStrip = new LinearLayout(activity);
        opponentStrip.setOrientation(LinearLayout.HORIZONTAL);
        opponentStrip.setGravity(Gravity.CENTER);
        main.addView(opponentStrip, lp(-1, -2, 0, dp(4), 0, dp(6)));

        // ── Board + dice overlay ───────────────────────────────────────────────
        FrameLayout boardFrame = new FrameLayout(activity);

        board = new BoardView(activity);
        board.setTapListener(pieceId -> callback.movePiece(pieceId));
        boardFrame.addView(board, new FrameLayout.LayoutParams(-1, -1));

        diceOverlay = new DiceOverlayView(activity);
        diceOverlay.setVisibility(View.INVISIBLE);
        boardFrame.addView(diceOverlay, new FrameLayout.LayoutParams(-1, -1));

        LinearLayout.LayoutParams bfLp = new LinearLayout.LayoutParams(-1, 0);
        bfLp.weight = 1;
        bfLp.setMargins(0, 0, 0, dp(6));
        main.addView(boardFrame, bfLp);

        // ── My row ────────────────────────────────────────────────────────────
        myRow = new LinearLayout(activity);
        myRow.setOrientation(LinearLayout.HORIZONTAL);
        myRow.setGravity(Gravity.CENTER_VERTICAL);
        myRow.setPadding(dp(12), dp(8), dp(12), dp(8));
        myRow.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));
        main.addView(myRow, lp(-1, -2, 0, 0, 0, dp(6)));

        myColorDot = new View(activity);
        myColorDot.setBackground(circle(seatColor(0)));
        myRow.addView(myColorDot, lp(dp(28), dp(28), 0, 0, dp(8), 0));

        LinearLayout myInfo = new LinearLayout(activity);
        myInfo.setOrientation(LinearLayout.VERTICAL);

        LinearLayout myNameRow = new LinearLayout(activity);
        myNameRow.setOrientation(LinearLayout.HORIZONTAL);
        myNameRow.setGravity(Gravity.CENTER_VERTICAL);
        String flag = callback.getCountry();
        myNameRow.addView(text(flag + " ", 14, theme.txtPrimary(), Typeface.NORMAL));
        myNameText = text(callback.getDisplayName(), 14, theme.txtPrimary(), Typeface.BOLD);
        myNameRow.addView(myNameText);
        myInfo.addView(myNameRow);

        movesText = text("Waiting...", 11, theme.txtMuted(), Typeface.NORMAL);
        myInfo.addView(movesText);
        myRow.addView(myInfo, new LinearLayout.LayoutParams(0, -2, 1));

        diceView = new DiceView(activity);
        myRow.addView(diceView, lp(dp(44), dp(44)));

        // ── Status bar ─────────────────────────────────────────────────────────
        statusText = text("Waiting for match...", 13, theme.txtSecondary(), Typeface.BOLD);
        statusText.setGravity(Gravity.CENTER);
        statusText.setPadding(dp(12), dp(10), dp(12), dp(10));
        statusText.setBackground(card(theme.bgMetric(), dp(14), theme.strokeCardAlt()));
        main.addView(statusText, lp(-1, -2, 0, 0, 0, dp(6)));

        // ── Action buttons ─────────────────────────────────────────────────────
        LinearLayout actions = new LinearLayout(activity);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        main.addView(actions, lp(-1, dp(56)));

        rollButton = actionButton("🎲  Roll Dice", ThemeManager.RED, 0xffF9502E);
        rollButton.setTextSize(14);
        rollButton.setOnClickListener(v -> {
            v.animate().scaleX(0.9f).scaleY(0.9f).setDuration(70)
                .withEndAction(() -> v.animate().scaleX(1f).scaleY(1f).setDuration(120).start())
                .start();
            callback.rollDice();
        });
        LinearLayout.LayoutParams rp = new LinearLayout.LayoutParams(0, -1, 1);
        rp.setMargins(0, 0, dp(4), 0);
        actions.addView(rollButton, rp);

        moveButton = actionButton("⚡  Auto Move", ThemeManager.NAVY, ThemeManager.BLUE);
        moveButton.setTextSize(14);
        moveButton.setOnClickListener(v -> callback.moveBestPiece());
        LinearLayout.LayoutParams mp = new LinearLayout.LayoutParams(0, -1, 1);
        mp.setMargins(dp(4), 0, dp(4), 0);
        actions.addView(moveButton, mp);

        Button chatBtn = actionButton("💬 Chat", ThemeManager.TEAL, 0xff1A9A90);
        chatBtn.setTextSize(14);
        chatBtn.setOnClickListener(v -> toggleChat());
        LinearLayout.LayoutParams cp2 = new LinearLayout.LayoutParams(0, -1, 0.75f);
        cp2.setMargins(dp(4), 0, 0, 0);
        actions.addView(chatBtn, cp2);

        // ── Chat drawer ────────────────────────────────────────────────────────
        chatDrawer = buildChatDrawer();
        chatDrawer.setTranslationY(dp(300));
        chatDrawer.setAlpha(0f);
        chatDrawer.setVisibility(View.GONE);
        root.addView(chatDrawer, new FrameLayout.LayoutParams(-1, dp(300), Gravity.BOTTOM));

        return root;
    }

    // ── Chat ───────────────────────────────────────────────────────────────────

    private FrameLayout buildChatDrawer() {
        FrameLayout drawer = new FrameLayout(activity);

        LinearLayout panel = new LinearLayout(activity);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setPadding(dp(14), dp(14), dp(14), dp(14));

        android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable();
        bg.setColor(theme.bgCard());
        bg.setCornerRadii(new float[]{dp(20), dp(20), dp(20), dp(20), 0, 0, 0, 0});
        bg.setStroke(dp(1), theme.strokeCard());
        panel.setBackground(bg);
        drawer.addView(panel, new FrameLayout.LayoutParams(-1, -1));

        // Header row
        LinearLayout chatHeader = new LinearLayout(activity);
        chatHeader.setOrientation(LinearLayout.HORIZONTAL);
        chatHeader.setGravity(Gravity.CENTER_VERTICAL);
        chatHeader.addView(text("💬 Chat", 16, theme.txtPrimary(), Typeface.BOLD),
            new LinearLayout.LayoutParams(0, -2, 1));
        Button close = new Button(activity);
        close.setText("✕"); close.setAllCaps(false);
        close.setTextColor(theme.txtMuted()); close.setTextSize(16);
        close.setBackground(null);
        close.setOnClickListener(v -> toggleChat());
        chatHeader.addView(close, lp(dp(40), dp(40)));
        panel.addView(chatHeader, lp(-1, -2, 0, 0, 0, dp(8)));

        // Message log
        ScrollView msgScroll = new ScrollView(activity);
        msgScroll.setOverScrollMode(View.OVER_SCROLL_NEVER);
        msgScroll.setVerticalScrollBarEnabled(false);
        chatMessages = new LinearLayout(activity);
        chatMessages.setOrientation(LinearLayout.VERTICAL);
        msgScroll.addView(chatMessages, new ScrollView.LayoutParams(-1, -2));
        panel.addView(msgScroll, new LinearLayout.LayoutParams(-1, 0, 1));

        // Quick-reply presets
        String[] presets = {"Good game!", "Nice move!", "That was close!", "Lucky!", "GG", "Rematch?"};
        LinearLayout presetRow = new LinearLayout(activity);
        presetRow.setOrientation(LinearLayout.HORIZONTAL);
        HorizontalScrollView hScroll = new HorizontalScrollView(activity);
        hScroll.setHorizontalScrollBarEnabled(false);
        hScroll.addView(presetRow, new HorizontalScrollView.LayoutParams(-2, -2));
        LinearLayout.LayoutParams hsLp = new LinearLayout.LayoutParams(-1, -2);
        hsLp.setMargins(0, dp(8), 0, dp(6));
        panel.addView(hScroll, hsLp);

        for (String msg : presets) {
            Button btn = new Button(activity);
            btn.setAllCaps(false); btn.setText(msg);
            btn.setTextColor(theme.txtPrimary()); btn.setTextSize(13);
            btn.setBackground(card(theme.bgCardHigh(), dp(16), theme.strokeCardAlt()));
            btn.setOnClickListener(v -> sendChatMessage(msg));
            LinearLayout.LayoutParams pp = new LinearLayout.LayoutParams(-2, dp(36));
            pp.setMargins(0, 0, dp(8), 0);
            presetRow.addView(btn, pp);
        }

        // Free text for 13+ only
        if (!callback.isUnder13()) {
            LinearLayout inputRow = new LinearLayout(activity);
            inputRow.setOrientation(LinearLayout.HORIZONTAL);
            inputRow.setGravity(Gravity.CENTER_VERTICAL);

            EditText input = new EditText(activity);
            input.setHint("Say something...");
            input.setHintTextColor(theme.txtDim());
            input.setTextColor(theme.txtPrimary());
            input.setTextSize(14); input.setMaxLines(1);
            input.setFilters(new InputFilter[]{new InputFilter.LengthFilter(50)});
            input.setBackground(card(theme.bgInput(), dp(12), theme.strokeCardAlt()));
            input.setPadding(dp(12), dp(8), dp(12), dp(8));
            inputRow.addView(input, new LinearLayout.LayoutParams(0, dp(44), 1));

            Button send = actionButton("Send", ThemeManager.TEAL, 0xff1A9A90);
            send.setTextSize(13);
            send.setOnClickListener(v -> {
                String m = input.getText().toString().trim();
                if (!m.isEmpty()) { sendChatMessage(m); input.setText(""); }
            });
            LinearLayout.LayoutParams sLp = new LinearLayout.LayoutParams(dp(72), dp(44));
            sLp.setMargins(dp(8), 0, 0, 0);
            inputRow.addView(send, sLp);
            panel.addView(inputRow, lp(-1, -2));
        }

        return drawer;
    }

    private void toggleChat() {
        chatOpen = !chatOpen;
        if (chatOpen) {
            chatDrawer.setVisibility(View.VISIBLE);
            chatDrawer.animate().translationY(0).alpha(1f)
                .setDuration(270).setInterpolator(new DecelerateInterpolator()).start();
        } else {
            chatDrawer.animate().translationY(dp(300)).alpha(0f)
                .setDuration(200).setInterpolator(new DecelerateInterpolator())
                .withEndAction(() -> chatDrawer.setVisibility(View.GONE)).start();
        }
    }

    private void sendChatMessage(String msg) {
        callback.sendChat(msg);
        addBubble("You: " + msg, true);
    }

    public void receiveChatMessage(String sender, String msg) {
        activity.runOnUiThread(() -> addBubble(sender + ": " + msg, false));
    }

    private void addBubble(String text, boolean mine) {
        if (chatMessages == null) return;
        TextView bubble = new TextView(activity);
        bubble.setText(text);
        bubble.setTextColor(mine ? Color.WHITE : theme.txtPrimary());
        bubble.setTextSize(13);
        bubble.setPadding(dp(10), dp(6), dp(10), dp(6));
        android.graphics.drawable.GradientDrawable bd = new android.graphics.drawable.GradientDrawable();
        bd.setColor(mine ? ThemeManager.TEAL : theme.bgCardHigh());
        bd.setCornerRadius(dp(12));
        bubble.setBackground(bd);
        LinearLayout.LayoutParams blp = new LinearLayout.LayoutParams(-2, -2);
        blp.setMargins(mine ? dp(40) : 0, 0, mine ? 0 : dp(40), dp(4));
        blp.gravity = mine ? Gravity.END : Gravity.START;
        chatMessages.addView(bubble, blp);
    }

    // ── Dialogs ────────────────────────────────────────────────────────────────

    private void showLeaveConfirmation() {
        new AlertDialog.Builder(activity)
            .setTitle("Leave Match?")
            .setMessage("Leaving counts as a resignation.")
            .setPositiveButton("Leave & Resign", (d, w) -> { callback.resign(); callback.goBack(); })
            .setNegativeButton("Stay", null).show();
    }

    private void showResignConfirmation() {
        new AlertDialog.Builder(activity)
            .setTitle("Resign Match?")
            .setMessage("This ends the match and counts as a loss.")
            .setPositiveButton("Resign", (d, w) -> { callback.resign(); callback.navigateTo("home"); })
            .setNegativeButton("Cancel", null).show();
    }

    // ── UI refresh ─────────────────────────────────────────────────────────────

    private void refreshUi() {
        if (snapshot == null) return;
        String status   = snapshot.optString("status", "waiting");
        int dice        = snapshot.optInt("diceValue", 0);
        JSONArray moves = snapshot.optJSONArray("availableMoves");
        int turnSeat    = snapshot.optInt("currentTurnSeat", -1);
        int mySeat      = mySeat();
        boolean myTurn  = mySeat >= 0 && mySeat == turnSeat && "playing".equals(status);
        boolean canRoll = myTurn && dice == 0 && !diceAnimating;
        boolean canMove = myTurn && dice > 0 && moves != null && moves.length() > 0;

        if (dice != prevDiceValue) {
            if (dice > 0 && dice <= 6) {
                diceAnimating = true;
                rollButton.setEnabled(false);
                rollButton.setAlpha(0.4f);
                board.stopPulse();
                diceView.startRoll(dice, () -> {
                    diceAnimating = false;
                    if (myTurn && canMove) board.startPulse();
                    updateButtonStates(snapshot);
                });
                diceOverlay.showRoll(dice);
            } else {
                diceView.setValue(dice);
                diceOverlay.hide();
                board.stopPulse();
            }
            prevDiceValue = dice;
        }

        updateButtonStates(snapshot);
        updateMovesText(moves);

        if ("finished".equals(status)) {
            statusText.setText(winnerText());
            board.stopPulse();
            diceOverlay.hide();
            showCoinRewardIfNeeded();
        } else if (canRoll) {
            statusText.setText("Your turn — Roll the dice!");
        } else if (diceAnimating) {
            statusText.setText("Rolling...");
        } else if (canMove) {
            statusText.setText("Rolled " + dice + " — tap a piece to move!");
        } else if (myTurn) {
            statusText.setText("No legal moves — skipping turn.");
        } else {
            statusText.setText("Waiting for " + seatName(turnSeat) + "...");
        }

        renderPlayers();
    }

    private void showCoinRewardIfNeeded() {
        if (coinRewardShown || snapshot == null) return;
        coinRewardShown = true;
        String winnerId = snapshot.optString("winnerPlayerId", "");
        boolean won = callback.getPlayerId() != null && callback.getPlayerId().equals(winnerId);
        int moves = 0;
        JSONArray pieces = snapshot.optJSONArray("pieces");
        if (pieces != null) {
            for (int i = 0; i < pieces.length(); i++) {
                JSONObject p = pieces.optJSONObject(i);
                if (p != null && callback.getPlayerId() != null
                        && callback.getPlayerId().equals(p.optString("ownerId", ""))) {
                    moves += p.optInt("progress", 0);
                }
            }
        }
        new CoinRewardDialog(activity, theme, won, moves, callback,
            () -> callback.navigateTo("results")).show();
    }

    private void updateButtonStates(JSONObject snap) {
        if (snap == null) return;
        String status = snap.optString("status", "waiting");
        int dice      = snap.optInt("diceValue", 0);
        JSONArray mvs = snap.optJSONArray("availableMoves");
        int mySeat    = mySeat();
        int turnSeat  = snap.optInt("currentTurnSeat", -1);
        boolean myTurn  = mySeat >= 0 && mySeat == turnSeat && "playing".equals(status);
        boolean canRoll = myTurn && dice == 0 && !diceAnimating;
        boolean canMove = myTurn && dice > 0 && mvs != null && mvs.length() > 0;
        rollButton.setEnabled(canRoll);
        rollButton.setAlpha(canRoll ? 1f : 0.38f);
        moveButton.setEnabled(canMove);
        moveButton.setAlpha(canMove ? 1f : 0.38f);
    }

    private void updateMovesText(JSONArray moves) {
        int count = moves == null ? 0 : moves.length();
        if (movesText != null)
            movesText.setText(count > 0 ? count + " moves available" : "Waiting...");
    }

    private void renderPlayers() {
        if (opponentStrip == null || snapshot == null) return;
        opponentStrip.removeAllViews();
        JSONArray seats = snapshot.optJSONArray("seats");
        if (seats == null) return;
        int activeSeat = snapshot.optInt("currentTurnSeat", -1);
        String myId    = callback.getPlayerId();

        for (int i = 0; i < seats.length(); i++) {
            JSONObject s = seats.optJSONObject(i);
            if (s == null) continue;
            int seat    = s.optInt("seat", 0);
            boolean isMe   = myId != null && myId.equals(s.optString("playerId"));
            boolean active = activeSeat == seat;

            if (isMe) {
                if (myColorDot != null) myColorDot.setBackground(circle(seatColor(seat)));
                if (myNameText != null) myNameText.setText(callback.getDisplayName());
                if (myRow != null) myRow.setBackground(card(
                    active ? theme.bgSel() : theme.bgCard(), dp(14),
                    active ? seatColor(seat) : theme.strokeCard()));
                continue;
            }

            String name   = s.optString("displayName", "Player");
            boolean isBot = s.optBoolean("isBot");
            String sub    = isBot ? "Bot" : "Online"; // no "ready" emoji
            int color     = seatColor(seat);
            String sflag  = s.optString("country", "");
            if (sflag.isEmpty()) sflag = "🌍"; // globe

            LinearLayout card = new LinearLayout(activity);
            card.setOrientation(LinearLayout.VERTICAL);
            card.setGravity(Gravity.CENTER);
            card.setPadding(dp(10), dp(6), dp(10), dp(6));
            card.setBackground(card(
                active ? theme.bgSel() : theme.bgCard(), dp(12),
                active ? color : theme.strokeCardAlt()));

            View dot = new View(activity);
            dot.setBackground(circle(color));
            card.addView(dot, lp(dp(18), dp(18), 0, 0, 0, dp(3)));

            // Flag + name row
            LinearLayout nr = new LinearLayout(activity);
            nr.setOrientation(LinearLayout.HORIZONTAL);
            nr.setGravity(Gravity.CENTER);
            nr.addView(text(sflag + " ", 10, theme.txtPrimary(), Typeface.NORMAL));
            TextView nv = text(name, 11, theme.txtPrimary(), Typeface.BOLD);
            nv.setSingleLine(true);
            nr.addView(nv);
            card.addView(nr);

            TextView sv = text(sub, 10, active ? color : theme.txtMuted(), Typeface.BOLD);
            sv.setGravity(Gravity.CENTER);
            card.addView(sv);

            if (active) flashGold(card, color);

            LinearLayout.LayoutParams cp = new LinearLayout.LayoutParams(0, -2, 1);
            cp.setMargins(dp(3), 0, dp(3), 0);
            opponentStrip.addView(card, cp);
        }
    }

    private void flashGold(LinearLayout card, int seatColor) {
        ValueAnimator anim = ValueAnimator.ofArgb(seatColor, ThemeManager.GOLD, seatColor);
        anim.setDuration(900);
        anim.setRepeatCount(2);
        anim.addUpdateListener(a ->
            card.setBackground(card(theme.bgSel(), dp(12), (int) a.getAnimatedValue())));
        anim.start();
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private int mySeat() {
        if (snapshot == null || callback.getPlayerId() == null) return -1;
        JSONArray seats = snapshot.optJSONArray("seats");
        if (seats == null) return -1;
        for (int i = 0; i < seats.length(); i++) {
            JSONObject s = seats.optJSONObject(i);
            if (s != null && callback.getPlayerId().equals(s.optString("playerId")))
                return s.optInt("seat", -1);
        }
        return -1;
    }

    private String seatName(int idx) {
        if (snapshot == null) return "Player";
        JSONArray seats = snapshot.optJSONArray("seats");
        if (seats == null) return "Seat " + (idx + 1);
        for (int i = 0; i < seats.length(); i++) {
            JSONObject s = seats.optJSONObject(i);
            if (s != null && s.optInt("seat", -1) == idx) {
                if (callback.getPlayerId() != null &&
                        callback.getPlayerId().equals(s.optString("playerId"))) return "You";
                return s.optString("displayName", "Seat " + (idx + 1));
            }
        }
        return "Seat " + (idx + 1);
    }

    private String winnerText() {
        String winner = snapshot.optString("winnerPlayerId", "");
        if (callback.getPlayerId() != null && callback.getPlayerId().equals(winner))
            return "🏆 You won!";
        JSONArray seats = snapshot.optJSONArray("seats");
        if (seats != null) {
            for (int i = 0; i < seats.length(); i++) {
                JSONObject s = seats.optJSONObject(i);
                if (s != null && winner.equals(s.optString("playerId")))
                    return s.optString("displayName", "Opponent") + " won.";
            }
        }
        return "Match finished.";
    }

    public JSONObject getSnapshot() { return snapshot; }

    // ══════════════════════════════════════════════════════════════════════════
    // Coin Reward Dialog
    // ══════════════════════════════════════════════════════════════════════════

    public static final class CoinRewardDialog extends Dialog {
        private final ThemeManager theme;
        private final boolean won;
        private final int bonusMoves;
        private final ScreenCallback callback;
        private final Runnable onDismiss;

        public CoinRewardDialog(Activity ctx, ThemeManager theme, boolean won,
                                int bonusMoves, ScreenCallback callback, Runnable onDismiss) {
            super(ctx);
            this.theme = theme; this.won = won;
            this.bonusMoves = bonusMoves; this.callback = callback;
            this.onDismiss = onDismiss;
        }

        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            requestWindowFeature(Window.FEATURE_NO_TITLE);
            setCancelable(false);
            if (getWindow() != null) {
                getWindow().setBackgroundDrawable(new ColorDrawable(0xCC000000));
                int w = (int)(getContext().getResources().getDisplayMetrics().widthPixels * 0.88f);
                getWindow().setLayout(w, WindowManager.LayoutParams.WRAP_CONTENT);
            }

            Activity activity = (Activity) getContext();
            float d = activity.getResources().getDisplayMetrics().density;
            int base   = won ? 150 : 25;
            int bonus  = won ? Math.min(50, bonusMoves / 10) : 0;
            int amount = base + bonus;
            callback.addCoins(amount);

            FrameLayout outer = new FrameLayout(getContext());

            ConfettiView confetti = new ConfettiView(getContext());
            outer.addView(confetti, new FrameLayout.LayoutParams(-1, (int)(180 * d)));

            LinearLayout card = new LinearLayout(getContext());
            card.setOrientation(LinearLayout.VERTICAL);
            card.setGravity(Gravity.CENTER);
            card.setPadding((int)(22*d),(int)(28*d),(int)(22*d),(int)(22*d));
            android.graphics.drawable.GradientDrawable cbg = new android.graphics.drawable.GradientDrawable();
            cbg.setColor(theme.bgCard());
            cbg.setCornerRadius(22 * d);
            cbg.setStroke((int)(2*d), theme.strokeCard());
            card.setBackground(cbg);
            outer.addView(card, new FrameLayout.LayoutParams(-1, -2));

            // Animated coin
            TextView coin = new TextView(getContext());
            coin.setText("🪙"); coin.setTextSize(52);
            coin.setGravity(Gravity.CENTER);
            coin.setScaleX(0f); coin.setScaleY(0f);
            card.addView(coin);
            ValueAnimator coinIn = ValueAnimator.ofFloat(0f, 1f);
            coinIn.setDuration(700);
            coinIn.setInterpolator(new OvershootInterpolator());
            coinIn.addUpdateListener(a -> {
                float v = (float) a.getAnimatedValue();
                coin.setScaleX(v); coin.setScaleY(v);
            });
            coinIn.start();

            // Result label
            TextView resultLbl = new TextView(getContext());
            resultLbl.setText(won ? "🏆 You Won!" : "Good Game!");
            resultLbl.setTextSize(24);
            resultLbl.setTextColor(won ? ThemeManager.GOLD : theme.txtSecondary());
            resultLbl.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
            resultLbl.setGravity(Gravity.CENTER);
            LinearLayout.LayoutParams rlp = new LinearLayout.LayoutParams(-1, -2);
            rlp.setMargins(0,(int)(8*d),0,(int)(4*d));
            card.addView(resultLbl, rlp);

            TextView coinsLbl = new TextView(getContext());
            coinsLbl.setText("+" + amount + " coins!");
            coinsLbl.setTextSize(20);
            coinsLbl.setTextColor(ThemeManager.YELLOW);
            coinsLbl.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
            coinsLbl.setGravity(Gravity.CENTER);
            LinearLayout.LayoutParams clp = new LinearLayout.LayoutParams(-1, -2);
            clp.setMargins(0,0,0,(int)(4*d));
            card.addView(coinsLbl, clp);

            TextView sub = new TextView(getContext());
            sub.setText(won ? "Excellent performance!" : "Keep playing to earn more!");
            sub.setTextSize(12); sub.setTextColor(theme.txtMuted());
            sub.setGravity(Gravity.CENTER);
            LinearLayout.LayoutParams slp = new LinearLayout.LayoutParams(-1, -2);
            slp.setMargins(0,0,0,(int)(20*d));
            card.addView(sub, slp);

            Button cont = new Button(getContext());
            cont.setAllCaps(false); cont.setText("Continue");
            cont.setTextColor(0xff1A0800); cont.setTextSize(15);
            cont.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
            android.graphics.drawable.GradientDrawable btnBg =
                new android.graphics.drawable.GradientDrawable(
                    android.graphics.drawable.GradientDrawable.Orientation.LEFT_RIGHT,
                    new int[]{ThemeManager.GOLD, ThemeManager.AMBER});
            btnBg.setCornerRadius(18 * d);
            cont.setBackground(btnBg);
            cont.setOnClickListener(v -> { dismiss(); onDismiss.run(); });
            card.addView(cont, new LinearLayout.LayoutParams(-1, (int)(50*d)));

            setContentView(outer);
            confetti.start();
        }

        // Confetti dots falling down
        static final class ConfettiView extends View {
            private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
            private final int[] colors = {
                ThemeManager.RED, ThemeManager.BLUE, ThemeManager.YELLOW,
                ThemeManager.GREEN, ThemeManager.GOLD, ThemeManager.TEAL,
                0xffFF69B4, 0xffFF8C00
            };
            private float[] xs, ys, rots, speeds, sizes;
            private ValueAnimator anim;
            private static final int N = 32;

            ConfettiView(Context ctx) {
                super(ctx);
                xs = new float[N]; ys = new float[N];
                rots = new float[N]; speeds = new float[N]; sizes = new float[N];
            }

            void start() {
                post(() -> {
                    float w = getWidth() > 0 ? getWidth() : 300;
                    for (int i = 0; i < N; i++) {
                        xs[i]    = ((i * 137 + 31) % 100) / 100f * w;
                        ys[i]    = -((i * 53 + 7) % 80);
                        speeds[i] = 1.2f + (i % 5) * 0.5f;
                        sizes[i]  = 5f + (i % 4) * 3f;
                        rots[i]   = (i * 31 % 360);
                    }
                    anim = ValueAnimator.ofFloat(0f, 1f);
                    anim.setDuration(2200);
                    anim.setRepeatCount(1);
                    anim.addUpdateListener(a -> {
                        float t = (float) a.getAnimatedValue();
                        float h = getHeight() > 0 ? getHeight() : 180;
                        for (int i = 0; i < N; i++) {
                            ys[i]   = -sizes[i] + t * (h + sizes[i] * 2) * speeds[i] * 0.7f;
                            rots[i] += 4f;
                        }
                        invalidate();
                    });
                    anim.start();
                });
            }

            @Override protected void onDraw(Canvas canvas) {
                for (int i = 0; i < N; i++) {
                    p.setColor(colors[i % colors.length]);
                    canvas.save();
                    canvas.translate(xs[i], ys[i]);
                    canvas.rotate(rots[i]);
                    float s = sizes[i];
                    canvas.drawRoundRect(-s, -s/2f, s, s/2f, 2, 2, p);
                    canvas.restore();
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Large dice overlay shown center-board during roll
    // ══════════════════════════════════════════════════════════════════════════

    public static final class DiceOverlayView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF r = new RectF();
        private int displayValue;
        private float slideOff = 0f;
        private final Handler h = new Handler(Looper.getMainLooper());

        public DiceOverlayView(Context ctx) { super(ctx); }

        void showRoll(int finalValue) {
            setVisibility(VISIBLE);
            setAlpha(1f); setScaleX(1f); setScaleY(1f);
            slideOff = 0f;

            // Slide in from below
            ValueAnimator slideIn = ValueAnimator.ofFloat(220f, 0f);
            slideIn.setDuration(280);
            slideIn.setInterpolator(new DecelerateInterpolator());
            slideIn.addUpdateListener(a -> { slideOff = (float) a.getAnimatedValue(); invalidate(); });
            slideIn.start();

            // Cycle faces then land
            int[] seq = {3, 1, 5, 2, 6, 4, 1, 3, 5, 2, 4, finalValue};
            for (int i = 0; i < seq.length; i++) {
                final int face = seq[i];
                final boolean last = i == seq.length - 1;
                h.postDelayed(() -> {
                    displayValue = face;
                    if (last) {
                        ValueAnimator pop = ValueAnimator.ofFloat(1.18f, 1f);
                        pop.setDuration(320);
                        pop.setInterpolator(new OvershootInterpolator());
                        pop.addUpdateListener(a -> {
                            float v = (float) a.getAnimatedValue();
                            setScaleX(v); setScaleY(v);
                        });
                        pop.start();
                    }
                    invalidate();
                }, 65L * (i + 1));
            }
            // Auto-hide after 2.5s
            h.postDelayed(this::hide, 2800);
        }

        void hide() {
            animate().alpha(0f).setDuration(300)
                .withEndAction(() -> { setVisibility(INVISIBLE); displayValue = 0; invalidate(); })
                .start();
        }

        @Override protected void onDraw(Canvas canvas) {
            if (displayValue < 1 || displayValue > 6) return;
            int w = getWidth(), wh = getHeight();
            float size  = Math.min(w, wh) * 0.44f;
            float cx    = w / 2f, cy = wh / 2f + slideOff;
            float left  = cx - size/2, top  = cy - size/2;
            float right = cx + size/2, bot  = cy + size/2;
            float rad   = size * 0.18f;
            float cw    = right - left, ch = bot - top;

            // Backdrop scrim
            paint.setColor(0xCC000000);
            float scrim = size * 0.7f;
            canvas.drawRoundRect(cx-scrim, cy-scrim, cx+scrim, cy+scrim,
                size*0.14f, size*0.14f, paint);

            // Shadow
            r.set(left+size*0.04f, top+size*0.06f, right+size*0.04f, bot+size*0.06f);
            paint.setColor(0x60000000);
            canvas.drawRoundRect(r, rad, rad, paint);

            // Face gradient (ivory)
            r.set(left, top, right, bot);
            paint.setShader(new LinearGradient(left, top, right, bot,
                0xffFFFDF4, 0xffE8DFB8, Shader.TileMode.CLAMP));
            canvas.drawRoundRect(r, rad, rad, paint);
            paint.setShader(null);

            // Gold rim
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(size * 0.052f);
            paint.setColor(ThemeManager.GOLD);
            canvas.drawRoundRect(r, rad, rad, paint);
            paint.setStyle(Paint.Style.FILL);

            // Pips in classic arrangement
            float pr = cw * 0.1f;
            float lx = left + cw*0.29f, rx = right - cw*0.29f;
            float ty2 = top + ch*0.29f, by2 = bot - ch*0.29f;
            float mid_cx = left + cw/2f, mid_cy = top + ch/2f;
            paint.setColor(ThemeManager.NAVY);
            boolean diag  = displayValue == 2 || displayValue == 3;
            boolean four  = displayValue >= 4;
            boolean midDot = displayValue % 2 == 1;
            boolean six   = displayValue == 6;
            if (four) {
                canvas.drawCircle(lx, ty2, pr, paint); canvas.drawCircle(rx, ty2, pr, paint);
                canvas.drawCircle(lx, by2, pr, paint); canvas.drawCircle(rx, by2, pr, paint);
            } else if (diag) {
                canvas.drawCircle(lx, ty2, pr, paint); canvas.drawCircle(rx, by2, pr, paint);
            }
            if (six) {
                canvas.drawCircle(lx, mid_cy, pr, paint); canvas.drawCircle(rx, mid_cy, pr, paint);
            }
            if (midDot) canvas.drawCircle(mid_cx, mid_cy, pr, paint);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Small dice in my-row
    // ══════════════════════════════════════════════════════════════════════════

    public static final class DiceView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF r = new RectF();
        private int displayValue;
        private final Handler uiHandler = new Handler(Looper.getMainLooper());

        public DiceView(Activity activity) { super(activity); }

        public void setValue(int v) { displayValue = v; invalidate(); }

        public void startRoll(int finalValue, Runnable onDone) {
            int[] seq = {3, 1, 5, 2, 6, 4, 1, 3, 5, 2, 4, finalValue};
            for (int i = 0; i < seq.length; i++) {
                final int face = seq[i];
                final boolean last = i == seq.length - 1;
                uiHandler.postDelayed(() -> {
                    displayValue = face;
                    ValueAnimator sc = ValueAnimator.ofFloat(1.08f, 1f);
                    sc.setDuration(55);
                    sc.addUpdateListener(a -> {
                        float v = (float) a.getAnimatedValue();
                        setScaleX(v); setScaleY(v);
                    });
                    sc.start();
                    invalidate();
                    if (last && onDone != null) onDone.run();
                }, 55L * (i + 1));
            }
        }

        @Override protected void onDraw(Canvas canvas) {
            int w = getWidth(), h = getHeight();
            float s = Math.min(w, h);
            float pad = s * 0.1f;
            float left = (w-s)/2f+pad, top = (h-s)/2f+pad;
            float right = (w+s)/2f-pad, bottom = (h+s)/2f-pad;
            float cw = right-left, ch = bottom-top;
            float rad = cw * 0.24f;

            r.set(left, top+s*0.05f, right, bottom+s*0.05f);
            paint.setColor(0x40000000);
            canvas.drawRoundRect(r, rad, rad, paint);

            r.set(left, top, right, bottom);
            paint.setShader(new LinearGradient(left, top, right, bottom,
                0xffFFFDF4, 0xffEADFC0, Shader.TileMode.CLAMP));
            canvas.drawRoundRect(r, rad, rad, paint);
            paint.setShader(null);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(s * 0.06f);
            paint.setColor(ThemeManager.GOLD);
            canvas.drawRoundRect(r, rad, rad, paint);
            paint.setStyle(Paint.Style.FILL);

            float cx = left+cw/2f, cy = top+ch/2f;
            if (displayValue < 1 || displayValue > 6) {
                paint.setColor(0xff9A8A5E);
                paint.setStrokeWidth(s*0.05f);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeCap(Paint.Cap.ROUND);
                canvas.drawLine(cx-cw*0.16f, cy, cx+cw*0.16f, cy, paint);
                paint.setStyle(Paint.Style.FILL);
                return;
            }

            float pr = cw*0.1f;
            float lx = left+cw*0.29f, rx = right-cw*0.29f;
            float ty = top+ch*0.29f, by = bottom-ch*0.29f;
            paint.setColor(ThemeManager.NAVY);
            boolean diag = displayValue==2||displayValue==3;
            boolean four = displayValue>=4;
            boolean mid  = displayValue%2==1;
            boolean six  = displayValue==6;
            if (four) {
                canvas.drawCircle(lx,ty,pr,paint); canvas.drawCircle(rx,ty,pr,paint);
                canvas.drawCircle(lx,by,pr,paint); canvas.drawCircle(rx,by,pr,paint);
            } else if (diag) {
                canvas.drawCircle(lx,ty,pr,paint); canvas.drawCircle(rx,by,pr,paint);
            }
            if (six) { canvas.drawCircle(lx,cy,pr,paint); canvas.drawCircle(rx,cy,pr,paint); }
            if (mid) canvas.drawCircle(cx,cy,pr,paint);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Board canvas — with 3D sphere pieces, skin support, move animation
    // ══════════════════════════════════════════════════════════════════════════

    public static final class BoardView extends View {
        private static final int[][] PATH = {
            {6,14},{6,13},{6,12},{6,11},{6,10},{6,9},{5,8},{4,8},{3,8},{2,8},{1,8},{0,8},{0,7},
            {0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,5},{6,4},{6,3},{6,2},{6,1},{6,0},{7,0},
            {8,0},{8,1},{8,2},{8,3},{8,4},{8,5},{9,6},{10,6},{11,6},{12,6},{13,6},{14,6},{14,7},
            {14,8},{13,8},{12,8},{11,8},{10,8},{9,8},{8,9},{8,10},{8,11},{8,12},{8,13},{8,14},{7,14}
        };
        private static final int[][] SAFE = {
            {6,14},{3,8},{0,6},{6,3},{8,0},{11,6},{14,8},{8,11}
        };
        private static final int[][][] HOME_LANES = {
            {{7,13},{7,12},{7,11},{7,10},{7,9}},
            {{1,7},{2,7},{3,7},{4,7},{5,7}},
            {{7,1},{7,2},{7,3},{7,4},{7,5}},
            {{13,7},{12,7},{11,7},{10,7},{9,7}}
        };

        private static final int NAVY    = ThemeManager.NAVY_DEEP;
        private static final int IVORY   = 0xffF7F2E2;
        private static final int GOLD    = ThemeManager.GOLD;
        private static final int GOLD_DK = ThemeManager.GOLD_DARK;

        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF  rect  = new RectF();
        private JSONObject snapshot;
        private String playerId;
        private String equippedSkin = "classic";

        // Tap-to-move
        interface PieceTapListener { void onPieceTap(String pieceId); }
        private PieceTapListener tapListener;
        public void setTapListener(PieceTapListener l) { tapListener = l; }

        private static final class PieceHit {
            final String pieceId; final float cx, cy, r; final boolean legal;
            PieceHit(String id, float cx, float cy, float r, boolean legal) {
                this.pieceId=id; this.cx=cx; this.cy=cy; this.r=r; this.legal=legal;
            }
        }
        private final List<PieceHit> pieceHits = new ArrayList<>();

        // Pulse animation
        private float pulsePhase = 1f;
        private ValueAnimator pulseAnim;

        // Move animation
        private static final class AnimPiece {
            String pieceId;
            float sx, sy, ex, ey, t;
        }
        private AnimPiece animPiece;
        private ValueAnimator moveAnim;

        public BoardView(Activity ctx) {
            super(ctx);
            setMinimumHeight(600);
            SharedPreferences p = ctx.getSharedPreferences("ludo_settings", 0);
            equippedSkin = p.getString("equipped_skin", "classic");
        }

        public void setSnapshot(JSONObject snap, String pid) {
            if (this.snapshot != null && getWidth() > 0)
                detectAndAnimateMoves(snap);
            this.snapshot = snap;
            this.playerId = pid;
            // Refresh skin pref
            SharedPreferences p = getContext().getSharedPreferences("ludo_settings", 0);
            equippedSkin = p.getString("equipped_skin", "classic");
            invalidate();
        }

        private void detectAndAnimateMoves(JSONObject newSnap) {
            JSONArray oldPs = this.snapshot.optJSONArray("pieces");
            JSONArray newPs = newSnap.optJSONArray("pieces");
            if (oldPs == null || newPs == null) return;
            int w = getWidth(), h = getHeight();
            int size = Math.min(w - 8, h - 8);
            int left = (w - size) / 2, top = (h - size) / 2;
            float cell = size / 15f;

            for (int i = 0; i < newPs.length(); i++) {
                JSONObject np = newPs.optJSONObject(i);
                if (np == null) continue;
                String pid = np.optString("pieceId");
                for (int j = 0; j < oldPs.length(); j++) {
                    JSONObject op = oldPs.optJSONObject(j);
                    if (op == null || !pid.equals(op.optString("pieceId"))) continue;
                    float[] os = piecePos(op, left, top, cell);
                    float[] ns = piecePos(np, left, top, cell);
                    if (Math.abs(os[0]-ns[0]) > 2f || Math.abs(os[1]-ns[1]) > 2f) {
                        if (moveAnim != null) moveAnim.cancel();
                        animPiece = new AnimPiece();
                        animPiece.pieceId = pid;
                        animPiece.sx = os[0]; animPiece.sy = os[1];
                        animPiece.ex = ns[0]; animPiece.ey = ns[1];
                        animPiece.t  = 0f;
                        moveAnim = ValueAnimator.ofFloat(0f, 1f);
                        moveAnim.setDuration(320);
                        moveAnim.setInterpolator(new DecelerateInterpolator());
                        moveAnim.addUpdateListener(a -> {
                            if (animPiece != null) animPiece.t = (float) a.getAnimatedValue();
                            invalidate();
                        });
                        moveAnim.addListener(new AnimatorListenerAdapter() {
                            @Override public void onAnimationEnd(Animator an) {
                                animPiece = null; invalidate();
                            }
                        });
                        moveAnim.start();
                    }
                    break;
                }
            }
        }

        public void startPulse() {
            if (pulseAnim != null && pulseAnim.isRunning()) return;
            pulseAnim = ValueAnimator.ofFloat(0.25f, 1f);
            pulseAnim.setDuration(580);
            pulseAnim.setRepeatMode(ValueAnimator.REVERSE);
            pulseAnim.setRepeatCount(ValueAnimator.INFINITE);
            pulseAnim.addUpdateListener(a -> { pulsePhase = (float) a.getAnimatedValue(); invalidate(); });
            pulseAnim.start();
        }

        public void stopPulse() {
            if (pulseAnim != null) { pulseAnim.cancel(); pulseAnim = null; }
            pulsePhase = 1f; invalidate();
        }

        @Override
        public boolean onTouchEvent(MotionEvent event) {
            if (event.getAction() != MotionEvent.ACTION_UP) return true;
            float tx = event.getX(), ty = event.getY();
            PieceHit best = null; float bestDist = Float.MAX_VALUE;
            for (PieceHit h : pieceHits) {
                float d = (float) Math.sqrt((tx-h.cx)*(tx-h.cx)+(ty-h.cy)*(ty-h.cy));
                if (h.legal && d < h.r * 2.8f && d < bestDist) { bestDist = d; best = h; }
            }
            if (best != null && tapListener != null) {
                tapListener.onPieceTap(best.pieceId); stopPulse();
            }
            return true;
        }

        @Override protected void onDraw(Canvas canvas) {
            int w = getWidth(), h = getHeight();
            int size = Math.min(w - 8, h - 8);
            int left = (w - size) / 2, top = (h - size) / 2;
            float cell = size / 15f;

            drawShell(canvas, left, top, size);
            drawBases(canvas, left, top, cell);
            drawTrack(canvas, left, top, cell);
            drawHomeLanes(canvas, left, top, cell);
            drawGridLines(canvas, left, top, cell);
            drawCenter(canvas, left, top, cell);
            drawPieces(canvas, left, top, cell);
            drawEmpty(canvas, left, top, size);
        }

        private int blend(int a, int b, float t) {
            float ia = 1f - t;
            int aa = (int)(((a>>>24)&0xff)*ia+((b>>>24)&0xff)*t);
            int rr = (int)(((a>>16)&0xff)*ia+((b>>16)&0xff)*t);
            int gg = (int)(((a>>8 )&0xff)*ia+((b>>8 )&0xff)*t);
            int bb = (int)(( a     &0xff)*ia+( b     &0xff)*t);
            return (aa<<24)|(rr<<16)|(gg<<8)|bb;
        }

        private void drawShell(Canvas canvas, int left, int top, int size) {
            rect.set(left, top, left+size, top+size);
            paint.setColor(NAVY);
            canvas.drawRect(rect, paint);
            float ow = Math.max(4f, size*0.018f), iw = Math.max(2f, size*0.009f);
            float gap = Math.max(2f, size*0.009f);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(ow); paint.setColor(GOLD);
            canvas.drawRect(rect, paint);
            float inset = ow/2f + gap + iw/2f;
            rect.set(left+inset, top+inset, left+size-inset, top+size-inset);
            paint.setStrokeWidth(iw);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawGridLines(Canvas canvas, int left, int top, float cell) {
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(1f, cell*0.02f));
            paint.setColor(0x18000000);
            for (int i = 0; i <= 15; i++) {
                float p = i * cell;
                canvas.drawLine(left+p, top, left+p, top+15*cell, paint);
                canvas.drawLine(left, top+p, left+15*cell, top+p, paint);
            }
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawBases(Canvas canvas, int left, int top, float cell) {
            drawBase(canvas, left, top, cell, 0, 9, ThemeManager.RED);
            drawBase(canvas, left, top, cell, 0, 0, ThemeManager.BLUE);
            drawBase(canvas, left, top, cell, 9, 0, ThemeManager.YELLOW);
            drawBase(canvas, left, top, cell, 9, 9, ThemeManager.GREEN);
        }

        private void drawBase(Canvas canvas, int left, int top, float cell,
                              int gx, int gy, int color) {
            float x1 = left+gx*cell, y1 = top+gy*cell;
            float x2 = left+(gx+6)*cell, y2 = top+(gy+6)*cell;

            // Base fill
            rect.set(x1, y1, x2, y2);
            paint.setColor(color);
            canvas.drawRect(rect, paint);

            // Gold border
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(cell*0.1f);
            paint.setColor(GOLD);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);

            // Inner dark yard area
            float ins = cell * 0.85f;
            rect.set(x1+ins, y1+ins, x2-ins, y2-ins);
            paint.setColor(blend(color, 0xff04080F, 0.80f));
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(cell*0.05f);
            paint.setColor(0x99D4AF37);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);

            // Home triangles from corners toward center (decorative)
            float bx = (x1+x2)/2f, by = (y1+y2)/2f;
            float ts = cell * 0.6f;
            paint.setColor(blend(color, 0xffFFFFFF, 0.25f));
            paint.setAlpha(120);
            Path tri = new Path();
            // top-left triangle
            tri.moveTo(x1+ins, y1+ins); tri.lineTo(x1+ins+ts, y1+ins); tri.lineTo(bx, by); tri.close();
            canvas.drawPath(tri, paint);
            tri.reset();
            tri.moveTo(x1+ins, y1+ins); tri.lineTo(x1+ins, y1+ins+ts); tri.lineTo(bx, by); tri.close();
            canvas.drawPath(tri, paint);
            paint.setAlpha(255);

            // 4 home pieces as 3D spheres
            float cx2 = (x1+x2)/2f, cy2 = (y1+y2)/2f;
            float off = cell*0.9f, rr = cell*0.44f;
            float[][] slots = {{-off,-off},{off,-off},{-off,off},{off,off}};
            for (float[] sl : slots) {
                float px = cx2 + sl[0], py = cy2 + sl[1];
                paint.setColor(0x55000000);
                canvas.drawCircle(px + rr*0.12f, py + rr*0.17f, rr, paint);
                // 3D radial gradient sphere
                paint.setShader(new RadialGradient(
                    px - rr*0.32f, py - rr*0.35f, rr * 1.15f,
                    new int[]{0xffFFFFFF,
                        blend(color, 0xffFFFFFF, 0.55f),
                        color,
                        blend(color, 0xff000000, 0.35f)},
                    new float[]{0f, 0.18f, 0.6f, 1f},
                    Shader.TileMode.CLAMP));
                canvas.drawCircle(px, py, rr, paint);
                paint.setShader(null);
                // Gold ring
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(cell*0.07f);
                paint.setColor(GOLD);
                canvas.drawCircle(px, py, rr, paint);
                paint.setStyle(Paint.Style.FILL);
                // White specular highlight
                paint.setColor(0xccFFFFFF);
                canvas.drawCircle(px - rr*0.33f, py - rr*0.35f, rr*0.21f, paint);
            }
        }

        private void drawTrack(Canvas canvas, int left, int top, float cell) {
            int[] si = {0, 13, 26, 39};
            int[] sc = {ThemeManager.RED, ThemeManager.BLUE, ThemeManager.YELLOW, ThemeManager.GREEN};
            for (int i = 0; i < PATH.length; i++) {
                int[] p = PATH[i];
                int fill = IVORY, stroke = 0x33B8941F;
                for (int s = 0; s < si.length; s++) {
                    if (i == si[s]) { fill = sc[s]; stroke = GOLD; break; }
                }
                drawCell(canvas, left, top, cell, p[0], p[1], fill, stroke);
            }
            for (int[] p : SAFE) {
                drawStar(canvas,
                    left + (p[0]+0.5f)*cell,
                    top  + (p[1]+0.5f)*cell,
                    cell*0.27f, GOLD);
            }
        }

        private void drawHomeLanes(Canvas canvas, int left, int top, float cell) {
            int[] soft = {ThemeManager.RED_SOFT, ThemeManager.BLUE_SOFT,
                          ThemeManager.YELLOW_SOFT, ThemeManager.GREEN_SOFT};
            for (int seat = 0; seat < HOME_LANES.length; seat++) {
                for (int[] p : HOME_LANES[seat])
                    drawCell(canvas, left, top, cell, p[0], p[1], soft[seat], 0x66D4AF37);
            }
        }

        private void drawCenter(Canvas canvas, int left, int top, float cell) {
            int[] c = {ThemeManager.RED, ThemeManager.BLUE, ThemeManager.YELLOW, ThemeManager.GREEN};
            float cx = left+7.5f*cell, cy = top+7.5f*cell;
            float x6 = left+6*cell, x9 = left+9*cell;
            float y6 = top+6*cell,  y9 = top+9*cell;
            rect.set(x6, y6, x9, y9);
            paint.setColor(0xffFFF8E8);
            canvas.drawRect(rect, paint);
            // 4 colored triangles pointing toward center
            Path t = new Path();
            t.moveTo(x6, y9); t.lineTo(x9, y9); t.lineTo(cx, cy); t.close();
            paint.setColor(c[0]); canvas.drawPath(t, paint);
            t.reset(); t.moveTo(x6, y6); t.lineTo(x6, y9); t.lineTo(cx, cy); t.close();
            paint.setColor(c[1]); canvas.drawPath(t, paint);
            t.reset(); t.moveTo(x6, y6); t.lineTo(x9, y6); t.lineTo(cx, cy); t.close();
            paint.setColor(c[2]); canvas.drawPath(t, paint);
            t.reset(); t.moveTo(x9, y6); t.lineTo(x9, y9); t.lineTo(cx, cy); t.close();
            paint.setColor(c[3]); canvas.drawPath(t, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(cell*0.05f); paint.setColor(0x88D4AF37);
            canvas.drawLine(x6, y6, x9, y9, paint);
            canvas.drawLine(x6, y9, x9, y6, paint);
            paint.setStrokeWidth(cell*0.22f); paint.setColor(GOLD);
            canvas.drawCircle(cx, cy, cell*0.98f, paint);
            paint.setStrokeWidth(cell*0.04f); paint.setColor(GOLD_DK);
            canvas.drawCircle(cx, cy, cell*1.12f, paint);
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0xffFFF8E8);
            canvas.drawCircle(cx, cy, cell*0.66f, paint);
            drawGoldStar6(canvas, cx, cy, cell*0.6f);
        }

        private void drawGoldStar6(Canvas canvas, float cx, float cy, float r) {
            Path s = new Path();
            for (int i = 0; i < 12; i++) {
                double angle = -Math.PI/2 + i*Math.PI/6;
                float rr = i%2==0 ? r : r*0.5f;
                float x = cx + (float)Math.cos(angle)*rr;
                float y = cy + (float)Math.sin(angle)*rr;
                if (i==0) s.moveTo(x,y); else s.lineTo(x,y);
            }
            s.close();
            paint.setColor(GOLD); canvas.drawPath(s, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(r*0.08f); paint.setColor(GOLD_DK);
            canvas.drawPath(s, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawCell(Canvas canvas, int left, int top, float cell,
                              int gx, int gy, int fill, int stroke) {
            float pad = cell*0.03f;
            rect.set(left+gx*cell+pad, top+gy*cell+pad,
                     left+(gx+1)*cell-pad, top+(gy+1)*cell-pad);
            paint.setColor(fill);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(1f, cell*0.04f));
            paint.setColor(stroke);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawPieces(Canvas canvas, int left, int top, float cell) {
            pieceHits.clear();
            if (snapshot == null) return;
            JSONArray pieces = snapshot.optJSONArray("pieces");
            if (pieces == null) return;
            JSONArray avail  = snapshot.optJSONArray("availableMoves");
            int activeSeat   = snapshot.optInt("currentTurnSeat", -1);
            for (int i = 0; i < pieces.length(); i++) {
                JSONObject p = pieces.optJSONObject(i);
                if (p == null) continue;
                String pid  = p.optString("pieceId");
                boolean legal = contains(avail, pid);
                int seat    = p.optInt("seat");

                float[] pos = piecePos(p, left, top, cell);
                // Apply move animation if this is the animating piece
                if (animPiece != null && pid.equals(animPiece.pieceId)) {
                    float t = animPiece.t;
                    pos = new float[]{
                        animPiece.sx + (animPiece.ex - animPiece.sx) * t,
                        animPiece.sy + (animPiece.ey - animPiece.sy) * t
                    };
                }

                pieceHits.add(new PieceHit(pid, pos[0], pos[1], cell*0.38f, legal));
                drawPiece(canvas, pos[0], pos[1], cell*0.38f,
                    seatColor(seat), legal, activeSeat == seat);
            }
        }

        private void drawPiece(Canvas canvas, float cx, float cy, float r,
                               int color, boolean legal, boolean active) {
            if (legal || active) {
                paint.setStyle(Paint.Style.STROKE);
                float ra = legal ? pulsePhase : 0.55f;
                int halo = ((int)(ra * 220) << 24) | (GOLD & 0x00FFFFFF);
                paint.setStrokeWidth(legal ? r*0.38f : r*0.18f);
                paint.setColor(halo);
                canvas.drawCircle(cx, cy, r * (legal ? 1.68f : 1.35f), paint);
                paint.setStyle(Paint.Style.FILL);
            }
            // Drop shadow
            paint.setColor(0x44000000);
            canvas.drawCircle(cx + r*0.15f, cy + r*0.18f, r, paint);

            // 3D sphere using RadialGradient
            int skinHighlight, skinMid, skinDark;
            switch (equippedSkin) {
                case "crystal":
                    skinHighlight = 0xffFFFFFF;
                    skinMid       = 0xff87CEEB;
                    skinDark      = 0xff1E90FF;
                    // Blue-white crystal: blend with actual color tint
                    paint.setShader(new RadialGradient(
                        cx - r*0.32f, cy - r*0.35f, r*1.15f,
                        new int[]{0xffFFFFFF, 0xffB3E5FC, blend(color,0xff1E90FF,0.6f), blend(color,0xff000088,0.5f)},
                        new float[]{0f, 0.2f, 0.6f, 1f},
                        Shader.TileMode.CLAMP));
                    break;
                case "flame":
                    paint.setShader(new RadialGradient(
                        cx - r*0.32f, cy - r*0.35f, r*1.15f,
                        new int[]{0xffFFFFFF, 0xffFFE066, blend(color,0xffFF4500,0.6f), blend(color,0xff3D0000,0.5f)},
                        new float[]{0f, 0.2f, 0.6f, 1f},
                        Shader.TileMode.CLAMP));
                    break;
                default: // classic — 3D sphere with piece color
                    paint.setShader(new RadialGradient(
                        cx - r*0.32f, cy - r*0.35f, r*1.15f,
                        new int[]{0xffFFFFFF,
                            blend(color, 0xffFFFFFF, 0.55f),
                            color,
                            blend(color, 0xff000000, 0.32f)},
                        new float[]{0f, 0.18f, 0.6f, 1f},
                        Shader.TileMode.CLAMP));
                    break;
            }
            canvas.drawCircle(cx, cy, r, paint);
            paint.setShader(null);

            // Gold outer ring
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(r*0.22f);
            paint.setColor(GOLD);
            canvas.drawCircle(cx, cy, r, paint);
            paint.setStyle(Paint.Style.FILL);

            // Specular highlight
            paint.setColor(0xccFFFFFF);
            canvas.drawCircle(cx - r*0.32f, cy - r*0.34f, r*0.22f, paint);
        }

        private float[] piecePos(JSONObject piece, int left, int top, float cell) {
            int seat = piece.optInt("seat");
            int pi   = pieceIdx(piece.optString("pieceId"));
            String state = piece.optString("state");
            int progress = piece.optInt("progress", -1);
            if ("yard".equals(state) || progress < 0)
                return yardPos(seat, pi, left, top, cell);
            if ("finished".equals(state) || progress >= 57)
                return offset(left+7.5f*cell, top+7.5f*cell, pi, cell);
            if ("home".equals(state) || progress > 51) {
                int li = Math.max(0, Math.min(4, progress-52));
                int[] p = HOME_LANES[Math.max(0,Math.min(3,seat))][li];
                return offset(left+(p[0]+0.5f)*cell, top+(p[1]+0.5f)*cell, pi, cell*0.4f);
            }
            int ti = piece.optInt("trackIndex", -1);
            if (ti < 0 || ti >= PATH.length) ti = (seatStart(seat) + progress) % PATH.length;
            int[] p = PATH[ti];
            return offset(left+(p[0]+0.5f)*cell, top+(p[1]+0.5f)*cell, pi, cell*0.34f);
        }

        private float[] yardPos(int seat, int idx, int left, int top, float cell) {
            int[][] bases = {{0,9},{0,0},{9,0},{9,9}};
            int s = Math.max(0, Math.min(3, seat));
            float[][] slots = {{2.1f,2.1f},{3.9f,2.1f},{2.1f,3.9f},{3.9f,3.9f}};
            return new float[]{
                left + (bases[s][0] + slots[idx%4][0]) * cell,
                top  + (bases[s][1] + slots[idx%4][1]) * cell
            };
        }

        private float[] offset(float x, float y, int idx, float amt) {
            float d = Math.max(3f, amt*0.16f);
            return new float[]{x+(idx%2==0?-d:d), y+(idx<2?-d:d)};
        }

        private int pieceIdx(String id) {
            if (id==null||id.isEmpty()) return 0;
            char c = id.charAt(id.length()-1);
            return c>='0'&&c<='3' ? c-'0' : 0;
        }

        private int seatStart(int s) {
            int[] starts = {0,13,26,39};
            return starts[Math.max(0,Math.min(3,s))];
        }

        private int seatColor(int s) {
            int[] c = {ThemeManager.RED,ThemeManager.BLUE,ThemeManager.YELLOW,ThemeManager.GREEN};
            return c[Math.max(0,Math.min(3,s))];
        }

        private boolean contains(JSONArray a, String v) {
            if (a==null||v==null) return false;
            for (int i=0; i<a.length(); i++) if (v.equals(a.optString(i))) return true;
            return false;
        }

        private void drawEmpty(Canvas canvas, int left, int top, int size) {
            if (snapshot != null) return;
            rect.set(left+size*0.16f, top+size*0.39f, left+size*0.84f, top+size*0.61f);
            paint.setColor(0xE6091428);
            canvas.drawRoundRect(rect, size*0.05f, size*0.05f, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, size*0.006f)); paint.setColor(GOLD);
            canvas.drawRoundRect(rect, size*0.05f, size*0.05f, paint);
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(GOLD);
            paint.setTypeface(Typeface.DEFAULT_BOLD);
            paint.setTextSize(size*0.047f);
            paint.setTextAlign(Paint.Align.CENTER);
            canvas.drawText("Waiting for match", left+size/2f, top+size*0.49f, paint);
            paint.setTextSize(size*0.032f); paint.setColor(0xffC0C7D2);
            canvas.drawText("Setting up your game...", left+size/2f, top+size*0.55f, paint);
            paint.setTextAlign(Paint.Align.LEFT);
        }

        private void drawStar(Canvas canvas, float cx, float cy, float radius, int color) {
            Path star = new Path();
            for (int i=0; i<10; i++) {
                double angle = -Math.PI/2 + i*Math.PI/5;
                float rr = i%2==0 ? radius : radius*0.45f;
                float x = cx+(float)Math.cos(angle)*rr, y = cy+(float)Math.sin(angle)*rr;
                if (i==0) star.moveTo(x,y); else star.lineTo(x,y);
            }
            star.close();
            paint.setColor(color); canvas.drawPath(star, paint);
        }
    }
}
