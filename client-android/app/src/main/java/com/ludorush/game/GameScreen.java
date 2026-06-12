package com.ludorush.game;

import android.app.AlertDialog;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import org.json.JSONArray;
import org.json.JSONObject;

public final class GameScreen extends BaseScreen {

    private BoardView boardView;
    private DiceView diceView;
    private TextView statusText;
    private JSONObject snapshot;
    private String myPlayerId;
    private int lastRollValue;
    private boolean lastRollMine;
    private long lastRollAt;

    public GameScreen(android.app.Activity activity, ScreenCallback callback) {
        super(activity, callback);
    }

    public void updateSnapshot(JSONObject snap, String playerId) {
        snapshot = snap;
        myPlayerId = playerId;
        if (boardView != null) boardView.setSnapshot(snap, playerId);
        if (diceView != null) diceView.setValue(displayDiceValue(), lastRollMine);
        if (statusText != null) refreshStatus();
    }

    public void setStatus(String text) {
        if (statusText != null) statusText.setText(text);
    }

    public void setLastRoll(int value, boolean mine) {
        lastRollValue = Math.max(0, Math.min(6, value));
        lastRollMine = mine;
        lastRollAt = System.currentTimeMillis();
        if (diceView != null) diceView.setValue(lastRollValue, mine);
    }

    @Override
    public View createView() {
        LinearLayout root = new LinearLayout(activity);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(theme.bgPage());

        root.addView(buildPlayerStrip(1, 2), lp(-1, -2));

        statusText = text("Connecting to match...", 13, Color.WHITE, Typeface.BOLD);
        statusText.setGravity(Gravity.CENTER);
        statusText.setPadding(dp(14), dp(9), dp(14), dp(9));
        GradientDrawable statusBg = new GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT,
                theme.isDark()
                        ? new int[]{0xff7A1B87, 0xffD92784, 0xff7A1B87}
                        : new int[]{0xffFF4FA3, 0xff7C4DFF, 0xff18BFF5});
        statusBg.setCornerRadius(dp(18));
        statusBg.setStroke(dp(2), ThemeManager.GOLD);
        statusText.setBackground(statusBg);
        root.addView(statusText, lp(-1, -2, dp(14), dp(8), dp(14), 0));

        boardView = new BoardView(activity, theme, callback);
        LinearLayout.LayoutParams boardLp = new LinearLayout.LayoutParams(-1, 0);
        boardLp.weight = 1;
        boardLp.setMargins(dp(10), dp(8), dp(10), dp(8));
        root.addView(boardView, boardLp);

        root.addView(buildPlayerStrip(0, 3), lp(-1, -2));
        root.addView(buildActionTray(), lp(-1, -2));

        if (snapshot != null) updateSnapshot(snapshot, myPlayerId);
        return root;
    }

    private void refreshStatus() {
        if (snapshot == null) return;

        String status = snapshot.optString("status", "waiting");
        int mySeat = myActiveSeat();
        int turnSeat = snapshot.optInt("currentTurnSeat", -1);
        boolean myTurn = mySeat >= 0 && mySeat == turnSeat;
        boolean hasDice = hasDiceValue(snapshot);
        int dice = hasDice ? snapshot.optInt("diceValue", 0) : 0;
        JSONArray moves = snapshot.optJSONArray("availableMoves");
        boolean hasMoves = moves != null && moves.length() > 0;

        if ("finished".equals(status)) {
            statusText.setText("Match finished.");
        } else if ("waiting".equals(status)) {
            statusText.setText("Waiting for players...");
        } else if (myTurn && !hasDice) {
            statusText.setText("Your turn. Roll the dice.");
        } else if (myTurn && hasMoves) {
            statusText.setText("Rolled " + dice + ". Tap a highlighted piece.");
        } else if (myTurn) {
            statusText.setText("No legal moves. Passing turn...");
        } else {
            statusText.setText("Waiting for " + playerNameForSeat(turnSeat) + ".");
        }
    }

    private int displayDiceValue() {
        if (snapshot != null && hasDiceValue(snapshot)) {
            return Math.max(1, Math.min(6, snapshot.optInt("diceValue", 1)));
        }
        long age = System.currentTimeMillis() - lastRollAt;
        return age < 8000 ? lastRollValue : 0;
    }

    private boolean hasDiceValue(JSONObject snap) {
        return snap != null && snap.has("diceValue") && !snap.isNull("diceValue");
    }

    private int myActiveSeat() {
        if (snapshot == null || myPlayerId == null) return -1;
        JSONArray seats = snapshot.optJSONArray("seats");
        if (seats == null) return -1;
        for (int i = 0; i < seats.length(); i++) {
            JSONObject seat = seats.optJSONObject(i);
            if (seat != null && myPlayerId.equals(seat.optString("playerId"))) {
                return seat.optInt("seat", -1);
            }
        }
        return -1;
    }

    private String playerNameForSeat(int seatNumber) {
        if (snapshot == null) return "player " + (seatNumber + 1);
        JSONArray seats = snapshot.optJSONArray("seats");
        if (seats != null) {
            for (int i = 0; i < seats.length(); i++) {
                JSONObject seat = seats.optJSONObject(i);
                if (seat != null && seat.optInt("seat", -1) == seatNumber) {
                    String name = seat.optString("displayName", "");
                    if (!name.isEmpty()) return name;
                }
            }
        }
        return "player " + (seatNumber + 1);
    }

    private View buildPlayerStrip(int seatA, int seatB) {
        LinearLayout strip = new LinearLayout(activity);
        strip.setOrientation(LinearLayout.HORIZONTAL);
        strip.setPadding(dp(8), dp(7), dp(8), dp(7));
        strip.setBackgroundColor(theme.bgHeader());
        strip.addView(buildSeatChip(seatA), new LinearLayout.LayoutParams(0, -2, 1));
        strip.addView(new View(activity), lp(dp(10), 1));
        strip.addView(buildSeatChip(seatB), new LinearLayout.LayoutParams(0, -2, 1));
        return strip;
    }

    private View buildSeatChip(int seat) {
        int color = seatColor(seat);
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(7), dp(5), dp(7), dp(5));

        GradientDrawable bg = new GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT,
                theme.isDark()
                        ? new int[]{darken(color, 0.62f), 0xff1F0E2F}
                        : new int[]{brighten(color, 1.18f), 0xffffffff});
        bg.setCornerRadius(dp(9));
        bg.setStroke(dp(3), ThemeManager.GOLD);
        card.setBackground(bg);
        card.setElevation(dp(2));

        card.addView(avatarRing("P" + (seat + 1), color, dp(34)),
                lp(dp(34), dp(34), 0, 0, dp(8), 0));

        LinearLayout col = new LinearLayout(activity);
        col.setOrientation(LinearLayout.VERTICAL);
        TextView name = text(playerNameForSeat(seat), 13, theme.isDark() ? Color.WHITE : theme.txtPrimary(), Typeface.BOLD);
        name.setSingleLine(true);
        col.addView(name, lp(-1, -2));
        TextView meta = text(seat == myActiveSeat() ? "You" : "Seat " + (seat + 1),
                9, theme.isDark() ? 0xffFFECA8 : 0xff5A245C, Typeface.BOLD);
        meta.setSingleLine(true);
        col.addView(meta, lp(-1, -2, 0, dp(2), 0, 0));
        card.addView(col, new LinearLayout.LayoutParams(0, -2, 1));

        TextView mic = text("MIC", 9, Color.WHITE, Typeface.BOLD);
        mic.setGravity(Gravity.CENTER);
        mic.setBackground(circle(0xff24102F));
        card.addView(mic, lp(dp(34), dp(34), dp(6), 0, 0, 0));

        return card;
    }

    private View buildActionTray() {
        LinearLayout tray = new LinearLayout(activity);
        tray.setOrientation(LinearLayout.VERTICAL);
        tray.setPadding(dp(14), dp(10), dp(14), dp(14));
        tray.setBackgroundColor(theme.bgHeader());

        TextView voice = text("REAL TIME VOICE CHAT", 13, ThemeManager.GOLD, Typeface.BOLD);
        voice.setGravity(Gravity.CENTER);
        voice.setPadding(dp(8), dp(6), dp(8), dp(6));
        voice.setBackground(card(theme.isDark() ? 0xff154A9A : 0xff6738E8, dp(8), ThemeManager.GOLD));
        tray.addView(voice, lp(-1, -2, 0, 0, 0, dp(8)));

        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);

        diceView = new DiceView(activity, theme);
        GradientDrawable diceWrap = new GradientDrawable();
        diceWrap.setColor(theme.bgCard());
        diceWrap.setCornerRadius(dp(18));
        diceWrap.setStroke(dp(1), theme.strokeCard());
        diceView.setBackground(diceWrap);
        row.addView(diceView, lp(dp(78), dp(78), 0, 0, dp(12), 0));

        LinearLayout buttons = new LinearLayout(activity);
        buttons.setOrientation(LinearLayout.VERTICAL);

        Button roll = primaryButton("Roll Dice");
        roll.setTextSize(17);
        roll.setOnClickListener(v -> callback.rollDice());
        buttons.addView(roll, lp(-1, dp(48), 0, 0, 0, dp(8)));

        LinearLayout secondary = new LinearLayout(activity);
        secondary.setOrientation(LinearLayout.HORIZONTAL);
        Button best = actionButton("Best Move", ThemeManager.TEAL, 0xff008FA1);
        best.setTextSize(13);
        best.setOnClickListener(v -> callback.moveBestPiece());
        secondary.addView(best, new LinearLayout.LayoutParams(0, dp(42), 1));

        Button resign = ghostButton("Resign", ThemeManager.RED);
        resign.setTextSize(13);
        resign.setOnClickListener(v -> confirmResign());
        LinearLayout.LayoutParams resignLp = new LinearLayout.LayoutParams(0, dp(42), 1);
        resignLp.setMargins(dp(8), 0, 0, 0);
        secondary.addView(resign, resignLp);
        buttons.addView(secondary, lp(-1, -2));

        row.addView(buttons, new LinearLayout.LayoutParams(0, -2, 1));
        tray.addView(row, lp(-1, -2));
        return tray;
    }

    private void confirmResign() {
        new AlertDialog.Builder(activity)
                .setTitle("Resign game?")
                .setMessage("This will forfeit the match.")
                .setPositiveButton("Resign", (d, w) -> callback.resign())
                .setNegativeButton("Keep playing", null)
                .show();
    }

    private int darken(int color, float factor) {
        return Color.rgb(
                Math.max(0, (int) (Color.red(color) * factor)),
                Math.max(0, (int) (Color.green(color) * factor)),
                Math.max(0, (int) (Color.blue(color) * factor)));
    }

    private int brighten(int color, float factor) {
        return Color.rgb(
                Math.min(255, (int) (Color.red(color) * factor)),
                Math.min(255, (int) (Color.green(color) * factor)),
                Math.min(255, (int) (Color.blue(color) * factor)));
    }

    public static final class DiceView extends View {
        private final ThemeManager theme;
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private int value;
        private boolean mine;

        DiceView(android.app.Activity activity, ThemeManager theme) {
            super(activity);
            this.theme = theme;
            setPadding(8, 8, 8, 8);
        }

        void setValue(int next, boolean mineRoll) {
            value = Math.max(0, Math.min(6, next));
            mine = mineRoll;
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float w = getWidth();
            float h = getHeight();
            float pad = Math.min(w, h) * 0.12f;
            RectF die = new RectF(pad, pad, w - pad, h - pad);

            paint.setShader(new LinearGradient(0, 0, w, h,
                    mine
                            ? new int[]{ThemeManager.GOLD, ThemeManager.AMBER}
                            : new int[]{0xffF8FAFC, 0xffD8E2EF},
                    null,
                    Shader.TileMode.CLAMP));
            paint.setStyle(Paint.Style.FILL);
            canvas.drawRoundRect(die, pad * 0.7f, pad * 0.7f, paint);
            paint.setShader(null);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, pad * 0.22f));
            paint.setColor(mine ? 0xffFFF6CA : 0xff91A3B8);
            canvas.drawRoundRect(die, pad * 0.7f, pad * 0.7f, paint);

            if (value == 0) {
                paint.setStyle(Paint.Style.FILL);
                paint.setColor(0xff506070);
                paint.setTextAlign(Paint.Align.CENTER);
                paint.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
                paint.setTextSize(Math.min(w, h) * 0.18f);
                canvas.drawText("ROLL", w / 2f, h / 2f + paint.getTextSize() * 0.34f, paint);
                return;
            }

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0xff111827);
            float r = Math.min(w, h) * 0.055f;
            float left = die.left + die.width() * 0.28f;
            float midX = die.centerX();
            float right = die.right - die.width() * 0.28f;
            float top = die.top + die.height() * 0.28f;
            float midY = die.centerY();
            float bottom = die.bottom - die.height() * 0.28f;

            if (value == 1 || value == 3 || value == 5) dot(canvas, midX, midY, r);
            if (value >= 2) {
                dot(canvas, left, top, r);
                dot(canvas, right, bottom, r);
            }
            if (value >= 4) {
                dot(canvas, right, top, r);
                dot(canvas, left, bottom, r);
            }
            if (value == 6) {
                dot(canvas, left, midY, r);
                dot(canvas, right, midY, r);
            }
        }

        private void dot(Canvas canvas, float x, float y, float r) {
            canvas.drawCircle(x, y, r, paint);
        }
    }

    public static final class BoardView extends View {
        private static final int CELLS = 15;
        private static final int[] START_OFFSETS = {0, 13, 26, 39};
        private static final int[][] TRACK_CELLS = {
                {6,14},{6,13},{6,12},{6,11},{6,10},{6,9},{5,8},{4,8},{3,8},{2,8},{1,8},{0,8},{0,7},
                {0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,5},{6,4},{6,3},{6,2},{6,1},{6,0},{7,0},
                {8,0},{8,1},{8,2},{8,3},{8,4},{8,5},{9,6},{10,6},{11,6},{12,6},{13,6},{14,6},{14,7},
                {14,8},{13,8},{12,8},{11,8},{10,8},{9,8},{8,9},{8,10},{8,11},{8,12},{8,13},{8,14},{7,14}
        };
        private static final int[][][] HOME_LANES = {
                {{7,13},{7,12},{7,11},{7,10},{7,9}},
                {{1,7},{2,7},{3,7},{4,7},{5,7}},
                {{7,1},{7,2},{7,3},{7,4},{7,5}},
                {{13,7},{12,7},{11,7},{10,7},{9,7}}
        };
        private static final float[][] BASE_CORNERS = {{0,9}, {0,0}, {9,0}, {9,9}};
        private static final float[][] YARD_SLOTS = {{2.1f,2.1f}, {3.9f,2.1f}, {2.1f,3.9f}, {3.9f,3.9f}};
        private static final int[] SAFE_TRACK_INDEXES = {0, 8, 13, 21, 26, 34, 39, 47};

        private final ThemeManager theme;
        private final ScreenCallback callback;
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private JSONObject snapshot;
        private String playerId;
        private float ox;
        private float oy;
        private float cell;
        private float size;

        public BoardView(android.app.Activity activity, ThemeManager theme, ScreenCallback callback) {
            super(activity);
            this.theme = theme;
            this.callback = callback;
            setClickable(true);
        }

        public void setSnapshot(JSONObject snap, String pid) {
            snapshot = snap;
            playerId = pid;
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int w = getWidth();
            int h = getHeight();
            size = Math.min(w, h);
            ox = (w - size) / 2f;
            oy = (h - size) / 2f;
            cell = size / (float) CELLS;

            drawBoardBase(canvas);
            drawTrackCells(canvas);
            drawHomeZones(canvas);
            drawHomeLanes(canvas);
            drawCenter(canvas);
            drawGrid(canvas);
            drawLegalMoveHints(canvas);
            drawPieces(canvas);
            drawVoiceChatOverlay(canvas);
        }

        @Override
        public boolean onTouchEvent(MotionEvent event) {
            if (event.getAction() != MotionEvent.ACTION_UP || snapshot == null) {
                return true;
            }

            JSONArray moves = snapshot.optJSONArray("availableMoves");
            JSONArray pieces = snapshot.optJSONArray("pieces");
            if (moves == null || pieces == null || moves.length() == 0) {
                return true;
            }

            String bestPiece = "";
            float bestDistance = Float.MAX_VALUE;
            float maxDistance = cell * 0.75f;
            for (int i = 0; i < moves.length(); i++) {
                String pieceId = moves.optString(i, "");
                JSONObject piece = pieceById(pieces, pieceId);
                if (piece == null) continue;

                float[] center = pieceCenter(piece);
                float x = ox + center[0] * cell;
                float y = oy + center[1] * cell;
                float dx = event.getX() - x;
                float dy = event.getY() - y;
                float distance = (float) Math.sqrt(dx * dx + dy * dy);
                if (distance < bestDistance) {
                    bestDistance = distance;
                    bestPiece = pieceId;
                }
            }

            if (!bestPiece.isEmpty() && bestDistance <= maxDistance) {
                callback.movePiece(bestPiece);
            }
            return true;
        }

        private void drawBoardBase(Canvas canvas) {
            RectF outer = new RectF(ox, oy, ox + size, oy + size);
            paint.setStyle(Paint.Style.FILL);
            paint.setShader(new LinearGradient(ox, oy, ox + size, oy + size,
                    new int[]{theme.bgBoard(), theme.isDark() ? 0xff182436 : 0xffffffff, theme.bgBoard()},
                    null,
                    Shader.TileMode.CLAMP));
            canvas.drawRoundRect(outer, cell * 0.55f, cell * 0.55f, paint);
            paint.setShader(null);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(3f, cell * 0.08f));
            paint.setColor(theme.strokeCardGlow());
            canvas.drawRoundRect(outer, cell * 0.55f, cell * 0.55f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawTrackCells(Canvas canvas) {
            for (int i = 0; i < TRACK_CELLS.length; i++) {
                int[] xy = TRACK_CELLS[i];
                int fill = isStartIndex(i) ? seatColorForStart(i) : (theme.isDark() ? 0xffF7F1E3 : 0xffffffff);
                drawCell(canvas, xy[0], xy[1], fill, theme.isDark() ? 0xffC9D1DA : 0xffD7C8FF);
                if (isSafeIndex(i)) drawStar(canvas, xy[0] + 0.5f, xy[1] + 0.5f, cell * 0.24f, ThemeManager.GOLD);
            }
        }

        private void drawHomeZones(Canvas canvas) {
            for (int seat = 0; seat < 4; seat++) {
                float x = BASE_CORNERS[seat][0];
                float y = BASE_CORNERS[seat][1];
                int color = seatColor(seat);

                RectF zone = rectForGrid(x, y, 6f, 6f, 1.5f);
                paint.setStyle(Paint.Style.FILL);
                paint.setColor(color);
                canvas.drawRoundRect(zone, cell * 0.42f, cell * 0.42f, paint);

                paint.setColor(0x2EFFFFFF);
                canvas.drawRoundRect(zone, cell * 0.42f, cell * 0.42f, paint);

                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(Math.max(2f, cell * 0.05f));
                paint.setColor(0xE8FFFFFF);
                canvas.drawRoundRect(zone, cell * 0.42f, cell * 0.42f, paint);

                RectF tray = rectForGrid(x + 1.1f, y + 1.1f, 3.8f, 3.8f, 3f);
                paint.setStyle(Paint.Style.FILL);
                paint.setColor(theme.isDark() ? theme.bgBoard() : 0xeeFFFFFF);
                canvas.drawRoundRect(tray, cell * 0.34f, cell * 0.34f, paint);

                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(Math.max(1.5f, cell * 0.04f));
                paint.setColor(theme.isDark() ? 0x66FFFFFF : 0x887C4DFF);
                canvas.drawRoundRect(tray, cell * 0.34f, cell * 0.34f, paint);
                paint.setStyle(Paint.Style.FILL);
            }
        }

        private void drawHomeLanes(Canvas canvas) {
            for (int seat = 0; seat < HOME_LANES.length; seat++) {
                int fill = seatColorSoft(seat);
                for (int i = 0; i < HOME_LANES[seat].length; i++) {
                    int[] xy = HOME_LANES[seat][i];
                    drawCell(canvas, xy[0], xy[1], fill, theme.isDark() ? 0xffF8FAFC : 0xffffffff);
                }
            }
        }

        private void drawCenter(Canvas canvas) {
            float cx = ox + 7.5f * cell;
            float cy = oy + 7.5f * cell;
            int centerFill = theme.isDark() ? 0xffF7F1E3 : 0xffffffff;
            int centerStroke = theme.isDark() ? 0xffC9D1DA : 0xffD7C8FF;
            drawCell(canvas, 6, 6, centerFill, centerStroke);
            drawCell(canvas, 7, 6, centerFill, centerStroke);
            drawCell(canvas, 8, 6, centerFill, centerStroke);
            drawCell(canvas, 6, 7, centerFill, centerStroke);
            drawCell(canvas, 7, 7, centerFill, centerStroke);
            drawCell(canvas, 8, 7, centerFill, centerStroke);
            drawCell(canvas, 6, 8, centerFill, centerStroke);
            drawCell(canvas, 7, 8, centerFill, centerStroke);
            drawCell(canvas, 8, 8, centerFill, centerStroke);

            drawTriangle(canvas, cx, cy, 7.5f, 9f, 6f, 9f, ThemeManager.RED);
            drawTriangle(canvas, cx, cy, 6f, 6f, 6f, 9f, ThemeManager.BLUE);
            drawTriangle(canvas, cx, cy, 6f, 6f, 9f, 6f, ThemeManager.YELLOW);
            drawTriangle(canvas, cx, cy, 9f, 6f, 9f, 9f, ThemeManager.GREEN);
            drawStar(canvas, 7.5f, 7.5f, cell * 0.52f, Color.WHITE);
        }

        private void drawGrid(Canvas canvas) {
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(0.7f, cell * 0.018f));
            paint.setColor(theme.isDark() ? 0x28000000 : 0x1F5A245C);
            for (int i = 0; i <= CELLS; i++) {
                float line = i * cell;
                canvas.drawLine(ox + line, oy, ox + line, oy + size, paint);
                canvas.drawLine(ox, oy + line, ox + size, oy + line, paint);
            }
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawLegalMoveHints(Canvas canvas) {
            if (snapshot == null) return;
            JSONArray moves = snapshot.optJSONArray("availableMoves");
            JSONArray pieces = snapshot.optJSONArray("pieces");
            if (moves == null || pieces == null) return;

            for (int i = 0; i < moves.length(); i++) {
                JSONObject piece = pieceById(pieces, moves.optString(i, ""));
                if (piece == null) continue;
                float[] center = pieceCenter(piece);
                float x = ox + center[0] * cell;
                float y = oy + center[1] * cell;

                paint.setStyle(Paint.Style.FILL);
                paint.setColor(0x33FFD700);
                canvas.drawCircle(x, y, cell * 0.58f, paint);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(Math.max(3f, cell * 0.07f));
                paint.setColor(ThemeManager.GOLD);
                canvas.drawCircle(x, y, cell * 0.48f, paint);
                paint.setStyle(Paint.Style.FILL);
            }
        }

        private void drawPieces(Canvas canvas) {
            if (snapshot == null) return;
            JSONArray pieces = snapshot.optJSONArray("pieces");
            if (pieces == null) return;

            for (int i = 0; i < pieces.length(); i++) {
                JSONObject piece = pieces.optJSONObject(i);
                if (piece == null) continue;
                drawPiece(canvas, piece);
            }
        }

        private void drawVoiceChatOverlay(Canvas canvas) {
            float cx = ox + 7.5f * cell;
            float cy = oy + 7.5f * cell;
            float width = size * 0.42f;
            float height = cell * 0.86f;
            RectF panel = new RectF(cx - width / 2f, cy - height / 2f, cx + width / 2f, cy + height / 2f);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(theme.isDark() ? 0x9935104F : 0xbbFFFFFF);
            canvas.drawRoundRect(panel, height * 0.45f, height * 0.45f, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, cell * 0.040f));
            paint.setColor(theme.isDark() ? ThemeManager.GOLD : 0xff7C4DFF);
            canvas.drawRoundRect(panel, height * 0.45f, height * 0.45f, paint);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0xffFF2E7E);
            canvas.drawCircle(cx, cy, height * 0.48f, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(3f, cell * 0.060f));
            paint.setColor(ThemeManager.GOLD);
            canvas.drawCircle(cx, cy, height * 0.48f, paint);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(Color.WHITE);
            canvas.drawRoundRect(new RectF(cx - cell * 0.10f, cy - cell * 0.23f, cx + cell * 0.10f, cy + cell * 0.17f),
                    cell * 0.09f, cell * 0.09f, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, cell * 0.045f));
            paint.setColor(Color.WHITE);
            canvas.drawArc(new RectF(cx - cell * 0.24f, cy - cell * 0.03f, cx + cell * 0.24f, cy + cell * 0.34f),
                    20, 140, false, paint);
            canvas.drawLine(cx, cy + cell * 0.34f, cx, cy + cell * 0.49f, paint);
            canvas.drawLine(cx - cell * 0.15f, cy + cell * 0.49f, cx + cell * 0.15f, cy + cell * 0.49f, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, cell * 0.045f));
            paint.setColor(0xEFFFFFFF);
            for (int side = -1; side <= 1; side += 2) {
                for (int i = 0; i < 6; i++) {
                    float x = cx + side * (cell * 0.58f + i * cell * 0.24f);
                    float y1 = cy - (i % 3 + 1) * cell * 0.09f;
                    float y2 = cy + (i % 3 + 1) * cell * 0.09f;
                    canvas.drawLine(x, y1, x, y2, paint);
                }
            }
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawPiece(Canvas canvas, JSONObject piece) {
            int seat = clampSeat(piece.optInt("seat", 0));
            int color = seatColor(seat);
            int index = pieceIndex(piece.optString("pieceId", ""));
            float[] center = pieceCenter(piece);
            boolean yard = "yard".equals(piece.optString("state", ""));
            if (!yard) {
                float offset = cell * 0.13f;
                if (index == 0) { center[0] -= offset / cell; center[1] -= offset / cell; }
                if (index == 1) { center[0] += offset / cell; center[1] -= offset / cell; }
                if (index == 2) { center[0] -= offset / cell; center[1] += offset / cell; }
                if (index == 3) { center[0] += offset / cell; center[1] += offset / cell; }
            }

            float x = ox + center[0] * cell;
            float y = oy + center[1] * cell;
            float radius = cell * (yard ? 0.39f : 0.37f);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0x66000000);
            canvas.drawCircle(x + cell * 0.05f, y + cell * 0.07f, radius, paint);

            paint.setColor(color);
            canvas.drawCircle(x, y, radius, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, cell * 0.055f));
            paint.setColor(0xEFFFFFFF);
            canvas.drawCircle(x, y, radius * 0.9f, paint);
            paint.setStyle(Paint.Style.FILL);

            paint.setColor(0xCCFFFFFF);
            canvas.drawCircle(x - radius * 0.28f, y - radius * 0.32f, radius * 0.23f, paint);
        }

        private float[] pieceCenter(JSONObject piece) {
            int seat = clampSeat(piece.optInt("seat", 0));
            int progress = piece.optInt("progress", -1);
            int index = pieceIndex(piece.optString("pieceId", ""));
            String state = piece.optString("state", "yard");

            if ("yard".equals(state) || progress < 0) {
                return new float[]{
                        BASE_CORNERS[seat][0] + YARD_SLOTS[index % 4][0],
                        BASE_CORNERS[seat][1] + YARD_SLOTS[index % 4][1]
                };
            }

            if ("home".equals(state)) {
                int lane = Math.max(0, Math.min(4, progress - 52));
                return new float[]{HOME_LANES[seat][lane][0] + 0.5f, HOME_LANES[seat][lane][1] + 0.5f};
            }

            if ("finished".equals(state)) {
                float offset = (index - 1.5f) * 0.18f;
                return new float[]{7.5f + offset, 7.5f + offset};
            }

            int track = piece.has("trackIndex")
                    ? piece.optInt("trackIndex", trackIndex(seat, progress))
                    : trackIndex(seat, progress);
            track = Math.max(0, Math.min(TRACK_CELLS.length - 1, track));
            return new float[]{TRACK_CELLS[track][0] + 0.5f, TRACK_CELLS[track][1] + 0.5f};
        }

        private JSONObject pieceById(JSONArray pieces, String id) {
            for (int i = 0; i < pieces.length(); i++) {
                JSONObject piece = pieces.optJSONObject(i);
                if (piece != null && id.equals(piece.optString("pieceId"))) {
                    return piece;
                }
            }
            return null;
        }

        private int trackIndex(int seat, int progress) {
            if (progress < 0 || progress > 51) return 0;
            return (START_OFFSETS[clampSeat(seat)] + progress) % TRACK_CELLS.length;
        }

        private int pieceIndex(String id) {
            int idx = id.lastIndexOf('p');
            if (idx < 0 || idx == id.length() - 1) return 0;
            try {
                return Math.max(0, Math.min(3, Integer.parseInt(id.substring(idx + 1))));
            } catch (NumberFormatException e) {
                return 0;
            }
        }

        private int clampSeat(int seat) {
            return Math.max(0, Math.min(3, seat));
        }

        private void drawCell(Canvas canvas, int x, int y, int fill, int stroke) {
            RectF rect = rectForGrid(x, y, 1, 1, 1.8f);
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(fill);
            canvas.drawRoundRect(rect, cell * 0.12f, cell * 0.12f, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(1f, cell * 0.02f));
            paint.setColor(stroke);
            canvas.drawRoundRect(rect, cell * 0.12f, cell * 0.12f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private RectF rectForGrid(float x, float y, float w, float h, float insetPx) {
            return new RectF(
                    ox + x * cell + insetPx,
                    oy + y * cell + insetPx,
                    ox + (x + w) * cell - insetPx,
                    oy + (y + h) * cell - insetPx);
        }

        private void drawTriangle(Canvas canvas, float cx, float cy, float x1, float y1, float x2, float y2, int color) {
            Path path = new Path();
            path.moveTo(cx, cy);
            path.lineTo(ox + x1 * cell, oy + y1 * cell);
            path.lineTo(ox + x2 * cell, oy + y2 * cell);
            path.close();
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(color);
            canvas.drawPath(path, paint);
        }

        private void drawStar(Canvas canvas, float gridX, float gridY, float radius, int color) {
            float cx = ox + gridX * cell;
            float cy = oy + gridY * cell;
            Path star = new Path();
            for (int i = 0; i < 5; i++) {
                double a = -Math.PI / 2 + i * 2 * Math.PI / 5;
                float x = cx + (float) (Math.cos(a) * radius);
                float y = cy + (float) (Math.sin(a) * radius);
                if (i == 0) star.moveTo(x, y); else star.lineTo(x, y);
                double inner = a + Math.PI / 5;
                star.lineTo(
                        cx + (float) (Math.cos(inner) * radius * 0.42f),
                        cy + (float) (Math.sin(inner) * radius * 0.42f));
            }
            star.close();
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(color);
            canvas.drawPath(star, paint);
        }

        private boolean isStartIndex(int idx) {
            return idx == 0 || idx == 13 || idx == 26 || idx == 39;
        }

        private int seatColorForStart(int idx) {
            if (idx == 0) return ThemeManager.RED_SOFT;
            if (idx == 13) return ThemeManager.BLUE_SOFT;
            if (idx == 26) return ThemeManager.YELLOW_SOFT;
            return ThemeManager.GREEN_SOFT;
        }

        private boolean isSafeIndex(int idx) {
            for (int safe : SAFE_TRACK_INDEXES) {
                if (safe == idx) return true;
            }
            return false;
        }

        private int seatColor(int seat) {
            int[] c = {ThemeManager.RED, ThemeManager.BLUE, ThemeManager.YELLOW, ThemeManager.GREEN};
            return c[clampSeat(seat)];
        }

        private int seatColorSoft(int seat) {
            int[] c = {ThemeManager.RED_SOFT, ThemeManager.BLUE_SOFT, ThemeManager.YELLOW_SOFT, ThemeManager.GREEN_SOFT};
            return c[clampSeat(seat)];
        }
    }
}
