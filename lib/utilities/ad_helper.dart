// lib/utilities/ad_helper.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // -------------------- Banner --------------------
  static BannerAd? _bannerAd;
  static bool _isBannerAdLoaded = false;

  static const String _androidBannerAdUnitId = 'ca-app-pub-7816037574743099/6084765847';
  static const String _iosBannerAdUnitId = 'YOUR_IOS_BANNER_AD_UNIT_ID_HERE';

  static void loadBannerAd() {
    if (_isBannerAdLoaded) return;

    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid ? _androidBannerAdUnitId : _iosBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => _isBannerAdLoaded = true,
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _bannerAd = null;
          _isBannerAdLoaded = false;
        },
      ),
    )..load();
  }

  static Widget? getBannerAdWidget() {
    if (_isBannerAdLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }

  static void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  // -------------------- Interstitial --------------------
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialLoading = false;
  static bool _isInterstitialLoaded = false;

  static const String _androidInterstitialAdUnitId = 'ca-app-pub-7816037574743099/4400729645';
  static const String _iosInterstitialAdUnitId = 'YOUR_IOS_INTERSTITIAL_AD_UNIT_ID_HERE';

  static void loadInterstitialAd() {
    if (_isInterstitialLoading || _isInterstitialLoaded) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? _androidInterstitialAdUnitId : _iosInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd?.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  static void showInterstitialAd() {
    final ad = _interstitialAd;
    if (!_isInterstitialLoaded || ad == null) {
      if (!_isInterstitialLoading) loadInterstitialAd();
      return;
    }

    // ✅ Make sure the ad is NOT immersive so the X is placed within content
    ad.setImmersiveMode(false);

    // ✅ Exit your app’s fullscreen while the ad is visible
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;

        // ✅ Restore your app’s immersive UI
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;

        // ✅ Restore immersive on failure, too
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

        loadInterstitialAd();
      },
    );

    ad.show();
  }

  // -------------------- Rewarded (for Hint) --------------------
  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdLoading = false;
  static bool _isRewardedAdLoaded = false;

  static final ValueNotifier<bool> rewardedReady = ValueNotifier<bool>(false);

  static const String _androidRewardedAdUnitId = 'ca-app-pub-7816037574743099/3355783859';
  static const String _iosRewardedAdUnitId = 'YOUR_IOS_REWARDED_AD_UNIT_ID_HERE';

  static void loadRewardedAd() {
    if (_isRewardedAdLoading || _isRewardedAdLoaded) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: Platform.isAndroid ? _androidRewardedAdUnitId : _iosRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _isRewardedAdLoading = false;
          rewardedReady.value = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              rewardedReady.value = false;
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              rewardedReady.value = false;
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd?.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          _isRewardedAdLoading = false;
          rewardedReady.value = false;
          Future.delayed(const Duration(seconds: 3), loadRewardedAd);
        },
      ),
    );
  }

  static void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) {
    final ad = _rewardedAd;
    if (!_isRewardedAdLoaded || ad == null) {
      onAdFailedToShow?.call();
      if (!_isRewardedAdLoading) loadRewardedAd();
      return;
    }

    rewardedReady.value = false;

    // ✅ Non-immersive ad so close button is visible
    ad.setImmersiveMode(false);

    // ✅ Exit fullscreen while ad is showing
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
        onAdDismissed?.call();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
        onAdFailedToShow?.call();
        loadRewardedAd();
      },
    );

    ad.show(onUserEarnedReward: (adWithoutView, reward) {
      onUserEarnedReward(reward);
    });

    _rewardedAd = null;
    _isRewardedAdLoaded = false;
  }

  // -------------------- Dispose All --------------------
  static void disposeAllAds() {
    disposeBannerAd();

    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoaded = false;
    _isInterstitialLoading = false;

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
    _isRewardedAdLoading = false;
    rewardedReady.value = false;
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) return _androidRewardedAdUnitId;
    if (Platform.isIOS) return _iosRewardedAdUnitId;
    throw UnsupportedError('Unsupported platform');
  }
}
