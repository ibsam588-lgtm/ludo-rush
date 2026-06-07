using LudoRush.Core;
using LudoRush.Networking;
using UnityEngine;

namespace LudoRush.Game
{
    public sealed class LudoGameController : MonoBehaviour
    {
        [SerializeField] private LudoRushApiClient apiClient;
        [SerializeField] private RealtimeRoomClient realtimeClient;
        [SerializeField] private LudoRushConfig config;
        [SerializeField] private LudoBoardPresenter boardPresenter;
        [SerializeField] private string guestName = "Guest";
        [SerializeField] private float matchPollSeconds = 1.5f;

        private PlayerProfile player;
        private MatchResponse activeMatch;
        private LudoRoomSnapshot latestSnapshot;

        public PlayerProfile Player => player;
        public MatchResponse ActiveMatch => activeMatch;
        public LudoRoomSnapshot LatestSnapshot => latestSnapshot;

        private void Awake()
        {
            realtimeClient.MessageReceived += HandleRoomMessage;
        }

        public void StartGuestQuickMatch()
        {
            EnsureGuest(() =>
            {
                StartCoroutine(apiClient.QuickMatch(player, async match =>
                {
                    if (match.status == "waiting")
                    {
                        Debug.Log($"Waiting for match ticket {match.ticketId}");
                        StartCoroutine(PollTicket(match.ticketId));
                        return;
                    }

                    await ConnectToMatch(match);
                }, Debug.LogError));
            });
        }

        public void StartBotMatch()
        {
            EnsureGuest(() =>
            {
                StartCoroutine(apiClient.BotMatch(player, async match =>
                {
                    await ConnectToMatch(match);
                    await realtimeClient.FillBotsAsync(player.id);
                }, Debug.LogError));
            });
        }

        public void CreatePrivateRoom()
        {
            EnsureGuest(() =>
            {
                StartCoroutine(apiClient.CreatePrivateRoom(player, async match =>
                {
                    Debug.Log($"Private room code: {match.code}");
                    await ConnectToMatch(match);
                }, Debug.LogError));
            });
        }

        public void JoinPrivateRoom(string code)
        {
            EnsureGuest(() =>
            {
                StartCoroutine(apiClient.JoinPrivateRoom(player, code, async match =>
                {
                    await ConnectToMatch(match);
                }, Debug.LogError));
            });
        }

        public async void RollDice()
        {
            if (player != null)
            {
                await realtimeClient.RollDiceAsync(player.id);
            }
        }

        public async void MovePiece(string pieceId)
        {
            if (player != null)
            {
                await realtimeClient.MovePieceAsync(player.id, pieceId);
            }
        }

        public void MoveFirstAvailablePiece()
        {
            if (latestSnapshot?.availableMoves == null || latestSnapshot.availableMoves.Length == 0)
            {
                Debug.LogWarning("No legal pieces are currently available.");
                return;
            }

            MovePiece(latestSnapshot.availableMoves[0]);
        }

        private void EnsureGuest(System.Action onReady)
        {
            if (player != null)
            {
                onReady?.Invoke();
                return;
            }

            StartCoroutine(apiClient.CreateGuest(guestName, createdPlayer =>
            {
                player = createdPlayer;
                onReady?.Invoke();
            }, Debug.LogError));
        }

        private System.Collections.IEnumerator PollTicket(string ticketId)
        {
            while (true)
            {
                yield return new WaitForSeconds(matchPollSeconds);
                var completed = false;

                yield return apiClient.PollMatchTicket(ticketId, async match =>
                {
                    completed = match.status != "waiting";
                    if (match.status == "matched")
                    {
                        await ConnectToMatch(match);
                    }
                    else if (match.status == "expired")
                    {
                        Debug.LogWarning("Match ticket expired. Try quick match again.");
                    }
                }, Debug.LogError);

                if (completed)
                {
                    yield break;
                }
            }
        }

        private async System.Threading.Tasks.Task ConnectToMatch(MatchResponse match)
        {
            activeMatch = match;
            Debug.Log($"Matched into room {activeMatch.roomId}");
            await realtimeClient.ConnectAsync(config.BackendBaseUrl, activeMatch.socketUrl, player.id, player.displayName);
            await realtimeClient.JoinAsync(player.id, player.displayName);
        }

        private void HandleRoomMessage(string json)
        {
            if (string.IsNullOrWhiteSpace(json))
            {
                return;
            }

            var envelope = JsonUtility.FromJson<RoomMessageEnvelope>(json);
            if (envelope.snapshot != null)
            {
                latestSnapshot = envelope.snapshot;
                boardPresenter?.ApplySnapshot(latestSnapshot);
                Debug.Log($"Room {latestSnapshot.roomId}: {envelope.type}, status={latestSnapshot.status}, turn={latestSnapshot.currentTurnSeat}");
            }
        }

        private void OnDestroy()
        {
            if (realtimeClient != null)
            {
                realtimeClient.MessageReceived -= HandleRoomMessage;
            }
        }
    }

    [System.Serializable]
    public sealed class RoomMessageEnvelope
    {
        public string type;
        public string playerId;
        public int value;
        public string pieceId;
        public string winnerPlayerId;
        public LudoRoomSnapshot snapshot;
    }
}
