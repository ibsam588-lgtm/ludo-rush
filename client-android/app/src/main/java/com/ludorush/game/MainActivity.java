package com.ludorush.game;

import android.app.Activity;
import android.content.SharedPreferences;
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
import android.widget.Toast;
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
    private static final String REGION = "us-east";
    private static final String PROFILE_PREFS = "ludo_profile";
    private static final String HISTORY_PREFS = "ludo_history";
    private static final int MAX_TICKET_POLLS = 20;

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
    private String authToken;
    private String displayName = "Rush Tester";
    private int coins = 500;
    private int rating = 1000;
    private int gamesPlayed = 0;
    private int wins = 0;
    private boolean backendOnline;
    private boolean connecting;
    private boolean matchCounted;
    private String pendingTicketId;
    private String currentMode = "classic_2p";
    private JSONObject lastSnapshot;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        loadProfile();

        FrameLayout shell = new FrameLayout(this);
        shell.setBackgroundColor(Color.rgb(8, 11, 19));

        BackgroundView bg = new BackgroundView(this);
        shell.addView(bg, new FrameLayout.LayoutParams(-1, -1));

        container = new FrameLayout(this);
        shell.addView(container, new FrameLayout.LayoutParams(-1, -1));

        setContentView(shell);
        healthCheck();
        syncProfile();
        navigateTo("home");
    }

    @Override
    protected void onDestroy() {
        if (socket != null) {
            if (isMatchPlaying()) {
                send(json("type", "resign", "playerId", playerId));
            }
            socket.close(1000, "activity_destroyed");
        }
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        if (screenStack.size() > 1) {
            goBack();
        } else {
            Dialogs.confirm(this, "👋", "Quit Ludo Rush?", "Do you want to quit the app?",
                    "Quit", this::finish);
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
            if ("game".equals(screenStack.peek()) && isMatchActive()) {
                Dialogs.confirm(this, "🏳️", "Leave match?",
                        "You'll forfeit this game and lose rating.", "Leave",
                        () -> {
                            leaveMatch();
                            popBack();
                        });
                return;
            }
            popBack();
        });
    }

    private void popBack() {
        if (screenStack.size() <= 1) return;
        screenStack.pop();
        String prev = screenStack.peek();
        if (prev != null) showScreen(prev, null);
    }

    @Override public String getPlayerId() { return playerId; }
    @Override public String getDisplayName() { return displayName; }
    @Override public int getCoins() { return coins; }
    @Override public int getRating() { return rating; }
    @Override public int getGamesPlayed() { return gamesPlayed; }
    @Override public int getWins() { return wins; }
    @Override public boolean isOnline() { return backendOnline; }

    @Override
    public boolean isMatchActive() {
        return socket != null || connecting || pendingTicketId != null;
    }

    private boolean isMatchPlaying() {
        return socket != null && !matchCounted && lastSnapshot != null
                && "playing".equals(lastSnapshot.optString("status"));
    }

    @Override
    public void startBotMatch(String mode) {
        if (connecting) return;
        beginMatch(mode);
        updateGameStatus("Preparing match...");

        ensurePlayer(() -> {
            updateGameStatus("Creating bot match...");
            post("/api/v1/matchmaking/bots", json(
                    "playerId", playerId,
                    "displayName", displayName,
                    "mode", mode,
                    "region", REGION,
                    "rating", rating), match -> connect(match.getString("socketUrl"), true));
        });
    }

    @Override
    public void startQuickMatch(String mode) {
        if (connecting) return;
        beginMatch(mode);
        updateGameStatus("Preparing match...");

        ensurePlayer(() -> {
            updateGameStatus("Searching for match...");
            post("/api/v1/matchmaking/quick", json(
                    "playerId", playerId,
                    "displayName", displayName,
                    "mode", mode,
                    "region", REGION,
                    "rating", rating), ticket -> {
                String status = ticket.optString("status", "waiting");
                if ("matched".equals(status)) {
                    String socketUrl = ticket.optString("socketUrl", "");
                    if (!socketUrl.isEmpty()) {
                        connect(socketUrl, false);
                        return;
                    }
                }
                String ticketId = ticket.optString("ticketId", "");
                if (ticketId.isEmpty()) {
                    updateGameStatus("Matchmaking failed.");
                    connecting = false;
                    return;
                }
                pendingTicketId = ticketId;
                pollTicket(ticketId, 0);
            });
        });
    }

    @Override
    public void startPrivateRoom(String mode) {
        if (connecting) return;
        beginMatch(mode);
        updateGameStatus("Creating private room...");

        ensurePlayer(() -> post("/api/v1/rooms/private", json(
                "playerId", playerId,
                "displayName", displayName,
                "mode", mode,
                "region", REGION), room -> {
            String code = room.optString("code", "------");
            connect(room.getString("socketUrl"), false);
            main.postDelayed(() ->
                    updateGameStatus("Room code: " + code + " — share it with a friend!"), 600);
        }));
    }

    @Override
    public void joinPrivateRoom(String code) {
        if (connecting) return;
        beginMatch("classic_2p");
        updateGameStatus("Joining private room...");

        ensurePlayer(() -> post("/api/v1/rooms/private/join", json(
                "playerId", playerId,
                "displayName", displayName,
                "code", code), room -> connect(room.getString("socketUrl"), false)));
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
        if (socket != null && playerId != null && isMatchPlaying()) {
            send(json("type", "resign", "playerId", playerId));
        }
    }

    @Override
    public void addCoins(int amount) {
        coins = Math.max(0, coins + amount);
        saveProfile();
    }

    @Override
    public void resetAccount() {
        if (playerId != null && authToken != null) {
            Request req = new Request.Builder()
                    .url(BACKEND_URL + "/api/v1/players/" + playerId + "?token=" + encodeQuery(authToken))
                    .delete()
                    .build();
            http.newCall(req).enqueue(new Callback() {
                @Override public void onFailure(Call call, IOException e) { }
                @Override public void onResponse(Call call, Response r) { r.close(); }
            });
        }
        leaveMatch();
        playerId = null;
        authToken = null;
        displayName = "Rush Tester";
        coins = 500;
        rating = 1000;
        gamesPlayed = 0;
        wins = 0;
        getSharedPreferences(PROFILE_PREFS, 0).edit().clear().apply();
        getSharedPreferences(HISTORY_PREFS, 0).edit().clear().apply();
        main.post(() -> {
            Toast.makeText(this, "Account deleted", Toast.LENGTH_SHORT).show();
            navigateTo("home");
        });
    }

    @Override
    public String getAppVersion() {
        try {
            return getPackageManager().getPackageInfo(getPackageName(), 0).versionName;
        } catch (Exception e) {
            return "0.2.0";
        }
    }

    @Override
    public void fetchJson(String path, BaseScreen.ScreenCallback.JsonResult handler) {
        Request req = new Request.Builder().url(BACKEND_URL + path).build();
        http.newCall(req).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) {
                main.post(() -> handler.onError(e.getMessage() == null ? "Network error" : e.getMessage()));
            }

            @Override public void onResponse(Call call, Response r) throws IOException {
                String text = r.body() == null ? "{}" : r.body().string();
                r.close();
                if (!r.isSuccessful()) {
                    main.post(() -> handler.onError("HTTP " + r.code()));
                    return;
                }
                try {
                    JSONObject body = new JSONObject(text);
                    main.post(() -> handler.onSuccess(body));
                } catch (Exception e) {
                    main.post(() -> handler.onError("Invalid response"));
                }
            }
        });
    }

    /** Resets per-match state and tears down any previous match before starting a new one. */
    private void beginMatch(String mode) {
        leaveMatch();
        connecting = true;
        matchCounted = false;
        currentMode = mode;
        navigateTo("game");
    }

    /**
     * Leaves the current match (if any): cancels a waiting matchmaking ticket,
     * resigns an in-progress game, and closes the socket. A forfeited game is
     * counted as a loss locally so stats stay honest.
     */
    private void leaveMatch() {
        if (pendingTicketId != null) {
            String ticket = pendingTicketId;
            pendingTicketId = null;
            post("/api/v1/matchmaking/tickets/" + ticket + "/cancel", new JSONObject(), body -> { });
        }
        if (socket != null) {
            if (isMatchPlaying()) {
                send(json("type", "resign", "playerId", playerId));
                matchCounted = true;
                countForfeit();
            }
            socket.close(1000, "left_match");
            socket = null;
        }
        connecting = false;
        gameScreen = null;
        lastSnapshot = null;
    }

    private void countForfeit() {
        gamesPlayed++;
        rating = Math.max(0, rating - 6);
        saveProfile();
        appendHistory(false, currentMode, "Forfeit", -6, 0);
    }

    private void showScreen(String name, String data) {
        if ("home".equals(name)) {
            screenStack.clear();
            healthCheck();
        }
        if ("results".equals(name) && "game".equals(screenStack.peek())) {
            // Replace the finished game screen so back from results skips it.
            screenStack.pop();
        }

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
        } else {
            gameScreen = null;
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

    /** Runs the continuation once a guest account exists, creating one only if needed. */
    private void ensurePlayer(Runnable next) {
        if (playerId != null && authToken != null) {
            next.run();
            return;
        }
        post("/api/v1/auth/guest", json("displayName", displayName, "region", REGION), body -> {
            JSONObject player = body.getJSONObject("player");
            playerId = player.getString("id");
            authToken = body.optString("token", "");
            displayName = player.getString("displayName");
            rating = player.optInt("rating", 1000);
            coins = player.optInt("coins", 500);
            saveProfile();
            next.run();
        });
    }

    private void connect(String socketPath, boolean fillBots) {
        pendingTicketId = null;
        if (socket != null) {
            socket.close(1000, "starting_new_match");
            socket = null;
        }

        String wsUrl = BACKEND_URL.replace("https://", "wss://") + socketPath
                + "?playerId=" + playerId
                + "&displayName=" + encodeQuery(displayName)
                + "&token=" + encodeQuery(authToken == null ? "" : authToken);
        Request req = new Request.Builder().url(wsUrl).build();
        socket = http.newWebSocket(req, new WebSocketListener() {
            @Override public void onOpen(WebSocket ws, Response r) {
                if (ws != socket) return;
                connecting = false;
                send(json("type", "join", "playerId", playerId, "displayName", displayName));
                if (fillBots) {
                    send(json("type", "fill_bots", "playerId", playerId));
                    updateGameStatus("Match connected. Bots are seated.");
                } else {
                    updateGameStatus("Connected. Waiting for players...");
                }
            }

            @Override public void onMessage(WebSocket ws, String text) {
                if (ws != socket) return;
                handleMessage(text);
            }

            @Override public void onFailure(WebSocket ws, Throwable t, Response r) {
                if (ws != socket) return;
                connecting = false;
                if (!matchCounted) {
                    updateGameStatus("Connection error: " + t.getMessage());
                }
            }

            @Override public void onClosed(WebSocket ws, int code, String reason) {
                if (ws != socket) return;
                connecting = false;
                if (!matchCounted) {
                    updateGameStatus("Connection closed.");
                }
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
                    if ("finished".equals(snap.optString("status")) && !matchCounted) {
                        matchCounted = true;
                        trackMatchResult(snap);
                        if ("game".equals(screenStack.peek())) {
                            main.postDelayed(() -> navigateTo("results"), 1500);
                        }
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
        boolean won = playerId != null && playerId.equals(winnerId);
        int ratingDelta = won ? 12 : -6;
        int coinsDelta = won ? 100 : 15;
        if (won) wins++;
        rating = Math.max(0, rating + ratingDelta);
        coins += coinsDelta;
        saveProfile();
        appendHistory(won, snap.optString("mode", currentMode), opponentNames(snap), ratingDelta, coinsDelta);

        if (socket != null) {
            socket.close(1000, "match_finished");
            socket = null;
        }
        gameScreen = null;
        connecting = false;
    }

    private String opponentNames(JSONObject snap) {
        JSONArray seats = snap.optJSONArray("seats");
        if (seats == null) return "Unknown";
        StringBuilder names = new StringBuilder();
        for (int i = 0; i < seats.length(); i++) {
            JSONObject s = seats.optJSONObject(i);
            if (s == null || (playerId != null && playerId.equals(s.optString("playerId")))) continue;
            if (names.length() > 0) names.append(", ");
            names.append(s.optString("displayName", "Player"));
        }
        return names.length() == 0 ? "Unknown" : names.toString();
    }

    private void pollTicket(String ticketId, int attempt) {
        if (!ticketId.equals(pendingTicketId)) return;
        if (attempt > MAX_TICKET_POLLS) {
            pendingTicketId = null;
            post("/api/v1/matchmaking/tickets/" + ticketId + "/cancel", new JSONObject(), body -> { });
            updateGameStatus("Matchmaking timed out. Go back and try again.");
            connecting = false;
            return;
        }
        main.postDelayed(() -> {
            if (!ticketId.equals(pendingTicketId)) return;
            Request req = new Request.Builder()
                    .url(BACKEND_URL + "/api/v1/matchmaking/tickets/" + ticketId)
                    .build();
            http.newCall(req).enqueue(new Callback() {
                @Override public void onFailure(Call call, IOException e) {
                    if (!ticketId.equals(pendingTicketId)) return;
                    pendingTicketId = null;
                    connecting = false;
                    updateGameStatus("Ticket check failed.");
                }

                @Override public void onResponse(Call call, Response response) throws IOException {
                    String body = response.body() == null ? "{}" : response.body().string();
                    response.close();
                    if (!ticketId.equals(pendingTicketId)) return;
                    try {
                        JSONObject ticket = new JSONObject(body);
                        String status = ticket.optString("status", "waiting");
                        if ("matched".equals(status)) {
                            String socketUrl = ticket.optString("socketUrl", "");
                            if (!socketUrl.isEmpty()) {
                                connect(socketUrl, false);
                                return;
                            }
                        }
                        if ("waiting".equals(status)) {
                            updateGameStatus("Searching for an opponent... (" + (attempt + 1) + ")");
                            pollTicket(ticketId, attempt + 1);
                        } else {
                            pendingTicketId = null;
                            connecting = false;
                            updateGameStatus("Matchmaking: " + status);
                        }
                    } catch (Exception e) {
                        pendingTicketId = null;
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

    private void loadProfile() {
        SharedPreferences prefs = getSharedPreferences(PROFILE_PREFS, 0);
        playerId = prefs.getString("player_id", null);
        authToken = prefs.getString("auth_token", null);
        displayName = prefs.getString("display_name", "Rush Tester");
        coins = prefs.getInt("coins", 500);
        rating = prefs.getInt("rating", 1000);
        gamesPlayed = prefs.getInt("games_played", 0);
        wins = prefs.getInt("wins", 0);
    }

    private void saveProfile() {
        getSharedPreferences(PROFILE_PREFS, 0).edit()
                .putString("player_id", playerId)
                .putString("auth_token", authToken)
                .putString("display_name", displayName)
                .putInt("coins", coins)
                .putInt("rating", rating)
                .putInt("games_played", gamesPlayed)
                .putInt("wins", wins)
                .apply();
    }

    /** Pulls server-side rating/coins for a persisted guest at startup. */
    private void syncProfile() {
        if (playerId == null || authToken == null) return;
        Request req = new Request.Builder()
                .url(BACKEND_URL + "/api/v1/players/" + playerId + "?token=" + encodeQuery(authToken))
                .build();
        http.newCall(req).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) { }

            @Override public void onResponse(Call call, Response r) throws IOException {
                String text = r.body() == null ? "{}" : r.body().string();
                int code = r.code();
                r.close();
                if (code == 404 || code == 401) {
                    // Account no longer exists server-side; re-register on next match.
                    playerId = null;
                    authToken = null;
                    saveProfile();
                    return;
                }
                if (code != 200) return;
                try {
                    JSONObject player = new JSONObject(text).getJSONObject("player");
                    rating = player.optInt("rating", rating);
                    // Local coins can be ahead of the server (ad/daily bonuses are
                    // client-side for now), so never lower the local balance.
                    coins = Math.max(coins, player.optInt("coins", coins));
                    saveProfile();
                } catch (Exception ignored) { }
            }
        });
    }

    private void appendHistory(boolean won, String mode, String opponents, int ratingDelta, int coinsDelta) {
        try {
            SharedPreferences prefs = getSharedPreferences(HISTORY_PREFS, 0);
            JSONArray existing = new JSONArray(prefs.getString("entries", "[]"));
            JSONObject entry = new JSONObject();
            entry.put("won", won);
            entry.put("mode", mode);
            entry.put("opponents", opponents);
            entry.put("ratingDelta", ratingDelta);
            entry.put("coinsDelta", coinsDelta);
            entry.put("at", System.currentTimeMillis());

            JSONArray next = new JSONArray();
            next.put(entry);
            for (int i = 0; i < Math.min(existing.length(), 19); i++) {
                next.put(existing.get(i));
            }
            prefs.edit().putString("entries", next.toString()).apply();
        } catch (Exception ignored) { }
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
                        if (r.code() == 404) {
                            updateGameStatus("Not found. The room code may be wrong or expired.");
                        } else {
                            updateGameStatus("HTTP " + r.code() + ": " + text);
                        }
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
