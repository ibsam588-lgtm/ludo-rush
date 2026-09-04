import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../config/levelplay_ad_config.dart';
import 'ad_placement_policy.dart';

class LevelPlayAdService extends ChangeNotifier
    with
        LevelPlayInitListener,
        LevelPlayImpressionDataListener,
        LevelPlayInterstitialAdListener,
        LevelPlayRewardedAdListener {
  LevelPlayAdService._();

  static final LevelPlayAdService instance = LevelPlayAdService._();

  LevelPlayInterstitialAd? _interstitialAd;
  LevelPlayRewardedAd? _rewardedAd;
  Completer<bool>? _rewardCompleter;
  Completer<void>? _interstitialCloseCompleter;
  DateTime? _lastInterstitialAt;
  bool _initializing = false;
  bool _initialized = false;
  bool _interstitialShowing = false;
  bool _rewardedReady = false;
  bool _rewardedShowing = false;
  bool _rewardEarned = false;
  int _completedRounds = 0;

  bool get isConfigured => LevelPlayAdConfig.isConfigured;
  bool get isInitialized => _initialized;
  bool get canShowBanner => isConfigured && _initialized;
  bool get canShowRewarded =>
      isConfigured && _initialized && _rewardedReady && !_rewardedShowing;
  int get completedRounds => _completedRounds;

  Future<void> initialize({String? userId}) async {
    if (_initializing || _initialized || !LevelPlayAdConfig.isConfigured) {
      return;
    }

    _initializing = true;
    notifyListeners();

    try {
      LevelPlay.addImpressionDataListener(this);
      await LevelPlay.setAdaptersDebug(!LevelPlayAdConfig.isProduction);
      if (LevelPlayAdConfig.enableTestSuite) {
        await LevelPlay.setMetaData({
          'is_test_suite': ['enable']
        });
      }

      final cleanUserId = userId?.trim();
      var requestBuilder =
          LevelPlayInitRequest.builder(LevelPlayAdConfig.appKey);
      if (cleanUserId != null && cleanUserId.isNotEmpty) {
        requestBuilder = requestBuilder.withUserId(cleanUserId);
      }

      _interstitialAd = LevelPlayInterstitialAd(
        adUnitId: LevelPlayAdConfig.interstitialAdUnitId,
      )..setListener(this);
      _rewardedAd = LevelPlayRewardedAd(
        adUnitId: LevelPlayAdConfig.rewardedAdUnitId,
      )..setListener(this);

      await LevelPlay.init(
        initRequest: requestBuilder.build(),
        initListener: this,
      );
    } on PlatformException catch (error) {
      debugPrint('LevelPlay initialization failed: $error');
      _initializing = false;
      notifyListeners();
    }
  }

  Future<bool> showInterstitial({
    String placementName = 'DefaultInterstitial',
    Duration minInterval = const Duration(seconds: 90),
    bool waitForDismissal = false,
    Duration dismissalTimeout = const Duration(seconds: 90),
  }) async {
    if (!_initialized || _interstitialAd == null || _interstitialShowing) {
      return false;
    }
    final lastShownAt = _lastInterstitialAt;
    if (lastShownAt != null &&
        DateTime.now().difference(lastShownAt) < minInterval) {
      return false;
    }
    if (!await _interstitialAd!.isAdReady()) {
      _interstitialAd!.loadAd();
      return false;
    }

    _lastInterstitialAt = DateTime.now();
    _interstitialShowing = true;
    if (waitForDismissal) {
      _interstitialCloseCompleter = Completer<void>();
    }
    notifyListeners();

    try {
      await _interstitialAd!.showAd(placementName: placementName);
      if (waitForDismissal) {
        await _interstitialCloseCompleter?.future.timeout(
          dismissalTimeout,
          onTimeout: _finishInterstitial,
        );
      }
      return true;
    } on PlatformException catch (error) {
      debugPrint('LevelPlay interstitial failed: $error');
      _finishInterstitial();
      _interstitialAd?.loadAd();
      return false;
    }
  }

  Future<bool> showAfterCompletedRound() {
    _completedRounds++;
    if (!AdPlacementPolicy.shouldShowAfterCompletedRound(_completedRounds)) {
      return Future.value(false);
    }
    return showInterstitial(
      placementName: 'RoundComplete',
      minInterval: Duration.zero,
    );
  }

  Future<bool> showAfterConfirmedQuit() => showInterstitial(
        placementName: 'ConfirmedQuit',
        minInterval: Duration.zero,
        waitForDismissal: true,
      );

  Future<bool> showBeforeAppExit() => showInterstitial(
        placementName: 'ConfirmedAppExit',
        minInterval: Duration.zero,
        waitForDismissal: true,
      );

  Future<bool> showRewarded({
    String placementName = 'DefaultRewarded',
    Duration timeout = const Duration(seconds: 90),
  }) async {
    if (!_initialized ||
        _rewardedAd == null ||
        _rewardCompleter != null ||
        _rewardedShowing) {
      return false;
    }
    if (!await _rewardedAd!.isAdReady()) {
      _rewardedAd!.loadAd();
      return false;
    }

    _rewardCompleter = Completer<bool>();
    _rewardEarned = false;
    _rewardedShowing = true;
    _rewardedReady = false;
    final rewardFuture = _rewardCompleter!.future;
    notifyListeners();
    try {
      await _rewardedAd!.showAd(placementName: placementName);
      return rewardFuture.timeout(
        timeout,
        onTimeout: () {
          _finishReward(false);
          return false;
        },
      );
    } on PlatformException catch (error) {
      debugPrint('LevelPlay rewarded ad failed: $error');
      _finishReward(false);
      _rewardedAd?.loadAd();
      return false;
    }
  }

  Future<void> launchTestSuite() async {
    if (!_initialized || LevelPlayAdConfig.isProduction) return;
    await LevelPlay.launchTestSuite();
  }

  void _loadFullScreenAds() {
    _interstitialAd?.loadAd();
    _rewardedAd?.loadAd();
  }

  void _finishReward(bool earned) {
    final completer = _rewardCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(earned);
    }
    _rewardCompleter = null;
    _rewardedShowing = false;
    _rewardEarned = false;
    notifyListeners();
  }

  void _finishInterstitial() {
    final completer = _interstitialCloseCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _interstitialCloseCompleter = null;
    _interstitialShowing = false;
    notifyListeners();
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    _initializing = false;
    _initialized = true;
    _loadFullScreenAds();
    notifyListeners();
  }

  @override
  void onInitFailed(LevelPlayInitError error) {
    debugPrint('LevelPlay init error: $error');
    _initializing = false;
    _initialized = false;
    notifyListeners();
  }

  @override
  void onImpressionSuccess(LevelPlayImpressionData impressionData) {
    debugPrint('LevelPlay impression: $impressionData');
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    final adUnitId = adInfo.adUnitId;
    if (adUnitId == LevelPlayAdConfig.rewardedAdUnitId) {
      _rewardedReady = true;
    }
    notifyListeners();
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    debugPrint('LevelPlay ad load failed: $error');
    notifyListeners();
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    if (adInfo.adUnitId == LevelPlayAdConfig.rewardedAdUnitId) {
      _finishReward(false);
      _rewardedAd?.loadAd();
    }
    if (adInfo.adUnitId == LevelPlayAdConfig.interstitialAdUnitId) {
      _finishInterstitial();
      _interstitialAd?.loadAd();
    }
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    if (adInfo.adUnitId == LevelPlayAdConfig.rewardedAdUnitId) {
      _finishReward(_rewardEarned);
      _rewardedAd?.loadAd();
    }
    if (adInfo.adUnitId == LevelPlayAdConfig.interstitialAdUnitId) {
      _finishInterstitial();
      _interstitialAd?.loadAd();
    }
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
    _rewardEarned = true;
  }
}
