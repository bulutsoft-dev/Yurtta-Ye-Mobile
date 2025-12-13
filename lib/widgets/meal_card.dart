import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yurttaye_mobile/models/menu.dart';
import 'package:yurttaye_mobile/models/menu_item.dart';
import 'package:yurttaye_mobile/themes/app_theme.dart';
import 'package:yurttaye_mobile/utils/constants.dart';
import 'package:yurttaye_mobile/utils/localization.dart';
import 'package:yurttaye_mobile/providers/language_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yurttaye_mobile/services/share_service.dart';

/// Kompakt ve toplu yemek kartı
class MealCard extends StatefulWidget {
  final Menu menu;
  final bool isDetailed;
  final VoidCallback? onTap;

  const MealCard({
    super.key,
    required this.menu,
    this.isDetailed = false,
    this.onTap,
  });

  @override
  _MealCardState createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Öğün tipi ikonu
  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'Kahvaltı':
        return Icons.breakfast_dining;
      case 'Öğle Yemeği':
        return Icons.lunch_dining;
      case 'Akşam Yemeği':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  /// Kısa öğün adı
  String _getShortMealType(String mealType) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final languageCode = languageProvider.currentLanguageCode;
    
    switch (mealType) {
      case 'Kahvaltı':
        return languageCode == 'tr' 
            ? Localization.getText('breakfast', languageCode)
            : Localization.getText('breakfast_short', languageCode);
      case 'Öğle Yemeği':
        return Localization.getText('lunch', languageCode);
      case 'Akşam Yemeği':
        return languageCode == 'tr'
            ? Localization.getText('dinner', languageCode)
            : Localization.getText('dinner_short', languageCode);
      default:
        return mealType;
    }
  }

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

  /// Kategori ikonu
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

  /// Kategori rengi
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
        return Constants.kykPrimary;
    }
  }

  /// Kategori ismini lokalize et
  String _getLocalizedCategoryName(String category) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final languageCode = languageProvider.currentLanguageCode;
    
    switch (category.toLowerCase()) {
      case 'çorba':
        return Localization.getText('soup', languageCode);
      case 'ana yemek':
        return Localization.getText('main_dish', languageCode);
      case 'et yemeği':
        return Localization.getText('meat_dish', languageCode);
      case 'salata':
        return Localization.getText('salad', languageCode);
      case 'yeşillik':
        return Localization.getText('greens', languageCode);
      case 'tatlı':
      case 'dessert':
        return Localization.getText('dessert', languageCode);
      case 'pilav':
        return Localization.getText('rice', languageCode);
      case 'makarna':
        return Localization.getText('pasta', languageCode);
      case 'ekmek':
        return Localization.getText('bread', languageCode);
      case 'kahvaltılık':
        return Localization.getText('breakfast_items', languageCode);
      default:
        return category;
    }
  }

  /// Tarihi lokalize et
  String _getLocalizedDate(DateTime date) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final languageCode = languageProvider.currentLanguageCode;
    
    final locale = languageCode == 'tr' ? 'tr_TR' : 'en_US';
    return DateFormat('d MMM yyyy', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.menu.items.fold<Map<String, List<MenuItem>>>(
      {},
      (map, item) {
        map[item.category] = (map[item.category] ?? [])..add(item);
        return map;
      },
    );

    final mealTypeConstant = _getMealTypeConstant(widget.menu.mealType);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final languageCode = languageProvider.currentLanguageCode;

    return Semantics(
      label: '${_getShortMealType(widget.menu.mealType)} ${Localization.getText('menu', languageCode)} - ${_getLocalizedDate(widget.menu.date)}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: Constants.space3,
                vertical: Constants.space2,
              ),
              decoration: BoxDecoration(
                color: isDark ? Constants.darkCard : Constants.white,
                border: Border.all(
                  color: _isHovered 
                      ? AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.3)
                      : isDark ? Constants.darkBorder : Constants.kykGray200,
                  width: _isHovered ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered 
                        ? AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.15)
                        : (isDark ? Constants.black : Constants.kykGray200).withOpacity(_isHovered ? 0.08 : 0.05),
                    blurRadius: _isHovered ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.onTap ??
                    () => context.pushNamed(
                      'menu_detail',
                      pathParameters: {'id': widget.menu.id.toString()},
                    ),
                onTapDown: (_) => _controller.forward(),
                onTapUp: (_) => _controller.reverse(),
                onTapCancel: () => _controller.reverse(),
                splashColor: AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.1),
                child: Column(
                  children: [
                    _buildCompactHeader(categories, mealTypeConstant),
                    _buildCompactContent(categories, mealTypeConstant),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kompakt başlık bölümü
  Widget _buildCompactHeader(Map<String, List<MenuItem>> categories, String mealTypeConstant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final languageCode = languageProvider.currentLanguageCode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Constants.space4),
      decoration: AppTheme.getMealTypeGradient(mealTypeConstant),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Öğün ikonu
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Constants.black.withOpacity(0.85) : Constants.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMealTypeIcon(widget.menu.mealType),
              color: isDark ? Color(0xFFFFF59D) : Constants.white,
              shadows: isDark
                  ? [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
              size: 20,
            ),
          ),
          const SizedBox(width: Constants.space3),
          // Öğün adı ve tarih
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _getShortMealType(widget.menu.mealType),
                        style: AppTheme.getMealTypeTitleStyle(mealTypeConstant, context).copyWith(
                          color: isDark ? Constants.white : Constants.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Constants.space3),
                    Flexible(
                      child: Text(
                        _getLocalizedDate(widget.menu.date),
                        style: AppTheme.getMealTypeSubtitleStyle(mealTypeConstant, context).copyWith(
                          color: isDark ? Constants.white.withOpacity(0.8) : Constants.white.withOpacity(0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (widget.menu.energy.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, color: isDark ? Constants.white.withOpacity(0.9) : Constants.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.menu.energy + ' ' + Localization.getText('kcal', languageCode),
                        style: GoogleFonts.inter(
                          fontSize: Constants.textSm,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Constants.white.withOpacity(0.9) : Constants.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Paylaş butonu
          const SizedBox(width: Constants.space2),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ShareService.shareMenuAsText(widget.menu, languageCode: languageCode);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Constants.black.withOpacity(0.5) : Constants.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.share_rounded,
                  color: isDark ? Constants.white.withOpacity(0.9) : Constants.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kompakt içerik bölümü
  Widget _buildCompactContent(Map<String, List<MenuItem>> categories, String mealTypeConstant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final languageCode = languageProvider.currentLanguageCode;
    
    return Padding(
      padding: const EdgeInsets.all(Constants.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategoriler
          ...categories.entries.map((entry) => _buildCompactCategory(entry.key, entry.value)),
          
          const SizedBox(height: Constants.space3),
          
          // Detay butonu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.space3,
              vertical: Constants.space2,
            ),
            decoration: AppTheme.getMealTypeGradient(mealTypeConstant),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 16,
                  color: Constants.white,
                ),
                const SizedBox(width: Constants.space2),
                Text(
                  Localization.getText('view_details', languageCode),
                  style: GoogleFonts.inter(
                    fontSize: Constants.textSm,
                    fontWeight: FontWeight.w600,
                    color: Constants.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kompakt kategori
  Widget _buildCompactCategory(String category, List<MenuItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: Constants.space2),
      decoration: BoxDecoration(
        color: isDark ? Constants.darkGray : Constants.kykGray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Constants.darkBorder : Constants.kykGray200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Kategori başlığı
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.space3,
              vertical: Constants.space2,
            ),
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(isDark ? 0.13 : 0.09),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: 16,
                  color: isDark ? Color(0xFFFFF59D) : _getCategoryColor(category),
                ),
                const SizedBox(width: Constants.space2),
                Expanded(
                  child: Text(
                    _getLocalizedCategoryName(category),
                    style: GoogleFonts.inter(
                      fontSize: Constants.textBase,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Constants.white : Constants.kykGray700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? _getCategoryColor(category).withOpacity(0.5) : _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${items.length}',
                    style: GoogleFonts.inter(
                      fontSize: Constants.textXs,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Constants.white : Constants.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Yemek listesi
          Padding(
            padding: const EdgeInsets.all(Constants.space2),
            child: Column(
              children: items.map((item) => _buildCompactMenuItem(item, category)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Kompakt yemek öğesi
  Widget _buildCompactMenuItem(MenuItem item, String category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white 
                  : _getCategoryColor(category),
              borderRadius: BorderRadius.circular(5),
              boxShadow: isDark ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
          ),
          const SizedBox(width: Constants.space2),
          Expanded(
            child: Text(
              item.name,
              style: GoogleFonts.inter(
                fontSize: Constants.textSm,
                fontWeight: FontWeight.w500,
                color: isDark ? Constants.white : Constants.kykGray700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.gram.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isDark ? Constants.darkGrayLight : Constants.kykGray100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.gram,
                style: GoogleFonts.inter(
                  fontSize: Constants.textXs,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Constants.white.withOpacity(0.8) : Constants.kykGray600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}