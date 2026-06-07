using System;
using System.Collections.Concurrent;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

namespace LudoRush.Networking
{
    public sealed class RealtimeRoomClient : MonoBehaviour
    {
        private ClientWebSocket socket;
        private CancellationTokenSource cancellation;
        private readonly ConcurrentQueue<string> pendingMessages = new ConcurrentQueue<string>();

        public event Action<string> MessageReceived;
        public bool IsConnected => socket?.State == WebSocketState.Open;

        public async Task ConnectAsync(string backendBaseUrl, string socketPath, string playerId, string displayName)
        {
            await DisconnectAsync();

            cancellation = new CancellationTokenSource();
            socket = new ClientWebSocket();

            var uri = BuildSocketUri(backendBaseUrl, socketPath, playerId, displayName);
            await socket.ConnectAsync(uri, cancellation.Token);
            _ = ReceiveLoop();
        }

        public Task JoinAsync(string playerId, string displayName)
        {
            return SendJsonAsync($"{{\"type\":\"join\",\"playerId\":\"{Escape(playerId)}\",\"displayName\":\"{Escape(displayName)}\"}}");
        }

        public Task RollDiceAsync(string playerId)
        {
            return SendJsonAsync($"{{\"type\":\"roll_dice\",\"playerId\":\"{Escape(playerId)}\"}}");
        }

        public Task MovePieceAsync(string playerId, string pieceId)
        {
            return SendJsonAsync($"{{\"type\":\"move_piece\",\"playerId\":\"{Escape(playerId)}\",\"pieceId\":\"{Escape(pieceId)}\"}}");
        }

        public Task FillBotsAsync(string playerId)
        {
            return SendJsonAsync($"{{\"type\":\"fill_bots\",\"playerId\":\"{Escape(playerId)}\"}}");
        }

        public Task ResignAsync(string playerId)
        {
            return SendJsonAsync($"{{\"type\":\"resign\",\"playerId\":\"{Escape(playerId)}\"}}");
        }

        public async Task DisconnectAsync()
        {
            if (socket == null)
            {
                return;
            }

            cancellation?.Cancel();

            if (socket.State == WebSocketState.Open)
            {
                await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, "client disconnect", CancellationToken.None);
            }

            socket.Dispose();
            socket = null;
        }

        private async Task SendJsonAsync(string json)
        {
            if (!IsConnected)
            {
                Debug.LogWarning("Room socket is not connected.");
                return;
            }

            var bytes = Encoding.UTF8.GetBytes(json);
            await socket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, cancellation.Token);
        }

        private async Task ReceiveLoop()
        {
            var buffer = new byte[4096];

            while (socket != null && socket.State == WebSocketState.Open && !cancellation.IsCancellationRequested)
            {
                var builder = new StringBuilder();
                WebSocketReceiveResult result;

                do
                {
                    result = await socket.ReceiveAsync(new ArraySegment<byte>(buffer), cancellation.Token);
                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        return;
                    }

                    builder.Append(Encoding.UTF8.GetString(buffer, 0, result.Count));
                } while (!result.EndOfMessage);

                pendingMessages.Enqueue(builder.ToString());
            }
        }

        private static Uri BuildSocketUri(string backendBaseUrl, string socketPath, string playerId, string displayName)
        {
            var baseUri = new Uri(backendBaseUrl);
            var builder = new UriBuilder(baseUri)
            {
                Scheme = baseUri.Scheme == "https" ? "wss" : "ws",
                Path = socketPath.TrimStart('/')
            };

            builder.Query = $"playerId={Uri.EscapeDataString(playerId)}&displayName={Uri.EscapeDataString(displayName)}";

            return builder.Uri;
        }

        private static string Escape(string value)
        {
            return value.Replace("\\", "\\\\").Replace("\"", "\\\"");
        }

        private void OnDestroy()
        {
            _ = DisconnectAsync();
        }

        private void Update()
        {
            while (pendingMessages.TryDequeue(out var message))
            {
                MessageReceived?.Invoke(message);
            }
        }
    }
}
