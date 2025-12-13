import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yurttaye_mobile/models/menu.dart';
import 'package:yurttaye_mobile/utils/app_logger.dart';

/// Menü paylaşım servisi
class ShareService {
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.yurttaye.yurttaye';
  static const String webAppUrl = 'https://yurttaye.onrender.com/';

  /// Menüyü metin olarak paylaş
  static Future<void> shareMenuAsText(Menu menu, {String languageCode = 'tr'}) async {
    try {
      final formattedDate = DateFormat('d MMMM yyyy', languageCode).format(menu.date);
      final dayName = DateFormat('EEEE', languageCode).format(menu.date);
      
      // Yemek türü emoji
      final mealEmoji = menu.mealType == 'Kahvaltı' ? '🍳' : '🍽️';
      final mealTypeName = languageCode == 'tr' ? menu.mealType : (menu.mealType == 'Kahvaltı' ? 'Breakfast' : 'Dinner');
      
      // Menü öğelerini formatla
      final menuItems = menu.items.map((item) => '  • ${item.name}').join('\n');
      
      // Enerji bilgisi
      final energyInfo = menu.energy.isNotEmpty 
          ? '\n📊 ${languageCode == 'tr' ? 'Enerji' : 'Energy'}: ${menu.energy} kcal'
          : '';

      final shareText = '''
$mealEmoji $mealTypeName - $dayName
📅 $formattedDate

$menuItems
$energyInfo

━━━━━━━━━━━━━━━━━━━━
📱 YurttaYe - KYK Yemek Menüsü
🌐 Web: $webAppUrl
📲 Play Store: $playStoreUrl
━━━━━━━━━━━━━━━━━━━━
''';

      await Share.share(shareText.trim());
      AppLogger.info('Menu shared as text: ${menu.id}');
    } catch (e) {
      AppLogger.error('Error sharing menu as text', e);
      rethrow;
    }
  }

  /// Menüyü görsel olarak paylaş (screenshot)
  static Future<void> shareMenuAsImage({
    required ScreenshotController screenshotController,
    required Menu menu,
    String languageCode = 'tr',
  }) async {
    try {
      // Screenshot al
      final Uint8List? imageBytes = await screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0, // Yüksek kalite
      );

      if (imageBytes == null) {
        throw Exception('Screenshot capture failed');
      }

      // Geçici dosyaya kaydet
      final directory = await getTemporaryDirectory();
      final fileName = 'yurttaye_menu_${menu.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final imagePath = '${directory.path}/$fileName';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // Paylaşım metni
      final formattedDate = DateFormat('d MMMM', languageCode).format(menu.date);
      final mealTypeName = menu.mealType;
      
      final shareText = languageCode == 'tr'
          ? '$mealTypeName menüsü - $formattedDate 🍽️\n\n📱 YurttaYe: $playStoreUrl'
          : '$mealTypeName menu - $formattedDate 🍽️\n\n📱 YurttaYe: $playStoreUrl';

      // Görsel ile paylaş
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareText,
      );

      // Geçici dosyayı temizle (opsiyonel, OS yapabilir)
      // await imageFile.delete();

      AppLogger.info('Menu shared as image: ${menu.id}');
    } catch (e) {
      AppLogger.error('Error sharing menu as image', e);
      rethrow;
    }
  }

  /// Paylaşım seçenekleri modal'ını göster
  static Future<void> showShareOptions({
    required BuildContext context,
    required Menu menu,
    ScreenshotController? screenshotController,
    String languageCode = 'tr',
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Başlık
                Text(
                  languageCode == 'tr' ? 'Menüyü Paylaş' : 'Share Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Metin olarak paylaş
                _buildShareOption(
                  context: context,
                  icon: Icons.text_fields,
                  title: languageCode == 'tr' ? 'Metin Olarak Paylaş' : 'Share as Text',
                  subtitle: languageCode == 'tr' ? 'WhatsApp, SMS, E-posta' : 'WhatsApp, SMS, Email',
                  color: Colors.blue,
                  onTap: () async {
                    Navigator.pop(context);
                    await shareMenuAsText(menu, languageCode: languageCode);
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Görsel olarak paylaş
                if (screenshotController != null)
                  _buildShareOption(
                    context: context,
                    icon: Icons.image,
                    title: languageCode == 'tr' ? 'Görsel Olarak Paylaş' : 'Share as Image',
                    subtitle: languageCode == 'tr' ? 'Instagram, Twitter, Hikaye' : 'Instagram, Twitter, Story',
                    color: Colors.purple,
                    onTap: () async {
                      Navigator.pop(context);
                      await shareMenuAsImage(
                        screenshotController: screenshotController,
                        menu: menu,
                        languageCode: languageCode,
                      );
                    },
                  ),
                
                if (screenshotController != null)
                  const SizedBox(height: 12),
                
                // Uygulama linkini paylaş
                _buildShareOption(
                  context: context,
                  icon: Icons.link,
                  title: languageCode == 'tr' ? 'Uygulama Linkini Paylaş' : 'Share App Link',
                  subtitle: 'Play Store & Web',
                  color: Colors.green,
                  onTap: () async {
                    Navigator.pop(context);
                    await shareAppLink(languageCode: languageCode);
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Paylaşım seçeneği widget'ı
  static Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sadece uygulama linkini paylaş
  static Future<void> shareAppLink({String languageCode = 'tr'}) async {
    try {
      final shareText = languageCode == 'tr'
          ? '''
📱 YurttaYe - KYK Yemek Menüsü

Yurt yemeğini kontrol etmek artık çok kolay!

🌐 Web: $webAppUrl
📲 Play Store: $playStoreUrl

#YurttaYe #KYK #Yemek
'''
          : '''
📱 YurttaYe - Dormitory Meal Menu

Checking dorm food is now easy!

🌐 Web: $webAppUrl
📲 Play Store: $playStoreUrl

#YurttaYe #Dormitory #Food
''';

      await Share.share(shareText.trim());
      AppLogger.info('App link shared');
    } catch (e) {
      AppLogger.error('Error sharing app link', e);
      rethrow;
    }
  }
}
