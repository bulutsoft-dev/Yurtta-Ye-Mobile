import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // App Information
  static const String appName = 'YurttaYe';
  static const String appVersion = '1.4.0';
  static const String appBuildNumber = '28';
  
  // Website URLs
  static const String websiteUrl = 'https://yurttaye.onrender.com/';
  static const String githubUrl = 'https://github.com/bulutsoft-dev/Yurtta-Ye-Mobile';
  
  // Developer Information
  static const String developerName = 'Furkan Bulut';
  static const String developerEmail = 'bulutsoftdev@gmail.com';
  static const String developerCompany = 'BulutSoft Dev';
  
  // App Store Links
  static const String googlePlayUrl = 'https://play.google.com/store/apps/details?id=com.yurttaye.yurttaye';
  
  // Support Information
  static const String supportEmail = 'bulutsoftdev@gmail.com';
  static const String privacyPolicyUrl = 'https://github.com/bulutsoft-dev/Yurtta-Ye-Mobile/blob/main/privacy-policy.md';
  
  // API Configuration
  static const String apiBaseUrl = 'https://yurttaye.onrender.com/api';
  static const String cityEndpoint = '/City';
  static const String menuEndpoint = '/Menu';

  // Localization
  static const String defaultLanguage = 'tr';
  static const List<String> supportedLanguages = ['tr', 'en'];
  
  // Öğün türleri
  static const List<String> mealTypes = [
    'Kahvaltı',
    'Akşam Yemeği',
  ];
  static const String allMealTypesLabel = 'Tüm Öğünler';

  // Tarih formatları
  static final DateFormat apiDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat displayDateFormat = DateFormat('dd.MM.yyyy');

  // Sayfalama ayarları
  static const int pageSize = 5; // Sayfa başına menü
  static const int initialPage = 1;
  
  // AdMob Reklam Ayarları
  static final bool isDebug = !kReleaseMode; // Build tipine göre otomatik ayarlanır

  // Banner reklam birimi kimliği
  static String get bannerAdUnitId {
    if (isDebug) {
      return dotenv.env['TEST_BANNER_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/6300978111';
    } else {
      return dotenv.env['BANNER_AD_UNIT_ID'] ?? 'ca-app-pub-9589008379442992/4947036856';
    }
  }

  // Geçişli reklam birimi kimliği
  static String get interstitialAdUnitId {
    if (isDebug) {
      return dotenv.env['TEST_INTERSTITIAL_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/1033173712';
    } else {
      return dotenv.env['INTERSTITIAL_AD_UNIT_ID'] ?? 'ca-app-pub-9589008379442992/7379674790';
    }
  }

  // Rewarded reklam birimi kimliği
  static String get rewardedAdUnitId {
    if (isDebug) {
      return dotenv.env['TEST_REWARDED_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/5224354917';
    } else {
      return dotenv.env['REWARDED_AD_UNIT_ID'] ?? 'ca-app-pub-9589008379442992/6298796913';
    }
  }

  // App Open reklam birimi kimliği (Uygulama açılışı)
  static String get appOpenAdUnitId {
    if (isDebug) {
      return dotenv.env['TEST_APP_OPEN_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/9257395921';
    } else {
      return dotenv.env['APP_OPEN_AD_UNIT_ID'] ?? 'ca-app-pub-9589008379442992/6376210156';
    }
  }
} 