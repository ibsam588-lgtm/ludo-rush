using UnityEngine;

namespace LudoRush.Core
{
    [CreateAssetMenu(menuName = "Ludo Rush/App Config", fileName = "LudoRushConfig")]
    public sealed class LudoRushConfig : ScriptableObject
    {
        [SerializeField] private string backendBaseUrl = "http://localhost:8787";
        [SerializeField] private string defaultRegion = "auto";
        [SerializeField] private string defaultMode = "classic_2p";

        public string BackendBaseUrl => backendBaseUrl;
        public string DefaultRegion => defaultRegion;
        public string DefaultMode => defaultMode;
    }
}
