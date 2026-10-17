import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads.dart';

class NoAds extends Ads {
  @override
  Future<void> init() async {}

  @override
  Future<void> loadAppOpenAd() async {}

  @override
  void showAdIfAvailableOpenAds({VoidCallback? onDismissed}) {
    onDismissed?.call();
  }

  @override
  Future<void> loadBannerAd(Function? onLoaded, Key key) async {}

  @override
  Future<void> loadInterstitialAd() async {}

  @override
  void showInterstitialAd({VoidCallback? onDismissed}) {
    onDismissed?.call();
  }

  @override
  Widget getBannerAdWidget(Key key) => Container();

  @override
  Future<void> disposeBanner(Key key) async {}

  @override
  Future<void> loadNativeAd(
      Function? onLoaded, Key key, TemplateType templateType) async {}

  @override
  Future<void> disposeNative(Key key) async {}

  @override
  Widget getNativeAdWidget(Key key, double height) {
    return Container();
  }

  @override
  Future<void> loadRewardAd() async {}

  @override
  void showRewardAd(Function rewarded) {
    rewarded();
  }
}