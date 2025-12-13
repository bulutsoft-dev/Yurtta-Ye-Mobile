import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu.dart';
import '../utils/localization.dart';
import '../utils/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notifications.initialize(initializationSettings);
  }

  Future<void> scheduleDailyMealNotifications(List<Menu> menus) async {
    if (menus.isEmpty) {
      AppLogger.notification('Menu list empty, cannot schedule notifications');
      return;
    }

    // Clear existing notifications
    await notifications.cancelAll();

    // Get today's date
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Filter today's menus
    var todayMenus = menus.where((menu) {
      final menuDate = '${menu.date.year}-${menu.date.month.toString().padLeft(2, '0')}-${menu.date.day.toString().padLeft(2, '0')}';
      return menuDate == todayString;
    }).toList();

    // If no menu for today, find nearest date
    if (todayMenus.isEmpty) {
      AppLogger.notification('No menu for today, searching for nearest date...');
      
      final futureMenus = menus.where((menu) => menu.date.isAfter(today)).toList();
      
      if (futureMenus.isNotEmpty) {
        final nearestDate = futureMenus.map((m) => m.date).reduce((a, b) => a.isBefore(b) ? a : b);
        todayMenus = futureMenus.where((menu) => 
          menu.date.year == nearestDate.year && 
          menu.date.month == nearestDate.month && 
          menu.date.day == nearestDate.day
        ).toList();
        
        AppLogger.notification('Found nearest menu date: ${nearestDate.toString().split(' ')[0]}');
      } else {
        final pastMenus = menus.where((menu) => menu.date.isBefore(today)).toList();
        if (pastMenus.isNotEmpty) {
          final latestDate = pastMenus.map((m) => m.date).reduce((a, b) => a.isAfter(b) ? a : b);
          todayMenus = pastMenus.where((menu) => 
            menu.date.year == latestDate.year && 
            menu.date.month == latestDate.month && 
            menu.date.day == latestDate.day
          ).toList();
          AppLogger.notification('Using past menu for test: ${latestDate.toString().split(' ')[0]}');
        }
      }
    }

    if (todayMenus.isEmpty) {
      AppLogger.notification('No menu found, cannot schedule notifications');
      return;
    }

    // Find breakfast menu
    final breakfastMenu = todayMenus.firstWhere(
      (menu) => menu.mealType == 'Kahvaltı',
      orElse: () => Menu(
        id: 0,
        cityId: 0,
        mealType: 'Kahvaltı',
        date: today,
        energy: '',
        items: [],
      ),
    );

    // Find dinner menu
    final dinnerMenu = todayMenus.firstWhere(
      (menu) => menu.mealType == 'Akşam Yemeği',
      orElse: () => Menu(
        id: 0,
        cityId: 0,
        mealType: 'Akşam Yemeği',
        date: today,
        energy: '',
        items: [],
      ),
    );

    AppLogger.notification('Breakfast menu found: ${breakfastMenu.items.length} items');
    AppLogger.notification('Dinner menu found: ${dinnerMenu.items.length} items');

    // Breakfast notifications
    await _scheduleNotification(
      id: 1,
      title: 'Kahvaltı Başladı! 🍳',
      body: 'Bugünün kahvaltı menüsü:\n${_getMenuSummary(breakfastMenu)}',
      scheduledTime: _getTodayAt(7, 0),
    );

    await _scheduleNotification(
      id: 2,
      title: 'Kahvaltı Bitmek Üzere! ⏰',
      body: 'Kahvaltı menüsü:\n${_getMenuSummary(breakfastMenu)}\n\nHemen yemekhaneye gidin!',
      scheduledTime: _getTodayAt(11, 15),
    );

    // Dinner notifications
    await _scheduleNotification(
      id: 3,
      title: 'Akşam Yemeği Başladı! 🍽️',
      body: 'Bugünün akşam yemeği menüsü:\n${_getMenuSummary(dinnerMenu)}',
      scheduledTime: _getTodayAt(16, 00),
    );

    await _scheduleNotification(
      id: 4,
      title: 'Akşam Yemeği Bitmek Üzere! ⏰',
      body: 'Akşam yemeği menüsü:\n${_getMenuSummary(dinnerMenu)}\n\nHemen yemekhaneye gidin!',
      scheduledTime: _getTodayAt(22, 15),
    );

    AppLogger.notification('Daily meal notifications scheduled');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    DateTime targetTime = scheduledTime;
    if (targetTime.isBefore(DateTime.now())) {
      targetTime = targetTime.add(const Duration(days: 1));
    }

    try {
      await notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(targetTime, tz.local),
        const NotificationDetails(
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
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      AppLogger.notification('Notification scheduled: $title - ${targetTime.toString()}');
    } catch (e) {
      AppLogger.error('Error scheduling notification', e);
      if (e.toString().contains('exact_alarms_not_permitted')) {
        AppLogger.notification('No exact alarm permission, using inexact mode...');
        try {
          await notifications.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(targetTime, tz.local),
            const NotificationDetails(
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
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          AppLogger.notification('Inexact notification scheduled: $title');
        } catch (e2) {
          AppLogger.error('Inexact notification also failed', e2);
        }
      }
    }
  }

  DateTime _getTodayAt(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _getMenuSummary(Menu menu) {
    if (menu.items.isEmpty) return 'Menü henüz açıklanmadı';
    
    final mainItems = menu.items.take(5).map((item) => item.name).toList();
    
    if (mainItems.length <= 3) {
      return mainItems.join(', ');
    } else {
      return '${mainItems.take(3).join(', ')} ve ${mainItems.length - 3} yemek daha';
    }
  }

  Future<void> cancelAllNotifications() async {
    await notifications.cancelAll();
    AppLogger.notification('All notifications cancelled');
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (!enabled) {
      await cancelAllNotifications();
    }
    AppLogger.notification('Notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> sendTestNotification() async {
    await notifications.show(
      999,
      'Test Bildirimi',
      'Yemek bildirimleri çalışıyor!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_notifications',
          'Yemek Bildirimleri',
          channelDescription: 'Günlük yemek menüsü bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pendingNotifications = await notifications.pendingNotificationRequests();
      AppLogger.notification('Pending notifications count: ${pendingNotifications.length}');
      return pendingNotifications;
    } catch (e) {
      AppLogger.error('Error getting pending notifications', e);
      return [];
    }
  }

  Future<void> rescheduleNotifications(List<Menu> menus) async {
    await cancelAllNotifications();
    await scheduleDailyMealNotifications(menus);
  }
}