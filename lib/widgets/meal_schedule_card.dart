import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yurttaye_mobile/themes/app_theme.dart';
import 'package:yurttaye_mobile/utils/constants.dart';
import 'package:yurttaye_mobile/utils/localization.dart';
import 'package:provider/provider.dart';
import 'package:yurttaye_mobile/providers/language_provider.dart';

class MealScheduleCard extends StatelessWidget {
  const MealScheduleCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final languageCode = languageProvider.currentLanguageCode;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray800 : Constants.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Constants.kykGray700 : Constants.kykGray200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Constants.black : Constants.kykGray200).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.kykPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Constants.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Localization.getText('meal_schedule', languageCode),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Constants.white : Constants.kykGray800,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Yemek saatleri
          Row(
            children: [
              // Kahvaltı
              Expanded(
                child: _buildMealTimeCard(
                  context: context,
                  icon: Icons.breakfast_dining,
                  title: Localization.getText('breakfast', languageCode),
                  startTime: '06:30',
                  endTime: '12:00',
                  mealType: Constants.breakfastType,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Akşam Yemeği
              Expanded(
                child: _buildMealTimeCard(
                  context: context,
                  icon: Icons.dinner_dining,
                  title: Localization.getText('dinner', languageCode),
                  startTime: '16:00',
                  endTime: '22:00',
                  mealType: Constants.dinnerType,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Bilgi notu
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Constants.kykGray700 : Constants.kykGray50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Constants.kykGray600 : Constants.kykGray200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark ? Constants.kykGray300 : Constants.kykGray600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Localization.getText('meal_hours_note', languageCode),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Constants.kykGray300 : Constants.kykGray600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String startTime,
    required String endTime,
    required String mealType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.getMealTypePrimaryColor(mealType);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final languageCode = languageProvider.currentLanguageCode;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray800 : Constants.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // İkon ve başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Constants.white : Constants.kykGray700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Saat bilgileri
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeInfo(Localization.getText('start_time', languageCode), startTime, primaryColor, context),
              Container(
                height: 20,
                width: 1,
                color: isDark ? Constants.kykGray600 : Constants.kykGray300,
              ),
              _buildTimeInfo(Localization.getText('end_time', languageCode), endTime, primaryColor, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, Color color, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? Constants.kykGray400 : Constants.kykGray500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}