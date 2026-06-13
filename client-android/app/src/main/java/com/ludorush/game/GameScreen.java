package com.ludorush.game;

import android.app.AlertDialog;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RadialGradient;
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
        root.setPadding(dp(8), dp(6), dp(8), 0);

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
        boardLp.setMargins(0, dp(8), 0, dp(8));
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
        private long rollAnimStart;

        DiceView(android.app.Activity activity, ThemeManager theme) {
            super(activity);
            this.theme = theme;
            setPadding(8, 8, 8, 8);
        }

        void setValue(int next, boolean mineRoll) {
            int old = value;
            value = Math.max(0, Math.min(6, next));
            mine = mineRoll;
            if (value > 0 && value != old) {
                rollAnimStart = System.currentTimeMillis();
            }
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float w = getWidth();
            float h = getHeight();
            float pad = Math.min(w, h) * 0.12f;
            RectF die = new RectF(pad, pad, w - pad, h - pad);
            long age = System.currentTimeMillis() - rollAnimStart;
            float anim = value > 0 && age < 720 ? 1f - (age / 720f) : 0f;

            if (anim > 0f) {
                canvas.save();
                float wobble = (float) Math.sin(anim * Math.PI * 6f) * anim;
                float scale = 1f + 0.10f * anim;
                canvas.rotate(wobble * 10f, w / 2f, h / 2f);
                canvas.scale(scale, scale, w / 2f, h / 2f);
            }

            paint.setColor(0x66000000);
            canvas.drawRoundRect(new RectF(die.left + pad * 0.28f, die.top + pad * 0.38f,
                    die.right + pad * 0.28f, die.bottom + pad * 0.38f), pad * 0.85f, pad * 0.85f, paint);
            paint.setAlpha(255);
            paint.setShader(new LinearGradient(0, 0, w, h,
                    mine
                            ? new int[]{ThemeManager.GOLD, ThemeManager.AMBER}
                            : new int[]{0xffF8FAFC, 0xffD8E2EF},
                    null,
                    Shader.TileMode.CLAMP));
            paint.setStyle(Paint.Style.FILL);
            canvas.drawRoundRect(die, pad * 0.7f, pad * 0.7f, paint);
            paint.setShader(null);
            paint.setColor(0x44FFFFFF);
            canvas.drawRoundRect(new RectF(die.left + pad * 0.22f, die.top + pad * 0.20f,
                    die.right - pad * 0.22f, die.top + die.height() * 0.44f),
                    pad * 0.55f, pad * 0.55f, paint);

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
                if (anim > 0f) canvas.restore();
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
            if (anim > 0f) {
                canvas.restore();
                postInvalidateOnAnimation();
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
        private final Path path = new Path();
        private JSONObject snapshot;
        private String playerId;
        private String movingPieceId = "";
        private float[] movingFrom;
        private float[] movingTo;
        private long movingSince;
        private boolean attached;
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
            captureMovingPiece(snap);
            snapshot = snap;
            playerId = pid;
            invalidate();
        }

        @Override
        protected void onAttachedToWindow() {
            super.onAttachedToWindow();
            attached = true;
            postInvalidateOnAnimation();
        }

        @Override
        protected void onDetachedFromWindow() {
            attached = false;
            super.onDetachedFromWindow();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int w = getWidth();
            int h = getHeight();
            size = Math.min(w, h) - Math.max(6f, Math.min(w, h) * 0.018f);
            cell = size / (float) CELLS;
            ox = (w - size) / 2f;
            oy = Math.max(0f, (h - size) * 0.28f);

            drawBoardBase(canvas);
            drawTrackCells(canvas);
            drawHomeZones(canvas);
            drawHomeLanes(canvas);
            drawCenter(canvas);
            drawGrid(canvas);
            drawLegalMoveHints(canvas);
            drawPieces(canvas);
            drawVoiceChatOverlay(canvas);
            if (attached) postInvalidateOnAnimation();
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
                float y = oy + center[1] * cell - cell * 0.10f;
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

        private void captureMovingPiece(JSONObject next) {
            if (snapshot == null || next == null) return;
            JSONArray oldPieces = snapshot.optJSONArray("pieces");
            JSONArray nextPieces = next.optJSONArray("pieces");
            if (oldPieces == null || nextPieces == null) return;

            for (int i = 0; i < nextPieces.length(); i++) {
                JSONObject nextPiece = nextPieces.optJSONObject(i);
                if (nextPiece == null) continue;
                String id = nextPiece.optString("pieceId", "");
                JSONObject oldPiece = pieceById(oldPieces, id);
                if (oldPiece == null) continue;
                boolean changed = oldPiece.optInt("progress", -999) != nextPiece.optInt("progress", -999)
                        || oldPiece.optInt("trackIndex", -999) != nextPiece.optInt("trackIndex", -999)
                        || !oldPiece.optString("state", "").equals(nextPiece.optString("state", ""));
                if (changed) {
                    movingPieceId = id;
                    movingFrom = pieceDrawCenter(oldPiece);
                    movingTo = pieceDrawCenter(nextPiece);
                    movingSince = System.currentTimeMillis();
                    return;
                }
            }
        }

        private void drawBoardBase(Canvas canvas) {
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0x66000000);
            RectF shadow = new RectF(ox + cell * 0.18f, oy + cell * 0.46f,
                    ox + size + cell * 0.18f, oy + size + cell * 0.66f);
            canvas.drawRoundRect(shadow, cell * 0.48f, cell * 0.48f, paint);

            RectF side = new RectF(ox - cell * 0.08f, oy + cell * 0.18f,
                    ox + size + cell * 0.08f, oy + size + cell * 0.36f);
            paint.setShader(new LinearGradient(side.left, side.top, side.right, side.bottom,
                    new int[]{0xff461153, 0xff17001F, 0xff351060},
                    null,
                    Shader.TileMode.CLAMP));
            canvas.drawRoundRect(side, cell * 0.45f, cell * 0.45f, paint);
            paint.setShader(null);

            RectF board = new RectF(ox, oy, ox + size, oy + size);
            paint.setAlpha(255);
            paint.setShader(new LinearGradient(board.left, board.top, board.right, board.bottom,
                    new int[]{0xffFFF7CA, 0xffffffff, 0xffEAFBFF, 0xffFFF2B7},
                    null,
                    Shader.TileMode.CLAMP));
            canvas.drawRoundRect(board, cell * 0.38f, cell * 0.38f, paint);
            paint.setShader(null);

            paint.setColor(0x22FFD426);
            canvas.drawRoundRect(new RectF(board.left + cell * 0.12f, board.top + cell * 0.10f,
                    board.right - cell * 0.12f, board.top + size * 0.30f),
                    cell * 0.28f, cell * 0.28f, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(7f, cell * 0.19f));
            paint.setColor(0xffFFD426);
            canvas.drawRoundRect(board, cell * 0.38f, cell * 0.38f, paint);
            paint.setStrokeWidth(Math.max(2.5f, cell * 0.065f));
            paint.setColor(0xff7C3AED);
            canvas.drawRoundRect(new RectF(board.left + cell * 0.10f, board.top + cell * 0.10f,
                    board.right - cell * 0.10f, board.bottom - cell * 0.10f),
                    cell * 0.30f, cell * 0.30f, paint);
            paint.setStrokeWidth(Math.max(1.5f, cell * 0.040f));
            paint.setColor(0xeeFFFFFF);
            canvas.drawRoundRect(new RectF(board.left + cell * 0.20f, board.top + cell * 0.20f,
                    board.right - cell * 0.20f, board.bottom - cell * 0.20f),
                    cell * 0.22f, cell * 0.22f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawRaisedBlock(Canvas canvas, float gx, float gy, float gw, float gh, int color,
                                     boolean active, float pulse) {
            RectF rect = rectForGrid(gx, gy, gw, gh, cell * 0.06f);
            float radius = cell * 0.36f;
            float depth = cell * 0.18f;
            paint.setStyle(Paint.Style.FILL);
            if (active) {
                paint.setColor(withAlpha(ThemeManager.GOLD, (int) (80 + pulse * 72)));
                canvas.drawRoundRect(new RectF(rect.left - cell * 0.22f, rect.top - cell * 0.22f,
                        rect.right + cell * 0.22f, rect.bottom + cell * 0.22f),
                        radius * 1.08f, radius * 1.08f, paint);
            }

            RectF lower = new RectF(rect);
            lower.offset(0, depth);
            paint.setShader(new LinearGradient(lower.left, lower.top, lower.right, lower.bottom,
                    darken(color, 0.72f), darken(color, 0.44f), Shader.TileMode.CLAMP));
            canvas.drawRoundRect(lower, radius, radius, paint);
            paint.setShader(null);

            paint.setColor(0x55000000);
            canvas.drawRoundRect(new RectF(rect.left + cell * 0.08f, rect.top + cell * 0.26f,
                    rect.right + cell * 0.08f, rect.bottom + cell * 0.34f),
                    radius, radius, paint);

            paint.setAlpha(255);
            paint.setShader(new LinearGradient(rect.left, rect.top, rect.right, rect.bottom,
                    new int[]{brighten(color, 1.35f), brighten(color, 1.12f), color, darken(color, 0.86f)},
                    null,
                    Shader.TileMode.CLAMP));
            canvas.drawRoundRect(rect, radius, radius, paint);
            paint.setShader(null);

            paint.setColor(0x32FFFFFF);
            canvas.drawRoundRect(new RectF(rect.left + cell * 0.28f, rect.top + cell * 0.22f,
                    rect.right - cell * 0.28f, rect.top + rect.height() * 0.36f),
                    radius * 0.62f, radius * 0.62f, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(3f, cell * 0.07f));
            paint.setColor(0xFAFFFFFF);
            canvas.drawRoundRect(rect, radius, radius, paint);
            paint.setStrokeWidth(Math.max(2f, cell * 0.045f));
            paint.setColor(0xAAFFD426);
            canvas.drawRoundRect(new RectF(rect.left + cell * 0.12f, rect.top + cell * 0.12f,
                    rect.right - cell * 0.12f, rect.bottom - cell * 0.12f),
                    radius * 0.82f, radius * 0.82f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawPearlTray(Canvas canvas, float gx, float gy, float gw, float gh, int accent) {
            RectF tray = rectForGrid(gx, gy, gw, gh, cell * 0.16f);
            float radius = cell * 0.18f;
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0x44000000);
            canvas.drawRoundRect(new RectF(tray.left + cell * 0.08f, tray.top + cell * 0.10f,
                    tray.right + cell * 0.08f, tray.bottom + cell * 0.12f),
                    radius, radius, paint);

            paint.setAlpha(255);
            paint.setShader(new LinearGradient(tray.left, tray.top, tray.right, tray.bottom,
                    new int[]{0xffffffff, 0xfffff8e6, 0xffffefc0},
                    null,
                    Shader.TileMode.CLAMP));
            canvas.drawRoundRect(tray, radius, radius, paint);
            paint.setShader(null);

            paint.setColor(withAlpha(accent, 36));
            canvas.drawRoundRect(new RectF(tray.left + cell * 0.18f, tray.top + cell * 0.18f,
                    tray.right - cell * 0.18f, tray.bottom - cell * 0.18f),
                    radius * 0.72f, radius * 0.72f, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, cell * 0.045f));
            paint.setColor(0xF5FFFFFF);
            canvas.drawRoundRect(tray, radius, radius, paint);
            paint.setStrokeWidth(Math.max(1.3f, cell * 0.026f));
            paint.setColor(withAlpha(accent, 160));
            canvas.drawRoundRect(new RectF(tray.left + cell * 0.10f, tray.top + cell * 0.10f,
                    tray.right - cell * 0.10f, tray.bottom - cell * 0.10f),
                    radius * 0.82f, radius * 0.82f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawSocket(Canvas canvas, float cx, float cy, float radius, int color, boolean active, float pulse) {
            if (active) {
                paint.setStyle(Paint.Style.FILL);
                paint.setColor(withAlpha(ThemeManager.GOLD, (int) (36 + pulse * 54)));
                canvas.drawCircle(cx, cy, radius * (1.35f + pulse * 0.18f), paint);
            }

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0x33000000);
            canvas.drawOval(new RectF(cx - radius * 0.86f, cy + radius * 0.50f,
                    cx + radius * 0.86f, cy + radius * 1.00f), paint);

            paint.setAlpha(255);
            paint.setShader(new RadialGradient(cx - radius * 0.25f, cy - radius * 0.28f,
                    radius * 1.10f,
                    new int[]{0xffffffff, brighten(color, 1.18f), darken(color, 0.88f)},
                    null,
                    Shader.TileMode.CLAMP));
            canvas.drawCircle(cx, cy, radius, paint);
            paint.setShader(null);

            paint.setColor(0x88FFFFFF);
            canvas.drawCircle(cx - radius * 0.28f, cy - radius * 0.34f, radius * 0.26f, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(1.5f, cell * 0.032f));
            paint.setColor(0xEEFFFFFF);
            canvas.drawCircle(cx, cy, radius * 0.94f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawTrackCells(Canvas canvas) {
            for (int i = 0; i < TRACK_CELLS.length; i++) {
                int[] xy = TRACK_CELLS[i];
                int fill = isStartIndex(i) ? seatColorForStart(i) : 0xffFFFDF2;
                drawCell(canvas, xy[0], xy[1], fill, 0xffB8B5D0);
                if (isSafeIndex(i)) drawSafeStar(canvas, xy[0] + 0.5f, xy[1] + 0.5f);
            }
            drawStartArrows(canvas);
        }

        private void drawHomeZones(Canvas canvas) {
            int turnSeat = snapshot == null ? -1 : snapshot.optInt("currentTurnSeat", -1);
            float pulse = pulse(1500L, 0f);
            for (int seat = 0; seat < 4; seat++) {
                float x = BASE_CORNERS[seat][0];
                float y = BASE_CORNERS[seat][1];
                int color = seatColor(seat);

                drawRaisedBlock(canvas, x, y, 6f, 6f, color, seat == turnSeat, pulse);
                drawPearlTray(canvas, x + 1.1f, y + 1.1f, 3.8f, 3.8f, seatColorSoft(seat));

                for (float[] slot : YARD_SLOTS) {
                    float sx = ox + (x + slot[0]) * cell;
                    float sy = oy + (y + slot[1]) * cell;
                    float slotRadius = cell * (seat == turnSeat ? 0.41f + pulse * 0.025f : 0.39f);
                    drawSocket(canvas, sx, sy, slotRadius, seatColorSoft(seat), seat == turnSeat, pulse);
                }
            }
        }

        private void drawHomeLanes(Canvas canvas) {
            for (int seat = 0; seat < HOME_LANES.length; seat++) {
                int fill = brighten(seatColorSoft(seat), 1.10f);
                for (int i = 0; i < HOME_LANES[seat].length; i++) {
                    int[] xy = HOME_LANES[seat][i];
                    drawCell(canvas, xy[0], xy[1], fill, 0xeeFFFFFF);
                    if (i == HOME_LANES[seat].length - 1) {
                        drawLaneArrow(canvas, xy[0], xy[1], seat, 0x99FFFFFF);
                    }
                }
            }
        }

        private void drawCenter(Canvas canvas) {
            float cx = ox + 7.5f * cell;
            float cy = oy + 7.5f * cell;
            drawRaisedBlock(canvas, 6, 6, 3, 3, 0xff6B2DCC, false, 0f);

            drawTriangleGloss(canvas, cx, cy, 7.5f, 9f, 6f, 9f, ThemeManager.RED);
            drawTriangleGloss(canvas, cx, cy, 6f, 6f, 6f, 9f, ThemeManager.BLUE);
            drawTriangleGloss(canvas, cx, cy, 6f, 6f, 9f, 6f, ThemeManager.YELLOW);
            drawTriangleGloss(canvas, cx, cy, 9f, 6f, 9f, 9f, ThemeManager.GREEN);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0x77000000);
            canvas.drawOval(new RectF(cx - cell * 0.68f, cy + cell * 0.30f,
                    cx + cell * 0.68f, cy + cell * 0.78f), paint);

            paint.setAlpha(255);
            paint.setShader(new RadialGradient(cx - cell * 0.18f, cy - cell * 0.20f,
                    cell * 0.86f,
                    new int[]{0xffffffff, 0xffFFF4B5, 0xffFFB000},
                    null,
                    Shader.TileMode.CLAMP));
            canvas.drawCircle(cx, cy, cell * 0.58f, paint);
            paint.setShader(null);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(3f, cell * 0.07f));
            paint.setColor(0xff7C2D12);
            canvas.drawCircle(cx, cy, cell * 0.58f, paint);
            paint.setStyle(Paint.Style.FILL);
            drawStar(canvas, 7.5f, 7.5f, cell * 0.34f, 0xffffffff);
        }

        private void drawGrid(Canvas canvas) {
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, cell * 0.045f));
            paint.setColor(0x55FFFFFF);
            RectF board = new RectF(ox + cell * 0.10f, oy + cell * 0.10f,
                    ox + size - cell * 0.10f, oy + size - cell * 0.10f);
            canvas.drawRoundRect(board, cell * 0.25f, cell * 0.25f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawLegalMoveHints(Canvas canvas) {
            if (snapshot == null) return;
            JSONArray moves = snapshot.optJSONArray("availableMoves");
            JSONArray pieces = snapshot.optJSONArray("pieces");
            if (moves == null || pieces == null) return;
            float pulse = pulse(880L, 0.18f);

            for (int i = 0; i < moves.length(); i++) {
                JSONObject piece = pieceById(pieces, moves.optString(i, ""));
                if (piece == null) continue;
                float[] center = pieceCenter(piece);
                float x = ox + center[0] * cell;
                float y = oy + center[1] * cell - cell * 0.10f;

                paint.setStyle(Paint.Style.FILL);
                paint.setColor(withAlpha(ThemeManager.GOLD, (int) (38 + pulse * 62)));
                canvas.drawCircle(x, y, cell * (0.55f + pulse * 0.16f), paint);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(Math.max(3f, cell * (0.055f + pulse * 0.025f)));
                paint.setColor(ThemeManager.GOLD);
                canvas.drawCircle(x, y, cell * (0.44f + pulse * 0.12f), paint);
                paint.setColor(0xDFFFFFFF);
                paint.setStrokeWidth(Math.max(2f, cell * 0.035f));
                canvas.drawCircle(x, y, cell * 0.30f, paint);
                paint.setStyle(Paint.Style.FILL);
            }
        }

        private void drawPieces(Canvas canvas) {
            if (snapshot == null) return;
            JSONArray pieces = snapshot.optJSONArray("pieces");
            if (pieces == null) return;
            long now = System.currentTimeMillis();
            float moveT = movingPieceId.isEmpty() ? 1f : Math.min(1f, (now - movingSince) / 360f);
            float easedMove = easeOutCubic(moveT);

            for (int i = 0; i < pieces.length(); i++) {
                JSONObject piece = pieces.optJSONObject(i);
                if (piece == null) continue;
                String id = piece.optString("pieceId", "");
                if (id.equals(movingPieceId) && movingFrom != null && movingTo != null && moveT < 1f) {
                    float gx = lerp(movingFrom[0], movingTo[0], easedMove);
                    float gy = lerp(movingFrom[1], movingTo[1], easedMove);
                    drawPieceAt(canvas, piece, gx, gy, (float) Math.sin(moveT * Math.PI));
                } else {
                    drawPiece(canvas, piece);
                }
            }
            if (moveT >= 1f) movingPieceId = "";
        }

        private void drawVoiceChatOverlay(Canvas canvas) {
            float cx = ox + 7.5f * cell;
            float cy = oy + 7.5f * cell;
            float phase = (System.currentTimeMillis() % 1200L) / 1200f;
            float pulse = pulse(1200L, 0f);
            float width = size * 0.41f;
            float height = cell * 0.84f;
            RectF panel = new RectF(cx - width / 2f, cy - height / 2f, cx + width / 2f, cy + height / 2f);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(withAlpha(ThemeManager.GOLD, (int) (34 + pulse * 34)));
            canvas.drawRoundRect(new RectF(panel.left - cell * 0.10f, panel.top - cell * 0.10f,
                    panel.right + cell * 0.10f, panel.bottom + cell * 0.10f),
                    height * 0.56f, height * 0.56f, paint);
            paint.setAlpha(255);
            paint.setShader(new LinearGradient(panel.left, panel.top, panel.right, panel.bottom,
                    new int[]{0xaa361070, 0xcc163E62, 0xaa361070},
                    null,
                    Shader.TileMode.CLAMP));
            canvas.drawRoundRect(panel, height * 0.45f, height * 0.45f, paint);
            paint.setShader(null);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, cell * 0.040f));
            paint.setColor(ThemeManager.GOLD);
            canvas.drawRoundRect(panel, height * 0.45f, height * 0.45f, paint);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(withAlpha(0xffFF2E7E, 72));
            canvas.drawCircle(cx, cy, height * (0.62f + pulse * 0.20f), paint);
            paint.setAlpha(255);
            paint.setShader(new LinearGradient(cx - height * 0.46f, cy - height * 0.46f,
                    cx + height * 0.46f, cy + height * 0.46f,
                    0xffFF6CBD, 0xffE9005B, Shader.TileMode.CLAMP));
            canvas.drawCircle(cx, cy, height * 0.48f, paint);
            paint.setShader(null);
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
                    float amp = 0.10f + 0.13f * (float) Math.abs(Math.sin((phase * Math.PI * 2f) + i * 0.75f));
                    float y1 = cy - amp * cell;
                    float y2 = cy + amp * cell;
                    canvas.drawLine(x, y1, x, y2, paint);
                }
            }
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawPiece(Canvas canvas, JSONObject piece) {
            int seat = clampSeat(piece.optInt("seat", 0));
            float[] center = pieceDrawCenter(piece);
            drawPieceAt(canvas, piece, center[0], center[1], 0f);
        }

        private void drawPieceAt(Canvas canvas, JSONObject piece, float gridX, float gridY, float lift) {
            int seat = clampSeat(piece.optInt("seat", 0));
            int color = seatColor(seat);
            boolean yard = "yard".equals(piece.optString("state", ""));
            float x = ox + gridX * cell;
            float y = oy + gridY * cell - lift * cell * 0.34f;
            float radius = cell * (yard ? 0.38f : 0.35f) * (1f + lift * 0.12f);

            paint.setStyle(Paint.Style.FILL);
            paint.setColor(0x77000000);
            canvas.drawOval(new RectF(x - radius * 0.92f, y + radius * 0.48f,
                    x + radius * 0.92f, y + radius * 0.98f), paint);

            RectF foot = new RectF(x - radius * 0.76f, y + radius * 0.28f,
                    x + radius * 0.76f, y + radius * 0.74f);
            paint.setAlpha(255);
            paint.setShader(new LinearGradient(foot.left, foot.top, foot.right, foot.bottom,
                    brighten(color, 1.18f), darken(color, 0.72f), Shader.TileMode.CLAMP));
            canvas.drawOval(foot, paint);
            paint.setShader(null);

            RectF body = new RectF(x - radius * 0.43f, y - radius * 0.08f,
                    x + radius * 0.43f, y + radius * 0.48f);
            paint.setAlpha(255);
            paint.setShader(new LinearGradient(body.left, body.top, body.right, body.bottom,
                    new int[]{brighten(color, 1.28f), color, darken(color, 0.68f)},
                    null,
                    Shader.TileMode.CLAMP));
            canvas.drawRoundRect(body, radius * 0.24f, radius * 0.24f, paint);
            paint.setShader(null);

            paint.setAlpha(255);
            paint.setShader(new RadialGradient(x - radius * 0.18f, y - radius * 0.42f,
                    radius * 0.74f,
                    new int[]{0xffffffff, brighten(color, 1.20f), darken(color, 0.76f)},
                    null,
                    Shader.TileMode.CLAMP));
            canvas.drawCircle(x, y - radius * 0.42f, radius * 0.47f, paint);
            paint.setShader(null);

            paint.setColor(0x88FFFFFF);
            canvas.drawCircle(x - radius * 0.18f, y - radius * 0.58f, radius * 0.14f, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, cell * 0.050f));
            paint.setColor(0xEFFFFFFF);
            canvas.drawOval(foot, paint);
            canvas.drawRoundRect(body, radius * 0.24f, radius * 0.24f, paint);
            canvas.drawCircle(x, y - radius * 0.42f, radius * 0.47f, paint);

            paint.setStyle(Paint.Style.FILL);
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

        private float[] pieceDrawCenter(JSONObject piece) {
            int index = pieceIndex(piece.optString("pieceId", ""));
            float[] center = pieceCenter(piece);
            boolean yard = "yard".equals(piece.optString("state", ""));
            if (!yard) {
                float offset = 0.13f;
                if (index == 0) { center[0] -= offset; center[1] -= offset; }
                if (index == 1) { center[0] += offset; center[1] -= offset; }
                if (index == 2) { center[0] -= offset; center[1] += offset; }
                if (index == 3) { center[0] += offset; center[1] += offset; }
            }
            return center;
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
            RectF rect = rectForGrid(x, y, 1, 1, Math.max(1.2f, cell * 0.060f));
            float radius = cell * 0.12f;
            float depth = cell * 0.105f;
            paint.setStyle(Paint.Style.FILL);
            boolean neutral = Color.red(fill) > 238 && Color.green(fill) > 232 && Color.blue(fill) > 210;

            RectF lower = new RectF(rect);
            lower.offset(0, depth);
            paint.setColor(neutral ? 0xffC8B99C : darken(fill, 0.70f));
            canvas.drawRoundRect(lower, radius, radius, paint);

            paint.setColor(0x28000000);
            canvas.drawRoundRect(new RectF(rect.left + cell * 0.03f, rect.top + cell * 0.09f,
                    rect.right + cell * 0.03f, rect.bottom + cell * 0.11f),
                    radius, radius, paint);

            paint.setAlpha(255);
            paint.setShader(new LinearGradient(rect.left, rect.top, rect.right, rect.bottom,
                    neutral ? 0xffffffff : brighten(fill, 1.22f),
                    neutral ? 0xffFFF2CA : fill,
                    Shader.TileMode.CLAMP));
            canvas.drawRoundRect(rect, radius, radius, paint);
            paint.setShader(null);

            paint.setColor(neutral ? 0x44FFFFFF : 0x55FFFFFF);
            canvas.drawRoundRect(new RectF(rect.left + cell * 0.12f, rect.top + cell * 0.10f,
                    rect.right - cell * 0.12f, rect.top + rect.height() * 0.40f),
                    radius * 0.78f, radius * 0.78f, paint);

            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(1.4f, cell * 0.034f));
            paint.setColor(stroke);
            canvas.drawRoundRect(rect, radius, radius, paint);
            paint.setStrokeWidth(Math.max(0.8f, cell * 0.016f));
            paint.setColor(0xAAFFFFFF);
            canvas.drawRoundRect(new RectF(rect.left + cell * 0.08f, rect.top + cell * 0.08f,
                    rect.right - cell * 0.08f, rect.bottom - cell * 0.08f),
                    radius * 0.70f, radius * 0.70f, paint);
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

        private void drawTriangleGloss(Canvas canvas, float cx, float cy, float x1, float y1, float x2, float y2, int color) {
            path.reset();
            float p1x = ox + x1 * cell;
            float p1y = oy + y1 * cell;
            float p2x = ox + x2 * cell;
            float p2y = oy + y2 * cell;
            path.moveTo(cx, cy);
            path.lineTo(p1x, p1y);
            path.lineTo(p2x, p2y);
            path.close();
            paint.setStyle(Paint.Style.FILL);
            paint.setAlpha(255);
            paint.setShader(new LinearGradient(cx, cy, p1x, p1y,
                    brighten(color, 1.24f), darken(color, 0.78f), Shader.TileMode.CLAMP));
            canvas.drawPath(path, paint);
            paint.setShader(null);
            paint.setColor(0x33FFFFFF);
            canvas.drawPath(path, paint);
        }

        private void drawSafeStar(Canvas canvas, float gridX, float gridY) {
            float glow = pulse(1300L, (gridX + gridY) * 0.05f);
            float cx = ox + gridX * cell;
            float cy = oy + gridY * cell;
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(withAlpha(ThemeManager.GOLD, (int) (35 + glow * 45)));
            canvas.drawCircle(cx, cy, cell * (0.36f + glow * 0.10f), paint);
            drawStar(canvas, gridX, gridY, cell * 0.24f, ThemeManager.GOLD);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(1.5f, cell * 0.028f));
            paint.setColor(0xDDFFFFFF);
            canvas.drawCircle(cx, cy, cell * 0.30f, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawStartArrows(Canvas canvas) {
            drawLaneArrow(canvas, 6, 14, 0, 0xAAFFFFFF);
            drawLaneArrow(canvas, 0, 6, 1, 0xAAFFFFFF);
            drawLaneArrow(canvas, 8, 0, 2, 0xAAFFFFFF);
            drawLaneArrow(canvas, 14, 8, 3, 0xAAFFFFFF);
        }

        private void drawLaneArrow(Canvas canvas, int x, int y, int seat, int color) {
            float cx = ox + (x + 0.5f) * cell;
            float cy = oy + (y + 0.5f) * cell;
            float s = cell * 0.23f;
            path.reset();
            if (seat == 0) {
                path.moveTo(cx, cy - s);
                path.lineTo(cx - s * 0.78f, cy + s * 0.72f);
                path.lineTo(cx + s * 0.78f, cy + s * 0.72f);
            } else if (seat == 1) {
                path.moveTo(cx + s, cy);
                path.lineTo(cx - s * 0.72f, cy - s * 0.78f);
                path.lineTo(cx - s * 0.72f, cy + s * 0.78f);
            } else if (seat == 2) {
                path.moveTo(cx, cy + s);
                path.lineTo(cx - s * 0.78f, cy - s * 0.72f);
                path.lineTo(cx + s * 0.78f, cy - s * 0.72f);
            } else {
                path.moveTo(cx - s, cy);
                path.lineTo(cx + s * 0.72f, cy - s * 0.78f);
                path.lineTo(cx + s * 0.72f, cy + s * 0.78f);
            }
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

        private float pulse(long durationMs, float offset) {
            float p = ((System.currentTimeMillis() % durationMs) / (float) durationMs + offset) % 1f;
            return 0.5f + 0.5f * (float) Math.sin(p * Math.PI * 2f);
        }

        private float easeOutCubic(float t) {
            float p = 1f - Math.max(0f, Math.min(1f, t));
            return 1f - p * p * p;
        }

        private float lerp(float a, float b, float t) {
            return a + (b - a) * Math.max(0f, Math.min(1f, t));
        }

        private int withAlpha(int color, int alpha) {
            return (Math.max(0, Math.min(255, alpha)) << 24) | (color & 0x00FFFFFF);
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
    }
}
