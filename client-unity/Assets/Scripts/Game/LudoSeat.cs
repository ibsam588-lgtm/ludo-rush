using System;

namespace LudoRush.Game
{
    [Serializable]
    public sealed class LudoSeat
    {
        public int seat;
        public string playerId;
        public string displayName;
        public bool connected;
        public bool isBot;
        public long joinedAt;
        public long disconnectedAt;
        public int finishRank;
    }
}
