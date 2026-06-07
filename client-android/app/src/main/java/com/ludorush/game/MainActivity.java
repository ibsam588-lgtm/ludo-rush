package com.ludorush.game;

import android.app.Activity;
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
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.TimeUnit;

public final class MainActivity extends Activity {
    private static final String BACKEND_URL = "https://ludo-rush-backend.ibsam588.workers.dev";
    private static final MediaType JSON = MediaType.get("application/json; charset=utf-8");

    private final Handler main = new Handler(Looper.getMainLooper());
    private final OkHttpClient http = new OkHttpClient.Builder()
            .readTimeout(0, TimeUnit.MILLISECONDS)
            .build();

    private TextView statusText;
    private TextView matchTitle;
    private TextView matchMeta;
    private TextView diceText;
    private TextView turnText;
    private TextView movesText;
    private TextView roomText;
    private LinearLayout playerStrip;
    private BoardView board;
    private Button playButton;
    private Button rollButton;
    private Button moveButton;
    private Button healthButton;

    private WebSocket socket;
    private String playerId;
    private String displayName = "Rush Tester";
    private JSONObject snapshot;
    private boolean backendOnline;
    private boolean connecting;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(createUi());
        updateUi();
        health();
    }

    @Override
    protected void onDestroy() {
        if (socket != null) {
            socket.close(1000, "activity_destroyed");
        }
        super.onDestroy();
    }

    private View createUi() {
        FrameLayout shell = new FrameLayout(this);
        shell.setBackgroundColor(Color.rgb(8, 11, 19));

        BackgroundView background = new BackgroundView(this);
        shell.addView(background, new FrameLayout.LayoutParams(-1, -1));

        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setOverScrollMode(View.OVER_SCROLL_NEVER);
        shell.addView(scroll, new FrameLayout.LayoutParams(-1, -1));

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(18), dp(20), dp(18), dp(18));
        scroll.addView(root, new ScrollView.LayoutParams(-1, -2));

        LinearLayout hero = new LinearLayout(this);
        hero.setOrientation(LinearLayout.VERTICAL);
        hero.setPadding(dp(20), dp(18), dp(20), dp(18));
        hero.setBackground(cardGradient(0xff192133, 0xff101827, dp(22)));
        root.addView(hero, lp(-1, -2, 0, 0, 0, dp(14)));

        LinearLayout top = new LinearLayout(this);
        top.setGravity(Gravity.CENTER_VERTICAL);
        top.setOrientation(LinearLayout.HORIZONTAL);
        hero.addView(top, lp(-1, -2));

        LinearLayout titleColumn = new LinearLayout(this);
        titleColumn.setOrientation(LinearLayout.VERTICAL);
        top.addView(titleColumn, new LinearLayout.LayoutParams(0, -2, 1));

        TextView brand = text("Ludo Rush", 32, Color.WHITE, Typeface.BOLD);
        titleColumn.addView(brand);

        matchTitle = text("Online board sprint", 15, 0xffAAB7CF, Typeface.BOLD);
        matchTitle.setPadding(0, dp(4), 0, 0);
        titleColumn.addView(matchTitle);

        TextView live = chip("LIVE BACKEND", 0xff37E6A5, 0x2237E6A5);
        top.addView(live);

        roomText = text("No room yet", 12, 0xff91A0BA, Typeface.NORMAL);
        roomText.setPadding(0, dp(14), 0, 0);
        hero.addView(roomText);

        LinearLayout stats = new LinearLayout(this);
        stats.setOrientation(LinearLayout.HORIZONTAL);
        stats.setGravity(Gravity.CENTER);
        hero.addView(stats, lp(-1, -2, 0, dp(16), 0, 0));

        diceText = metric("Dice", "-");
        turnText = metric("Turn", "Waiting");
        movesText = metric("Moves", "0");
        stats.addView(diceText, new LinearLayout.LayoutParams(0, dp(74), 1));
        stats.addView(turnText, new LinearLayout.LayoutParams(0, dp(74), 1));
        stats.addView(movesText, new LinearLayout.LayoutParams(0, dp(74), 1));

        playerStrip = new LinearLayout(this);
        playerStrip.setOrientation(LinearLayout.HORIZONTAL);
        playerStrip.setGravity(Gravity.CENTER);
        root.addView(playerStrip, lp(-1, -2, 0, 0, 0, dp(12)));

        board = new BoardView(this);
        root.addView(board, lp(-1, dp(420), 0, 0, 0, dp(14)));

        LinearLayout commandPanel = new LinearLayout(this);
        commandPanel.setOrientation(LinearLayout.VERTICAL);
        commandPanel.setPadding(dp(16), dp(16), dp(16), dp(16));
        commandPanel.setBackground(card(0xee111A2A, dp(20), 0x2237E6A5));
        root.addView(commandPanel, lp(-1, -2));

        statusText = text("Checking Cloudflare room server...", 15, 0xffE6ECF8, Typeface.BOLD);
        commandPanel.addView(statusText, lp(-1, -2, 0, 0, 0, dp(12)));

        matchMeta = text("Bot match is ready for internal gameplay testing.", 13, 0xff94A3B8, Typeface.NORMAL);
        commandPanel.addView(matchMeta, lp(-1, -2, 0, 0, 0, dp(14)));

        playButton = actionButton("Start Bot Match", 0xffFF4D6D, 0xffFFB14A);
        commandPanel.addView(playButton, lp(-1, dp(56), 0, 0, 0, dp(10)));
        playButton.setOnClickListener(v -> startBotMatch());

        LinearLayout actions = new LinearLayout(this);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        commandPanel.addView(actions, lp(-1, dp(54)));

        rollButton = secondaryButton("Roll Dice");
        moveButton = secondaryButton("Move Best Piece");
        healthButton = secondaryButton("Check Server");
        actions.addView(rollButton, new LinearLayout.LayoutParams(0, -1, 1));
        actions.addView(moveButton, new LinearLayout.LayoutParams(0, -1, 1));
        actions.addView(healthButton, new LinearLayout.LayoutParams(0, -1, 1));

        rollButton.setOnClickListener(v -> roll());
        moveButton.setOnClickListener(v -> moveFirstAvailable());
        healthButton.setOnClickListener(v -> health());

        return shell;
    }

    private TextView metric(String label, String value) {
        TextView view = new TextView(this);
        view.setGravity(Gravity.CENTER);
        view.setTextColor(Color.WHITE);
        view.setTextSize(16);
        view.setTypeface(Typeface.DEFAULT_BOLD);
        view.setText(label.toUpperCase(Locale.US) + "\n" + value);
        view.setBackground(card(0x331C2A3F, dp(16), 0x226C7A96));
        view.setPadding(dp(4), dp(8), dp(4), dp(8));
        return view;
    }

    private TextView chip(String text, int color, int fill) {
        TextView view = text(text, 11, color, Typeface.BOLD);
        view.setGravity(Gravity.CENTER);
        view.setPadding(dp(12), dp(8), dp(12), dp(8));
        view.setBackground(card(fill, dp(18), color));
        return view;
    }

    private Button actionButton(String label, int start, int end) {
        Button button = new Button(this);
        button.setAllCaps(false);
        button.setText(label);
        button.setTextColor(Color.WHITE);
        button.setTextSize(16);
        button.setTypeface(Typeface.DEFAULT_BOLD);
        button.setBackground(buttonGradient(start, end, dp(18)));
        return button;
    }

    private Button secondaryButton(String label) {
        Button button = new Button(this);
        button.setAllCaps(false);
        button.setText(label);
        button.setTextColor(Color.WHITE);
        button.setTextSize(13);
        button.setTypeface(Typeface.DEFAULT_BOLD);
        button.setBackground(card(0xff1A2638, dp(16), 0x335D6D86));
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, -1, 1);
        params.setMargins(dp(4), 0, dp(4), 0);
        button.setLayoutParams(params);
        return button;
    }

    private void health() {
        setStatus("Checking room server...");
        Request request = new Request.Builder().url(BACKEND_URL + "/health").build();
        http.newCall(request).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) {
                backendOnline = false;
                setStatus("Server offline: " + e.getMessage());
                main.post(MainActivity.this::updateUi);
            }

            @Override public void onResponse(Call call, Response response) {
                backendOnline = response.isSuccessful();
                setStatus(backendOnline ? "Server online. Start a bot match." : "Server error " + response.code());
                response.close();
                main.post(MainActivity.this::updateUi);
            }
        });
    }

    private void startBotMatch() {
        if (connecting) {
            return;
        }
        connecting = true;
        setStatus("Creating guest profile...");
        updateUi();
        post("/api/v1/auth/guest", json(
                "displayName", displayName,
                "region", "us-east"), body -> {
            JSONObject player = body.getJSONObject("player");
            playerId = player.getString("id");
            displayName = player.getString("displayName");
            setStatus("Creating bot match...");
            post("/api/v1/matchmaking/bots", json(
                    "playerId", playerId,
                    "displayName", displayName,
                    "mode", "classic_2p",
                    "region", "us-east",
                    "rating", player.optInt("rating", 1000)), match -> connect(match.getString("socketUrl")));
        });
    }

    private void connect(String socketPath) {
        String encodedName = encodeQuery(displayName);
        String wsUrl = BACKEND_URL.replace("https://", "wss://") + socketPath
                + "?playerId=" + playerId
                + "&displayName=" + encodedName;
        Request request = new Request.Builder().url(wsUrl).build();
        socket = http.newWebSocket(request, new WebSocketListener() {
            @Override public void onOpen(WebSocket webSocket, Response response) {
                connecting = false;
                send(json("type", "join", "playerId", playerId, "displayName", displayName));
                send(json("type", "fill_bots", "playerId", playerId));
                setStatus("Match connected. Bots are seated.");
                main.post(MainActivity.this::updateUi);
            }

            @Override public void onMessage(WebSocket webSocket, String text) {
                handleRoomMessage(text);
            }

            @Override public void onFailure(WebSocket webSocket, Throwable t, Response response) {
                connecting = false;
                setStatus("Socket error: " + t.getMessage());
                main.post(MainActivity.this::updateUi);
            }
        });
    }

    private String encodeQuery(String value) {
        try {
            return URLEncoder.encode(value, "UTF-8");
        } catch (UnsupportedEncodingException ignored) {
            return value.replace(" ", "%20");
        }
    }

    private void roll() {
        if (socket == null || playerId == null) {
            setStatus("Start a bot match first.");
            return;
        }
        if (!isMyTurn()) {
            setStatus("Wait for your turn.");
            return;
        }
        send(json("type", "roll_dice", "playerId", playerId));
        setStatus("Rolling server-controlled dice...");
    }

    private void moveFirstAvailable() {
        if (socket == null || snapshot == null) {
            setStatus("No active room.");
            return;
        }
        JSONArray moves = snapshot.optJSONArray("availableMoves");
        if (moves == null || moves.length() == 0) {
            setStatus("No legal move is available.");
            return;
        }
        String bestPiece = chooseBestMove(moves);
        send(json("type", "move_piece", "playerId", playerId, "pieceId", bestPiece));
        setStatus("Moving " + bestPiece + "...");
    }

    private String chooseBestMove(JSONArray moves) {
        String best = moves.optString(0);
        int bestScore = Integer.MIN_VALUE;
        JSONArray pieces = snapshot == null ? null : snapshot.optJSONArray("pieces");
        for (int i = 0; i < moves.length(); i += 1) {
            String id = moves.optString(i);
            int score = 0;
            if (pieces != null) {
                for (int j = 0; j < pieces.length(); j += 1) {
                    JSONObject piece = pieces.optJSONObject(j);
                    if (piece != null && id.equals(piece.optString("pieceId"))) {
                        score = piece.optInt("progress", -1);
                    }
                }
            }
            if (score > bestScore) {
                bestScore = score;
                best = id;
            }
        }
        return best;
    }

    private void handleRoomMessage(String text) {
        try {
            JSONObject envelope = new JSONObject(text);
            if ("error".equals(envelope.optString("type"))) {
                setStatus(envelope.optString("message", "Room error"));
                return;
            }

            JSONObject next = envelope.optJSONObject("snapshot");
            if (next != null) {
                snapshot = next;
                main.post(() -> {
                    board.setSnapshot(snapshot, playerId);
                    updateUi();
                });
            }
        } catch (Exception e) {
            setStatus("Message parse error: " + e.getMessage());
        }
    }

    private void updateUi() {
        RoomUi room = readRoom();
        diceText.setText("DICE\n" + room.dice);
        turnText.setText("TURN\n" + room.turn);
        movesText.setText("MOVES\n" + room.moves);
        roomText.setText(room.room);
        matchTitle.setText(room.title);
        matchMeta.setText(room.meta);

        if (room.status.length() > 0) {
            statusText.setText(room.status);
        }

        playButton.setEnabled(!connecting);
        playButton.setText(socket == null ? "Start Bot Match" : "New Bot Match");
        rollButton.setEnabled(room.canRoll);
        moveButton.setEnabled(room.canMove);
        healthButton.setEnabled(!connecting);
        setButtonAlpha(rollButton, room.canRoll);
        setButtonAlpha(moveButton, room.canMove);
        setButtonAlpha(playButton, !connecting);

        renderPlayers(room.seats);
    }

    private RoomUi readRoom() {
        RoomUi ui = new RoomUi();
        ui.title = backendOnline ? "Cloudflare realtime room" : "Waiting for server";
        ui.room = "Region us-east | Guest login | Server-authoritative dice";
        ui.meta = "Tap Start Bot Match to play against a server bot.";
        ui.status = "";
        ui.dice = "-";
        ui.turn = "Lobby";
        ui.moves = "0";
        ui.canRoll = false;
        ui.canMove = false;

        if (connecting) {
            ui.status = "Setting up a live match...";
            ui.turn = "Joining";
            return ui;
        }

        if (snapshot == null) {
            ui.status = backendOnline ? "Server online. Ready for a bot match." : "Checking Cloudflare backend...";
            return ui;
        }

        String mode = snapshot.optString("mode", "classic_2p").replace("_", " ").toUpperCase(Locale.US);
        String status = snapshot.optString("status", "waiting");
        int dice = snapshot.optInt("diceValue", 0);
        JSONArray moves = snapshot.optJSONArray("availableMoves");
        ui.dice = dice == 0 ? "-" : String.valueOf(dice);
        ui.moves = String.valueOf(moves == null ? 0 : moves.length());
        ui.room = "Room " + shortRoom(snapshot.optString("roomId")) + " | " + mode + " | " + snapshot.optString("region", "global");
        ui.title = "Live " + mode;

        int mySeat = mySeat();
        int turnSeat = snapshot.optInt("currentTurnSeat", -1);
        boolean myTurn = mySeat >= 0 && mySeat == turnSeat && "playing".equals(status);
        ui.turn = myTurn ? "You" : seatName(turnSeat);
        ui.canRoll = myTurn && dice == 0;
        ui.canMove = myTurn && dice > 0 && moves != null && moves.length() > 0;

        if ("finished".equals(status)) {
            ui.status = winnerText();
            ui.turn = "Done";
        } else if (ui.canRoll) {
            ui.status = "Your turn. Roll the dice.";
        } else if (ui.canMove) {
            ui.status = "Dice " + dice + ". Choose Move Best Piece.";
        } else if (myTurn) {
            ui.status = "No legal move. Waiting for server turn advance.";
        } else {
            ui.status = "Waiting for " + seatName(turnSeat) + ".";
        }

        JSONArray seats = snapshot.optJSONArray("seats");
        if (seats != null) {
            for (int i = 0; i < seats.length(); i += 1) {
                JSONObject seat = seats.optJSONObject(i);
                if (seat != null) {
                    ui.seats.add(seat);
                }
            }
        }

        return ui;
    }

    private void renderPlayers(List<JSONObject> seats) {
        playerStrip.removeAllViews();
        if (seats.isEmpty()) {
            playerStrip.addView(playerCard("You", "Start a match", 0, false, false), new LinearLayout.LayoutParams(0, dp(72), 1));
            playerStrip.addView(playerCard("Rush Bot", "Waiting", 1, false, true), new LinearLayout.LayoutParams(0, dp(72), 1));
            return;
        }

        for (JSONObject seat : seats) {
            int index = seat.optInt("seat", 0);
            boolean isMe = playerId != null && playerId.equals(seat.optString("playerId"));
            boolean active = snapshot != null && snapshot.optInt("currentTurnSeat", -1) == index;
            String name = isMe ? "You" : seat.optString("displayName", "Player");
            String label = seat.optBoolean("isBot") ? "Bot" : (seat.optBoolean("connected", true) ? "Online" : "Offline");
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, dp(72), 1);
            params.setMargins(dp(4), 0, dp(4), 0);
            playerStrip.addView(playerCard(name, label, index, active, seat.optBoolean("isBot")), params);
        }
    }

    private View playerCard(String name, String label, int seat, boolean active, boolean bot) {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.HORIZONTAL);
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(10), dp(8), dp(10), dp(8));
        card.setBackground(card(active ? 0xee20324A : 0xcc111A2A, dp(18), active ? seatColor(seat) : 0x225D6D86));

        ColorDot dot = new ColorDot(this, seatColor(seat));
        card.addView(dot, new LinearLayout.LayoutParams(dp(34), dp(34)));

        LinearLayout textColumn = new LinearLayout(this);
        textColumn.setOrientation(LinearLayout.VERTICAL);
        textColumn.setPadding(dp(9), 0, 0, 0);
        card.addView(textColumn, new LinearLayout.LayoutParams(0, -2, 1));

        TextView nameView = text(name, 13, Color.WHITE, Typeface.BOLD);
        nameView.setSingleLine(true);
        textColumn.addView(nameView);
        TextView sub = text((active ? "Turn" : label) + (bot ? " AI" : ""), 11, 0xff9AA8C2, Typeface.NORMAL);
        sub.setSingleLine(true);
        textColumn.addView(sub);

        return card;
    }

    private boolean isMyTurn() {
        return snapshot != null && mySeat() == snapshot.optInt("currentTurnSeat", -1) && "playing".equals(snapshot.optString("status"));
    }

    private int mySeat() {
        if (snapshot == null || playerId == null) {
            return -1;
        }
        JSONArray seats = snapshot.optJSONArray("seats");
        if (seats == null) {
            return -1;
        }
        for (int i = 0; i < seats.length(); i += 1) {
            JSONObject seat = seats.optJSONObject(i);
            if (seat != null && playerId.equals(seat.optString("playerId"))) {
                return seat.optInt("seat", -1);
            }
        }
        return -1;
    }

    private String seatName(int seatIndex) {
        if (snapshot == null) {
            return "Player";
        }
        JSONArray seats = snapshot.optJSONArray("seats");
        if (seats == null) {
            return "Seat " + (seatIndex + 1);
        }
        for (int i = 0; i < seats.length(); i += 1) {
            JSONObject seat = seats.optJSONObject(i);
            if (seat != null && seat.optInt("seat", -1) == seatIndex) {
                if (playerId != null && playerId.equals(seat.optString("playerId"))) {
                    return "You";
                }
                return seat.optString("displayName", "Seat " + (seatIndex + 1));
            }
        }
        return "Seat " + (seatIndex + 1);
    }

    private String winnerText() {
        String winner = snapshot == null ? "" : snapshot.optString("winnerPlayerId", "");
        if (playerId != null && playerId.equals(winner)) {
            return "You won the match.";
        }
        JSONArray seats = snapshot == null ? null : snapshot.optJSONArray("seats");
        if (seats != null) {
            for (int i = 0; i < seats.length(); i += 1) {
                JSONObject seat = seats.optJSONObject(i);
                if (seat != null && winner.equals(seat.optString("playerId"))) {
                    return seat.optString("displayName", "Opponent") + " won.";
                }
            }
        }
        return "Match finished.";
    }

    private void post(String path, JSONObject payload, JsonHandler handler) {
        Request request = new Request.Builder()
                .url(BACKEND_URL + path)
                .post(RequestBody.create(payload.toString(), JSON))
                .build();
        http.newCall(request).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) {
                connecting = false;
                setStatus("Request failed: " + e.getMessage());
                main.post(MainActivity.this::updateUi);
            }

            @Override public void onResponse(Call call, Response response) throws IOException {
                String text = response.body() == null ? "{}" : response.body().string();
                response.close();
                try {
                    if (!response.isSuccessful()) {
                        connecting = false;
                        setStatus("HTTP " + response.code() + ": " + text);
                        main.post(MainActivity.this::updateUi);
                        return;
                    }
                    handler.handle(new JSONObject(text));
                } catch (Exception e) {
                    connecting = false;
                    setStatus("Response error: " + e.getMessage());
                    main.post(MainActivity.this::updateUi);
                }
            }
        });
    }

    private void send(JSONObject message) {
        if (socket != null) {
            socket.send(message.toString());
        }
    }

    private JSONObject json(Object... values) {
        JSONObject object = new JSONObject();
        for (int i = 0; i + 1 < values.length; i += 2) {
            try {
                object.put(String.valueOf(values[i]), values[i + 1]);
            } catch (Exception e) {
                throw new IllegalArgumentException("Invalid JSON payload", e);
            }
        }
        return object;
    }

    private void setStatus(String text) {
        main.post(() -> {
            if (statusText != null) {
                statusText.setText(text);
            }
        });
    }

    private String shortRoom(String roomId) {
        if (roomId == null || roomId.length() <= 8) {
            return roomId == null ? "-" : roomId;
        }
        return roomId.substring(0, 4) + "-" + roomId.substring(roomId.length() - 4);
    }

    private void setButtonAlpha(Button button, boolean enabled) {
        button.setAlpha(enabled ? 1f : 0.42f);
    }

    private TextView text(String text, int sp, int color, int style) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextSize(sp);
        view.setTextColor(color);
        view.setTypeface(Typeface.DEFAULT, style);
        view.setIncludeFontPadding(true);
        return view;
    }

    private LinearLayout.LayoutParams lp(int width, int height) {
        return new LinearLayout.LayoutParams(width, height);
    }

    private LinearLayout.LayoutParams lp(int width, int height, int left, int top, int right, int bottom) {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(width, height);
        params.setMargins(left, top, right, bottom);
        return params;
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    private GradientDrawable card(int color, int radius, int strokeColor) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(radius);
        drawable.setStroke(dp(1), strokeColor);
        return drawable;
    }

    private GradientDrawable cardGradient(int start, int end, int radius) {
        GradientDrawable drawable = new GradientDrawable(GradientDrawable.Orientation.TL_BR, new int[]{start, end});
        drawable.setCornerRadius(radius);
        drawable.setStroke(dp(1), 0x334B5D78);
        return drawable;
    }

    private GradientDrawable buttonGradient(int start, int end, int radius) {
        GradientDrawable drawable = new GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT, new int[]{start, end});
        drawable.setCornerRadius(radius);
        return drawable;
    }

    private int seatColor(int seat) {
        int[] colors = {0xffE8293E, 0xff1E88E5, 0xffF9A825, 0xff43A047};
        return colors[Math.max(0, Math.min(colors.length - 1, seat))];
    }

    private interface JsonHandler {
        void handle(JSONObject body) throws Exception;
    }

    private static final class RoomUi {
        String title;
        String room;
        String meta;
        String status;
        String dice;
        String turn;
        String moves;
        boolean canRoll;
        boolean canMove;
        final List<JSONObject> seats = new ArrayList<>();
    }

    public static final class BackgroundView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);

        public BackgroundView(Activity activity) {
            super(activity);
        }

        @Override protected void onDraw(Canvas canvas) {
            int width = getWidth();
            int height = getHeight();
            paint.setShader(new LinearGradient(0, 0, width, height,
                    new int[]{0xff07111F, 0xff111827, 0xff0A0F1B},
                    null, Shader.TileMode.CLAMP));
            canvas.drawRect(0, 0, width, height, paint);

            paint.setShader(new RadialGradient(width * 0.15f, height * 0.08f, width * 0.55f,
                    0x5522C7E8, 0x00111827, Shader.TileMode.CLAMP));
            canvas.drawCircle(width * 0.15f, height * 0.08f, width * 0.55f, paint);
            paint.setShader(new RadialGradient(width * 0.9f, height * 0.22f, width * 0.45f,
                    0x44FFB14A, 0x000A0F1B, Shader.TileMode.CLAMP));
            canvas.drawCircle(width * 0.9f, height * 0.22f, width * 0.45f, paint);
            paint.setShader(null);
        }
    }

    public static final class ColorDot extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final int color;

        public ColorDot(Activity activity, int color) {
            super(activity);
            this.color = color;
        }

        @Override protected void onDraw(Canvas canvas) {
            int size = Math.min(getWidth(), getHeight());
            float cx = getWidth() / 2f;
            float cy = getHeight() / 2f;
            paint.setColor(0xff0B1020);
            canvas.drawCircle(cx, cy, size * 0.48f, paint);
            paint.setColor(color);
            canvas.drawCircle(cx, cy, size * 0.34f, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(2f, size * 0.08f));
            paint.setColor(0x66FFFFFF);
            canvas.drawCircle(cx, cy, size * 0.34f, paint);
            paint.setStyle(Paint.Style.FILL);
        }
    }

    public static final class BoardView extends View {
        private static final int[][] PATH = {
                {6,14},{6,13},{6,12},{6,11},{6,10},{6,9},{5,8},{4,8},{3,8},{2,8},{1,8},{0,8},{0,7},
                {0,6},{1,6},{2,6},{3,6},{4,6},{5,6},{6,5},{6,4},{6,3},{6,2},{6,1},{6,0},{7,0},
                {8,0},{8,1},{8,2},{8,3},{8,4},{8,5},{9,6},{10,6},{11,6},{12,6},{13,6},{14,6},{14,7},
                {14,8},{13,8},{12,8},{11,8},{10,8},{9,8},{8,9},{8,10},{8,11},{8,12},{8,13},{8,14},{7,14}
        };
        private static final int[][] SAFE = {{6,14},{3,8},{0,6},{6,3},{8,0},{11,6},{14,8},{8,11}};
        private static final int[][][] HOME_LANES = {
                {{7,13},{7,12},{7,11},{7,10},{7,9}},
                {{1,7},{2,7},{3,7},{4,7},{5,7}},
                {{7,1},{7,2},{7,3},{7,4},{7,5}},
                {{13,7},{12,7},{11,7},{10,7},{9,7}}
        };

        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF rect = new RectF();
        private JSONObject snapshot;
        private String playerId;

        public BoardView(Activity activity) {
            super(activity);
            setMinimumHeight(720);
        }

        public void setSnapshot(JSONObject snapshot, String playerId) {
            this.snapshot = snapshot;
            this.playerId = playerId;
            invalidate();
        }

        @Override protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int width = getWidth();
            int height = getHeight();
            int size = Math.min(width - 8, height - 8);
            int left = (width - size) / 2;
            int top = (height - size) / 2;
            float cell = size / 15f;

            drawBoardShell(canvas, left, top, size);
            drawBases(canvas, left, top, cell);
            drawTrack(canvas, left, top, cell);
            drawHomeLanes(canvas, left, top, cell);
            drawCenter(canvas, left, top, cell);
            drawPieces(canvas, left, top, cell);
            drawEmptyState(canvas, left, top, size);
        }

        private void drawBoardShell(Canvas canvas, int left, int top, int size) {
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

        private void drawBase(Canvas canvas, int left, int top, float cell, int gx, int gy, int color) {
            float x1 = left + gx * cell;
            float y1 = top + gy * cell;
            float x2 = left + (gx + 6) * cell;
            float y2 = top + (gy + 6) * cell;
            rect.set(x1, y1, x2, y2);
            paint.setColor(color);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(cell * 0.08f);
            paint.setColor(0x33000000);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);
            float inset = cell * 0.85f;
            rect.set(x1 + inset, y1 + inset, x2 - inset, y2 - inset);
            paint.setColor(0xffFFF8EE);
            canvas.drawRect(rect, paint);
            float cx = (x1 + x2) / 2f;
            float cy = (y1 + y2) / 2f;
            float off = cell * 0.9f;
            float r = cell * 0.45f;
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
            int[] startIdx = {0, 13, 26, 39};
            int[] startClr = {0xffE8293E, 0xff1E88E5, 0xffF9A825, 0xff43A047};
            for (int i = 0; i < PATH.length; i++) {
                int[] point = PATH[i];
                int fill = 0xffFFFFFF;
                int stroke = 0x22000000;
                for (int s = 0; s < startIdx.length; s++) {
                    if (i == startIdx[s]) {
                        fill = startClr[s];
                        stroke = 0x44000000;
                        break;
                    }
                }
                drawCell(canvas, left, top, cell, point[0], point[1], fill, stroke);
            }
            for (int[] point : SAFE) {
                boolean isStart = false;
                for (int si : startIdx) {
                    if (PATH[si][0] == point[0] && PATH[si][1] == point[1]) {
                        isStart = true;
                        break;
                    }
                }
                int starColor = isStart ? 0xccFFFFFF : 0xff888888;
                drawStar(canvas, left + (point[0] + 0.5f) * cell, top + (point[1] + 0.5f) * cell, cell * 0.25f, starColor);
            }
        }

        private void drawHomeLanes(Canvas canvas, int left, int top, float cell) {
            int[] fills = {0xffF8B4BF, 0xffA8D8EA, 0xffFFF0A0, 0xffA8E6CF};
            int[] strokes = {0xffE8293E, 0xff1E88E5, 0xffF9A825, 0xff43A047};
            for (int seat = 0; seat < HOME_LANES.length; seat += 1) {
                for (int[] point : HOME_LANES[seat]) {
                    drawCell(canvas, left, top, cell, point[0], point[1], fills[seat], strokes[seat]);
                }
            }
        }

        private void drawCenter(Canvas canvas, int left, int top, float cell) {
            int[] colors = {0xffE8293E, 0xff1E88E5, 0xffF9A825, 0xff43A047};
            float cx = left + 7.5f * cell;
            float cy = top + 7.5f * cell;
            float x6 = left + 6 * cell;
            float x9 = left + 9 * cell;
            float y6 = top + 6 * cell;
            float y9 = top + 9 * cell;
            Path tri = new Path();
            tri.moveTo(x6, y9); tri.lineTo(x9, y9); tri.lineTo(cx, cy); tri.close();
            paint.setColor(colors[0]);
            canvas.drawPath(tri, paint);
            tri.reset();
            tri.moveTo(x6, y6); tri.lineTo(x6, y9); tri.lineTo(cx, cy); tri.close();
            paint.setColor(colors[1]);
            canvas.drawPath(tri, paint);
            tri.reset();
            tri.moveTo(x6, y6); tri.lineTo(x9, y6); tri.lineTo(cx, cy); tri.close();
            paint.setColor(colors[2]);
            canvas.drawPath(tri, paint);
            tri.reset();
            tri.moveTo(x9, y6); tri.lineTo(x9, y9); tri.lineTo(cx, cy); tri.close();
            paint.setColor(colors[3]);
            canvas.drawPath(tri, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(cell * 0.06f);
            paint.setColor(0x44000000);
            canvas.drawLine(x6, y6, x9, y9, paint);
            canvas.drawLine(x6, y9, x9, y6, paint);
            tri.reset();
            tri.moveTo(x6, y6); tri.lineTo(x9, y6); tri.lineTo(x9, y9); tri.lineTo(x6, y9); tri.close();
            canvas.drawPath(tri, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawCell(Canvas canvas, int left, int top, float cell, int gx, int gy, int fill, int stroke) {
            float pad = cell * 0.03f;
            rect.set(left + gx * cell + pad, top + gy * cell + pad, left + (gx + 1) * cell - pad, top + (gy + 1) * cell - pad);
            paint.setColor(fill);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(Math.max(1f, cell * 0.04f));
            paint.setColor(stroke);
            canvas.drawRect(rect, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private void drawPieces(Canvas canvas, int left, int top, float cell) {
            if (snapshot == null) {
                return;
            }
            JSONArray pieces = snapshot.optJSONArray("pieces");
            if (pieces == null) {
                return;
            }
            JSONArray available = snapshot.optJSONArray("availableMoves");
            int activeSeat = snapshot.optInt("currentTurnSeat", -1);

            for (int i = 0; i < pieces.length(); i += 1) {
                JSONObject piece = pieces.optJSONObject(i);
                if (piece == null) {
                    continue;
                }
                float[] pos = piecePosition(piece, left, top, cell);
                int seat = piece.optInt("seat");
                boolean legal = contains(available, piece.optString("pieceId"));
                boolean active = activeSeat == seat;
                drawPiece(canvas, pos[0], pos[1], cell * 0.38f, seatColor(seat), legal, active);
            }
        }

        private void drawPiece(Canvas canvas, float cx, float cy, float radius, int color, boolean legal, boolean active) {
            if (legal || active) {
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(legal ? radius * 0.28f : radius * 0.16f);
                paint.setColor(legal ? 0xffFFFFFF : 0x88FFFFFF);
                canvas.drawCircle(cx, cy, radius * (legal ? 1.45f : 1.28f), paint);
                paint.setStyle(Paint.Style.FILL);
            }
            paint.setColor(0x33000000);
            canvas.drawCircle(cx + radius * 0.18f, cy + radius * 0.22f, radius, paint);
            paint.setColor(color);
            canvas.drawCircle(cx, cy, radius, paint);
            paint.setShader(new RadialGradient(cx - radius * 0.25f, cy - radius * 0.3f, radius * 1.2f,
                    0xAAFFFFFF, 0x00000000, Shader.TileMode.CLAMP));
            canvas.drawCircle(cx, cy, radius, paint);
            paint.setShader(null);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(radius * 0.16f);
            paint.setColor(0xeeFFFFFF);
            canvas.drawCircle(cx, cy, radius, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private float[] piecePosition(JSONObject piece, int left, int top, float cell) {
            int seat = piece.optInt("seat");
            int pieceIndex = pieceIndex(piece.optString("pieceId"));
            String state = piece.optString("state");
            int progress = piece.optInt("progress", -1);
            if ("yard".equals(state) || progress < 0) {
                return yardPosition(seat, pieceIndex, left, top, cell);
            }
            if ("finished".equals(state) || progress >= 57) {
                return offset(left + 7.5f * cell, top + 7.5f * cell, pieceIndex, cell);
            }
            if ("home".equals(state) || progress > 51) {
                int laneIndex = Math.max(0, Math.min(4, progress - 52));
                int[] point = HOME_LANES[Math.max(0, Math.min(3, seat))][laneIndex];
                return offset(left + (point[0] + 0.5f) * cell, top + (point[1] + 0.5f) * cell, pieceIndex, cell * 0.4f);
            }
            int trackIndex = piece.optInt("trackIndex", -1);
            if (trackIndex < 0 || trackIndex >= PATH.length) {
                trackIndex = (seatStart(seat) + progress) % PATH.length;
            }
            int[] point = PATH[trackIndex];
            return offset(left + (point[0] + 0.5f) * cell, top + (point[1] + 0.5f) * cell, pieceIndex, cell * 0.34f);
        }

        private float[] yardPosition(int seat, int index, int left, int top, float cell) {
            int[][] bases = {{0, 9}, {0, 0}, {9, 0}, {9, 9}};
            int safeSeat = Math.max(0, Math.min(3, seat));
            int gx = bases[safeSeat][0];
            int gy = bases[safeSeat][1];
            float[][] slots = {{2.1f, 2.1f}, {3.9f, 2.1f}, {2.1f, 3.9f}, {3.9f, 3.9f}};
            return new float[]{
                    left + (gx + slots[index % 4][0]) * cell,
                    top + (gy + slots[index % 4][1]) * cell
            };
        }

        private float[] offset(float x, float y, int index, float amount) {
            float d = Math.max(3f, amount * 0.16f);
            return new float[]{x + (index % 2 == 0 ? -d : d), y + (index < 2 ? -d : d)};
        }

        private int pieceIndex(String pieceId) {
            if (pieceId == null || pieceId.length() == 0) {
                return 0;
            }
            char last = pieceId.charAt(pieceId.length() - 1);
            return last >= '0' && last <= '3' ? last - '0' : 0;
        }

        private int seatStart(int seat) {
            int[] starts = {0, 13, 26, 39};
            return starts[Math.max(0, Math.min(3, seat))];
        }

        private boolean contains(JSONArray array, String value) {
            if (array == null || value == null) {
                return false;
            }
            for (int i = 0; i < array.length(); i += 1) {
                if (value.equals(array.optString(i))) {
                    return true;
                }
            }
            return false;
        }

        private void drawEmptyState(Canvas canvas, int left, int top, int size) {
            if (snapshot != null) {
                return;
            }
            paint.setColor(0xAA0B1020);
            rect.set(left + size * 0.18f, top + size * 0.39f, left + size * 0.82f, top + size * 0.61f);
            canvas.drawRoundRect(rect, size * 0.05f, size * 0.05f, paint);
            paint.setColor(Color.WHITE);
            paint.setTypeface(Typeface.DEFAULT_BOLD);
            paint.setTextSize(size * 0.047f);
            paint.setTextAlign(Paint.Align.CENTER);
            canvas.drawText("Start a match", left + size / 2f, top + size * 0.49f, paint);
            paint.setTextSize(size * 0.032f);
            paint.setColor(0xffB8C4D8);
            canvas.drawText("Server bots join instantly", left + size / 2f, top + size * 0.55f, paint);
            paint.setTextAlign(Paint.Align.LEFT);
        }

        private void drawStar(Canvas canvas, float cx, float cy, float radius, int color) {
            Path star = new Path();
            for (int i = 0; i < 10; i += 1) {
                double angle = -Math.PI / 2 + i * Math.PI / 5;
                float r = i % 2 == 0 ? radius : radius * 0.45f;
                float x = cx + (float) Math.cos(angle) * r;
                float y = cy + (float) Math.sin(angle) * r;
                if (i == 0) {
                    star.moveTo(x, y);
                } else {
                    star.lineTo(x, y);
                }
            }
            star.close();
            paint.setColor(color);
            canvas.drawPath(star, paint);
        }

        private int seatColor(int seat) {
            int[] colors = {0xffE8293E, 0xff1E88E5, 0xffF9A825, 0xff43A047};
            return colors[Math.max(0, Math.min(colors.length - 1, seat))];
        }
    }
}
