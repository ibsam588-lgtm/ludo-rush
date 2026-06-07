using System;

namespace LudoRush.Game
{
    [Serializable]
    public sealed class LudoRoomSnapshot
    {
        public string roomId;
        public string code;
        public string mode;
        public string region;
        public string status;
        public LudoSeat[] seats;
        public LudoPiece[] pieces;
        public int currentTurnSeat;
        public int diceValue;
        public string[] availableMoves;
        public long turnStartedAt;
        public long turnDeadlineAt;
        public string winnerPlayerId;
        public string[] finishOrder;
        public long createdAt;
        public long updatedAt;
    }
}
