import 'package:flutter/material.dart';
import 'package:yurttaye_mobile/services/notification_service.dart';
import 'package:yurttaye_mobile/utils/app_logger.dart';

/// Bildirim test yardımcı sınıfı
class NotificationTest {
  static final NotificationService _notificationService = NotificationService();

  /// Anlık test bildirimi gönder
  static Future<void> testImmediateNotification() async {
    try {
      await _notificationService.sendTestNotification();
      AppLogger.notification('Anlık test bildirimi gönderildi!');
    } catch (e) {
      AppLogger.error('Anlık test bildirimi hatası', e);
      rethrow;
    }
  }

  /// Tüm bildirimleri iptal et
  static Future<void> cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      AppLogger.notification('Tüm bildirimler iptal edildi!');
    } catch (e) {
      AppLogger.error('Bildirim iptal hatası', e);
      rethrow;
    }
  }

  /// Test dialog'u göster
  static Future<void> showTestDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bildirim Testi'),
          content: const Text('Anlık test bildirimi göndermek istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await testImmediateNotification();
                  _showSuccessSnackBar(context, 'Anlık test bildirimi gönderildi!');
                } catch (e) {
                  _showErrorSnackBar(context, 'Test hatası: $e');
                }
              },
              child: const Text('Test Et'),
            ),
          ],
        );
      },
    );
  }

  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}