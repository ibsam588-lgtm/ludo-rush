using System.Collections;
using System.Text;
using LudoRush.Core;
using UnityEngine;
using UnityEngine.Networking;

namespace LudoRush.Networking
{
    public sealed class LudoRushApiClient : MonoBehaviour
    {
        [SerializeField] private LudoRushConfig config;

        public IEnumerator CreateGuest(string displayName, System.Action<PlayerProfile> onSuccess, System.Action<string> onError)
        {
            var request = new GuestAuthRequest
            {
                displayName = displayName,
                region = config.DefaultRegion
            };

            yield return Post("/api/v1/auth/guest", JsonUtility.ToJson(request), body =>
            {
                var response = JsonUtility.FromJson<GuestAuthResponse>(body);
                onSuccess?.Invoke(new PlayerProfile
                {
                    id = response.player.id,
                    displayName = response.player.displayName,
                    region = response.player.region,
                    rating = response.player.rating,
                    coins = response.player.coins
                });
            }, onError);
        }

        public IEnumerator QuickMatch(PlayerProfile player, System.Action<MatchResponse> onSuccess, System.Action<string> onError)
        {
            var request = new QuickMatchRequest
            {
                playerId = player.id,
                displayName = player.displayName,
                mode = config.DefaultMode,
                region = player.region,
                latencyMs = 0,
                rating = player.rating
            };

            yield return Post("/api/v1/matchmaking/quick", JsonUtility.ToJson(request), body =>
            {
                onSuccess?.Invoke(JsonUtility.FromJson<MatchResponse>(body));
            }, onError);
        }

        public IEnumerator BotMatch(PlayerProfile player, System.Action<MatchResponse> onSuccess, System.Action<string> onError)
        {
            var request = new QuickMatchRequest
            {
                playerId = player.id,
                displayName = player.displayName,
                mode = config.DefaultMode,
                region = player.region,
                latencyMs = 0,
                rating = player.rating
            };

            yield return Post("/api/v1/matchmaking/bots", JsonUtility.ToJson(request), body =>
            {
                onSuccess?.Invoke(JsonUtility.FromJson<MatchResponse>(body));
            }, onError);
        }

        public IEnumerator PollMatchTicket(string ticketId, System.Action<MatchResponse> onSuccess, System.Action<string> onError)
        {
            yield return Get($"/api/v1/matchmaking/tickets/{ticketId}", body =>
            {
                onSuccess?.Invoke(JsonUtility.FromJson<MatchResponse>(body));
            }, onError);
        }

        public IEnumerator CreatePrivateRoom(PlayerProfile player, System.Action<MatchResponse> onSuccess, System.Action<string> onError)
        {
            var request = new PrivateRoomRequest
            {
                playerId = player.id,
                displayName = player.displayName,
                mode = config.DefaultMode,
                region = player.region
            };

            yield return Post("/api/v1/rooms/private", JsonUtility.ToJson(request), body =>
            {
                onSuccess?.Invoke(JsonUtility.FromJson<MatchResponse>(body));
            }, onError);
        }

        public IEnumerator JoinPrivateRoom(PlayerProfile player, string code, System.Action<MatchResponse> onSuccess, System.Action<string> onError)
        {
            var request = new JoinPrivateRoomRequest
            {
                playerId = player.id,
                displayName = player.displayName,
                code = code
            };

            yield return Post("/api/v1/rooms/private/join", JsonUtility.ToJson(request), body =>
            {
                onSuccess?.Invoke(JsonUtility.FromJson<MatchResponse>(body));
            }, onError);
        }

        private IEnumerator Post(string path, string json, System.Action<string> onSuccess, System.Action<string> onError)
        {
            using var request = new UnityWebRequest(config.BackendBaseUrl + path, UnityWebRequest.kHttpVerbPOST);
            var payload = Encoding.UTF8.GetBytes(json);
            request.uploadHandler = new UploadHandlerRaw(payload);
            request.downloadHandler = new DownloadHandlerBuffer();
            request.SetRequestHeader("Content-Type", "application/json");

            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                onSuccess?.Invoke(request.downloadHandler.text);
            }
            else
            {
                onError?.Invoke(request.error);
            }
        }

        private IEnumerator Get(string path, System.Action<string> onSuccess, System.Action<string> onError)
        {
            using var request = UnityWebRequest.Get(config.BackendBaseUrl + path);
            yield return request.SendWebRequest();

            if (request.result == UnityWebRequest.Result.Success)
            {
                onSuccess?.Invoke(request.downloadHandler.text);
            }
            else
            {
                onError?.Invoke(request.error);
            }
        }
    }
}
