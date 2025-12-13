import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:yurttaye_mobile/models/menu.dart';
import 'package:yurttaye_mobile/models/menu_item.dart';
import 'package:yurttaye_mobile/providers/menu_provider.dart';
import 'package:yurttaye_mobile/providers/theme_provider.dart';
import 'package:yurttaye_mobile/services/share_service.dart';
import 'package:yurttaye_mobile/themes/app_theme.dart';
import 'package:yurttaye_mobile/utils/app_config.dart';
import 'package:intl/intl.dart';
import 'package:yurttaye_mobile/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yurttaye_mobile/utils/localization.dart';
import 'package:yurttaye_mobile/widgets/banner_ad_widget.dart';

class MenuDetailScreen extends StatefulWidget {
  final int menuId;
  const MenuDetailScreen({Key? key, required this.menuId}) : super(key: key);

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  String _selectedMealType = AppConfig.mealTypes[0];
  final ScreenshotController _screenshotController = ScreenshotController();
  Menu? _currentMenu;

  /// Yemek türü sabitini al
  String _getMealTypeConstant(String mealType) {
    switch (mealType) {
      case 'Kahvaltı':
        return Constants.breakfastType;
      case 'Öğle Yemeği':
        return Constants.lunchType;
      case 'Akşam Yemeği':
        return Constants.dinnerType;
      default:
        return Constants.lunchType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MenuProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final menu = provider.menus.firstWhere(
      (m) => m.id == widget.menuId,
      orElse: () => Menu(
        id: 0,
        cityId: 0,
        mealType: '',
        date: DateTime.now(),
        energy: '',
        items: [],
      ),
    );

    // Localization
    final languageCode = Localizations.localeOf(context).languageCode;

    if (menu.id == 0) {
      return Scaffold(
        appBar: _buildAppBar(themeProvider, _getMealTypeConstant(menu.mealType), languageCode),
        body: _buildEmptyState(languageCode),
      );
    }

    final selectedDate = AppConfig.apiDateFormat.format(menu.date);
    final filteredMenu = provider.menus.firstWhere(
      (m) =>
          m.mealType == _selectedMealType &&
          AppConfig.apiDateFormat.format(m.date) == selectedDate,
      orElse: () => Menu(
        id: 0,
        cityId: 0,
        mealType: _selectedMealType,
        date: menu.date,
        energy: '',
        items: [],
      ),
    );

    final mealTypeConstant = _getMealTypeConstant(filteredMenu.id != 0 ? filteredMenu.mealType : menu.mealType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Share için güncel menüyü sakla
    _currentMenu = filteredMenu.id != 0 ? filteredMenu : menu;

    return Scaffold(
      backgroundColor: isDark ? Constants.kykGray900 : Constants.kykGray50,
      appBar: _buildAppBar(themeProvider, mealTypeConstant, languageCode),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Screenshot için sarmalanan menü içeriği
            Screenshot(
              controller: _screenshotController,
              child: Container(
                color: isDark ? Constants.kykGray900 : Constants.kykGray50,
                child: Column(
                  children: [
                    _buildHeroHeader(filteredMenu.id != 0 ? filteredMenu : menu, mealTypeConstant),
                    const SizedBox(height: Constants.space3),
                    filteredMenu.id != 0
                        ? _buildMenuContent(filteredMenu, mealTypeConstant)
                        : _buildNoMenuForMealType(mealTypeConstant),
                    const SizedBox(height: Constants.space3),
                    _buildNutritionSection(filteredMenu.id != 0 ? filteredMenu : menu, mealTypeConstant),
                    // YurttaYe watermark
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '📱 YurttaYe - yurttaye.onrender.com',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Constants.kykGray400 : Constants.kykGray500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Constants.space3),
            _buildMealTypeSelector(mealTypeConstant),
            const SizedBox(height: Constants.space3),
            _buildMealHoursInfo(mealTypeConstant),
            const SizedBox(height: Constants.space3),
            _buildDisclaimerInfo(mealTypeConstant),
            const SizedBox(height: Constants.space4),
            
            // Banner Reklam
            const Center(child: BannerAdWidget()),
            
            const SizedBox(height: Constants.space4),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeProvider themeProvider, String mealTypeConstant, String languageCode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? Constants.darkSurface : Constants.kykPrimary;
    final appBarFg = isDark ? Constants.darkTextPrimary : Constants.white;
    
    return AppBar(
      elevation: 0,
      backgroundColor: appBarBg,
      centerTitle: true,
      title: Text(
        Localization.getText('menu_detail', languageCode),
        style: GoogleFonts.inter(
          fontSize: Constants.textLg,
          fontWeight: FontWeight.w700,
          color: appBarFg,
        ),
      ), 
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: appBarFg.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_back_ios,
            color: appBarFg,
            size: 18,
          ),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appBarFg.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              themeProvider.isDarkMode ? Icons.brightness_7 : Icons.brightness_4,
              color: appBarFg,
              size: 18,
            ),
          ),
          onPressed: () {
            themeProvider.toggleTheme();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  themeProvider.isDarkMode
                    ? Localization.getText('dark_theme_active', languageCode)
                    : Localization.getText('light_theme_active', languageCode),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                backgroundColor: appBarBg,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appBarFg.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.share,
              color: appBarFg,
              size: 18,
            ),
          ),
          onPressed: () => _shareMenu(),
        ),
      ],
    );
  }

  void _shareMenu() {
    if (_currentMenu == null || _currentMenu!.id == 0) return;
    
    final languageCode = Localizations.localeOf(context).languageCode;
    ShareService.showShareOptions(
      context: context,
      menu: _currentMenu!,
      screenshotController: _screenshotController,
      languageCode: languageCode,
    );
  }

  Widget _buildEmptyState(String languageCode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Constants.kykGray800,
                  Constants.kykGray900,
                ]
              : [
                  Constants.kykPrimary.withOpacity(0.05),
                  Constants.kykGray50,
                ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Constants.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 80,
                color: isDark ? Constants.kykGray400 : Constants.kykGray300,
              ),
              const SizedBox(height: Constants.space4),
              Text(
                Localization.getText('no_menu_for_meal', languageCode),
                style: GoogleFonts.inter(
                  fontSize: Constants.text2xl,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Constants.white : Constants.kykGray800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Constants.space3),
              Text(
                Localization.getText('no_menu_description', languageCode),
                style: GoogleFonts.inter(
                  fontSize: Constants.textBase,
                  color: isDark ? Constants.kykGray300 : Constants.kykGray600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(Menu menu, String mealTypeConstant) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Constants.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getMealTypePrimaryColor(mealTypeConstant),
            AppTheme.getMealTypeSecondaryColor(mealTypeConstant),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tarih ve öğün bilgisi
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Constants.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: Constants.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLocalizedDate(menu.date),
                      style: GoogleFonts.inter(
                        fontSize: Constants.textBase,
                        fontWeight: FontWeight.w600,
                        color: Constants.white,
                      ),
                    ),
                    const SizedBox(height: Constants.space1),
                    Text(
                      _getLocalizedMealType(menu.mealType, languageCode),
                      style: GoogleFonts.inter(
                        fontSize: Constants.textSm,
                        fontWeight: FontWeight.w500,
                        color: Constants.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Constants.space3),
          // İstatistikler
          Wrap(
            spacing: Constants.space4,
            runSpacing: Constants.space4,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                Icons.restaurant,
                '${menu.items.length}',
                Localization.getText('filtered_results', languageCode),
              ),
              _buildStatItem(
                Icons.category,
                '${menu.items.map((e) => e.category).toSet().length}',
                Localization.getText('category', languageCode),
              ),
              if (menu.energy.isNotEmpty)
                _buildStatItem(
                  Icons.local_fire_department,
                  menu.energy,
                  Localization.getText('energy', languageCode),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Constants.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Constants.white,
            size: 18,
          ),
        ),
        const SizedBox(height: Constants.space2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: Constants.textLg,
            fontWeight: FontWeight.w800,
            color: Constants.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: Constants.textXs,
            fontWeight: FontWeight.w600,
            color: Constants.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMealTypeSelector(String mealTypeConstant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Constants.space4),
      padding: const EdgeInsets.all(Constants.space2),
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray800 : Constants.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Constants.black : Constants.kykGray200).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildMealTypeOption('Kahvaltı', mealTypeConstant, languageCode),
          const SizedBox(width: Constants.space2),
          _buildMealTypeOption('Akşam Yemeği', mealTypeConstant, languageCode),
        ],
      ),
    );
  }

  Widget _buildMealTypeOption(String mealType, String mealTypeConstant, String languageCode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedMealType == mealType;
    final localizedMealType = _getLocalizedMealType(mealType, languageCode);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMealType = mealType),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: Constants.space3,
            horizontal: Constants.space2,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.getMealTypePrimaryColor(mealTypeConstant) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            localizedMealType,
            style: GoogleFonts.inter(
              fontSize: Constants.textBase,
              fontWeight: FontWeight.w600,
              color: isSelected ? Constants.white : (isDark ? Constants.kykGray300 : Constants.kykGray700),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContent(Menu menu, String mealTypeConstant) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = menu.items.fold<Map<String, List<MenuItem>>>(
      {},
      (map, item) {
        map[item.category] = (map[item.category] ?? [])..add(item);
        return map;
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Constants.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  color: AppTheme.getMealTypePrimaryColor(mealTypeConstant),
                  size: 16,
                ),
              ),
              const SizedBox(width: Constants.space2),
              Text(
                Localization.getText('filtered_results', languageCode),
                style: GoogleFonts.inter(
                  fontSize: Constants.textLg,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Constants.white : Constants.kykGray800,
                ),
              ),
            ],
          ),
          const SizedBox(height: Constants.space2),
          ...categories.entries.map((entry) => _buildCategoryCard(entry.key, entry.value, mealTypeConstant, languageCode)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, List<MenuItem> items, String mealTypeConstant, String languageCode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: Constants.space2),
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray800 : Constants.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Constants.black : Constants.kykGray200).withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Kategori başlığı
          Container(
            padding: const EdgeInsets.all(Constants.space2),
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: Constants.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: Constants.space3),
                Expanded(
                  child: Text(
                    _getLocalizedCategoryName(category, languageCode),
                    style: GoogleFonts.inter(
                      fontSize: Constants.textSm,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Constants.white : Constants.kykGray800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Constants.space1,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${items.length}',
                    style: GoogleFonts.inter(
                      fontSize: Constants.textXs,
                      fontWeight: FontWeight.w600,
                      color: Constants.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Yemek listesi
          Padding(
            padding: const EdgeInsets.all(Constants.space3),
            child: Column(
              children: items.map((item) => _buildMenuItem(item, category, mealTypeConstant)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item, String category, String mealTypeConstant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Container(
      margin: const EdgeInsets.only(bottom: Constants.space1),
      padding: const EdgeInsets.all(Constants.space2),
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray700 : Constants.kykGray50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getCategoryColor(category).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: _getCategoryColor(category),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Constants.space2),
          Expanded(
            child: Text(
              item.name,
              style: GoogleFonts.inter(
                fontSize: Constants.textSm,
                fontWeight: FontWeight.w500,
                color: isDark ? Constants.white : Constants.kykGray800,
                height: 1.3,
              ),
            ),
          ),
          if (item.gram.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Constants.space1,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${item.gram}${Localization.getText('gram_unit', languageCode)}',
                style: GoogleFonts.inter(
                  fontSize: Constants.textXs,
                  fontWeight: FontWeight.w600,
                  color: _getCategoryColor(category),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoMenuForMealType(String mealTypeConstant) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Constants.space6),
      padding: const EdgeInsets.all(Constants.space6),
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray800 : Constants.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Constants.black : Constants.kykGray200).withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Constants.space6),
            decoration: BoxDecoration(
              color: Constants.kykGray100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: Constants.text2xl * 2,
              color: AppTheme.getMealTypePrimaryColor(mealTypeConstant),
            ),
          ),
          const SizedBox(height: Constants.space4),
          Text(
            Localization.getText('no_menu_for_meal', languageCode),
            style: GoogleFonts.inter(
              fontSize: Constants.textXl,
              fontWeight: FontWeight.w700,
              color: isDark ? Constants.white : Constants.kykGray800,
            ),
          ),
          const SizedBox(height: Constants.space2),
          Text(
            Localization.getText('no_menu_description', languageCode),
            style: GoogleFonts.inter(
              fontSize: Constants.textBase,
              color: isDark ? Constants.kykGray300 : Constants.kykGray600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Constants.space4),
          // Veri katkısı mesajı
          Container(
            padding: const EdgeInsets.all(Constants.space5),
            decoration: BoxDecoration(
              color: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.getMealTypePrimaryColor(mealTypeConstant),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism,
                        color: Constants.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: Constants.space4),
                    Expanded(
                      child: Text(
                        Localization.getText('data_contribution', languageCode),
                        style: GoogleFonts.inter(
                          fontSize: Constants.textLg,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Constants.white : Constants.kykGray800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Constants.space4),
                Text(
                  Localization.getText('data_contribution_desc', languageCode),
                  style: GoogleFonts.inter(
                    fontSize: Constants.textBase,
                    color: isDark ? Constants.kykGray300 : Constants.kykGray600,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Constants.space4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchEmail(),
                    icon: const Icon(Icons.email, size: 20),
                    label: Text(
                      Localization.getText('contact_us', languageCode),
                      style: GoogleFonts.inter(
                        fontSize: Constants.textBase,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.getMealTypePrimaryColor(mealTypeConstant),
                      foregroundColor: Constants.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Constants.space5,
                        vertical: Constants.space3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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

  Widget _buildNutritionSection(Menu menu, String mealTypeConstant) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (menu.energy.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Constants.space4),
      padding: const EdgeInsets.all(Constants.space4),
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray800 : Constants.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Constants.black : Constants.kykGray200).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: AppTheme.getMealTypePrimaryColor(mealTypeConstant),
                  size: 16,
                ),
              ),
              const SizedBox(width: Constants.space3),
              Text(
                Localization.getText('nutrition_info', languageCode),
                style: GoogleFonts.inter(
                  fontSize: Constants.textLg,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Constants.white : Constants.kykGray800,
                ),
              ),
            ],
          ),
          const SizedBox(height: Constants.space4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Constants.space3),
            decoration: BoxDecoration(
              color: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppTheme.getMealTypePrimaryColor(mealTypeConstant),
                  size: 24,
                ),
                const SizedBox(width: Constants.space3),
                Text(
                  menu.energy,
                  style: GoogleFonts.inter(
                    fontSize: Constants.textXl,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.getMealTypePrimaryColor(mealTypeConstant),
                  ),
                ),
                const SizedBox(width: Constants.space2),
                Text(
                  Localization.getText('kcal', languageCode),
                  style: GoogleFonts.inter(
                    fontSize: Constants.textBase,
                    color: AppTheme.getMealTypePrimaryColor(mealTypeConstant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealHoursInfo(String mealTypeConstant) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Constants.space4),
      padding: const EdgeInsets.all(Constants.space4),
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray800 : Constants.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Constants.black : Constants.kykGray200).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.access_time,
                  color: AppTheme.getMealTypePrimaryColor(mealTypeConstant),
                  size: 16,
                ),
              ),
              const SizedBox(width: Constants.space3),
              Text(
                Localization.getText('meal_hours', languageCode),
                style: GoogleFonts.inter(
                  fontSize: Constants.textLg,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Constants.white : Constants.kykGray800,
                ),
              ),
            ],
          ),
          const SizedBox(height: Constants.space3),
          Row(
            children: [
              Expanded(
                child: _buildMealTimeCard(
                  Localization.getText('breakfast', languageCode),
                  Localization.getText('breakfast_hours', languageCode),
                  Icons.wb_sunny,
                  AppTheme.getMealTypePrimaryColor(mealTypeConstant),
                ),
              ),
              const SizedBox(width: Constants.space3),
              Expanded(
                child: _buildMealTimeCard(
                  Localization.getText('dinner', languageCode),
                  Localization.getText('dinner_hours', languageCode),
                  Icons.nightlight,
                  AppTheme.getMealTypeSecondaryColor(mealTypeConstant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealTimeCard(String title, String time, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(Constants.space2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(height: Constants.space2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: Constants.textSm,
              fontWeight: FontWeight.w700,
              color: isDark ? Constants.white : Constants.kykGray800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Constants.space1),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: Constants.textSm,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerInfo(String mealTypeConstant) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Constants.space4),
      padding: const EdgeInsets.all(Constants.space4),
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray800 : Constants.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Constants.kykWarning.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Constants.black : Constants.kykGray200).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Constants.kykWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline,
              color: Constants.kykWarning,
              size: 16,
            ),
          ),
          const SizedBox(width: Constants.space3),
          Expanded(
            child: Text(
              Localization.getText('disclaimer_text', languageCode),
              style: GoogleFonts.inter(
                fontSize: Constants.textSm,
                fontWeight: FontWeight.w600,
                color: isDark ? Constants.white : Constants.kykGray800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'çorba':
        return Constants.foodWarm;
      case 'ana yemek':
      case 'et yemeği':
        return Constants.foodSpicy;
      case 'salata':
      case 'yeşillik':
        return Constants.foodFresh;
      case 'tatlı':
      case 'dessert':
        return Constants.foodSweet;
      case 'pilav':
      case 'makarna':
        return Constants.kykAccent;
      case 'ekmek':
      case 'kahvaltılık':
        return Constants.kykSecondary;
      default:
        return AppTheme.getMealTypePrimaryColor(_getMealTypeConstant(_selectedMealType));
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'çorba':
        return Icons.soup_kitchen;
      case 'ana yemek':
      case 'et yemeği':
        return Icons.restaurant;
      case 'salata':
      case 'yeşillik':
        return Icons.eco;
      case 'tatlı':
      case 'dessert':
        return Icons.cake;
      case 'pilav':
      case 'makarna':
        return Icons.rice_bowl;
      case 'ekmek':
      case 'kahvaltılık':
        return Icons.breakfast_dining;
      default:
        return Icons.fastfood;
    }
  }

  Future<void> _launchEmail() async {
    const String email = 'bulutsoftdev@gmail.com';
    final languageCode = Localizations.localeOf(context).languageCode;
    
    final String subject = Localization.getText('email_subject', languageCode);
    final String body = '''${Localization.getText('email_greeting', languageCode)}

${Localization.getText('email_city', languageCode)} 
${Localization.getText('email_date', languageCode)} 
${Localization.getText('email_meal_type', languageCode)} 
${Localization.getText('email_menu_details', languageCode)}

${Localization.getText('email_thanks', languageCode)}''';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      bool canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        await launchUrl(emailUri);
      } else {
        // Email uygulaması yoksa, email adresini kopyala
        await Clipboard.setData(const ClipboardData(text: email));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${Localization.getText('email_copied', languageCode)}: $email',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.getMealTypePrimaryColor(_getMealTypeConstant(_selectedMealType)),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: Localization.getText('ok', languageCode),
                textColor: Constants.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Localization.getText('email_error', languageCode)}: $e',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.getMealTypePrimaryColor(_getMealTypeConstant(_selectedMealType)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _getLocalizedMealType(String mealType, String languageCode) {
    switch (mealType) {
      case 'Kahvaltı':
        return Localization.getText('breakfast', languageCode);
      case 'Öğle Yemeği':
        return Localization.getText('lunch', languageCode);
      case 'Akşam Yemeği':
        return Localization.getText('dinner', languageCode);
      default:
        return Localization.getText('lunch', languageCode);
    }
  }

  String _getLocalizedDate(DateTime date) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final locale = languageCode == 'tr' ? 'tr_TR' : 'en_US';
    return DateFormat('dd MMMM yyyy, EEEE', locale).format(date);
  }

  String _getLocalizedCategoryName(String category, String languageCode) {
    switch (category.toLowerCase()) {
      case 'çorba':
        return Localization.getText('soup', languageCode);
      case 'ana yemek':
      case 'et yemeği':
        return Localization.getText('main_dish', languageCode);
      case 'salata':
      case 'yeşillik':
        return Localization.getText('salad', languageCode);
      case 'tatlı':
      case 'dessert':
        return Localization.getText('dessert', languageCode);
      case 'pilav':
      case 'makarna':
        return Localization.getText('rice', languageCode);
      case 'ekmek':
      case 'kahvaltılık':
        return Localization.getText('breakfast', languageCode);
      default:
        return category;
    }
  }
}