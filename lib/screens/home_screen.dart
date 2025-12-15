import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:yurttaye_mobile/providers/language_provider.dart';
import 'package:yurttaye_mobile/providers/menu_provider.dart';
import 'package:yurttaye_mobile/providers/theme_provider.dart';
import 'package:yurttaye_mobile/themes/app_theme.dart';
import 'package:yurttaye_mobile/utils/app_config.dart';
import 'package:yurttaye_mobile/utils/constants.dart';
import 'package:yurttaye_mobile/utils/app_logger.dart';
import 'package:yurttaye_mobile/widgets/error_widget.dart';
import 'package:yurttaye_mobile/widgets/meal_card.dart';
import 'package:yurttaye_mobile/widgets/shimmer_loading.dart';
import 'package:yurttaye_mobile/widgets/date_selector.dart';
import 'package:yurttaye_mobile/widgets/empty_state_widget.dart';
import 'package:yurttaye_mobile/widgets/upcoming_meals_section.dart';
import 'package:yurttaye_mobile/widgets/bottom_navigation_bar.dart';
import 'package:intl/intl.dart';
import 'package:yurttaye_mobile/models/menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yurttaye_mobile/widgets/upcoming_meal_card.dart';
import 'package:yurttaye_mobile/widgets/meal_schedule_card.dart';
import 'package:yurttaye_mobile/utils/localization.dart';
import 'package:yurttaye_mobile/services/ad_service.dart';
import 'package:yurttaye_mobile/services/ad_manager.dart';
import 'package:yurttaye_mobile/widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedMealIndex = 0;
  DateTime _selectedDate = DateTime.now();
  double _opacity = 1.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _selectMealTypeByTime();
    _initializeData();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<MenuProvider>(context, listen: false);
        provider.fetchCities();
        // Fetch fresh data. initialLoad=true enables Stale-While-Revalidate
        provider.fetchMenus(reset: true, initialLoad: true);
        AppLogger.debug('Initiating fetchMenus from HomeScreen initState');
      }
    });
  }

  void _selectMealTypeByTime() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (mounted) {
      setState(() {
        if (hour >= 13 || hour < 6) {
          _selectedMealIndex = 1; // Akşam yemeği
        } else {
          _selectedMealIndex = 0; // Kahvaltı
        }
      });
    }
  }

  void _onMealTypeChanged(int index) async {
    HapticFeedback.lightImpact();
    final provider = Provider.of<MenuProvider>(context, listen: false);
    provider.setSelectedMealIndex(index);
    
    // 3. tıklamadan itibaren reklam göster
    if (await AdManager.shouldShowAdOnMealSwitch()) {
      await AdService.showInterstitialAd();
      await AdManager.recordAdShown();
    }
    
    if (mounted) {
      setState(() {
        _opacity = 0.5;
        _selectedMealIndex = index;
      });
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _opacity = 1.0);
        }
      });
    }
  }

  bool _hasSelectedDateData(MenuProvider provider, String selectedMealType) {
    return provider.menus.any((menu) =>
        AppConfig.apiDateFormat.format(menu.date) == AppConfig.apiDateFormat.format(_selectedDate) &&
        menu.mealType == selectedMealType);
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

  Future<void> _launchWebsite() async {
    const String urlString = 'https://yurttaye.onrender.com/';
    final Uri url = Uri.parse(urlString);
    try {
      bool canLaunch = await canLaunchUrl(url);

      bool launched = false;
      if (!kIsWeb && canLaunch) {
        launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched) {
        if (kIsWeb || canLaunch) {
          launched = await launchUrl(
            url,
            mode: LaunchMode.platformDefault,
          );
        } else {
          throw 'No browser available to launch $urlString';
        }
      }

      if (!launched) {
        throw 'Failed to launch $urlString';
      }
    } catch (e) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${Localization.getCurrentText('website_error', languageProvider.currentLanguageCode)}: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _launchEmail() async {
    const String email = 'bulutsoftdev@gmail.com';
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final languageCode = languageProvider.currentLanguageCode;
    
    final String subject = Localization.getCurrentText('email_subject', languageCode);
    final String body = '''${Localization.getCurrentText('email_greeting', languageCode)}

${Localization.getCurrentText('email_city', languageCode)} 
${Localization.getCurrentText('email_date', languageCode)} 
${Localization.getCurrentText('email_meal_type', languageCode)} 
${Localization.getCurrentText('email_menu_details', languageCode)}

${Localization.getCurrentText('email_thanks', languageCode)}''';

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
        await Clipboard.setData(const ClipboardData(text: email));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${Localization.getCurrentText('email_copied', languageProvider.currentLanguageCode)}: $email',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Constants.kykPrimary,
              action: SnackBarAction(
                label: Localization.getCurrentText('ok', languageProvider.currentLanguageCode),
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
              '${Localization.getCurrentText('email_error', languageProvider.currentLanguageCode)}: $e',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Constants.kykPrimary,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MenuProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final selectedMealType = AppConfig.mealTypes[_selectedMealIndex];
    final hasSelectedDateData = _hasSelectedDateData(provider, selectedMealType);
    final mealTypeConstant = _getMealTypeConstant(selectedMealType);

    return Scaffold(
      extendBody: true,
      appBar: _buildAppBar(themeProvider, languageProvider, mealTypeConstant),
      body: _buildBody(provider, selectedMealType, hasSelectedDateData, mealTypeConstant, languageProvider),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedMealIndex: _selectedMealIndex,
        onMealTypeChanged: _onMealTypeChanged,
        pulseController: _pulseController,
        pulseAnimation: _pulseAnimation,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeProvider themeProvider, LanguageProvider languageProvider, String mealTypeConstant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight + statusBarHeight),
      child: Container(
        color: isDark ? Constants.kykPrimary : Constants.kykPrimary,
        padding: EdgeInsets.only(top: statusBarHeight),
        child: Container(
          height: kToolbarHeight,
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sol taraftaki butonlar (Web sitesi ve Dil değiştir)
            Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Constants.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  tooltip: Localization.getCurrentText('website_visit', languageProvider.currentLanguageCode),
                  onPressed: _launchWebsite,
                  splashRadius: 24,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Constants.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.translate,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  tooltip: Localization.getCurrentText('change_language', languageProvider.currentLanguageCode),
                  onPressed: () {
                    _showLanguageSelector(context, languageProvider);
                  },
                  splashRadius: 24,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            // Ortada başlık
            Expanded(
              child: Center(
                child: Text(
                  Localization.getCurrentText('app_title', languageProvider.currentLanguageCode),
                  style: GoogleFonts.inter(
                    fontSize: Constants.textXl,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Sağ taraftaki butonlar (Tema ve Filtre)
            Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Constants.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      themeProvider.isDarkMode ? Icons.brightness_7 : Icons.brightness_4,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  tooltip: themeProvider.isDarkMode 
                    ? Localization.getCurrentText('light_theme_tooltip', languageProvider.currentLanguageCode)
                    : Localization.getCurrentText('dark_theme_tooltip', languageProvider.currentLanguageCode),
                  onPressed: () {
                    themeProvider.toggleTheme();
                    AppLogger.debug('Theme toggled: ${themeProvider.isDarkMode ? 'Dark' : 'Light'}');
                  },
                  splashRadius: 24,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Constants.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  tooltip: Localization.getCurrentText('filter', languageProvider.currentLanguageCode),
                  onPressed: () => context.pushNamed('filter'),
                  splashRadius: 24,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildBody(MenuProvider provider, String selectedMealType, bool hasSelectedDateData, String mealTypeConstant, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.05),
                  Constants.kykGray900,
                ]
              : [
                  AppTheme.getMealTypePrimaryColor(mealTypeConstant).withOpacity(0.1),
                  Constants.white,
                ],
        ),
      ),
      child: provider.isLoading && provider.menus.isEmpty && provider.allMenus.isEmpty
          ? const ShimmerLoading()
          : provider.error != null && provider.menus.isEmpty && provider.allMenus.isEmpty
              ? AppErrorWidget(
                  error: provider.error!,
                  onRetry: () {
                    provider.fetchMenus(reset: true);
                  },
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await provider.fetchMenus(reset: true);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: 60.0 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateSelector(provider, selectedMealType),
                            _buildMainContent(provider, selectedMealType, hasSelectedDateData, mealTypeConstant, languageProvider),
                            const SizedBox(height: Constants.space6),
                            // Banner Reklam - Her zaman görünür
                            const Center(child: BannerAdWidget()),
                            const SizedBox(height: Constants.space4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildDateSelector(MenuProvider provider, String selectedMealType) {
    return DateSelector(
      selectedDate: _selectedDate,
      mealType: _getMealTypeConstant(selectedMealType),
      onDateChanged: (date) {
        setState(() {
          _selectedDate = date;
        });
        final provider = Provider.of<MenuProvider>(context, listen: false);
        final dateStr = AppConfig.apiDateFormat.format(date);
        
        // Sync date with provider without forcing a fetch yet
        provider.setDateFilter(dateStr);
        
        // Check if we have data for this date after filter application
        if (provider.menus.isEmpty) {
          // If no data, fetch from API. 
          // The provider's updated _selectedDate will ensure we fetch past data if needed.
          provider.fetchMenus(reset: false);
        }
      },
    );
  }

  Widget _buildMainContent(MenuProvider provider, String selectedMealType, bool hasSelectedDateData, String mealTypeConstant, LanguageProvider languageProvider) {
    if (!hasSelectedDateData) {
      return Container(
        width: double.infinity,
        child: EmptyStateWidget(
          selectedDate: _selectedDate,
          onEmailPressed: _launchEmail,
          onRefreshPressed: () {
            final provider = Provider.of<MenuProvider>(context, listen: false);
            provider.fetchMenus(reset: true);
          },
        ),
      );
    }

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodayMealCard(provider, selectedMealType),
          const SizedBox(height: 16),
          const MealScheduleCard(),
          const SizedBox(height: 16),
          _buildWeeklyMealsSection(provider, mealTypeConstant, languageProvider),
        ],
      ),
    );
  }

  Widget _buildTodayMealCard(MenuProvider provider, String selectedMealType) {
    final selectedDate = AppConfig.apiDateFormat.format(_selectedDate);
    final menu = provider.menus.firstWhere(
      (menu) =>
          AppConfig.apiDateFormat.format(menu.date) == selectedDate && menu.mealType == selectedMealType,
      orElse: () => Menu(
        id: 0,
        cityId: 0,
        mealType: selectedMealType,
        date: _selectedDate,
        energy: '',
        items: [],
      ),
    );

    // Return empty state if menu not found
    if (menu.id == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Constants.space4,
          vertical: Constants.space2,
        ),
        child: const SizedBox.shrink(),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Constants.space4,
        vertical: Constants.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Constants.space3),
          AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 300),
            child: MealCard(menu: menu),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyMealsSection(MenuProvider provider, String mealTypeConstant, LanguageProvider languageProvider) {
    // Seçili öğün türüne göre gelecek menüleri filtrele
    final selectedMealType = AppConfig.mealTypes[_selectedMealIndex];
    final upcomingMenus = provider.allMenus
        .where((menu) =>
            menu.date.isAfter(_selectedDate) && menu.mealType == selectedMealType)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Remove duplicates based on date and meal type
    final uniqueUpcomingMenus = <Menu>[];
    final seenDates = <String>{};
    
    for (final menu in upcomingMenus) {
      final dateKey = '${AppConfig.apiDateFormat.format(menu.date)}_${menu.mealType}';
      if (!seenDates.contains(dateKey)) {
        seenDates.add(dateKey);
        uniqueUpcomingMenus.add(menu);
      }
    }

    // Sadece 7 günlük menüyü al
    final limitedUpcomingMenus = uniqueUpcomingMenus.take(7).toList();

    // Loading durumu
    if (provider.isLoading && provider.allMenus.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Boş durum
    if (limitedUpcomingMenus.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: Constants.textBase,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: Constants.space2),
            Expanded(
              child: Text(
                Localization.getCurrentText('upcoming_meals_not_found', languageProvider.currentLanguageCode),
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Menü kartları
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  Localization.getCurrentText('upcoming_meals_title', languageProvider.currentLanguageCode),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Constants.white 
                        : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: Constants.textBase,
                color: AppTheme.getMealTypePrimaryColor(mealTypeConstant),
              ),
            ],
          ),
        ),
        const SizedBox(height: Constants.space3),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: limitedUpcomingMenus.length,
            itemBuilder: (context, index) {
              final menu = limitedUpcomingMenus[index];
              return Container(
                width: 300,
                margin: const EdgeInsets.only(right: 12),
                child: UpcomingMealCard(
                  menu: menu,
                  onTap: () => context.pushNamed(
                    'menu_detail',
                    pathParameters: {'id': menu.id.toString()},
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLanguageSelector(BuildContext context, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Constants.kykGray800 : Constants.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Constants.kykGray600 : Constants.kykGray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                Localization.getCurrentText('select_language', languageProvider.currentLanguageCode),
                style: GoogleFonts.inter(
                  fontSize: Constants.textLg,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Constants.kykGray200 : Constants.kykGray800,
                ),
              ),
            ),
            ...languageProvider.supportedLanguages.map((language) {
              final isSelected = language['code'] == languageProvider.currentLanguageCode;
              return ListTile(
                leading: Text(
                  language['flag']!,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  language['name']!,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Constants.kykGray200 : Constants.kykGray800,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Constants.kykPrimary,
                        size: 24,
                      )
                    : null,
                onTap: () {
                  languageProvider.changeLanguage(language['code']!);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}