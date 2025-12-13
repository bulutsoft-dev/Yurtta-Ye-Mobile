import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:yurttaye_mobile/utils/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yurttaye_mobile/utils/app_logger.dart';

class AdService {
  static String get interstitialAdUnitId {
    return AppConfig.interstitialAdUnitId;
  }

  static String get rewardedAdUnitId => AppConfig.rewardedAdUnitId;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;

  static Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          AppLogger.ad('Interstitial ad loaded');
          
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              AppLogger.ad('Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          AppLogger.ad('Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  static Future<bool> isAdFreeActive() async {
    final prefs = await SharedPreferences.getInstance();
    final adFreeMillis = prefs.getInt('adFreeUntil');
    if (adFreeMillis == null) return false;
    return DateTime.now().isBefore(DateTime.fromMillisecondsSinceEpoch(adFreeMillis));
  }

  static Future<bool> isInterstitialBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final blockMillis = prefs.getInt('interstitialAdBlockUntil');
    if (blockMillis == null) return false;
    return DateTime.now().isBefore(DateTime.fromMillisecondsSinceEpoch(blockMillis));
  }

  static Future<void> showInterstitialAd() async {
    if (await isAdFreeActive()) {
      AppLogger.ad('Ad-free active, interstitial ad not shown');
      return;
    }
    if (await isInterstitialBlocked()) {
      AppLogger.ad('Interstitial ad blocked, not showing');
      return;
    }
    
    if (_interstitialAd != null) {
      AppLogger.ad('Showing interstitial ad');
      await _interstitialAd!.show();
    } else {
      AppLogger.ad('Interstitial ad not loaded, loading now...');
      await loadInterstitialAd();
    }
  }

  static void dispose() {
    _interstitialAd?.dispose();
  }

  static Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          AppLogger.ad('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          AppLogger.ad('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  static Future<void> showRewardedAd({required VoidCallback onRewarded, VoidCallback? onClosed}) async {
    if (_rewardedAd == null) {
      AppLogger.ad('Rewarded ad not loaded, loading now...');
      await loadRewardedAd();
    }
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          if (onClosed != null) onClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          AppLogger.ad('Rewarded ad failed to show: $error');
          ad.dispose();
          _rewardedAd = null;
          if (onClosed != null) onClosed();
        },
      );
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          AppLogger.ad('User earned reward: ${reward.amount} ${reward.type}');
          onRewarded();
        },
      );
    } else {
      AppLogger.ad('Rewarded ad could not be loaded');
      if (onClosed != null) onClosed();
    }
  }
}