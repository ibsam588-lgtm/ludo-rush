using UnityEngine;

namespace LudoRush.Monetization
{
    public sealed class AdsController : MonoBehaviour
    {
        public void ShowLobbyBanner()
        {
            Debug.Log("Banner ad hook: wire AdMob after gameplay loop is stable.");
        }

        public void ShowRewardedCoins(System.Action<bool> onCompleted)
        {
            Debug.Log("Rewarded ad hook: wire AdMob rewarded video here.");
            onCompleted?.Invoke(false);
        }
    }
}
