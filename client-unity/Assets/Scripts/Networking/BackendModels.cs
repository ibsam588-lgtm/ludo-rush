using System;

namespace LudoRush.Networking
{
    [Serializable]
    public sealed class GuestAuthRequest
    {
        public string displayName;
        public string region;
    }

    [Serializable]
    public sealed class GuestAuthResponse
    {
        public PlayerDto player;
    }

    [Serializable]
    public sealed class QuickMatchRequest
    {
        public string playerId;
        public string displayName;
        public string mode;
        public string region;
        public int latencyMs;
        public int rating;
    }

    [Serializable]
    public sealed class MatchResponse
    {
        public string status;
        public string ticketId;
        public string roomId;
        public string code;
        public string mode;
        public string region;
        public string socketUrl;
        public long expiresAt;
    }

    [Serializable]
    public sealed class PrivateRoomRequest
    {
        public string playerId;
        public string displayName;
        public string mode;
        public string region;
    }

    [Serializable]
    public sealed class JoinPrivateRoomRequest
    {
        public string playerId;
        public string displayName;
        public string code;
    }

    [Serializable]
    public sealed class PlayerDto
    {
        public string id;
        public string displayName;
        public string region;
        public int rating;
        public int coins;
    }
}
