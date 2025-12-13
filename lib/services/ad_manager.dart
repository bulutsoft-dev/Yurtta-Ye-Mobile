import 'package:shared_preferences/shared_preferences.dart';
import 'package:yurttaye_mobile/services/ad_service.dart';
import 'package:yurttaye_mobile/utils/app_logger.dart';

class AdManager {
  static const String _lastAdShownKey = 'last_ad_shown';
  static const String _adShownCountKey = 'ad_shown_count';
  static const int _minAdIntervalMinutes = 3; // Minimum 3 minutes between ads
  static const int _maxAdsPerSession = 5; // Maximum 5 ads per day

  static Future<bool> shouldShowAd() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check last ad shown time
      final lastAdShown = prefs.getInt(_lastAdShownKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastAd = (currentTime - lastAdShown) / (1000 * 60); // In minutes
      
      // Check today's ad count
      final today = DateTime.now().day;
      final adShownCount = prefs.getInt('${_adShownCountKey}_$today') ?? 0;
      
      // Ad conditions
      final canShowByTime = timeSinceLastAd >= _minAdIntervalMinutes;
      final canShowByCount = adShownCount < _maxAdsPerSession;
      
      AppLogger.ad('Ad check - Time since last: ${timeSinceLastAd.toStringAsFixed(1)}min, Count today: $adShownCount, Can show: ${canShowByTime && canShowByCount}');
      
      return canShowByTime && canShowByCount;
    } catch (e) {
      AppLogger.error('AdManager shouldShowAd error', e);
      return false;
    }
  }

  static Future<void> recordAdShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Record ad shown time
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastAdShownKey, currentTime);
      
      // Increment today's ad count
      final today = DateTime.now().day;
      final currentCount = prefs.getInt('${_adShownCountKey}_$today') ?? 0;
      await prefs.setInt('${_adShownCountKey}_$today', currentCount + 1);
      
      AppLogger.ad('Ad shown recorded. Count today: ${currentCount + 1}');
    } catch (e) {
      AppLogger.error('AdManager recordAdShown error', e);
    }
  }

  static Future<void> showAdIfAllowed() async {
    if (await shouldShowAd()) {
      await AdService.showInterstitialAd();
      await recordAdShown();
    } else {
      AppLogger.ad('Ad not shown - conditions not met');
    }
  }

  static Future<void> resetDailyCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().day;
      await prefs.remove('${_adShownCountKey}_$today');
      AppLogger.ad('Daily ad count reset');
    } catch (e) {
      AppLogger.error('AdManager resetDailyCount error', e);
    }
  }

  static Future<Map<String, dynamic>> getAdStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().day;
      final adShownCount = prefs.getInt('${_adShownCountKey}_$today') ?? 0;
      final lastAdShown = prefs.getInt(_lastAdShownKey) ?? 0;
      
      return {
        'todayCount': adShownCount,
        'maxPerSession': _maxAdsPerSession,
        'lastAdShown': lastAdShown,
        'minIntervalMinutes': _minAdIntervalMinutes,
      };
    } catch (e) {
      AppLogger.error('AdManager getAdStats error', e);
      return {};
    }
  }
}