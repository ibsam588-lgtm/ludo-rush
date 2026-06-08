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
            super.onBackPressed();
        }
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
                    new int[]{0xff07111F, 0xff111827, 0xff0A0F1B}, null, Shader.TileMode.CLAMP));
            canvas.drawRect(0, 0, w, h, paint);
            paint.setShader(new RadialGradient(w * 0.15f, h * 0.08f, w * 0.55f,
                    0x5522C7E8, 0x00111827, Shader.TileMode.CLAMP));
            canvas.drawCircle(w * 0.15f, h * 0.08f, w * 0.55f, paint);
            paint.setShader(new RadialGradient(w * 0.9f, h * 0.22f, w * 0.45f,
                    0x44FFB14A, 0x000A0F1B, Shader.TileMode.CLAMP));
            canvas.drawCircle(w * 0.9f, h * 0.22f, w * 0.45f, paint);
            paint.setShader(null);
        }
    }
}
