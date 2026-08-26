import 'package:flutter/foundation.dart';

class LevelPlayAdConfig {
  static const bool isProduction =
      bool.fromEnvironment('LEVELPLAY_PRODUCTION', defaultValue: kReleaseMode);
  static const bool enableTestSuite =
      bool.fromEnvironment('LEVELPLAY_TEST_SUITE', defaultValue: false);

  static const String _androidAppKey =
      String.fromEnvironment('LEVELPLAY_ANDROID_APP_KEY');
  static const String _iosAppKey =
      String.fromEnvironment('LEVELPLAY_IOS_APP_KEY');
  static const String _androidBannerAdUnit =
      String.fromEnvironment('LEVELPLAY_ANDROID_BANNER_AD_UNIT');
  static const String _iosBannerAdUnit =
      String.fromEnvironment('LEVELPLAY_IOS_BANNER_AD_UNIT');
  static const String _androidInterstitialAdUnit =
      String.fromEnvironment('LEVELPLAY_ANDROID_INTERSTITIAL_AD_UNIT');
  static const String _iosInterstitialAdUnit =
      String.fromEnvironment('LEVELPLAY_IOS_INTERSTITIAL_AD_UNIT');
  static const String _androidRewardedAdUnit =
      String.fromEnvironment('LEVELPLAY_ANDROID_REWARDED_AD_UNIT');
  static const String _iosRewardedAdUnit =
      String.fromEnvironment('LEVELPLAY_IOS_REWARDED_AD_UNIT');

  static const String _demoAndroidAppKey = '25b63cf85';
  static const String _demoIosAppKey = '25c43a4a5';
  static const String _demoAndroidBannerAdUnit = '4fpetq4lhe5lsw3e';
  static const String _demoIosBannerAdUnit = 'xc2bsuntn9ea734t';
  static const String _demoAndroidInterstitialAdUnit = 'h3xw38h9214adgxo';
  static const String _demoIosInterstitialAdUnit = 'obg6ohwts3y690ks';
  static const String _demoAndroidRewardedAdUnit = 'syz3d8ekts22q0or';
  static const String _demoIosRewardedAdUnit = 'l1quzz1xmmdhw5er';

  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get _useDemoIds => !isProduction;

  static String get appKey => _forPlatform(
        android: _androidAppKey,
        ios: _iosAppKey,
        demoAndroid: _demoAndroidAppKey,
        demoIos: _demoIosAppKey,
      );

  static String get bannerAdUnitId => _forPlatform(
        android: _androidBannerAdUnit,
        ios: _iosBannerAdUnit,
        demoAndroid: _demoAndroidBannerAdUnit,
        demoIos: _demoIosBannerAdUnit,
      );

  static String get interstitialAdUnitId => _forPlatform(
        android: _androidInterstitialAdUnit,
        ios: _iosInterstitialAdUnit,
        demoAndroid: _demoAndroidInterstitialAdUnit,
        demoIos: _demoIosInterstitialAdUnit,
      );

  static String get rewardedAdUnitId => _forPlatform(
        android: _androidRewardedAdUnit,
        ios: _iosRewardedAdUnit,
        demoAndroid: _demoAndroidRewardedAdUnit,
        demoIos: _demoIosRewardedAdUnit,
      );

  static bool get isConfigured =>
      isSupportedPlatform &&
      appKey.isNotEmpty &&
      bannerAdUnitId.isNotEmpty &&
      interstitialAdUnitId.isNotEmpty &&
      rewardedAdUnitId.isNotEmpty;

  static String _forPlatform({
    required String android,
    required String ios,
    required String demoAndroid,
    required String demoIos,
  }) {
    if (!isSupportedPlatform) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android.isNotEmpty ? android : (_useDemoIds ? demoAndroid : '');
    }
    return ios.isNotEmpty ? ios : (_useDemoIds ? demoIos : '');
  }
}
