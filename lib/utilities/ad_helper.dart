// lib/utilities/ad_helper.dart

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdHelper {
  // --- Interstitial Ad ---
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialLoading = false;
  static bool _isInterstitialLoaded = false;

  // VVVVVV  REPLACE WITH YOUR LIVE ADMOB INTERSTITIAL AD UNIT ID FOR ANDROID VVVVVV
  static final String _androidInterstitialAdUnitId = 'ca-app-pub-7816037574743099/4400729645'; // <<< REPLACE THIS
  static final String _iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';     // iOS Test ID (Replace if you have a live iOS ID)
  // ^^^^^^  REPLACE WITH YOUR LIVE ADMOB INTERSTITIAL AD UNIT ID FOR ANDROID ^^^^^^


  static void loadInterstitialAd() {
    if (_isInterstitialLoading || _isInterstitialLoaded) {
      debugPrint('AdHelper: Interstitial load attempt skipped. Loading: $_isInterstitialLoading, Loaded: $_isInterstitialLoaded');
      return;
    }
    _isInterstitialLoading = true;
    debugPrint('AdHelper: Attempting to load interstitial ad...');
    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? _androidInterstitialAdUnitId : _iosInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('AdHelper: Interstitial ad loaded successfully.');
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AdHelper: Interstitial ad failed to load: $error');
          _interstitialAd?.dispose();
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  static void showInterstitialAd() {
    debugPrint('AdHelper: showInterstitialAd() called. Loaded: $_isInterstitialLoaded, Ad null: ${_interstitialAd == null}');
    if (!_isInterstitialLoaded || _interstitialAd == null) {
      debugPrint('AdHelper: Interstitial ad not ready.');
      if (!_isInterstitialLoading) {
        loadInterstitialAd();
      }
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) => debugPrint('AdHelper: Interstitial ad shown.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('AdHelper: Interstitial ad dismissed.');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('AdHelper: Interstitial ad failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        loadInterstitialAd();
      },
      onAdImpression: (InterstitialAd ad) => debugPrint('AdHelper: Interstitial ad impression.'),
    );
    _interstitialAd!.show();
  }

  // --- Rewarded Ad ---
  static RewardedAd? _rewardedAd;
  static bool _isRewardedAdLoading = false;
  static bool _isRewardedAdLoaded = false;

  // VVVVVV  REPLACE WITH YOUR LIVE ADMOB REWARDED AD UNIT ID FOR ANDROID VVVVVV
  static final String _androidRewardedAdUnitId = 'ca-app-pub-7816037574743099/3355783859'; // <<< REPLACE THIS
  static final String _iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';       // iOS Test ID (Replace if you have a live iOS ID)
  // ^^^^^^  REPLACE WITH YOUR LIVE ADMOB REWARDED AD UNIT ID FOR ANDROID ^^^^^^

  static void loadRewardedAd() {
    if (_isRewardedAdLoading || _isRewardedAdLoaded) {
      debugPrint('AdHelper: Rewarded ad load attempt skipped. Loading: $_isRewardedAdLoading, Loaded: $_isRewardedAdLoaded');
      return;
    }
    _isRewardedAdLoading = true;
    debugPrint('AdHelper: Attempting to load rewarded ad...');

    RewardedAd.load(
      adUnitId: Platform.isAndroid ? _androidRewardedAdUnitId : _iosRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('AdHelper: Rewarded ad loaded successfully.');
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AdHelper: Rewarded ad failed to load: $error');
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
    debugPrint('AdHelper: showRewardedAd() called. Loaded: $_isRewardedAdLoaded, Ad null: ${_rewardedAd == null}');
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      debugPrint('AdHelper: Rewarded ad not ready to be shown.');
      if (!_isRewardedAdLoading) {
        debugPrint('AdHelper: Triggering a new load for rewarded ad because it was not ready for show.');
        loadRewardedAd();
      }
      onAdFailedToShow?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('AdHelper: Rewarded ad shown full screen.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('AdHelper: Rewarded ad dismissed.');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        onAdDismissed?.call();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('AdHelper: Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        onAdFailedToShow?.call();
        loadRewardedAd();
      },
      onAdImpression: (RewardedAd ad) =>
          debugPrint('AdHelper: Rewarded ad impression occurred.'),
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      debugPrint('AdHelper: User earned reward: type=${reward.type}, amount=${reward.amount}');
      onUserEarnedReward(reward);
    });
  }

  static void disposeAllAds() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoaded = false;
    _isInterstitialLoading = false;

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
    _isRewardedAdLoading = false;
    debugPrint('AdHelper: All ads explicitly disposed.');
  }
}