import 'package:flutter/foundation.dart';

class AdTestIds {
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const iosBanner = 'ca-app-pub-3940256099942544/2934735716';

  static const androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';

  static const androidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static const androidRewardedInterstitial =
      'ca-app-pub-3940256099942544/5354046379';
  static const iosRewardedInterstitial =
      'ca-app-pub-3940256099942544/6978759866';

  static const androidNativeAdvanced = 'ca-app-pub-3940256099942544/2247696110';
  static const iosNativeAdvanced = 'ca-app-pub-3940256099942544/3986624511';

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static String get banner => _isIOS ? iosBanner : androidBanner;
  static String get interstitial =>
      _isIOS ? iosInterstitial : androidInterstitial;
  static String get rewarded => _isIOS ? iosRewarded : androidRewarded;
  static String get rewardedInterstitial =>
      _isIOS ? iosRewardedInterstitial : androidRewardedInterstitial;
  static String get nativeAdvanced =>
      _isIOS ? iosNativeAdvanced : androidNativeAdvanced;
}
