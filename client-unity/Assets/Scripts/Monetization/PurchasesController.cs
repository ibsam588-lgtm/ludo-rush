using UnityEngine;

namespace LudoRush.Monetization
{
    public sealed class PurchasesController : MonoBehaviour
    {
        public void BuyCoins(string productId)
        {
            Debug.Log($"IAP hook: purchase {productId} through platform billing.");
        }

        public void RestorePurchases()
        {
            Debug.Log("IAP hook: restore platform purchases.");
        }
    }
}
