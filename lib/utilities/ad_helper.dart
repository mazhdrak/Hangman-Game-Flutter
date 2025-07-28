// lib/utilities/ad_helper.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdHelper {

  // --- Banner Ad ---
  static BannerAd? _bannerAd;
  static bool _isBannerAdLoaded = false;

  // YOUR REAL BANNER ID
  static final String _androidBannerAdUnitId = 'ca-app-pub-7816037574743099/6084765847';
  static final String _iosBannerAdUnitId = 'YOUR_IOS_BANNER_AD_UNIT_ID_HERE'; // TODO: Replace if you have an iOS version

  static void loadBannerAd() {
    // Don't load if already loaded or if there's no ad instance
    if (_isBannerAdLoaded) return;

    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid ? _androidBannerAdUnitId : _iosBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          _isBannerAdLoaded = true;
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  // Method to get the ad widget for the UI
  static Widget? getBannerAdWidget() {
    if (_isBannerAdLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Return an empty container if ad is not loaded
    return const SizedBox.shrink();
  }

  static void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }


  // --- Interstitial Ad ---
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialLoading = false;
  static bool _isInterstitialLoaded = false;

  // YOUR REAL INTERSTITIAL ID
  static final String _androidInterstitialAdUnitId = 'ca-app-pub-7816037574743099/4400729645';
  static final String _iosInterstitialAdUnitId = 'YOUR_IOS_INTERSTITIAL_AD_UNIT_ID_HERE'; // TODO: Replace if you have an iOS version

  static void loadInterstitialAd() {
    if (_isInterstitialLoading || _isInterstitialLoaded) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? _androidInterstitialAdUnitId : _iosInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd?.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (!_isInterstitialLoaded || _interstitialAd == null) {
      if (!_isInterstitialLoading) {
        loadInterstitialAd();
      }
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        loadInterstitialAd(); // Pre-load the next ad
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        loadInterstitialAd(); // Pre-load the next ad
      },
    );

    _interstitialAd!.show();
  }

  // --- Rewarded Ad ---
  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdLoading = false;
  static bool _isRewardedAdLoaded = false;

  // YOUR REAL REWARDED INTERSTITIAL ID
  static final String _androidRewardedAdUnitId = 'ca-app-pub-7816037574743099/3355783859';
  static final String _iosRewardedAdUnitId = 'YOUR_IOS_REWARDED_AD_UNIT_ID_HERE'; // TODO: Replace if you have an iOS version

  static void loadRewardedAd() {
    if (_isRewardedAdLoading || _isRewardedAdLoaded) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: Platform.isAndroid ? _androidRewardedAdUnitId : _iosRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd?.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  static void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      if (!_isRewardedAdLoading) {
        loadRewardedAd();
      }
      onAdFailedToShow?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        onAdDismissed?.call();
        loadRewardedAd(); // Pre-load the next ad
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        onAdFailedToShow?.call();
        loadRewardedAd(); // Pre-load the next ad
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      onUserEarnedReward(reward);
    });
  }

  // --- Dispose All ---
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
  }

  // --- GETTER THAT WAS MISSING ---
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return _androidRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return _iosRewardedAdUnitId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}