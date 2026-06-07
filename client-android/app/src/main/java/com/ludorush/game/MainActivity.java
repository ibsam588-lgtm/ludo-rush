package com.ludorush.game;

import android.app.Activity;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
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
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

public final class MainActivity extends Activity {
    private static final String BACKEND_URL = "https://ludo-rush-backend.ibsam588.workers.dev";
    private static final MediaType JSON = MediaType.get("application/json; charset=utf-8");

    private final Handler main = new Handler(Looper.getMainLooper());
    private final OkHttpClient http = new OkHttpClient.Builder()
            .readTimeout(0, TimeUnit.MILLISECONDS)
            .build();

    private TextView status;
    private BoardView board;
    private WebSocket socket;
    private String playerId;
    private String displayName = "Android Tester";
    private JSONObject snapshot;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(createUi());
        health();
    }

    private View createUi() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER_HORIZONTAL);
        root.setPadding(28, 42, 28, 28);
        root.setBackgroundColor(Color.rgb(12, 14, 22));

        TextView title = new TextView(this);
        title.setText("Ludo Rush");
        title.setTextColor(Color.WHITE);
        title.setTextSize(30);
        title.setGravity(Gravity.CENTER);
        root.addView(title, new LinearLayout.LayoutParams(-1, -2));

        status = new TextView(this);
        status.setText("Checking backend...");
        status.setTextColor(Color.WHITE);
        status.setTextSize(16);
        status.setPadding(0, 18, 0, 18);
        root.addView(status, new LinearLayout.LayoutParams(-1, -2));

        board = new BoardView(this);
        root.addView(board, new LinearLayout.LayoutParams(-1, 0, 1));

        LinearLayout row1 = row();
        row1.addView(button("Bot Match", v -> startBotMatch()));
        row1.addView(button("Roll", v -> roll()));
        root.addView(row1);

        LinearLayout row2 = row();
        row2.addView(button("Move", v -> moveFirstAvailable()));
        row2.addView(button("Health", v -> health()));
        root.addView(row2);

        return root;
    }

    private LinearLayout row() {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER);
        return row;
    }

    private Button button(String label, View.OnClickListener listener) {
        Button button = new Button(this);
        button.setText(label);
        button.setAllCaps(false);
        button.setOnClickListener(listener);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, 112, 1);
        params.setMargins(8, 8, 8, 8);
        button.setLayoutParams(params);
        return button;
    }

    private void health() {
        Request request = new Request.Builder().url(BACKEND_URL + "/health").build();
        http.newCall(request).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) {
                setStatus("Backend offline: " + e.getMessage());
            }

            @Override public void onResponse(Call call, Response response) throws IOException {
                setStatus(response.isSuccessful() ? "Backend online" : "Backend error " + response.code());
                response.close();
            }
        });
    }

    private void startBotMatch() {
        setStatus("Creating guest...");
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
        String wsUrl = BACKEND_URL.replace("https://", "wss://") + socketPath
                + "?playerId=" + playerId
                + "&displayName=" + displayName.replace(" ", "%20");
        Request request = new Request.Builder().url(wsUrl).build();
        socket = http.newWebSocket(request, new WebSocketListener() {
            @Override public void onOpen(WebSocket webSocket, Response response) {
                send(json("type", "join", "playerId", playerId, "displayName", displayName));
                send(json("type", "fill_bots", "playerId", playerId));
                setStatus("Connected to room");
            }

            @Override public void onMessage(WebSocket webSocket, String text) {
                handleRoomMessage(text);
            }

            @Override public void onFailure(WebSocket webSocket, Throwable t, Response response) {
                setStatus("Socket error: " + t.getMessage());
            }
        });
    }

    private void roll() {
        if (socket == null || playerId == null) {
            setStatus("Start a bot match first.");
            return;
        }
        send(json("type", "roll_dice", "playerId", playerId));
    }

    private void moveFirstAvailable() {
        if (socket == null || snapshot == null) {
            setStatus("No active room.");
            return;
        }
        JSONArray moves = snapshot.optJSONArray("availableMoves");
        if (moves == null || moves.length() == 0) {
            setStatus("No legal moves available.");
            return;
        }
        send(json("type", "move_piece", "playerId", playerId, "pieceId", moves.optString(0)));
    }

    private void handleRoomMessage(String text) {
        try {
            JSONObject envelope = new JSONObject(text);
            JSONObject next = envelope.optJSONObject("snapshot");
            if (next != null) {
                snapshot = next;
                main.post(() -> {
                    board.setSnapshot(snapshot);
                    int dice = snapshot.optInt("diceValue", 0);
                    setStatus("Room " + snapshot.optString("status") + " | Turn seat " + snapshot.optInt("currentTurnSeat") + " | Dice " + (dice == 0 ? "-" : dice));
                });
            }
        } catch (Exception e) {
            setStatus("Message parse error: " + e.getMessage());
        }
    }

    private void post(String path, JSONObject payload, JsonHandler handler) {
        Request request = new Request.Builder()
                .url(BACKEND_URL + path)
                .post(RequestBody.create(payload.toString(), JSON))
                .build();
        http.newCall(request).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) {
                setStatus("Request failed: " + e.getMessage());
            }

            @Override public void onResponse(Call call, Response response) throws IOException {
                String text = response.body() == null ? "{}" : response.body().string();
                response.close();
                try {
                    if (!response.isSuccessful()) {
                        setStatus("HTTP " + response.code() + ": " + text);
                        return;
                    }
                    handler.handle(new JSONObject(text));
                } catch (Exception e) {
                    setStatus("Response error: " + e.getMessage());
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
        main.post(() -> status.setText(text));
    }

    private interface JsonHandler {
        void handle(JSONObject body) throws Exception;
    }

    public static final class BoardView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private JSONObject snapshot;

        public BoardView(Activity activity) {
            super(activity);
            setMinimumHeight(720);
        }

        public void setSnapshot(JSONObject snapshot) {
            this.snapshot = snapshot;
            invalidate();
        }

        @Override protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            int width = getWidth();
            int height = getHeight();
            int size = Math.min(width - 40, height - 40);
            int left = (width - size) / 2;
            int top = (height - size) / 2;

            paint.setColor(Color.rgb(22, 25, 34));
            canvas.drawRect(left, top, left + size, top + size, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(5);
            paint.setColor(Color.WHITE);
            canvas.drawRect(left, top, left + size, top + size, paint);
            paint.setStyle(Paint.Style.FILL);

            drawHomes(canvas, left, top, size);
            drawPieces(canvas, left, top, size);
        }

        private void drawHomes(Canvas canvas, int left, int top, int size) {
            int block = size / 3;
            int[][] colors = {
                    {239, 55, 86}, {30, 187, 232}, {252, 202, 54}, {59, 220, 132}
            };
            int[][] pos = {
                    {left + 24, top + 24},
                    {left + size - block - 24, top + 24},
                    {left + size - block - 24, top + size - block - 24},
                    {left + 24, top + size - block - 24}
            };
            for (int i = 0; i < 4; i++) {
                paint.setColor(Color.rgb(colors[i][0], colors[i][1], colors[i][2]));
                canvas.drawRect(pos[i][0], pos[i][1], pos[i][0] + block, pos[i][1] + block, paint);
            }
            paint.setColor(Color.WHITE);
            canvas.drawCircle(left + size / 2f, top + size / 2f, size / 10f, paint);
        }

        private void drawPieces(Canvas canvas, int left, int top, int size) {
            if (snapshot == null) return;
            JSONArray pieces = snapshot.optJSONArray("pieces");
            if (pieces == null) return;
            List<JSONObject> list = new ArrayList<>();
            for (int i = 0; i < pieces.length(); i++) list.add(pieces.optJSONObject(i));
            int[] colors = {Color.rgb(239, 55, 86), Color.rgb(30, 187, 232), Color.rgb(252, 202, 54), Color.rgb(59, 220, 132)};
            for (JSONObject piece : list) {
                if (piece == null) continue;
                int seat = piece.optInt("seat");
                int index = piece.optString("pieceId").endsWith("p0") ? 0 : piece.optString("pieceId").endsWith("p1") ? 1 : piece.optString("pieceId").endsWith("p2") ? 2 : 3;
                float[] p = position(piece, left, top, size, index);
                paint.setColor(colors[Math.max(0, Math.min(seat, colors.length - 1))]);
                canvas.drawCircle(p[0], p[1], Math.max(14, size / 42f), paint);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(4);
                paint.setColor(Color.WHITE);
                canvas.drawCircle(p[0], p[1], Math.max(14, size / 42f), paint);
                paint.setStyle(Paint.Style.FILL);
            }
        }

        private float[] position(JSONObject piece, int left, int top, int size, int index) {
            String state = piece.optString("state");
            if ("yard".equals(state)) {
                int seat = piece.optInt("seat");
                float x = seat == 0 || seat == 3 ? left + size * 0.22f : left + size * 0.78f;
                float y = seat < 2 ? top + size * 0.22f : top + size * 0.78f;
                return offset(x, y, index, size);
            }
            if ("home".equals(state) || "finished".equals(state)) {
                return offset(left + size / 2f, top + size / 2f, index, size);
            }
            return track(piece.optInt("trackIndex"), left, top, size, index);
        }

        private float[] track(int trackIndex, int left, int top, int size, int index) {
            int side = trackIndex / 13;
            int pos = trackIndex % 13;
            float step = size / 13f;
            float x;
            float y;
            if (side == 0) { x = left + pos * step; y = top + size; }
            else if (side == 1) { x = left + size; y = top + size - pos * step; }
            else if (side == 2) { x = left + size - pos * step; y = top; }
            else { x = left; y = top + pos * step; }
            return offset(x, y, index, size);
        }

        private float[] offset(float x, float y, int index, int size) {
            float d = Math.max(8, size / 55f);
            return new float[]{x + (index % 2 == 0 ? -d : d), y + (index < 2 ? -d : d)};
        }
    }
}
