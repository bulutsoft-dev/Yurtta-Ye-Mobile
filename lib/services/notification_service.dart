import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/menu.dart';
import '../utils/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  /// Notification service'i başlat
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.notification('NotificationService already initialized');
      return;
    }

    // Timezone'ları başlat ve Türkiye saat dilimini ayarla
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    AppLogger.notification('Timezone set to Europe/Istanbul');

    // Android ayarları
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS ayarları
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Bildirimleri başlat
    final initialized = await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    AppLogger.notification('Notifications initialized: $initialized');

    // Android için notification channel oluştur
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
    
    _isInitialized = true;
    AppLogger.notification('NotificationService initialization complete');
  }

  /// Notification channel oluştur (Android 8+)
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'meal_notifications',
      'Yemek Bildirimleri',
      description: 'Günlük yemek menüsü bildirimleri',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    AppLogger.notification('Notification channel created: ${channel.id}');
  }

  /// Bildirime tıklandığında
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.notification('Notification tapped: ${response.payload}');
    // Burada navigasyon yapılabilir
  }

  /// Günlük yemek bildirimlerini zamanla
  Future<void> scheduleDailyMealNotifications(List<Menu> menus) async {
    if (!_isInitialized) {
      AppLogger.warning('NotificationService not initialized, initializing now...');
      await initialize();
    }

    if (menus.isEmpty) {
      AppLogger.notification('Menu list empty, cannot schedule notifications');
      return;
    }

    // Önce eski bildirimleri temizle
    await cancelAllNotifications();

    // Bugünün tarihini al
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Bugünün menülerini filtrele
    var todayMenus = menus.where((menu) {
      final menuDate = DateTime(menu.date.year, menu.date.month, menu.date.day);
      return menuDate.isAtSameMomentAs(today);
    }).toList();

    // Bugün menü yoksa, en yakın tarihi bul
    if (todayMenus.isEmpty) {
      AppLogger.notification('No menu for today, searching nearest date...');
      
      final futureMenus = menus.where((menu) => menu.date.isAfter(today)).toList();
      
      if (futureMenus.isNotEmpty) {
        futureMenus.sort((a, b) => a.date.compareTo(b.date));
        final nearestDate = DateTime(futureMenus.first.date.year, 
                                     futureMenus.first.date.month, 
                                     futureMenus.first.date.day);
        todayMenus = futureMenus.where((menu) {
          final menuDate = DateTime(menu.date.year, menu.date.month, menu.date.day);
          return menuDate.isAtSameMomentAs(nearestDate);
        }).toList();
        
        AppLogger.notification('Using future menu date: $nearestDate');
      }
    }

    if (todayMenus.isEmpty) {
      AppLogger.notification('No menu found for notifications');
      return;
    }

    // Kahvaltı menüsünü bul
    final breakfastMenu = todayMenus.firstWhere(
      (menu) => menu.mealType == 'Kahvaltı',
      orElse: () => Menu(id: 0, cityId: 0, mealType: 'Kahvaltı', date: today, energy: '', items: []),
    );

    // Akşam yemeği menüsünü bul
    final dinnerMenu = todayMenus.firstWhere(
      (menu) => menu.mealType == 'Akşam Yemeği',
      orElse: () => Menu(id: 0, cityId: 0, mealType: 'Akşam Yemeği', date: today, energy: '', items: []),
    );

    AppLogger.notification('Breakfast items: ${breakfastMenu.items.length}, Dinner items: ${dinnerMenu.items.length}');

    // Kahvaltı bildirimleri
    if (breakfastMenu.items.isNotEmpty) {
      await _scheduleNotification(
        id: 1,
        title: 'Kahvaltı Başladı! 🍳',
        body: 'Bugünün kahvaltı menüsü:\n${_getMenuSummary(breakfastMenu)}',
        hour: 7,
        minute: 0,
      );

      await _scheduleNotification(
        id: 2,
        title: 'Kahvaltı Bitmek Üzere! ⏰',
        body: 'Acele edin! Kahvaltı 12:00\'da kapanıyor.\n${_getMenuSummary(breakfastMenu)}',
        hour: 11,
        minute: 30,
      );
    }

    // Akşam yemeği bildirimleri
    if (dinnerMenu.items.isNotEmpty) {
      await _scheduleNotification(
        id: 3,
        title: 'Akşam Yemeği Başladı! 🍽️',
        body: 'Bugünün akşam menüsü:\n${_getMenuSummary(dinnerMenu)}',
        hour: 16,
        minute: 0,
      );

      await _scheduleNotification(
        id: 4,
        title: 'Akşam Yemeği Bitmek Üzere! ⏰',
        body: 'Acele edin! Yemek 22:00\'da kapanıyor.\n${_getMenuSummary(dinnerMenu)}',
        hour: 21,
        minute: 30,
      );
    }

    // Bekleyen bildirimleri kontrol et
    final pending = await getPendingNotifications();
    AppLogger.notification('Scheduled ${pending.length} notifications');
  }

  /// Tek bir bildirimi zamanla
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Eğer zaman geçmişse, yarına planla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'meal_notifications',
            'Yemek Bildirimleri',
            channelDescription: 'Günlük yemek menüsü bildirimleri',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableLights: true,
            enableVibration: true,
            playSound: true,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte tekrarla
      );
      
      AppLogger.notification('Scheduled: "$title" at ${scheduledDate.toString()}');
    } catch (e) {
      AppLogger.error('Error scheduling notification $id', e);
      
      // Exact alarm izni yoksa inexact dene
      if (e.toString().contains('exact_alarms_not_permitted')) {
        try {
          await _notifications.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'meal_notifications',
                'Yemek Bildirimleri',
                channelDescription: 'Günlük yemek menüsü bildirimleri',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                styleInformation: BigTextStyleInformation(body),
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          AppLogger.notification('Scheduled (inexact): "$title"');
        } catch (e2) {
          AppLogger.error('Inexact scheduling also failed', e2);
        }
      }
    }
  }

  /// Menü özetini al
  String _getMenuSummary(Menu menu) {
    if (menu.items.isEmpty) return 'Menü henüz açıklanmadı';
    
    final items = menu.items.take(4).map((item) => '• ${item.name}').toList();
    if (menu.items.length > 4) {
      items.add('... ve ${menu.items.length - 4} yemek daha');
    }
    return items.join('\n');
  }

  /// Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    AppLogger.notification('All notifications cancelled');
  }

  /// Bekleyen bildirimleri al
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Bildirimlerin açık olup olmadığını kontrol et
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  /// Bildirimleri aç/kapat
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (!enabled) {
      await cancelAllNotifications();
    }
    AppLogger.notification('Notifications ${enabled ? "enabled" : "disabled"}');
  }

  /// Test bildirimi gönder
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    await _notifications.show(
      999,
      'Test Bildirimi ✅',
      'Bildirim sistemi çalışıyor!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_notifications',
          'Yemek Bildirimleri',
          channelDescription: 'Günlük yemek menüsü bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
    AppLogger.notification('Test notification sent');
  }

  /// Bildirimleri yeniden zamanla
  Future<void> rescheduleNotifications(List<Menu> menus) async {
    await cancelAllNotifications();
    await scheduleDailyMealNotifications(menus);
  }
}