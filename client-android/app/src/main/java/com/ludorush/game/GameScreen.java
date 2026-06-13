package com.ludorush.game;

import android.animation.ValueAnimator;
import android.app.Activity;
import android.app.AlertDialog;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.List;

public final class GameScreen extends BaseScreen {
    private TextView statusText;
    private DiceView diceView;
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

    public GameScreen(Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    public void updateSnapshot(JSONObject snap, String playerId) {
        this.snapshot = snap;
        if (board != null) board.setSnapshot(snap, playerId);
        if (statusText != null) refreshUi();
    }

    public void setStatus(String text) {
        if (statusText != null) statusText.setText(text);
    }

    /** Called by MainActivity when a dice roll event arrives.
     *  Dice animation is already handled via updateSnapshot/refreshUi;
     *  this stub exists for backward compatibility. */
    public void setLastRoll(int value, boolean myRoll) {
        // no-op: animation is driven by snapshot diceValue in refreshUi()
    }

    @Override
    public View createView() {
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(theme.bgPage());
        root.setPadding(dp(10), dp(8), dp(10), dp(8));

        // ── Header ────────────────────────────────────────────────────────────
        LinearLayout header = new LinearLayout(activity);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        root.addView(header, lp(-1, dp(48), 0, 0, 0, 0));

        Button back = new Button(activity);
        back.setAllCaps(false);
        back.setText("‹");
        back.setTextColor(ThemeManager.GOLD);
        back.setTextSize(26);
        back.setTypeface(Typeface.DEFAULT_BOLD);
        back.setBackground(null);
        back.setOnClickListener(v -> showLeaveConfirmation());
        header.addView(back, lp(dp(48), dp(48)));

        TextView title = text("LIVE MATCH", 15, ThemeManager.GOLD, Typeface.BOLD);
        title.setLetterSpacing(0.1f);
        LinearLayout.LayoutParams titleLp = new LinearLayout.LayoutParams(0, -2, 1);
        header.addView(title, titleLp);

        Button resignBtn = new Button(activity);
        resignBtn.setAllCaps(false);
        resignBtn.setText("Resign");
        resignBtn.setTextColor(ThemeManager.RED);
        resignBtn.setTextSize(12);
        resignBtn.setTypeface(Typeface.DEFAULT_BOLD);
        resignBtn.setBackground(card(theme.bgDanger(), dp(12), theme.strokeDanger()));
        resignBtn.setPadding(dp(10), dp(4), dp(10), dp(4));
        resignBtn.setOnClickListener(v -> showResignConfirmation());
        header.addView(resignBtn);

        // ── Opponent strip ────────────────────────────────────────────────────
        opponentStrip = new LinearLayout(activity);
        opponentStrip.setOrientation(LinearLayout.HORIZONTAL);
        opponentStrip.setGravity(Gravity.CENTER);
        root.addView(opponentStrip, lp(-1, -2, 0, 0, 0, dp(6)));

        // ── Board ─────────────────────────────────────────────────────────────
        board = new BoardView(activity);
        board.setTapListener(pieceId -> callback.movePiece(pieceId));
        LinearLayout.LayoutParams boardLp = new LinearLayout.LayoutParams(-1, 0);
        boardLp.weight = 1;
        boardLp.setMargins(0, 0, 0, dp(6));
        root.addView(board, boardLp);

        // ── My row ────────────────────────────────────────────────────────────
        myRow = new LinearLayout(activity);
        myRow.setOrientation(LinearLayout.HORIZONTAL);
        myRow.setGravity(Gravity.CENTER_VERTICAL);
        myRow.setPadding(dp(12), dp(8), dp(12), dp(8));
        myRow.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));
        root.addView(myRow, lp(-1, -2, 0, 0, 0, dp(6)));

        myColorDot = new View(activity);
        myColorDot.setBackground(circle(seatColor(0)));
        myRow.addView(myColorDot, lp(dp(28), dp(28), 0, 0, dp(10), 0));

        LinearLayout myInfo = new LinearLayout(activity);
        myInfo.setOrientation(LinearLayout.VERTICAL);
        myNameText = text(callback.getDisplayName(), 14, theme.txtPrimary(), Typeface.BOLD);
        movesText = text("Waiting...", 11, theme.txtMuted(), Typeface.NORMAL);
        myInfo.addView(myNameText);
        myInfo.addView(movesText);
        myRow.addView(myInfo, new LinearLayout.LayoutParams(-2, -2));

        View spacer = new View(activity);
        myRow.addView(spacer, new LinearLayout.LayoutParams(0, 0, 1));

        diceView = new DiceView(activity);
        myRow.addView(diceView, lp(dp(44), dp(44)));

        // ── Status bar ────────────────────────────────────────────────────────
        statusText = text("Waiting for match...", 13, theme.txtSecondary(), Typeface.BOLD);
        statusText.setGravity(Gravity.CENTER);
        statusText.setPadding(dp(12), dp(10), dp(12), dp(10));
        statusText.setBackground(card(theme.bgMetric(), dp(14), theme.strokeCardAlt()));
        root.addView(statusText, lp(-1, -2, 0, 0, 0, dp(6)));

        // ── Action buttons ────────────────────────────────────────────────────
        LinearLayout actions = new LinearLayout(activity);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(actions, lp(-1, dp(56)));

        rollButton = actionButton("🎲  Roll Dice", ThemeManager.RED, 0xffF9502E);
        rollButton.setTextSize(15);
        rollButton.setOnClickListener(v -> callback.rollDice());
        LinearLayout.LayoutParams rp = new LinearLayout.LayoutParams(0, -1, 1);
        rp.setMargins(0, 0, dp(5), 0);
        actions.addView(rollButton, rp);

        moveButton = actionButton("⚡  Auto Move", ThemeManager.NAVY, ThemeManager.BLUE);
        moveButton.setTextSize(15);
        moveButton.setOnClickListener(v -> callback.moveBestPiece());
        LinearLayout.LayoutParams mp = new LinearLayout.LayoutParams(0, -1, 1);
        mp.setMargins(dp(5), 0, 0, 0);
        actions.addView(moveButton, mp);

        return root;
    }

    // ── Dialogs ───────────────────────────────────────────────────────────────

    private void showLeaveConfirmation() {
        new AlertDialog.Builder(activity)
                .setTitle("Leave Match?")
                .setMessage("Leaving during a match counts as a resignation. Are you sure?")
                .setPositiveButton("Leave & Resign", (d, w) -> {
                    callback.resign();
                    callback.goBack();
                })
                .setNegativeButton("Stay", null)
                .show();
    }

    private void showResignConfirmation() {
        new AlertDialog.Builder(activity)
                .setTitle("Resign Match?")
                .setMessage("This will end the current match and count as a loss.")
                .setPositiveButton("Resign", (d, w) -> {
                    callback.resign();
                    callback.navigateTo("home");
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    // ── UI refresh ────────────────────────────────────────────────────────────

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
                    if (canMove) board.startPulse();
                    updateButtonStates(snapshot);
                });
            } else {
                diceView.setValue(dice);
                board.stopPulse();
            }
            prevDiceValue = dice;
        }

        updateButtonStates(snapshot);
        updateMovesText(moves);

        if ("finished".equals(status)) {
            statusText.setText(winnerText());
            board.stopPulse();
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

    private void updateButtonStates(JSONObject snap) {
        if (snap == null) return;
        String status   = snap.optString("status", "waiting");
        int dice        = snap.optInt("diceValue", 0);
        JSONArray moves = snap.optJSONArray("availableMoves");
        int mySeat      = mySeat();
        int turnSeat    = snap.optInt("currentTurnSeat", -1);
        boolean myTurn  = mySeat >= 0 && mySeat == turnSeat && "playing".equals(status);
        boolean canRoll = myTurn && dice == 0 && !diceAnimating;
        boolean canMove = myTurn && dice > 0 && moves != null && moves.length() > 0;

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
            int seat   = s.optInt("seat", 0);
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

            String name = s.optString("displayName", "Player");
            String sub  = active ? "▶ TURN" : (s.optBoolean("isBot") ? "Bot" : "Online");
            int color   = seatColor(seat);

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

            TextView nameV = text(name, 11, theme.txtPrimary(), Typeface.BOLD);
            nameV.setSingleLine(true);
            nameV.setGravity(Gravity.CENTER);
            card.addView(nameV);

            TextView subV = text(sub, 10, active ? color : theme.txtMuted(), Typeface.BOLD);
            subV.setGravity(Gravity.CENTER);
            card.addView(subV);

            LinearLayout.LayoutParams cp = new LinearLayout.LayoutParams(0, -2, 1);
            cp.setMargins(dp(3), 0, dp(3), 0);
            opponentStrip.addView(card, cp);
        }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

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

    private String seatName(int seatIndex) {
        if (snapshot == null) return "Player";
        JSONArray seats = snapshot.optJSONArray("seats");
        if (seats == null) return "Seat " + (seatIndex + 1);
        for (int i = 0; i < seats.length(); i++) {
            JSONObject s = seats.optJSONObject(i);
            if (s != null && s.optInt("seat", -1) == seatIndex) {
                if (callback.getPlayerId() != null &&
                    callback.getPlayerId().equals(s.optString("playerId"))) return "You";
                return s.optString("displayName", "Seat " + (seatIndex + 1));
            }
        }
        return "Seat " + (seatIndex + 1);
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
    // Premium dice canvas
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
                final boolean last = (i == seq.length - 1);
                uiHandler.postDelayed(() -> {
                    displayValue = face;
                    invalidate();
                    if (last && onDone != null) onDone.run();
                }, 55L * (i + 1));
            }
        }

        @Override protected void onDraw(Canvas canvas) {
            int w = getWidth(), h = getHeight();
            float s = Math.min(w, h);
            float pad = s * 0.1f;
            float left = (w - s) / 2f + pad, top = (h - s) / 2f + pad;
            float right = (w + s) / 2f - pad, bottom = (h + s) / 2f - pad;
            float cw = right - left, ch = bottom - top;
            float rad = cw * 0.24f;

            // soft drop shadow
            r.set(left, top + s * 0.05f, right, bottom + s * 0.05f);
            paint.setColor(0x40000000);
            canvas.drawRoundRect(r, rad, rad, paint);

            // ivory face with a subtle top-to-bottom sheen
            r.set(left, top, right, bottom);
            paint.setShader(new LinearGradient(left, top, right, bottom,
                0xffFFFDF4, 0xffEADFC0, Shader.TileMode.CLAMP));
            canvas.drawRoundRect(r, rad, rad, paint);
            paint.setShader(null);

            // gold rim
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(s * 0.06f);
            paint.setColor(ThemeManager.GOLD);
            canvas.drawRoundRect(r, rad, rad, paint);
            paint.setStyle(Paint.Style.FILL);

            float cx = left + cw / 2f, cy = top + ch / 2f;

            // no active roll yet → a single muted dash
            if (displayValue < 1 || displayValue > 6) {
                paint.setColor(0xff9A8A5E);
                paint.setStrokeWidth(s * 0.05f);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeCap(Paint.Cap.ROUND);
                canvas.drawLine(cx - cw * 0.16f, cy, cx + cw * 0.16f, cy, paint);
                paint.setStyle(Paint.Style.FILL);
                return;
            }

            // navy pips in the standard face arrangement
            float pr = cw * 0.1f;
            float lx = left + cw * 0.29f, rx = right - cw * 0.29f;
            float ty = top + ch * 0.29f, by = bottom - ch * 0.29f;
            paint.setColor(ThemeManager.NAVY);
            boolean diag   = displayValue == 2 || displayValue == 3;
            boolean four   = displayValue >= 4;
            boolean mid    = displayValue % 2 == 1;
            boolean sixMid = displayValue == 6;
            if (four) {
                canvas.drawCircle(lx, ty, pr, paint);
                canvas.drawCircle(rx, ty, pr, paint);
                canvas.drawCircle(lx, by, pr, paint);
                canvas.drawCircle(rx, by, pr, paint);
            } else if (diag) {
                canvas.drawCircle(lx, ty, pr, paint);
                canvas.drawCircle(rx, by, pr, paint);
            }
            if (sixMid) {
                canvas.drawCircle(lx, cy, pr, paint);
                canvas.drawCircle(rx, cy, pr, paint);
            }
            if (mid) {
                canvas.drawCircle(cx, cy, pr, paint);
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // Board canvas
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

        // Royal Gold board surfaces
        private static final int NAVY    = ThemeManager.NAVY_DEEP;
        private static final int IVORY   = 0xffF5F0DC;
        private static final int GOLD    = ThemeManager.GOLD;
        private static final int GOLD_DK = ThemeManager.GOLD_DARK;

        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF  rect  = new RectF();
        private JSONObject snapshot;
        private String playerId;

        // Tap-to-move support
        interface PieceTapListener { void onPieceTap(String pieceId); }
        private PieceTapListener tapListener;
        public void setTapListener(PieceTapListener l) { tapListener = l; }

        private static final class PieceHit {
            final String pieceId;
            final float cx, cy, r;
            final boolean legal;
            PieceHit(String id, float cx, float cy, float r, boolean legal) {
                this.pieceId = id; this.cx = cx; this.cy = cy; this.r = r; this.legal = legal;
            }
        }
        private final List<PieceHit> pieceHits = new ArrayList<>();

        // Pulse animation
        private float pulsePhase = 1f;
        private ValueAnimator pulseAnim;

        public BoardView(Activity activity) {
            super(activity);
            setMinimumHeight(600);
        }

        public void setSnapshot(JSONObject snapshot, String playerId) {
            this.snapshot = snapshot;
            this.playerId = playerId;
            invalidate();
        }

        public void startPulse() {
            if (pulseAnim != null && pulseAnim.isRunning()) return;
            pulseAnim = ValueAnimator.ofFloat(0.2f, 1f);
            pulseAnim.setDuration(600);
            pulseAnim.setRepeatMode(ValueAnimator.REVERSE);
            pulseAnim.setRepeatCount(ValueAnimator.INFINITE);
            pulseAnim.addUpdateListener(a -> { pulsePhase = (float) a.getAnimatedValue(); invalidate(); });
            pulseAnim.start();
        }

        public void stopPulse() {
            if (pulseAnim != null) { pulseAnim.cancel(); pulseAnim = null; }
            pulsePhase = 1f;
            invalidate();
        }

        @Override
        public boolean onTouchEvent(MotionEvent event) {
            if (event.getAction() != MotionEvent.ACTION_UP) return true;
            float tx = event.getX(), ty = event.getY();
            PieceHit best = null;
            float bestDist = Float.MAX_VALUE;
            for (PieceHit h : pieceHits) {
                float d = (float) Math.sqrt((tx - h.cx) * (tx - h.cx) + (ty - h.cy) * (ty - h.cy));
                if (h.legal && d < h.r * 2.8f && d < bestDist) { bestDist = d; best = h; }
            }
            if (best != null && tapListener != null) {
                tapListener.onPieceTap(best.pieceId);
                stopPulse();
            }
            return true;
        }

        @Override protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
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
            int aa = (int) (((a >>> 24) & 0xff) * ia + ((b >>> 24) & 0xff) * t);
            int rr = (int) (((a >> 16) & 0xff) * ia + ((b >> 16) & 0xff) * t);
            int gg = (int) (((a >> 8)  & 0xff) * ia + ((b >> 8)  & 0xff) * t);
            int bb = (int) ((a & 0xff) * ia + (b & 0xff) * t);
            return (aa << 24) | (rr << 16) | (gg << 8) | bb;
        }

        private void drawShell(Canvas canvas, int left, int top, int size) {
            rect.set(left, top, left + size, top + size);
            paint.setColor(NAVY);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.STROKE);
            float outerW = Math.max(4f, size * 0.018f);
            float innerW = Math.max(2f, size * 0.009f);
            float gap    = Math.max(2f, size * 0.009f);
            paint.setStrokeWidth(outerW);
            paint.setColor(GOLD);
            canvas.drawRect(rect, paint);
            float inset = outerW / 2f + gap + innerW / 2f;
            rect.set(left + inset, top + inset, left + size - inset, top + size - inset);
            paint.setStrokeWidth(innerW);
            paint.setColor(GOLD);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawGridLines(Canvas canvas, int left, int top, float cell) {
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(1f, cell * 0.02f));
            paint.setColor(0x18000000);
            for (int i = 0; i <= 15; i++) {
                float p = i * cell;
                canvas.drawLine(left + p, top, left + p, top + 15 * cell, paint);
                canvas.drawLine(left, top + p, left + 15 * cell, top + p, paint);
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
            float x1 = left + gx * cell, y1 = top + gy * cell;
            float x2 = left + (gx + 6) * cell, y2 = top + (gy + 6) * cell;
            rect.set(x1, y1, x2, y2);
            paint.setColor(color);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(cell * 0.1f);
            paint.setColor(GOLD);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);
            float ins = cell * 0.85f;
            rect.set(x1 + ins, y1 + ins, x2 - ins, y2 - ins);
            paint.setColor(blend(color, 0xff04080F, 0.82f));
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(cell * 0.05f);
            paint.setColor(0x99D4AF37);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);
            float cx = (x1 + x2) / 2f, cy = (y1 + y2) / 2f;
            float off = cell * 0.9f, r = cell * 0.45f;
            for (int i = 0; i < 4; i++) {
                float px = cx + (i % 2 == 0 ? -off : off);
                float py = cy + (i < 2 ? -off : off);
                paint.setColor(0x55000000);
                canvas.drawCircle(px, py + r * 0.12f, r, paint);
                paint.setShader(new LinearGradient(px, py - r, px, py + r,
                    blend(color, 0xffFFFFFF, 0.55f), blend(color, 0xff000000, 0.3f),
                    Shader.TileMode.CLAMP));
                canvas.drawCircle(px, py, r, paint);
                paint.setShader(null);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(cell * 0.06f);
                paint.setColor(GOLD);
                canvas.drawCircle(px, py, r, paint);
                paint.setStyle(Paint.Style.FILL);
                paint.setColor(0xccFFFFFF);
                canvas.drawCircle(px - r * 0.34f, py - r * 0.36f, r * 0.2f, paint);
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
                    left + (p[0] + 0.5f) * cell,
                    top  + (p[1] + 0.5f) * cell,
                    cell * 0.27f,
                    GOLD);
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
            float cx = left + 7.5f * cell, cy = top + 7.5f * cell;
            float x6 = left + 6 * cell, x9 = left + 9 * cell;
            float y6 = top + 6 * cell,  y9 = top + 9 * cell;
            rect.set(x6, y6, x9, y9);
            paint.setColor(0xffFFF8E8);
            canvas.drawRect(rect, paint);
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
            paint.setStrokeWidth(cell * 0.05f);
            paint.setColor(0x88D4AF37);
            canvas.drawLine(x6, y6, x9, y9, paint);
            canvas.drawLine(x6, y9, x9, y6, paint);
            paint.setStrokeWidth(cell * 0.22f);
            paint.setColor(GOLD);
            canvas.drawCircle(cx, cy, cell * 0.98f, paint);
            paint.setStrokeWidth(cell * 0.04f);
            paint.setColor(GOLD_DK);
            canvas.drawCircle(cx, cy, cell * 1.12f, paint);
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0xffFFF8E8);
            canvas.drawCircle(cx, cy, cell * 0.66f, paint);
            drawGoldStar6(canvas, cx, cy, cell * 0.6f);
        }

        private void drawGoldStar6(Canvas canvas, float cx, float cy, float r) {
            Path s = new Path();
            for (int i = 0; i < 12; i++) {
                double angle = -Math.PI / 2 + i * Math.PI / 6;
                float rr = i % 2 == 0 ? r : r * 0.5f;
                float x = cx + (float) Math.cos(angle) * rr;
                float y = cy + (float) Math.sin(angle) * rr;
                if (i == 0) s.moveTo(x, y); else s.lineTo(x, y);
            }
            s.close();
            paint.setColor(GOLD);
            canvas.drawPath(s, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(r * 0.08f);
            paint.setColor(GOLD_DK);
            canvas.drawPath(s, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawCell(Canvas canvas, int left, int top, float cell,
                              int gx, int gy, int fill, int stroke) {
            float pad = cell * 0.03f;
            rect.set(left + gx * cell + pad,       top + gy * cell + pad,
                     left + (gx + 1) * cell - pad, top + (gy + 1) * cell - pad);
            paint.setColor(fill);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(1f, cell * 0.04f));
            paint.setColor(stroke);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawPieces(Canvas canvas, int left, int top, float cell) {
            pieceHits.clear();
            if (snapshot == null) return;
            JSONArray pieces = snapshot.optJSONArray("pieces");
            if (pieces == null) return;
            JSONArray avail = snapshot.optJSONArray("availableMoves");
            int activeSeat  = snapshot.optInt("currentTurnSeat", -1);
            for (int i = 0; i < pieces.length(); i++) {
                JSONObject p = pieces.optJSONObject(i);
                if (p == null) continue;
                float[] pos = piecePos(p, left, top, cell);
                int seat    = p.optInt("seat");
                boolean legal = contains(avail, p.optString("pieceId"));
                pieceHits.add(new PieceHit(p.optString("pieceId"), pos[0], pos[1], cell * 0.38f, legal));
                drawPiece(canvas, pos[0], pos[1], cell * 0.38f,
                    seatColor(seat), legal, activeSeat == seat);
            }
        }

        private void drawPiece(Canvas canvas, float cx, float cy, float r,
                               int color, boolean legal, boolean active) {
            if (legal || active) {
                paint.setStyle(Paint.Style.STROKE);
                float ringAlpha = legal ? pulsePhase : 0.55f;
                int haloColor = (int)(ringAlpha * 220) << 24 | (GOLD & 0x00FFFFFF);
                paint.setStrokeWidth(legal ? r * 0.36f : r * 0.18f);
                paint.setColor(haloColor);
                canvas.drawCircle(cx, cy, r * (legal ? 1.65f : 1.35f), paint);
                paint.setStyle(Paint.Style.FILL);
            }
            // drop shadow
            paint.setColor(0x44000000);
            canvas.drawCircle(cx + r * 0.16f, cy + r * 0.2f, r, paint);
            // gradient body
            paint.setShader(new LinearGradient(cx, cy - r, cx, cy + r,
                blend(color, 0xffFFFFFF, 0.38f), blend(color, 0xff000000, 0.28f),
                Shader.TileMode.CLAMP));
            canvas.drawCircle(cx, cy, r, paint);
            paint.setShader(null);
            // gold outer ring
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(r * 0.22f);
            paint.setColor(GOLD);
            canvas.drawCircle(cx, cy, r, paint);
            paint.setStyle(Paint.Style.FILL);
            // white highlight dot
            paint.setColor(0xccFFFFFF);
            canvas.drawCircle(cx - r * 0.32f, cy - r * 0.34f, r * 0.22f, paint);
        }

        private float[] piecePos(JSONObject piece, int left, int top, float cell) {
            int seat     = piece.optInt("seat");
            int pi       = pieceIdx(piece.optString("pieceId"));
            String state = piece.optString("state");
            int progress = piece.optInt("progress", -1);
            if ("yard".equals(state) || progress < 0)
                return yardPos(seat, pi, left, top, cell);
            if ("finished".equals(state) || progress >= 57)
                return offset(left + 7.5f * cell, top + 7.5f * cell, pi, cell);
            if ("home".equals(state) || progress > 51) {
                int li = Math.max(0, Math.min(4, progress - 52));
                int[] p = HOME_LANES[Math.max(0, Math.min(3, seat))][li];
                return offset(left + (p[0] + 0.5f) * cell, top + (p[1] + 0.5f) * cell, pi, cell * 0.4f);
            }
            int ti = piece.optInt("trackIndex", -1);
            if (ti < 0 || ti >= PATH.length) ti = (seatStart