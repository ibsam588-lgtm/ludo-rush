package com.ludorush.game;

import android.app.Activity;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.RadialGradient;
import android.graphics.Shader;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.FrameLayout;
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
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.concurrent.TimeUnit;

public final class MainActivity extends Activity implements BaseScreen.ScreenCallback {
    private static final String BACKEND_URL = "https://ludo-rush-backend.ibsam588.workers.dev";
    private static final MediaType JSON = MediaType.get("application/json; charset=utf-8");

    private final Handler main = new Handler(Looper.getMainLooper());
    private final OkHttpClient http = new OkHttpClient.Builder()
            .readTimeout(0, TimeUnit.MILLISECONDS)
            .build();
    private final Deque<String> screenStack = new ArrayDeque<>();

    private FrameLayout container;
    private View currentScreenView;
    private GameScreen gameScreen;

    private WebSocket socket;
    private String playerId;
    private String displayName = "Rush Tester";
    private int coins = 500;
    private int rating = 1000;
    private int gamesPlayed = 0;
    private int wins = 0;
    private boolean backendOnline;
    private boolean connecting;
    private JSONObject lastSnapshot;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        FrameLayout shell = new FrameLayout(this);
        shell.setBackgroundColor(Color.rgb(8, 11, 19));

        BackgroundView bg = new BackgroundView(this);
        shell.addView(bg, new FrameLayout.LayoutParams(-1, -1));

        container = new FrameLayout(this);
        shell.addView(container, new FrameLayout.LayoutParams(-1, -1));

        setContentView(shell);
        healthCheck();
        navigateTo("home");
    }

    @Override
    protected void onDestroy() {
        if (socket != null) socket.close(1000, "activity_destroyed");
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        if (screenStack.size() > 1) {
            goBack();
        } else {
            showExitDialog();
        }
    }

    private void showExitDialog() {
        android.app.Dialog dialog = new android.app.Dialog(this);
        dialog.requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);

        float density = getResources().getDisplayMetrics().density;
        int d20 = (int) (20 * density), d12 = (int) (12 * density), d8 = (int) (8 * density);

        android.widget.LinearLayout panel = new android.widget.LinearLayout(this);
        panel.setOrientation(android.widget.LinearLayout.VERTICAL);
        panel.setGravity(android.view.Gravity.CENTER_HORIZONTAL);
        panel.setPadding(d20, (int) (24 * density), d20, d20);
        android.graphics.drawable.GradientDrawable bg = new android.graphics.drawable.GradientDrawable(
                android.graphics.drawable.GradientDrawable.Orientation.TL_BR,
                new int[]{0xff1A2440, 0xff0F1626});
        bg.setCornerRadius(24 * density);
        bg.setStroke((int) density, 0x55809BC8);
        panel.setBackground(bg);

        android.widget.TextView icon = new android.widget.TextView(this);
        icon.setText("👋");
        icon.setTextSize(34);
        icon.setGravity(android.view.Gravity.CENTER);
        panel.addView(icon);

        android.widget.TextView title = new android.widget.TextView(this);
        title.setText("Quit Ludo Rush?");
        title.setTextSize(20);
        title.setTextColor(Color.WHITE);
        title.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
        title.setGravity(android.view.Gravity.CENTER);
        title.setPadding(0, d8, 0, 0);
        panel.addView(title);

        android.widget.TextView msg = new android.widget.TextView(this);
        msg.setText("Do you want to quit the app?");
        msg.setTextSize(14);
        msg.setTextColor(0xff8B9BB4);
        msg.setGravity(android.view.Gravity.CENTER);
        msg.setPadding(0, (int) (4 * density), 0, (int) (18 * density));
        panel.addView(msg);

        android.widget.LinearLayout buttons = new android.widget.LinearLayout(this);
        buttons.setOrientation(android.widget.LinearLayout.HORIZONTAL);
        panel.addView(buttons, new android.widget.LinearLayout.LayoutParams(-1, -2));

        android.widget.Button stay = new android.widget.Button(this);
        stay.setAllCaps(false);
        stay.setText("Stay");
        stay.setTextColor(Color.WHITE);
        stay.setTextSize(15);
        stay.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
        android.graphics.drawable.GradientDrawable stayBg = new android.graphics.drawable.GradientDrawable();
        stayBg.setColor(0xff1B2740);
        stayBg.setCornerRadius(16 * density);
        stayBg.setStroke((int) density, 0x446F84A8);
        stay.setBackground(stayBg);
        stay.setOnClickListener(v -> dialog.dismiss());
        android.widget.LinearLayout.LayoutParams sp =
                new android.widget.LinearLayout.LayoutParams(0, (int) (48 * density), 1);
        sp.setMargins(0, 0, d8, 0);
        buttons.addView(stay, sp);

        android.widget.Button quit = new android.widget.Button(this);
        quit.setAllCaps(false);
        quit.setText("Quit");
        quit.setTextColor(Color.WHITE);
        quit.setTextSize(15);
        quit.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
        android.graphics.drawable.GradientDrawable quitBg = new android.graphics.drawable.GradientDrawable(
                android.graphics.drawable.GradientDrawable.Orientation.LEFT_RIGHT,
                new int[]{0xffFF3D5A, 0xffFF9F1C});
        quitBg.setCornerRadius(16 * density);
        quit.setBackground(quitBg);
        quit.setOnClickListener(v -> {
            dialog.dismiss();
            finish();
        });
        android.widget.LinearLayout.LayoutParams qp =
                new android.widget.LinearLayout.LayoutParams(0, (int) (48 * density), 1);
        qp.setMargins(d8, 0, 0, 0);
        buttons.addView(quit, qp);

        dialog.setContentView(panel);
        android.view.Window w = dialog.getWindow();
        if (w != null) {
            w.setBackgroundDrawable(new android.graphics.drawable.ColorDrawable(Color.TRANSPARENT));
            w.setLayout((int) (getResources().getDisplayMetrics().widthPixels * 0.82f), -2);
        }
        dialog.show();
    }

    @Override
    public void navigateTo(String screen) {
        navigateTo(screen, null);
    }

    @Override
    public void navigateTo(String screen, String data) {
        main.post(() -> showScreen(screen, data));
    }

    @Override
    public void goBack() {
        main.post(() -> {
            if (screenStack.size() <= 1) return;
            screenStack.pop();
            String prev = screenStack.peek();
            if (prev != null) showScreen(prev, null);
        });
    }

    @Override public String getPlayerId() { return playerId; }
    @Override public String getDisplayName() { return displayName; }
    @Override public int getCoins() { return coins; }
    @Override public int getRating() { return rating; }
    @Override public int getGamesPlayed() { return gamesPlayed; }
    @Override public int getWins() { return wins; }
    @Override public boolean isOnline() { return backendOnline; }

    @Override
    public void startBotMatch(String mode) {
        if (connecting) return;
        connecting = true;
        navigateTo("game");
        updateGameStatus("Creating guest profile...");

        post("/api/v1/auth/guest", json("displayName", displayName, "region", "us-east"), body -> {
            JSONObject player = body.getJSONObject("player");
            playerId = player.getString("id");
            displayName = player.getString("displayName");
            rating = player.optInt("rating", 1000);
            coins = player.optInt("coins", 500);

            updateGameStatus("Creating bot match...");
            post("/api/v1/matchmaking/bots", json(
                    "playerId", playerId,
                    "displayName", displayName,
                    "mode", mode,
                    "region", "us-east",
                    "rating", rating), match -> connect(match.getString("socketUrl")));
        });
    }

    @Override
    public void startQuickMatch(String mode) {
        if (connecting) return;
        connecting = true;
        navigateTo("game");
        updateGameStatus("Creating guest profile...");

        post("/api/v1/auth/guest", json("displayName", displayName, "region", "us-east"), body -> {
            JSONObject player = body.getJSONObject("player");
            playerId = player.getString("id");
            displayName = player.getString("displayName");
            rating = player.optInt("rating", 1000);
            coins = player.optInt("coins", 500);

            updateGameStatus("Searching for match...");
            post("/api/v1/matchmaking/quick", json(
                    "playerId", playerId,
                    "displayName", displayName,
                    "mode", mode,
                    "region", "us-east",
                    "rating", rating), ticket -> {
                String ticketId = ticket.optString("ticketId", "");
                if (ticketId.isEmpty()) {
                    updateGameStatus("Matchmaking failed.");
                    connecting = false;
                    return;
                }
                pollTicket(ticketId, 0);
            });
        });
    }

    @Override
    public void rollDice() {
        if (socket == null || playerId == null) return;
        send(json("type", "roll_dice", "playerId", playerId));
    }

    @Override
    public void moveBestPiece() {
        if (socket == null || lastSnapshot == null) return;
        JSONArray moves = lastSnapshot.optJSONArray("availableMoves");
        if (moves == null || moves.length() == 0) return;
        String best = chooseBest(moves);
        send(json("type", "move_piece", "playerId", playerId, "pieceId", best));
    }

    @Override
    public void resign() {
        if (socket != null && playerId != null) {
            send(json("type", "resign", "playerId", playerId));
        }
    }

    private void showScreen(String name, String data) {
        if (currentScreenView != null) {
            container.removeView(currentScreenView);
        }

        BaseScreen screen = createScreen(name, data);
        View view = screen.createView();
        container.addView(view, new FrameLayout.LayoutParams(-1, -1));
        if ("game".equals(name)) {
            gameScreen = (GameScreen) screen;
            if (lastSnapshot != null) {
                gameScreen.updateSnapshot(lastSnapshot, playerId);
            }
        }

        currentScreenView = view;
        if (screenStack.isEmpty() || !name.equals(screenStack.peek())) {
            screenStack.push(name);
        }
    }

    private BaseScreen createScreen(String name, String data) {
        switch (name) {
            case "lobby": return new LobbyScreen(this, this);
            case "game": return new GameScreen(this, this);
            case "results": return new ResultsScreen(this, this, lastSnapshot);
            case "profile": return new ProfileScreen(this, this);
            case "history": return new MatchHistoryScreen(this, this);
            case "leaderboard": return new LeaderboardScreen(this, this);
            case "settings": return new SettingsScreen(this, this);
            case "shop": return new ShopScreen(this, this);
            default: return new HomeScreen(this, this);
        }
    }

    private void connect(String socketPath) {
        String encoded = encodeQuery(displayName);
        String wsUrl = BACKEND_URL.replace("https://", "wss://") + socketPath
                + "?playerId=" + playerId + "&displayName=" + encoded;
        Request req = new Request.Builder().url(wsUrl).build();
        socket = http.newWebSocket(req, new WebSocketListener() {
            @Override public void onOpen(WebSocket ws, Response r) {
                connecting = false;
                send(json("type", "join", "playerId", playerId, "displayName", displayName));
                send(json("type", "fill_bots", "playerId", playerId));
                updateGameStatus("Match connected. Bots are seated.");
            }

            @Override public void onMessage(WebSocket ws, String text) {
                handleMessage(text);
            }

            @Override public void onFailure(WebSocket ws, Throwable t, Response r) {
                connecting = false;
                updateGameStatus("Connection error: " + t.getMessage());
            }
        });
    }

    private void handleMessage(String text) {
        try {
            JSONObject envelope = new JSONObject(text);
            if ("error".equals(envelope.optString("type"))) {
                updateGameStatus(envelope.optString("message", "Room error"));
                return;
            }

            JSONObject snap = envelope.optJSONObject("snapshot");
            if (snap != null) {
                lastSnapshot = snap;
                main.post(() -> {
                    if (gameScreen != null) {
                        gameScreen.updateSnapshot(snap, playerId);
                    }
                    if ("finished".equals(snap.optString("status"))) {
                        trackMatchResult(snap);
                        main.postDelayed(() -> navigateTo("results"), 1500);
                    }
                });
            }
        } catch (Exception e) {
            updateGameStatus("Parse error: " + e.getMessage());
        }
    }

    private void trackMatchResult(JSONObject snap) {
        gamesPlayed++;
        String winnerId = snap.optString("winnerPlayerId", "");
        if (playerId != null && playerId.equals(winnerId)) {
            wins++;
            rating += 12;
            coins += 100;
        } else {
            rating = Math.max(0, rating - 6);
            coins += 15;
        }
        if (socket != null) {
            socket.close(1000, "match_finished");
            socket = null;
        }
        gameScreen = null;
    }

    private void pollTicket(String ticketId, int attempt) {
        if (attempt > 15) {
            updateGameStatus("Matchmaking timed out.");
            connecting = false;
            return;
        }
        main.postDelayed(() -> {
            Request req = new Request.Builder()
                    .url(BACKEND_URL + "/api/v1/matchmaking/tickets/" + ticketId)
                    .build();
            http.newCall(req).enqueue(new Callback() {
                @Override public void onFailure(Call call, IOException e) {
                    connecting = false;
                    updateGameStatus("Ticket check failed.");
                }

                @Override public void onResponse(Call call, Response response) throws IOException {
                    String body = response.body() == null ? "{}" : response.body().string();
                    response.close();
                    try {
                        JSONObject ticket = new JSONObject(body);
                        String status = ticket.optString("status", "waiting");
                        if ("matched".equals(status)) {
                            String socketUrl = ticket.optString("socketUrl", "");
                            if (!socketUrl.isEmpty()) {
                                connect(socketUrl);
                                return;
                            }
                        }
                        if ("waiting".equals(status)) {
                            updateGameStatus("Searching... (" + (attempt + 1) + ")");
                            pollTicket(ticketId, attempt + 1);
                        } else {
                            connecting = false;
                            updateGameStatus("Matchmaking: " + status);
                        }
                    } catch (Exception e) {
                        connecting = false;
                        updateGameStatus("Ticket parse error.");
                    }
                }
            });
        }, 2000);
    }

    private String chooseBest(JSONArray moves) {
        String best = moves.optString(0);
        int bestScore = Integer.MIN_VALUE;
        JSONArray pieces = lastSnapshot == null ? null : lastSnapshot.optJSONArray("pieces");
        for (int i = 0; i < moves.length(); i++) {
            String id = moves.optString(i);
            int score = 0;
            if (pieces != null) {
                for (int j = 0; j < pieces.length(); j++) {
                    JSONObject p = pieces.optJSONObject(j);
                    if (p != null && id.equals(p.optString("pieceId")))
                        score = p.optInt("progress", -1);
                }
            }
            if (score > bestScore) { bestScore = score; best = id; }
        }
        return best;
    }

    private void updateGameStatus(String text) {
        main.post(() -> {
            if (gameScreen != null) gameScreen.setStatus(text);
        });
    }

    private void healthCheck() {
        Request req = new Request.Builder().url(BACKEND_URL + "/health").build();
        http.newCall(req).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) { backendOnline = false; }
            @Override public void onResponse(Call call, Response r) {
                backendOnline = r.isSuccessful();
                r.close();
            }
        });
    }

    private void post(String path, JSONObject payload, JsonHandler handler) {
        Request req = new Request.Builder()
                .url(BACKEND_URL + path)
                .post(RequestBody.create(payload.toString(), JSON))
                .build();
        http.newCall(req).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) {
                connecting = false;
                updateGameStatus("Request failed: " + e.getMessage());
            }

            @Override public void onResponse(Call call, Response r) throws IOException {
                String text = r.body() == null ? "{}" : r.body().string();
                r.close();
                try {
                    if (!r.isSuccessful()) {
                        connecting = false;
                        updateGameStatus("HTTP " + r.code() + ": " + text);
                        return;
                    }
                    handler.handle(new JSONObject(text));
                } catch (Exception e) {
                    connecting = false;
                    updateGameStatus("Response error: " + e.getMessage());
                }
            }
        });
    }

    private void send(JSONObject msg) {
        if (socket != null) socket.send(msg.toString());
    }

    private JSONObject json(Object... values) {
        JSONObject obj = new JSONObject();
        for (int i = 0; i + 1 < values.length; i += 2) {
            try { obj.put(String.valueOf(values[i]), values[i + 1]); }
            catch (Exception e) { throw new IllegalArgumentException("Invalid JSON", e); }
        }
        return obj;
    }

    private String encodeQuery(String value) {
        try { return URLEncoder.encode(value, "UTF-8"); }
        catch (UnsupportedEncodingException e) { return value.replace(" ", "%20"); }
    }

    private interface JsonHandler {
        void handle(JSONObject body) throws Exception;
    }

    static final class BackgroundView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);

        BackgroundView(Activity activity) { super(activity); }

        @Override protected void onDraw(Canvas canvas) {
            int w = getWidth(), h = getHeight();
            paint.setShader(new LinearGradient(0, 0, w, h,
                    new int[]{0xff0A1228, 0xff101A33, 0xff070B14}, null, Shader.TileMode.CLAMP));
            canvas.drawRect(0, 0, w, h, paint);
            paint.setShader(new RadialGradient(w * 0.12f, h * 0.06f, w * 0.6f,
                    0x55226BE8, 0x00101A33, Shader.TileMode.CLAMP));
            canvas.drawCircle(w * 0.12f, h * 0.06f, w * 0.6f, paint);
            paint.setShader(new RadialGradient(w * 0.92f, h * 0.18f, w * 0.5f,
                    0x44FF3D5A, 0x00070B14, Shader.TileMode.CLAMP));
            canvas.drawCircle(w * 0.92f, h * 0.18f, w * 0.5f, paint);
            paint.setShader(new RadialGradient(w * 0.5f, h * 0.95f, w * 0.7f,
                    0x339C6BFF, 0x00070B14, Shader.TileMode.CLAMP));
            canvas.drawCircle(w * 0.5f, h * 0.95f, w * 0.7f, paint);
            paint.setShader(null);

            // Faint scattered "dice dot" pattern for texture
            paint.setColor(0x10FFFFFF);
            float[][] dots = {
                    {0.08f, 0.32f, 3f}, {0.22f, 0.55f, 2f}, {0.14f, 0.78f, 4f},
                    {0.86f, 0.42f, 3f}, {0.92f, 0.66f, 2f}, {0.78f, 0.88f, 4f},
                    {0.46f, 0.24f, 2f}, {0.62f, 0.72f, 3f}, {0.34f, 0.92f, 2f},
            };
            float d = getResources().getDisplayMetrics().density;
            for (float[] dot : dots) {
                canvas.drawCircle(w * dot[0], h * dot[1], dot[2] * d, paint);
            }
        }
    }
}
