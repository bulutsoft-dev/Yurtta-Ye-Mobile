import 'package:shared_preferences/shared_preferences.dart';
import 'package:yurttaye_mobile/services/ad_service.dart';
import 'package:yurttaye_mobile/utils/app_logger.dart';

class AdManager {
  static const String _lastAdShownKey = 'last_ad_shown';
  static const String _adShownCountKey = 'ad_shown_count';
  static const String _menuDetailClickKey = 'menu_detail_click_count';
  static const String _mealSwitchClickKey = 'meal_switch_click_count';
  static const int _minAdIntervalMinutes = 2; // Minimum 2 minutes between ads
  static const int _maxAdsPerSession = 8; // Maximum 8 ads per day
  static const int _menuDetailAdInterval = 2; // Her 2 tıklamada bir reklam
  static const int _mealSwitchAdThreshold = 3; // 3. tıklamadan itibaren reklam

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

  /// Menü detayına tıklamayı kaydet ve reklam gösterilmeli mi kontrol et
  static Future<bool> shouldShowAdOnMenuDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Tıklama sayısını al ve artır
      final clickCount = (prefs.getInt(_menuDetailClickKey) ?? 0) + 1;
      await prefs.setInt(_menuDetailClickKey, clickCount);
      
      // Her _menuDetailAdInterval tıklamada bir reklam göster
      final shouldShow = clickCount % _menuDetailAdInterval == 0;
      
      AppLogger.ad('Menu detail click: $clickCount, Show ad: $shouldShow');
      
      return shouldShow && await shouldShowAd();
    } catch (e) {
      AppLogger.error('AdManager shouldShowAdOnMenuDetail error', e);
      return false;
    }
  }

  /// Menü detay tıklama sayısını sıfırla
  static Future<void> resetMenuDetailClickCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_menuDetailClickKey);
      AppLogger.ad('Menu detail click count reset');
    } catch (e) {
      AppLogger.error('AdManager resetMenuDetailClickCount error', e);
    }
  }

  /// Öğün değişikliğinde tıklamayı kaydet ve reklam gösterilmeli mi kontrol et
  /// İlk 2 tıklama free, 3. tıklamadan itibaren reklam göster
  static Future<bool> shouldShowAdOnMealSwitch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Günlük key oluştur (her gün sıfırlansın)
      final today = DateTime.now();
      final todayKey = '${_mealSwitchClickKey}_${today.year}_${today.month}_${today.day}';
      
      // Tıklama sayısını al ve artır
      final clickCount = (prefs.getInt(todayKey) ?? 0) + 1;
      await prefs.setInt(todayKey, clickCount);
      
      // 3. tıklamadan itibaren reklam göster
      final shouldShow = clickCount >= _mealSwitchAdThreshold;
      
      AppLogger.ad('Meal switch click: $clickCount (today), Show ad: $shouldShow');
      
      return shouldShow && await shouldShowAd();
    } catch (e) {
      AppLogger.error('AdManager shouldShowAdOnMealSwitch error', e);
      return false;
    }
  }

  /// Öğün değişikliği tıklama sayısını sıfırla
  static Future<void> resetMealSwitchClickCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${_mealSwitchClickKey}_${today.year}_${today.month}_${today.day}';
      await prefs.remove(todayKey);
      AppLogger.ad('Meal switch click count reset');
    } catch (e) {
      AppLogger.error('AdManager resetMealSwitchClickCount error', e);
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
      final menuDetailClicks = prefs.getInt(_menuDetailClickKey) ?? 0;
      
      return {
        'todayCount': adShownCount,
        'maxPerSession': _maxAdsPerSession,
        'lastAdShown': lastAdShown,
        'minIntervalMinutes': _minAdIntervalMinutes,
        'menuDetailClicks': menuDetailClicks,
        'menuDetailAdInterval': _menuDetailAdInterval,
      };
    } catch (e) {
      AppLogger.error('AdManager getAdStats error', e);
      return {};
    }
  }
}