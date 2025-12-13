import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:yurttaye_mobile/providers/language_provider.dart';
import 'package:yurttaye_mobile/providers/menu_provider.dart';
import 'package:yurttaye_mobile/providers/theme_provider.dart';
import 'package:yurttaye_mobile/routes/app_routes.dart';
import 'package:yurttaye_mobile/screens/filter_screen.dart';
import 'package:yurttaye_mobile/screens/home_screen.dart';
import 'package:yurttaye_mobile/screens/menu_detail_screen.dart';
import 'package:yurttaye_mobile/screens/splash_screen.dart';
import 'package:yurttaye_mobile/services/notification_service.dart';
import 'package:yurttaye_mobile/services/ad_service.dart';
import 'package:yurttaye_mobile/services/ad_manager.dart';
import 'package:yurttaye_mobile/themes/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env dosyasını yükle
  await dotenv.load(fileName: ".env");
  
  await initializeDateFormatting('tr', null);
  
  // Google Mobile Ads'i başlat
  await AdService.initialize();
  
  // Interstitial reklamı önceden yükle
  await AdService.loadInterstitialAd();
  
  // Günlük reklam sayacını kontrol et ve gerekirse sıfırla
  await AdManager.resetDailyCount();
  
  // Bildirim servisini başlat
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  await _requestNotificationPermission();
  
  runApp(const MyApp());
}

Future<void> _requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp.router(
            title: 'YurttaYe',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('tr', 'TR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}