import 'package:flutter/material.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../config/levelplay_ad_config.dart';
import '../services/levelplay_ad_service.dart';

class LevelPlayBannerAd extends StatefulWidget {
  final String placementName;

  const LevelPlayBannerAd({
    super.key,
    required this.placementName,
  });

  @override
  State<LevelPlayBannerAd> createState() => _LevelPlayBannerAdState();
}

class _LevelPlayBannerAdState extends State<LevelPlayBannerAd>
    with LevelPlayBannerAdViewListener {
  final GlobalKey<LevelPlayBannerAdViewState> _bannerKey =
      GlobalKey<LevelPlayBannerAdViewState>();
  final LevelPlayAdSize _adSize = LevelPlayAdSize.BANNER;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    LevelPlayAdService.instance.addListener(_loadWhenReady);
  }

  @override
  void dispose() {
    LevelPlayAdService.instance.removeListener(_loadWhenReady);
    _bannerKey.currentState?.destroy();
    super.dispose();
  }

  void _loadWhenReady() {
    if (!mounted || _loaded || !LevelPlayAdService.instance.canShowBanner) {
      return;
    }
    _bannerKey.currentState?.loadAd();
  }

  @override
  Widget build(BuildContext context) {
    if (!LevelPlayAdConfig.isConfigured) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: _adSize.height.toDouble(),
      child: Center(
        child: SizedBox(
          width: _adSize.width.toDouble(),
          height: _adSize.height.toDouble(),
          child: LevelPlayBannerAdView(
            key: _bannerKey,
            adUnitId: LevelPlayAdConfig.bannerAdUnitId,
            adSize: _adSize,
            listener: this,
            placementName: widget.placementName,
            onPlatformViewCreated: _loadWhenReady,
          ),
        ),
      ),
    );
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    _loaded = true;
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {}

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdInfo adInfo, LevelPlayAdError error) {}

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdExpanded(LevelPlayAdInfo adInfo) {}

  @override
  void onAdCollapsed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdLeftApplication(LevelPlayAdInfo adInfo) {}
}
