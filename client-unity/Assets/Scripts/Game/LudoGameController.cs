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
        private string statusMessage = "Choose a mode to start.";
        private int lastRollValue;

        public event System.Action<string> StatusChanged;

        public PlayerProfile Player => player;
        public MatchResponse ActiveMatch => activeMatch;
        public LudoRoomSnapshot LatestSnapshot => latestSnapshot;
        public string StatusMessage => statusMessage;
        public int LastRollValue => latestSnapshot != null && latestSnapshot.diceValue > 0 ? latestSnapshot.diceValue : lastRollValue;

        private void Awake()
        {
            realtimeClient.MessageReceived += HandleRoomMessage;
        }

        public void StartGuestQuickMatch()
        {
            SetStatus("Searching for an online match...");
            EnsureGuest(() =>
            {
                StartCoroutine(apiClient.QuickMatch(player, async match =>
                {
                    if (match.status == "waiting")
                    {
                        SetStatus("Waiting for a matched player...");
                        StartCoroutine(PollTicket(match.ticketId));
                        return;
                    }

                    await ConnectToMatch(match);
                }, SetError));
            });
        }

        public void StartBotMatch()
        {
            SetStatus("Creating a bot match...");
            EnsureGuest(() =>
            {
                StartCoroutine(apiClient.BotMatch(player, async match =>
                {
                    await ConnectToMatch(match);
                    await realtimeClient.FillBotsAsync(player.id);
                }, SetError));
            });
        }

        public void CreatePrivateRoom()
        {
            SetStatus("Creating a private room...");
            EnsureGuest(() =>
            {
                StartCoroutine(apiClient.CreatePrivateRoom(player, async match =>
                {
                    SetStatus(string.IsNullOrWhiteSpace(match.code)
                        ? "Private room ready."
                        : $"Private room code: {match.code}");
                    await ConnectToMatch(match);
                }, SetError));
            });
        }

        public void JoinPrivateRoom(string code)
        {
            SetStatus("Joining private room...");
            EnsureGuest(() =>
            {
                StartCoroutine(apiClient.JoinPrivateRoom(player, code, async match =>
                {
                    await ConnectToMatch(match);
                }, SetError));
            });
        }

        public async void RollDice()
        {
            if (player == null || realtimeClient == null || !realtimeClient.IsConnected)
            {
                SetStatus("Start a match before rolling.");
                return;
            }

            SetStatus("Rolling dice...");
            await realtimeClient.RollDiceAsync(player.id);
        }

        public async void MovePiece(string pieceId)
        {
            if (player == null || realtimeClient == null || !realtimeClient.IsConnected)
            {
                SetStatus("Start a match before moving.");
                return;
            }

            SetStatus("Moving piece...");
            await realtimeClient.MovePieceAsync(player.id, pieceId);
        }

        public void MoveFirstAvailablePiece()
        {
            if (latestSnapshot?.availableMoves == null || latestSnapshot.availableMoves.Length == 0)
            {
                SetStatus("No legal pieces are currently available.");
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
                SetStatus($"Welcome, {player.displayName}.");
                onReady?.Invoke();
            }, SetError));
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
                        SetStatus("Match ticket expired. Try quick match again.");
                    }
                    else
                    {
                        SetStatus($"Matchmaking status: {match.status}");
                    }
                }, SetError);

                if (completed)
                {
                    yield break;
                }
            }
        }

        private async System.Threading.Tasks.Task ConnectToMatch(MatchResponse match)
        {
            activeMatch = match;
            SetStatus("Connecting to room...");
            await realtimeClient.ConnectAsync(config.BackendBaseUrl, activeMatch.socketUrl, player.id, player.displayName);
            await realtimeClient.JoinAsync(player.id, player.displayName);
            SetStatus("Match connected.");
        }

        private void HandleRoomMessage(string json)
        {
            if (string.IsNullOrWhiteSpace(json))
            {
                return;
            }

            var envelope = JsonUtility.FromJson<RoomMessageEnvelope>(json);
            if (envelope.value > 0)
            {
                lastRollValue = envelope.value;
            }

            if (envelope.snapshot != null)
            {
                latestSnapshot = envelope.snapshot;
                boardPresenter?.ApplySnapshot(latestSnapshot);
                SetStatus(StatusForMessage(envelope));
            }
            else if (!string.IsNullOrWhiteSpace(envelope.type))
            {
                SetStatus($"Room event: {envelope.type}");
            }
        }

        private string StatusForMessage(RoomMessageEnvelope envelope)
        {
            var snapshot = envelope.snapshot;
            if (snapshot == null)
            {
                return statusMessage;
            }

            if (snapshot.status == "finished")
            {
                return string.IsNullOrWhiteSpace(snapshot.winnerPlayerId)
                    ? "Match finished."
                    : "Match finished. Winner selected.";
            }

            if (envelope.type == "dice_rolled" && envelope.value > 0)
            {
                var moves = snapshot.availableMoves == null ? 0 : snapshot.availableMoves.Length;
                return moves > 0
                    ? $"Rolled {envelope.value}. Tap a highlighted piece."
                    : $"Rolled {envelope.value}. No legal move.";
            }

            if (envelope.type == "turn_skipped")
            {
                return "No legal move. Turn passed.";
            }

            if (IsMyTurn(snapshot))
            {
                return snapshot.diceValue > 0
                    ? "Tap a highlighted piece."
                    : "Your turn. Roll the dice.";
            }

            return $"Waiting for seat {snapshot.currentTurnSeat + 1}.";
        }

        private bool IsMyTurn(LudoRoomSnapshot snapshot)
        {
            if (snapshot == null || snapshot.seats == null || player == null)
            {
                return false;
            }

            for (var i = 0; i < snapshot.seats.Length; i++)
            {
                var seat = snapshot.seats[i];
                if (seat != null && seat.playerId == player.id)
                {
                    return seat.seat == snapshot.currentTurnSeat;
                }
            }

            return false;
        }

        private void SetError(string message)
        {
            SetStatus(string.IsNullOrWhiteSpace(message) ? "Something went wrong." : message);
            Debug.LogError(message);
        }

        private void SetStatus(string message)
        {
            statusMessage = message;
            StatusChanged?.Invoke(statusMessage);
            Debug.Log(statusMessage);
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
