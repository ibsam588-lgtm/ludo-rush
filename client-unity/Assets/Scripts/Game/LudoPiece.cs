using System;

namespace LudoRush.Game
{
    [Serializable]
    public sealed class LudoPiece
    {
        public string pieceId;
        public int seat;
        public int progress;
        public string state;
        public int trackIndex;
    }
}
