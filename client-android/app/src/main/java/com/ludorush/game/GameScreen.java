package com.ludorush.game;

import android.app.Activity;
import android.app.AlertDialog;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RadialGradient;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;

public final class GameScreen extends BaseScreen {
    private TextView statusText;
    private TextView diceText;
    private TextView turnText;
    private TextView movesText;
    private LinearLayout playerStrip;
    private BoardView board;
    private Button rollButton;
    private Button moveButton;
    private JSONObject snapshot;

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

    @Override
    public View createView() {
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(theme.bgPage());
        root.setPadding(dp(14), dp(14), dp(14), dp(10));

        // ── Header ────────────────────────────────────────────────────────────
        LinearLayout header = new LinearLayout(activity);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        header.setPadding(dp(2), dp(4), dp(8), dp(8));
        root.addView(header, lp(-1, -2, 0, 0, 0, dp(8)));

        Button back = new Button(activity);
        back.setAllCaps(false);
        back.setText("‹");
        back.setTextColor(theme.txtPrimary());
        back.setTextSize(26);
        back.setTypeface(Typeface.DEFAULT_BOLD);
        back.setBackground(null);
        back.setOnClickListener(v -> showLeaveConfirmation());
        header.addView(back, lp(dp(48), dp(48)));

        TextView title = text("Live Match", 18, theme.txtPrimary(), Typeface.BOLD);
        header.addView(title, new LinearLayout.LayoutParams(0, -2, 1));

        // Resign button (right side)
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

        // ── Stats row ─────────────────────────────────────────────────────────
        LinearLayout statsRow = new LinearLayout(activity);
        statsRow.setOrientation(LinearLayout.HORIZONTAL);
        root.addView(statsRow, lp(-1, -2, 0, 0, 0, dp(8)));

        diceText  = metric("DICE",  "—");
        turnText  = metric("TURN",  "Wait");
        movesText = metric("MOVES", "0");

        LinearLayout.LayoutParams mLp = new LinearLayout.LayoutParams(0, dp(64), 1);
        mLp.setMargins(dp(2), 0, dp(2), 0);
        statsRow.addView(diceText,  mLp);
        statsRow.addView(turnText,  new LinearLayout.LayoutParams(0, dp(64), 1));
        statsRow.addView(movesText, new LinearLayout.LayoutParams(0, dp(64), 1));

        // ── Player strip ──────────────────────────────────────────────────────
        playerStrip = new LinearLayout(activity);
        playerStrip.setOrientation(LinearLayout.HORIZONTAL);
        playerStrip.setGravity(Gravity.CENTER);
        root.addView(playerStrip, lp(-1, -2, 0, 0, 0, dp(8)));

        // ── Board ─────────────────────────────────────────────────────────────
        board = new BoardView(activity);
        LinearLayout.LayoutParams boardLp = new LinearLayout.LayoutParams(-1, 0);
        boardLp.weight = 1;
        boardLp.setMargins(0, 0, 0, dp(10));
        root.addView(board, boardLp);

        // ── Status bar ────────────────────────────────────────────────────────
        statusText = text("Waiting for match...", 14, theme.txtSecondary(), Typeface.BOLD);
        statusText.setPadding(dp(14), dp(12), dp(14), dp(12));
        statusText.setBackground(card(theme.bgCard(), dp(14), theme.strokeCard()));
        root.addView(statusText, lp(-1, -2, 0, 0, 0, dp(10)));

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

        moveButton = actionButton("⚡  Move Best", ThemeManager.BLUE, ThemeManager.BLUE_LIGHT);
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
        String status  = snapshot.optString("status", "waiting");
        int dice       = snapshot.optInt("diceValue", 0);
        JSONArray moves = snapshot.optJSONArray("availableMoves");
        int turnSeat   = snapshot.optInt("currentTurnSeat", -1);
        int mySeat     = mySeat();
        boolean myTurn = mySeat >= 0 && mySeat == turnSeat && "playing".equals(status);

        diceText.setText("DICE\n"  + (dice == 0 ? "—" : dice));
        turnText.setText("TURN\n"  + (myTurn ? "You" : seatName(turnSeat)));
        movesText.setText("MOVES\n" + (moves == null ? 0 : moves.length()));

        boolean canRoll = myTurn && dice == 0;
        boolean canMove = myTurn && dice > 0 && moves != null && moves.length() > 0;

        rollButton.setEnabled(canRoll);
        moveButton.setEnabled(canMove);
        rollButton.setAlpha(canRoll ? 1f : 0.38f);
        moveButton.setAlpha(canMove ? 1f : 0.38f);

        if ("finished".equals(status)) {
            statusText.setText(winnerText());
        } else if (canRoll) {
            statusText.setText("Your turn — Roll the dice!");
        } else if (canMove) {
            statusText.setText("Rolled " + dice + " — Tap Move Best.");
        } else if (myTurn) {
            statusText.setText("No legal moves. Waiting for turn advance.");
        } else {
            statusText.setText("Waiting for " + seatName(turnSeat) + "...");
        }

        renderPlayers();
    }

    private void renderPlayers() {
        playerStrip.removeAllViews();
        JSONArray seats = snapshot != null ? snapshot.optJSONArray("seats") : null;
        if (seats == null) return;
        int activeSeat = snapshot.optInt("currentTurnSeat", -1);
        String myId = callback.getPlayerId();

        for (int i = 0; i < seats.length(); i++) {
            JSONObject s = seats.optJSONObject(i);
            if (s == null) continue;
            int seat    = s.optInt("seat", 0);
            boolean isMe   = myId != null && myId.equals(s.optString("playerId"));
            boolean active = activeSeat == seat;
            String name  = isMe ? "You" : s.optString("displayName", "Player");
            String label = s.optBoolean("isBot") ? "Bot" : "Online";

            LinearLayout card = new LinearLayout(activity);
            card.setOrientation(LinearLayout.VERTICAL);
            card.setGravity(Gravity.CENTER);
            card.setPadding(dp(8), dp(6), dp(8), dp(6));
            card.setBackground(card(
                active ? theme.bgSel() : theme.bgCard(),
                dp(14),
                active ? seatColor(seat) : theme.strokeCardAlt()));

            View dot = new View(activity);
            dot.setBackground(circle(seatColor(seat)));
            card.addView(dot, lp(dp(20), dp(20), 0, 0, 0, dp(3)));

            TextView nameV = text(name, 11, theme.txtPrimary(), Typeface.BOLD);
            nameV.setSingleLine(true);
            nameV.setGravity(Gravity.CENTER);
            card.addView(nameV);

            TextView sub = text(active ? "Turn" : label, 10, theme.txtMuted(), Typeface.NORMAL);
            sub.setGravity(Gravity.CENTER);
            card.addView(sub);

            LinearLayout.LayoutParams cp = new LinearLayout.LayoutParams(0, -2, 1);
            cp.setMargins(dp(3), 0, dp(3), 0);
            playerStrip.addView(card, cp);
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

        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF  rect  = new RectF();
        private JSONObject snapshot;
        private String playerId;

        public BoardView(Activity activity) {
            super(activity);
            setMinimumHeight(600);
        }

        public void setSnapshot(JSONObject snapshot, String playerId) {
            this.snapshot = snapshot;
            this.playerId = playerId;
            invalidate();
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
            drawCenter(canvas, left, top, cell);
            drawPieces(canvas, left, top, cell);
            drawEmpty(canvas, left, top, size);
        }

        private void drawShell(Canvas canvas, int left, int top, int size) {
            rect.set(left, top, left + size, top + size);
            paint.setColor(0xffF5E6C8);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(4, size * 0.018f));
            paint.setColor(0xff5C3D2E);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawBases(Canvas canvas, int left, int top, float cell) {
            drawBase(canvas, left, top, cell, 0, 9, 0xffE8293E);
            drawBase(canvas, left, top, cell, 0, 0, 0xff1E88E5);
            drawBase(canvas, left, top, cell, 9, 0, 0xffF9A825);
            drawBase(canvas, left, top, cell, 9, 9, 0xff43A047);
        }

        private void drawBase(Canvas canvas, int left, int top, float cell,
                              int gx, int gy, int color) {
            float x1 = left + gx * cell, y1 = top + gy * cell;
            float x2 = left + (gx + 6) * cell, y2 = top + (gy + 6) * cell;
            rect.set(x1, y1, x2, y2);
            paint.setColor(color);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(cell * 0.08f);
            paint.setColor(0x33000000);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);
            float ins = cell * 0.85f;
            rect.set(x1 + ins, y1 + ins, x2 - ins, y2 - ins);
            paint.setColor(0xffFFF8EE);
            canvas.drawRect(rect, paint);
            float cx = (x1 + x2) / 2f, cy = (y1 + y2) / 2f;
            float off = cell * 0.9f, r = cell * 0.45f;
            for (int i = 0; i < 4; i++) {
                float px = cx + (i % 2 == 0 ? -off : off);
                float py = cy + (i < 2 ? -off : off);
                paint.setColor(0xffFFFFFF);
                canvas.drawCircle(px, py, r, paint);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(cell * 0.07f);
                paint.setColor(color);
                canvas.drawCircle(px, py, r, paint);
                paint.setStyle(Paint.Style.FILL);
            }
        }

        private void drawTrack(Canvas canvas, int left, int top, float cell) {
            int[] si = {0, 13, 26, 39};
            int[] sc = {0xffE8293E, 0xff1E88E5, 0xffF9A825, 0xff43A047};
            for (int i = 0; i < PATH.length; i++) {
                int[] p = PATH[i];
                int fill = 0xffFFFFFF, stroke = 0x22000000;
                for (int s = 0; s < si.length; s++) {
                    if (i == si[s]) { fill = sc[s]; stroke = 0x44000000; break; }
                }
                drawCell(canvas, left, top, cell, p[0], p[1], fill, stroke);
            }
            for (int[] p : SAFE) {
                boolean isStart = false;
                for (int s : si) {
                    if (PATH[s][0] == p[0] && PATH[s][1] == p[1]) { isStart = true; break; }
                }
                drawStar(canvas,
                    left + (p[0] + 0.5f) * cell,
                    top  + (p[1] + 0.5f) * cell,
                    cell * 0.25f,
                    isStart ? 0xccFFFFFF : 0xff888888);
            }
        }

        private void drawHomeLanes(Canvas canvas, int left, int top, float cell) {
            int[] f = {0xffF8B4BF, 0xffA8D8EA, 0xffFFF0A0, 0xffA8E6CF};
            int[] s = {0xffE8293E, 0xff1E88E5, 0xffF9A825, 0xff43A047};
            for (int seat = 0; seat < HOME_LANES.length; seat++)
                for (int[] p : HOME_LANES[seat])
                    drawCell(canvas, left, top, cell, p[0], p[1], f[seat], s[seat]);
        }

        private void drawCenter(Canvas canvas, int left, int top, float cell) {
            int[] c = {0xffE8293E, 0xff1E88E5, 0xffF9A825, 0xff43A047};
            float cx = left + 7.5f * cell, cy = top + 7.5f * cell;
            float x6 = left + 6 * cell, x9 = left + 9 * cell;
            float y6 = top + 6 * cell,  y9 = top + 9 * cell;
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
            paint.setStrokeWidth(cell * 0.06f);
            paint.setColor(0x44000000);
            canvas.drawLine(x6, y6, x9, y9, paint);
            canvas.drawLine(x6, y9, x9, y6, paint);
            t.reset();
            t.moveTo(x6, y6); t.lineTo(x9, y6); t.lineTo(x9, y9); t.lineTo(x6, y9); t.close();
            canvas.drawPath(t, paint);
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
            if (snapshot == null) return;
            JSONArray pieces = snapshot.optJSONArray("pieces");
            if (pieces == null) return;
            JSONArray avail  = snapshot.optJSONArray("availableMoves");
            int activeSeat   = snapshot.optInt("currentTurnSeat", -1);
            for (int i = 0; i < pieces.length(); i++) {
                JSONObject p = pieces.optJSONObject(i);
                if (p == null) continue;
                float[] pos = piecePos(p, left, top, cell);
                int seat    = p.optInt("seat");
                boolean legal  = contains(avail, p.optString("pieceId"));
                drawPiece(canvas, pos[0], pos[1], cell * 0.38f,
                    seatColor(seat), legal, activeSeat == seat);
            }
        }

        private void drawPiece(Canvas canvas, float cx, float cy, float r,
                               int color, boolean legal, boolean active) {
            if (legal || active) {
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(legal ? r * 0.28f : r * 0.16f);
                paint.setColor(legal ? 0xffFFFFFF : 0x88FFFFFF);
                canvas.drawCircle(cx, cy, r * (legal ? 1.45f : 1.28f), paint);
                paint.setStyle(Paint.Style.FILL);
            }
            paint.setColor(0x33000000);
            canvas.drawCircle(cx + r * 0.18f, cy + r * 0.22f, r, paint);
            paint.setColor(color);
            canvas.drawCircle(cx, cy, r, paint);
            paint.setShader(new RadialGradient(cx - r * 0.25f, cy - r * 0.3f, r * 1.2f,
                0xAAFFFFFF, 0x00000000, Shader.TileMode.CLAMP));
            canvas.drawCircle(cx, cy, r, paint);
            paint.setShader(null);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(r * 0.16f);
            paint.setColor(0xeeFFFFFF);
            canvas.drawCircle(cx, cy, r, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private float[] piecePos(JSONObject piece, int left, int top, float cell) {
            int seat    = piece.optInt("seat");
            int pi      = pieceIdx(piece.optString("pieceId"));
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
            if (ti < 0 || ti >= PATH.length) ti = (seatStart(seat) + progress) % PATH.length;
            int[] p = PATH[ti];
            return offset(left + (p[0] + 0.5f) * cell, top + (p[1] + 0.5f) * cell, pi, cell * 0.34f);
        }

        private float[] yardPos(int seat, int idx, int left, int top, float cell) {
            int[][] bases = {{0,9},{0,0},{9,0},{9,9}};
            int s = Math.max(0, Math.min(3, seat));
            float[][] slots = {{2.1f,2.1f},{3.9f,2.1f},{2.1f,3.9f},{3.9f,3.9f}};
            return new float[]{
                left + (bases[s][0] + slots[idx % 4][0]) * cell,
                top  + (bases[s][1] + slots[idx % 4][1]) * cell
            };
        }

        private float[] offset(float x, float y, int idx, float amt) {
            float d = Math.max(3f, amt * 0.16f);
            return new float[]{x + (idx % 2 == 0 ? -d : d), y + (idx < 2 ? -d : d)};
        }

        private int pieceIdx(String id) {
            if (id == null || id.isEmpty()) return 0;
            char c = id.charAt(id.length() - 1);
            return c >= '0' && c <= '3' ? c - '0' : 0;
        }

        private int seatStart(int s) {
            int[] starts = {0, 13, 26, 39};
            return starts[Math.max(0, Math.min(3, s))];
        }

        private int seatColor(int s) {
            int[] c = {0xffE8293E, 0xff1E88E5, 0xffF9A825, 0xff43A047};
            return c[Math.max(0, Math.min(3, s))];
        }

        private boolean contains(JSONArray a, String v) {
            if (a == null || v == null) return false;
            for (int i = 0; i < a.length(); i++) if (v.equals(a.optString(i))) return true;
            return false;
        }

        private void drawEmpty(Canvas canvas, int left, int top, int size) {
            if (snapshot != null) return;
            paint.setColor(0xAA0B1020);
            rect.set(left + size * 0.18f, top + size * 0.39f,
                     left + size * 0.82f, top + size * 0.61f);
            canvas.drawRoundRect(rect, size * 0.05f, size * 0.05f, paint);
            paint.setColor(Color.WHITE);
            paint.setTypeface(Typeface.DEFAULT_BOLD);
            paint.setTextSize(size * 0.047f);
            paint.setTextAlign(Paint.Align.CENTER);
            canvas.drawText("Waiting for match", left + size / 2f, top + size * 0.49f, paint);
            paint.setTextSize(size * 0.032f);
            paint.setColor(0xffB8C4D8);
            canvas.drawText("Setting up your game...", left + size / 2f, top + size * 0.55f, paint);
            paint.setTextAlign(Paint.Align.LEFT);
        }

        private void drawStar(Canvas canvas, float cx, float cy, float radius, int color) {
            Path star = new Path();
            for (int i = 0; i < 10; i++) {
                double angle = -Math.PI / 2 + i * Math.PI / 5;
                float r = i % 2 == 0 ? radius : radius * 0.45f;
                float x = cx + (float) Math.cos(angle) * r;
                float y = cy + (float) Math.sin(angle) * r;
                if (i == 0) star.moveTo(x, y); else star.lineTo(x, y);
            }
            star.close();
            paint.setColor(color);
            canvas.drawPath(star, paint);
        }
    }
}
