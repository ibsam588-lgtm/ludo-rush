package com.ludorush.game;

import android.app.Activity;
import android.app.Dialog;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Shader;
import android.graphics.Typeface;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
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
    private boolean adAttachScheduled;
    private boolean fallbackBotStarted;
    private boolean currentMatchIsBot;
    private JSONObject lastSnapshot;
    private int lastRollValue;
    private long lastRollAt;
    private String lastRollPlayerId;
    private String pendingMatchMode = "classic_2p";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Apply system bar colors to match the active theme

        // Initialise AdMob — attach() handles SDK init + preloads ads
        FrameLayout shell = new FrameLayout(this);
        shell.setBackgroundColor(ThemeManager.get(this).bgPage());

        BackgroundView bg = new BackgroundView(this);
        shell.addView(bg, new FrameLayout.LayoutParams(-1, -1));

        container = new FrameLayout(this);
        container.setPadding(0, systemBarHeight("status_bar_height"), 0, systemBarHeight("navigation_bar_height"));
        shell.addView(container, new FrameLayout.LayoutParams(-1, -1));

        setContentView(shell);
        applyThemeSystemBars();
        healthCheck();
        navigateTo("home");
        scheduleAdAttach();
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Re-attach in case the activity was recreated (theme change)
        scheduleAdAttach();
    }

    @Override
    protected void onDestroy() {
        if (socket != null) socket.close(1000, "activity_destroyed");
        super.onDestroy();
    }

    private void scheduleAdAttach() {
        if (adAttachScheduled) return;
        adAttachScheduled = true;
        main.postDelayed(() -> {
            adAttachScheduled = false;
            if (!isFinishing() && !isDestroyed()) {
                AdManager.get().attach(this);
            }
        }, 5000);
    }

    // ── Back press — show "Do you want to quit?" when on home screen ──────────

    @Override
    public void onBackPressed() {
        if (screenStack.size() <= 1) {
            showQuitDialog();
        } else if ("game".equals(screenStack.peek())) {
            showLeaveMatchDialog();
        } else {
            goBack();
        }
    }

    private void showQuitDialog() {
        showFableDialog(
            "Quit Ludo Rush?",
            "Your progress will be lost.",
            "Stay", "Quit",
            ThemeManager.RED, ThemeManager.YELLOW,
            () -> finish()
        );
    }

    private void showLeaveMatchDialog() {
        showFableDialog(
            "Leave Match?",
            "You'll forfeit this game.",
            "Stay", "Leave & Resign",
            ThemeManager.RED, 0xffB71C1C,
            () -> { resign(); goBack(); }
        );
    }

    /**
     * Shows a custom-styled "fable mode" confirmation dialog that matches the app's
     * dark/light theme instead of using the stock Android AlertDialog.
     */
    private void showFableDialog(String title, String subtitle,
                                  String cancelLabel, String confirmLabel,
                                  int gradStart, int gradEnd,
                                  Runnable onConfirm) {
        ThemeManager tm = ThemeManager.get(this);
        float density = getResources().getDisplayMetrics().density;

        Dialog dialog = new Dialog(this);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setCancelable(true);

        // ── Outer card ────────────────────────────────────────────────────────
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        int pad = (int) (28 * density);
        card.setPadding(pad, pad, pad, pad);

        GradientDrawable cardBg = new GradientDrawable();
        cardBg.setColor(tm.bgCard());
        cardBg.setCornerRadius(24 * density);
        cardBg.setStroke((int)(2 * density), tm.strokeCard());
        card.setBackground(cardBg);

        // Title
        TextView titleView = new TextView(this);
        titleView.setText(title);
        titleView.setTextSize(22);
        titleView.setTextColor(tm.txtPrimary());
        titleView.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
        titleView.setIncludeFontPadding(false);
        titleView.setGravity(Gravity.CENTER);
        card.addView(titleView);

        // Subtitle
        TextView subView = new TextView(this);
        subView.setText(subtitle);
        subView.setTextSize(13);
        subView.setTextColor(tm.txtMuted());
        subView.setTypeface(Typeface.create("sans-serif", Typeface.NORMAL));
        subView.setIncludeFontPadding(false);
        subView.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams subLp = new LinearLayout.LayoutParams(-1, -2);
        subLp.setMargins(0, (int)(6 * density), 0, (int)(20 * density));
        card.addView(subView, subLp);

        // ── Button row ────────────────────────────────────────────────────────
        LinearLayout btnRow = new LinearLayout(this);
        btnRow.setOrientation(LinearLayout.HORIZONTAL);

        // Stay / cancel button
        Button stayBtn = new Button(this);
        stayBtn.setAllCaps(false);
        stayBtn.setText(cancelLabel);
        stayBtn.setTextColor(tm.txtPrimary());
        stayBtn.setTextSize(14);
        stayBtn.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
        stayBtn.setIncludeFontPadding(false);
        GradientDrawable stayBg = new GradientDrawable();
        stayBg.setColor(tm.bgCard());
        stayBg.setCornerRadius(14 * density);
        stayBg.setStroke((int)(density), tm.strokeCard());
        stayBtn.setBackground(stayBg);
        stayBtn.setOnClickListener(v -> dialog.dismiss());
        LinearLayout.LayoutParams stayLp = new LinearLayout.LayoutParams(0, (int)(50 * density), 1);
        stayLp.setMargins(0, 0, (int)(6 * density), 0);
        btnRow.addView(stayBtn, stayLp);

        // Confirm / action button
        Button confirmBtn = new Button(this);
        confirmBtn.setAllCaps(false);
        confirmBtn.setText(confirmLabel);
        confirmBtn.setTextColor(Color.WHITE);
        confirmBtn.setTextSize(14);
        confirmBtn.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD));
        confirmBtn.setIncludeFontPadding(false);
        GradientDrawable confirmBg = new GradientDrawable(
            GradientDrawable.Orientation.LEFT_RIGHT, new int[]{gradStart, gradEnd});
        confirmBg.setCornerRadius(14 * density);
        confirmBtn.setBackground(confirmBg);
        confirmBtn.setOnClickListener(v -> {
            dialog.dismiss();
            onConfirm.run();
        });
        LinearLayout.LayoutParams confirmLp = new LinearLayout.LayoutParams(0, (int)(50 * density), 1);
        confirmLp.setMargins((int)(6 * density), 0, 0, 0);
        btnRow.addView(confirmBtn, confirmLp);

        card.addView(btnRow, new LinearLayout.LayoutParams(-1, -2));

        // ── Dialog window setup ───────────────────────────────────────────────
        dialog.setContentView(card);
        Window w = dialog.getWindow();
        if (w != null) {
            w.setBackgroundDrawable(new ColorDrawable(0x99000000));
            int maxWidth = (int)(320 * density);
            w.setLayout(Math.min(maxWidth,
                (int)(getResources().getDisplayMetrics().widthPixels * 0.88f)),
                WindowManager.LayoutParams.WRAP_CONTENT);
        }
        dialog.show();
    }

    // ── Navigation ────────────────────────────────────────────────────────────

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

    // ── ScreenCallback ────────────────────────────────────────────────────────

    @Override public String getPlayerId()    { return playerId; }
    @Override public String getDisplayName() { return displayName; }
    @Override public int getCoins()          { return coins; }
    @Override public int getRating()         { return rating; }
    @Override public int getGamesPlayed()    { return gamesPlayed; }
    @Override public int getWins()           { return wins; }
    @Override public boolean isOnline()      { return backendOnline; }
    @Override public void addCoins(int amount) { coins = Math.max(0, coins + amount); }

    @Override
    public void startBotMatch(String mode) {
        if (connecting) return;
        pendingMatchMode = mode;
        fallbackBotStarted = false;
        currentMatchIsBot = true;
        resetLiveMatch();
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
        pendingMatchMode = mode;
        fallbackBotStarted = false;
        currentMatchIsBot = false;
        resetLiveMatch();
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
                    fallbackToBots("No online room available.");
                    return;
                }
                pollTicket(ticketId, 0);
            }, () -> fallbackToBots("Online matchmaking is busy."));
        }, () -> fallbackToBots("Online matchmaking is busy."));
    }

    @Override
    public void rollDice() {
        if (socket == null || playerId == null) {
            updateGameStatus("Match is not connected yet.");
            return;
        }
        if (lastSnapshot == null) {
            updateGameStatus("Waiting for room state...");
            return;
        }
        if (!isMyTurn(lastSnapshot)) {
            updateGameStatus("Wait for your turn.");
            return;
        }
        if (hasDiceValue(lastSnapshot)) {
            updateGameStatus("Move a highlighted piece before rolling again.");
            return;
        }
        updateGameStatus("Rolling...");
        send(json("type", "roll_dice", "playerId", playerId));
    }

    @Override
    public void moveBestPiece() {
        if (socket == null || playerId == null) {
            updateGameStatus("Match is not connected yet.");
            return;
        }
        if (lastSnapshot == null) {
            updateGameStatus("Waiting for room state...");
            return;
        }
        JSONArray moves = lastSnapshot.optJSONArray("availableMoves");
        if (moves == null || moves.length() == 0) {
            updateGameStatus("No legal pieces to move.");
            return;
        }
        String best = chooseBest(moves);
        movePiece(best);
    }

    @Override
    public void movePiece(String pieceId) {
        if (socket == null || playerId == null) {
            updateGameStatus("Match is not connected yet.");
            return;
        }
        if (lastSnapshot == null) {
            updateGameStatus("Waiting for room state...");
            return;
        }
        if (!isMyTurn(lastSnapshot)) {
            updateGameStatus("Wait for your turn.");
            return;
        }
        if (!hasDiceValue(lastSnapshot)) {
            updateGameStatus("Roll before moving a piece.");
            return;
        }
        JSONArray moves = lastSnapshot.optJSONArray("availableMoves");
        if (!contains(moves, pieceId)) {
            updateGameStatus("That piece cannot move for this roll.");
            return;
        }
        updateGameStatus("Moving piece...");
        send(json("type", "move_piece", "playerId", playerId, "pieceId", pieceId));
    }

    @Override
    public void resign() {
        if (socket != null && playerId != null) {
            send(json("type", "resign", "playerId", playerId));
        }
    }

    @Override
    public void sendChat(String message) {
        // Chat messages are client-side only; backend chat not yet wired
    }

    @Override
    public String getCountry() {
        return getSharedPreferences("ludo_settings", 0).getString("player_country", "🌍");
    }

    @Override
    public boolean isUnder13() {
        return getSharedPreferences("ludo_settings", 0).getBoolean("is_under_13", false);
    }

    // ── Screen management ─────────────────────────────────────────────────────

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
            case "lobby":       return new LobbyScreen(this, this);
            case "game":        return new GameScreen(this, this);
            case "results":     return new ResultsScreen(this, this, lastSnapshot);
            case "profile":     return new ProfileScreen(this, this);
            case "history":     return new MatchHistoryScreen(this, this);
            case "leaderboard": return new LeaderboardScreen(this, this);
            case "settings":    return new SettingsScreen(this, this);
            case "shop":        return new ShopScreen(this, this);
            default:            return new HomeScreen(this, this);
        }
    }

    // ── Networking ────────────────────────────────────────────────────────────

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
                updateGameStatus(currentMatchIsBot
                        ? "Bot match connected. Roll when it is your turn."
                        : "Match connected. Empty seats fill with bots.");
            }

            @Override public void onMessage(WebSocket ws, String text) {
                handleMessage(text);
            }

            @Override public void onFailure(WebSocket ws, Throwable t, Response r) {
                connecting = false;
                if (!currentMatchIsBot) {
                    fallbackToBots("Online room connection failed.");
                } else {
                    updateGameStatus("Connection error: " + t.getMessage());
                }
            }
        });
    }

    private void handleMessage(String text) {
        try {
            JSONObject envelope = new JSONObject(text);
            String type = envelope.optString("type");
            if ("error".equals(type)) {
                updateGameStatus(envelope.optString("message", "Room error"));
                return;
            }

            JSONObject snap = envelope.optJSONObject("snapshot");
            String eventStatus = rememberRoomEvent(type, envelope, snap);
            if (snap != null) {
                lastSnapshot = snap;
                main.post(() -> {
                    if (gameScreen != null) {
                        gameScreen.updateSnapshot(snap, playerId);
                        if (lastRollValue > 0) {
                            gameScreen.setLastRoll(lastRollValue, playerId != null && playerId.equals(lastRollPlayerId));
                        }
                        if (eventStatus != null && !eventStatus.isEmpty()) {
                            gameScreen.setStatus(eventStatus);
                        }
                    }
                    if ("finished".equals(snap.optString("status"))) {
                        trackMatchResult(snap);
                        // CoinRewardDialog in GameScreen credits coins and navigates to results on dismiss
                    }
                });
            } else if (eventStatus != null && !eventStatus.isEmpty()) {
                updateGameStatus(eventStatus);
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
        } else {
            rating = Math.max(0, rating - 6);
        }
        if (socket != null) {
            socket.close(1000, "match_finished");
            socket = null;
        }
        clearRollState();
        gameScreen = null;
    }

    private void pollTicket(String ticketId, int attempt) {
        if (attempt >= 4) {
            fallbackToBots("No online players found.");
            return;
        }
        main.postDelayed(() -> {
            Request req = new Request.Builder()
                    .url(BACKEND_URL + "/api/v1/matchmaking/tickets/" + ticketId)
                    .build();
            http.newCall(req).enqueue(new Callback() {
                @Override public void onFailure(Call call, IOException e) {
                    fallbackToBots("Online matchmaking check failed.");
                }

                @Override public void onResponse(Call call, Response response) throws IOException {
                    String body = response.body() == null ? "{}" : response.body().string();
                    response.close();
                    try {
                        JSONObject ticket = new JSONObject(body);
                        String status = ticket.optString("status", "waiting");
                        if ("matched".equals(status)) {
                            String socketUrl = ticket.optString("socketUrl", "");
                            if (!socketUrl.isEmpty()) { connect(socketUrl); return; }
                        }
                        if ("waiting".equals(status)) {
                            updateGameStatus("Searching... (" + (attempt + 1) + ")");
                            pollTicket(ticketId, attempt + 1);
                        } else {
                            fallbackToBots("No online players found.");
                        }
                    } catch (Exception e) {
                        fallbackToBots("Online matchmaking check failed.");
                    }
                }
            });
        }, 2000);
    }

    private void fallbackToBots(String reason) {
        if (fallbackBotStarted) return;
        fallbackBotStarted = true;
        connecting = false;
        updateGameStatus(reason + " Starting bot match...");
        main.postDelayed(() -> {
            connecting = false;
            startBotMatch(pendingMatchMode);
        }, 650);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private String rememberRoomEvent(String type, JSONObject envelope, JSONObject snap) {
        if ("dice_rolled".equals(type)) {
            lastRollValue = envelope.optInt("value", 0);
            lastRollAt = System.currentTimeMillis();
            lastRollPlayerId = envelope.optString("playerId", "");

            boolean mine = playerId != null && playerId.equals(lastRollPlayerId);
            JSONArray moves = snap == null ? null : snap.optJSONArray("availableMoves");
            boolean hasMoves = moves != null && moves.length() > 0;
            if (mine) {
                return hasMoves
                        ? "You rolled " + lastRollValue + ". Tap a highlighted piece."
                        : "You rolled " + lastRollValue + ". No legal move, turn passed.";
            }
            return playerName(snap, lastRollPlayerId) + " rolled " + lastRollValue + ".";
        }

        if ("turn_skipped".equals(type)) {
            String eventPlayerId = envelope.optString("playerId", "");
            boolean mine = playerId != null && playerId.equals(eventPlayerId);
            String rollText = (lastRollValue > 0 && eventPlayerId.equals(lastRollPlayerId))
                    ? " rolled " + lastRollValue
                    : "";
            return mine
                    ? "You" + rollText + ". No legal move, turn passed."
                    : playerName(snap, eventPlayerId) + rollText + " and had no legal move.";
        }

        if ("move_accepted".equals(type)) {
            String eventPlayerId = envelope.optString("playerId", "");
            boolean mine = playerId != null && playerId.equals(eventPlayerId);
            String pieceId = envelope.optString("pieceId", "");
            return mine
                    ? "Moved " + pieceId + "."
                    : playerName(snap, eventPlayerId) + " moved a piece.";
        }

        if ("match_finished".equals(type)) {
            String winner = envelope.optString("winnerPlayerId", "");
            return playerId != null && playerId.equals(winner)
                    ? "You won the match."
                    : playerName(snap, winner) + " won the match.";
        }

        return null;
    }

    private void resetLiveMatch() {
        if (socket != null) {
            socket.close(1000, "new_match");
            socket = null;
        }
        lastSnapshot = null;
        clearRollState();
    }

    private void clearRollState() {
        lastRollValue = 0;
        lastRollAt = 0L;
        lastRollPlayerId = null;
    }

    private boolean hasDiceValue(JSONObject snap) {
        return snap != null && snap.has("diceValue") && !snap.isNull("diceValue");
    }

    private boolean isMyTurn(JSONObject snap) {
        int mySeat = seatForPlayer(snap, playerId);
        return mySeat >= 0 && mySeat == snap.optInt("currentTurnSeat", -1)
                && "playing".equals(snap.optString("status", ""));
    }

    private int seatForPlayer(JSONObject snap, String targetPlayerId) {
        if (snap == null || targetPlayerId == null) return -1;
        JSONArray seats = snap.optJSONArray("seats");
        if (seats == null) return -1;
        for (int i = 0; i < seats.length(); i++) {
            JSONObject seat = seats.optJSONObject(i);
            if (seat != null && targetPlayerId.equals(seat.optString("playerId"))) {
                return seat.optInt("seat", -1);
            }
        }
        return -1;
    }

    private String playerName(JSONObject snap, String targetPlayerId) {
        JSONObject source = snap != null ? snap : lastSnapshot;
        if (source != null && targetPlayerId != null) {
            JSONArray seats = source.optJSONArray("seats");
            if (seats != null) {
                for (int i = 0; i < seats.length(); i++) {
                    JSONObject seat = seats.optJSONObject(i);
                    if (seat != null && targetPlayerId.equals(seat.optString("playerId"))) {
                        String name = seat.optString("displayName", "");
                        if (!name.isEmpty()) return name;
                    }
                }
            }
        }
        return "Player";
    }

    private boolean contains(JSONArray array, String value) {
        if (array == null || value == null) return false;
        for (int i = 0; i < array.length(); i++) {
            if (value.equals(array.optString(i))) return true;
        }
        return false;
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
        main.post(() -> { if (gameScreen != null) gameScreen.setStatus(text); });
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
        post(path, payload, handler, null);
    }

    private void post(String path, JSONObject payload, JsonHandler handler, Runnable onError) {
        Request req = new Request.Builder()
                .url(BACKEND_URL + path)
                .post(RequestBody.create(payload.toString(), JSON))
                .build();
        http.newCall(req).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) {
                handleRequestError("Request failed: " + e.getMessage(), onError);
            }

            @Override public void onResponse(Call call, Response r) throws IOException {
                String text = r.body() == null ? "{}" : r.body().string();
                r.close();
                try {
                    if (!r.isSuccessful()) {
                        handleRequestError("HTTP " + r.code() + ": " + text, onError);
                        return;
                    }
                    handler.handle(new JSONObject(text));
                } catch (Exception e) {
                    handleRequestError("Response error: " + e.getMessage(), onError);
                }
            }
        });
    }

    private void handleRequestError(String message, Runnable onError) {
        connecting = false;
        if (onError != null) {
            onError.run();
        } else {
            updateGameStatus(message);
        }
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

    private int systemBarHeight(String name) {
        int id = getResources().getIdentifier(name, "dimen", "android");
        return id > 0 ? getResources().getDimensionPixelSize(id) : 0;
    }

    /** Apply status-bar and nav-bar colors from the active theme. */
    private void applyThemeSystemBars() {
        ThemeManager t = ThemeManager.get(this);
        int barColor = t.sysBarColor();
        getWindow().setStatusBarColor(barColor);
        getWindow().setNavigationBarColor(barColor);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowInsetsController controller = getWindow().getInsetsController();
            if (controller != null) {
                int mask = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
                        | WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS;
                int appearance = t.isDark() ? 0 : mask;
                controller.setSystemBarsAppearance(appearance, mask);
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            View decor = getWindow().getDecorView();
            int flags = decor.getSystemUiVisibility();
            if (t.isDark()) {
                flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    flags &= ~View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                }
            } else {
                flags |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    flags |= View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                }
            }
            decor.setSystemUiVisibility(flags);
        }
    }

    private interface JsonHandler {
        void handle(JSONObject body) throws Exception;
    }

    // ── Animated background canvas ────────────────────────────────────────────

    static final class BackgroundView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final ThemeManager theme;

        BackgroundView(Activity activity) {
            super(activity);
            theme = ThemeManager.get(activity);
        }

        @Override protected void onDraw(Canvas canvas) {
            int w = getWidth(), h = getHeight();
            if (theme.isDark()) {
                paint.setShader(new LinearGradient(0, 0, w, h,
                        new int[]{0xff150020, 0xff6B1B83, 0xff2A0B49}, null, Shader.TileMode.CLAMP));
                canvas.drawRect(0, 0, w, h, paint);
            } else {
                paint.setShader(new LinearGradient(0, 0, w, h,
                        new int[]{0xffFFF0FB, 0xffFFD95A, 0xff40D8FF, 0xff8D4CFF}, null, Shader.TileMode.CLAMP));
                canvas.drawRect(0, 0, w, h, paint);
            }
            paint.setShader(null);
            int[] colors = theme.isDark()
                    ? new int[]{0x55FFD426, 0x5532D3C8, 0x55FF5BC8, 0x4456FF32, 0x33FFFFFF}
                    : new int[]{0x777C4DFF, 0x77FF2F7E, 0x7732D3C8, 0x7756FF32, 0x66FFD426};
            for (int i = 0; i < 38; i++) {
                float x = ((i * 97 + 31) % 1000) / 1000f * w;
                float y = ((i * 53 + 19) % 1000) / 1000f * h;
                paint.setColor(colors[i % colors.length]);
                if (i % 4 == 0) {
                    canvas.drawCircle(x, y, 5f + (i % 3) * 2f, paint);
                } else {
                    canvas.save();
                    canvas.rotate((i * 23) % 180, x, y);
                    canvas.drawRoundRect(x, y, x + 18f, y + 5f, 3f, 3f, paint);
                    canvas.restore();
                }
            }
        }
    }
}
