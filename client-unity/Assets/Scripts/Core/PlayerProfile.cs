using System;

namespace LudoRush.Core
{
    [Serializable]
    public sealed class PlayerProfile
    {
        public string id;
        public string displayName;
        public string region;
        public int rating;
        public int coins;
    }
}
