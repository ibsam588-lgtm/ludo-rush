package com.ludorush.game;

import android.app.Activity;
import android.util.Log;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;

/**
 * Singleton ad controller.  Call attach(activity) in MainActivity.onCreate(), then use
 * createBanner(), showInterstitial(), and showRewarded() from any screen.
 *
 * Ad unit IDs come exclusively from BuildConfig (injected via local.properties at build time).
 * The fallback values in build.gradle are Google's official test unit IDs.
 */
public final class AdManager {

    private static final String TAG = "LudoAds";
    private static AdManager instance;

    private Activity activity;
    private InterstitialAd interstitialAd;
    private RewardedAd rewardedAd;
    private boolean initialized;

    private AdManager() {}

    public static AdManager get() {
        if (instance == null) instance = new AdManager();
        return instance;
    }

    /** Call once from MainActivity.onCreate() so ads load in the background. */
    public void attach(Activity a) {
        activity = a;
        if (!initialized) {
            initialized = true;
            MobileAds.initialize(a, status -> {
                Log.d(TAG, "SDK ready");
                loadInterstitial();
                loadRewarded();
            });
        }
    }

    /** Creates and loads a banner AdView sized BANNER (320×50). */
    public AdView createBanner() {
        AdView v = new AdView(activity);
        v.setAdSize(AdSize.BANNER);
        v.setAdUnitId(BuildConfig.ADMOB_BANNER_ID);
        v.loadAd(new AdRequest.Builder().build());
        return v;
    }

    /** Shows the pre-loaded interstitial.  Calls `after` when dismissed (or immediately if not ready). */
    public void showInterstitial(Runnable after) {
        if (interstitialAd == null || activity == null) {
            if (after != null) after.run();
            return;
        }
        interstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
            @Override public void onAdDismissedFullScreenContent() {
                interstitialAd = null;
                loadInterstitial();
                if (after != null) after.run();
            }
            @Override public void onAdFailedToShowFullScreenContent(com.google.android.gms.ads.AdError e) {
                interstitialAd = null;
                if (after != null) after.run();
            }
        });
        interstitialAd.show(activity);
    }

    /** Shows the pre-loaded rewarded ad.  Calls callback.onRewarded() with coin amount on success. */
    public void showRewarded(RewardCallback cb) {
        if (rewardedAd == null || activity == null) {
            if (cb != null) cb.onUnavailable();
            return;
        }
        rewardedAd.setFullScreenContentCallback(new FullScreenContentCallback() {
            @Override public void onAdDismissedFullScreenContent() {
                rewardedAd = null;
                loadRewarded();
            }
            @Override public void onAdFailedToShowFullScreenContent(com.google.android.gms.ads.AdError e) {
                rewardedAd = null;
                if (cb != null) cb.onUnavailable();
            }
        });
        rewardedAd.show(activity, item -> { if (cb != null) cb.onRewarded(item.getAmount()); });
    }

    public boolean isRewardedReady() { return rewardedAd != null; }

    private void loadInterstitial() {
        if (activity == null) return;
        InterstitialAd.load(activity, BuildConfig.ADMOB_INTERSTITIAL_ID,
            new AdRequest.Builder().build(),
            new InterstitialAdLoadCallback() {
                @Override public void onAdLoaded(InterstitialAd ad) { interstitialAd = ad; }
                @Override public void onAdFailedToLoad(LoadAdError e) {
                    Log.w(TAG, "Interstitial load failed: " + e.getMessage());
                }
            });
    }

    private void loadRewarded() {
        if (activity == null) return;
        RewardedAd.load(activity, BuildConfig.ADMOB_REWARDED_ID,
            new AdRequest.Builder().build(),
            new RewardedAdLoadCallback() {
                @Override public void onAdLoaded(RewardedAd ad) { rewardedAd = ad; }
                @Override public void onAdFailedToLoad(LoadAdError e) {
                    Log.w(TAG, "Rewarded load failed: " + e.getMessage());
                }
            });
    }

    public interface RewardCallback {
        void onRewarded(int coins);
        default void onUnavailable() {}
    }
}
