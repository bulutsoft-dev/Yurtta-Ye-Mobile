import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yurttaye_mobile/providers/language_provider.dart';
import 'package:yurttaye_mobile/providers/theme_provider.dart';
import 'package:yurttaye_mobile/services/notification_service.dart';
import 'package:yurttaye_mobile/services/notification_test.dart';
import 'package:yurttaye_mobile/services/ad_manager.dart';
import 'package:yurttaye_mobile/utils/app_config.dart';
import 'package:yurttaye_mobile/utils/constants.dart';
import 'package:yurttaye_mobile/utils/localization.dart';
import 'package:yurttaye_mobile/widgets/banner_ad_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yurttaye_mobile/providers/menu_provider.dart';
import 'package:yurttaye_mobile/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yurttaye_mobile/screens/ads_screen.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;

  // --- Coin & Ad-Free State ---
  int _coins = 0;
  int _totalCoins = 0;
  DateTime? _adFreeUntil;
  bool _isLoadingCoin = true;
  DateTime? _bannerBlockUntil;
  DateTime? _interstitialBlockUntil;
  DateTime? _appOpenBlockUntil;
  int _adsWatched = 0;
  Timer? _timer;

  static const int coinsRequired = 4; // 4 coin = 1 gün reklamsız
  static const int bannerBlockCost = 2;
  static const int interstitialBlockCost = 4;
  static const int appOpenBlockCost = 1; // 1 coin = 1 gün App Open engelle

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _loadCoinState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {}); // Süreleri güncelle
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    await _notificationService.setNotificationsEnabled(value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _loadCoinState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _coins = prefs.getInt('coins') ?? 0;
      _totalCoins = prefs.getInt('totalCoins') ?? 0;
      final adFreeMillis = prefs.getInt('adFreeUntil');
      _adFreeUntil = adFreeMillis != null ? DateTime.fromMillisecondsSinceEpoch(adFreeMillis) : null;
      final bannerMillis = prefs.getInt('bannerAdBlockUntil');
      _bannerBlockUntil = bannerMillis != null ? DateTime.fromMillisecondsSinceEpoch(bannerMillis) : null;
      final interstitialMillis = prefs.getInt('interstitialAdBlockUntil');
      _interstitialBlockUntil = interstitialMillis != null ? DateTime.fromMillisecondsSinceEpoch(interstitialMillis) : null;
      final appOpenMillis = prefs.getInt('appOpenAdBlockUntil');
      _appOpenBlockUntil = appOpenMillis != null ? DateTime.fromMillisecondsSinceEpoch(appOpenMillis) : null;
      _adsWatched = prefs.getInt('adsWatched') ?? 0;
      _isLoadingCoin = false;
    });
  }

  Future<void> _addCoin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _coins++;
      _totalCoins++;
      _adsWatched++;
    });
    await prefs.setInt('coins', _coins);
    await prefs.setInt('totalCoins', _totalCoins);
    await prefs.setInt('adsWatched', _adsWatched);
  }

  Future<void> _spendCoinsForAdFree() async {
    if (_coins < coinsRequired) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentAdFree = _adFreeUntil != null && _adFreeUntil!.isAfter(now) ? _adFreeUntil! : now;
    final newAdFreeUntil = currentAdFree.add(const Duration(days: 1));
    setState(() {
      _coins -= coinsRequired;
      _adFreeUntil = newAdFreeUntil;
    });
    await prefs.setInt('coins', _coins);
    await prefs.setInt('adFreeUntil', newAdFreeUntil.millisecondsSinceEpoch);
  }

  bool get _isAdFreeActive {
    if (_adFreeUntil == null) return false;
    return _adFreeUntil!.isAfter(DateTime.now());
  }

  String get _adFreeTimeLeft {
    if (!_isAdFreeActive) return '';
    final diff = _adFreeUntil!.difference(DateTime.now());
    return _formatDuration(diff);
  }

  Future<void> _blockBannerAds() async {
    if (_coins < bannerBlockCost) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final current = _bannerBlockUntil != null && _bannerBlockUntil!.isAfter(now) ? _bannerBlockUntil! : now;
    final newUntil = current.add(const Duration(days: 1));
    setState(() {
      _coins -= bannerBlockCost;
      _bannerBlockUntil = newUntil;
    });
    await prefs.setInt('coins', _coins);
    await prefs.setInt('bannerAdBlockUntil', newUntil.millisecondsSinceEpoch);
  }

  Future<void> _blockInterstitialAds() async {
    if (_coins < interstitialBlockCost) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final current = _interstitialBlockUntil != null && _interstitialBlockUntil!.isAfter(now) ? _interstitialBlockUntil! : now;
    final newUntil = current.add(const Duration(days: 1));
    setState(() {
      _coins -= interstitialBlockCost;
      _interstitialBlockUntil = newUntil;
    });
    await prefs.setInt('coins', _coins);
    await prefs.setInt('interstitialAdBlockUntil', newUntil.millisecondsSinceEpoch);
  }

  bool get _isBannerBlocked => _bannerBlockUntil != null && _bannerBlockUntil!.isAfter(DateTime.now());
  bool get _isInterstitialBlocked => _interstitialBlockUntil != null && _interstitialBlockUntil!.isAfter(DateTime.now());
  bool get _isAppOpenBlocked => _appOpenBlockUntil != null && _appOpenBlockUntil!.isAfter(DateTime.now());

  String get _bannerBlockTimeLeft {
    if (!_isBannerBlocked) return '';
    final diff = _bannerBlockUntil!.difference(DateTime.now());
    return _formatDuration(diff);
  }

  String get _interstitialBlockTimeLeft {
    if (!_isInterstitialBlocked) return '';
    final diff = _interstitialBlockUntil!.difference(DateTime.now());
    return _formatDuration(diff);
  }

  String get _appOpenBlockTimeLeft {
    if (!_isAppOpenBlocked) return '';
    final diff = _appOpenBlockUntil!.difference(DateTime.now());
    return _formatDuration(diff);
  }

  String _formatDuration(Duration diff) {
    if (diff.isNegative) return '0 saniye';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days gün');
    if (hours > 0) parts.add('$hours saat');
    if (minutes > 0) parts.add('$minutes dakika');
    if (seconds > 0 || parts.isEmpty) parts.add('$seconds saniye');
    return parts.join(' ');
  }

  Future<void> _resetAdBlocks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adFreeUntil = null;
      _bannerBlockUntil = null;
      _interstitialBlockUntil = null;
      _appOpenBlockUntil = null;
    });
    await prefs.remove('adFreeUntil');
    await prefs.remove('bannerAdBlockUntil');
    await prefs.remove('interstitialAdBlockUntil');
    await prefs.remove('appOpenAdBlockUntil');
  }

  Future<void> _blockAppOpenAds() async {
    if (_coins < appOpenBlockCost) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final current = _appOpenBlockUntil != null && _appOpenBlockUntil!.isAfter(now) ? _appOpenBlockUntil! : now;
    final newUntil = current.add(const Duration(days: 1));
    setState(() {
      _coins -= appOpenBlockCost;
      _appOpenBlockUntil = newUntil;
    });
    await prefs.setInt('coins', _coins);
    await prefs.setInt('appOpenAdBlockUntil', newUntil.millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final languageCode = languageProvider.currentLanguageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Constants.kykGray900 : Constants.kykGray50,
      appBar: _buildAppBar(context, isDark, languageProvider),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Constants.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Uygulama Ayarları (En İşlevsel)
            _buildSectionTitle(context, Localization.getText('app_settings_section', languageCode)),
            const SizedBox(height: Constants.space3),
            _buildSettingsCard(
              context: context,
              isDark: isDark,
              child: Column(
                children: [
                  _buildToggleSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.dark_mode_rounded,
                    title: Localization.getText('dark_mode', languageCode),
                    subtitle: Localization.getText('dark_mode_desc', languageCode),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      HapticFeedback.lightImpact();
                      themeProvider.toggleTheme();
                    },
                  ),
                  const Divider(height: 1),
                  _buildLanguageSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.language_rounded,
                    title: Localization.getText('language_settings', languageCode),
                    subtitle: Localization.getText('language_settings_desc', languageCode),
                    currentLanguage: languageCode,
                    onLanguageChanged: (languageCode) {
                      HapticFeedback.lightImpact();
                      languageProvider.changeLanguage(languageCode);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: Constants.space4),
            // 2. Bildirimler
            _buildSectionTitle(context, Localization.getText('notifications_section', languageCode)),
            const SizedBox(height: Constants.space3),
            _buildSettingsCard(
              context: context,
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.notifications_active_rounded,
                    title: Localization.getText('notification_permission', languageCode),
                    subtitle: Localization.getText('notification_permission_desc', languageCode),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showNotificationPermissionDialog(context, languageProvider);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.notifications_rounded,
                    title: Localization.getText('test_notification', languageCode),
                    subtitle: Localization.getText('test_notification_desc', languageCode),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await _testNotification();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.schedule_rounded,
                    title: Localization.getText('pending_notifications', languageCode),
                    subtitle: Localization.getText('pending_notifications_desc', languageCode),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await _showPendingNotifications();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.refresh_rounded,
                    title: Localization.getText('reschedule_notifications', languageCode),
                    subtitle: Localization.getText('reschedule_notifications_desc', languageCode),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await _rescheduleNotifications();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: Constants.space4),
            // 3. Destek
            _buildSectionTitle(context, Localization.getText('support_section', languageCode)),
            const SizedBox(height: Constants.space3),
            _buildSettingsCard(
              context: context,
              isDark: isDark,
              child: Column(
                children: [
                  // --- DESTEK BUTONLARI ALT ALTA ---
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.favorite_rounded,
                    title: Localization.getText('support_developer', languageCode),
                    subtitle: Localization.getText('support_developer_desc_long', languageCode),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await AdService.showInterstitialAd();
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdsScreen()));
                      _loadCoinState();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.star_rounded,
                    title: Localization.getText('rate_app_title', languageCode),
                    subtitle: Localization.getText('rate_app_desc', languageCode),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _launchGooglePlay();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.share_rounded,
                    title: Localization.getText('share_app', languageCode),
                    subtitle: Localization.getText('share_app_desc', languageCode),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _shareApp();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.coffee_rounded,
                    title: Localization.getText('donate', languageCode),
                    subtitle: Localization.getText('donate_desc', languageCode),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showDonationDialog(context, languageProvider);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: Constants.space4),
            // 4. Reklamlar
            _buildSectionTitle(context, Localization.getText('ads_section', languageCode)),
            const SizedBox(height: Constants.space3),
            _buildSettingsCard(
              context: context,
              isDark: isDark,
              child: Column(
                children: [
                  // --- Reklam İzle, Coin Kazan ---
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.play_circle_fill_rounded,
                    title: Localization.getText('ad_info_watch_ad', languageCode),
                    subtitle: Localization.getText('ad_info_watch_ad_desc', languageCode),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on_rounded, color: Constants.kykPrimary, size: 18),
                        const SizedBox(width: 4),
                        Text('$_coins', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Constants.kykPrimary)),
                      ],
                    ),
                    onTap: _isLoadingCoin ? null : () async {
                      await AdService.showRewardedAd(
                        onRewarded: () async {
                          await _addCoin();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(Localization.getText('ad_info_thanks', languageCode)),
                                backgroundColor: Constants.kykSuccess,
                              ),
                            );
                          }
                        },
                        onClosed: () {},
                      );
                    },
                  ),
                  const Divider(height: 1),
                  // --- Banner Reklamı Engelle ---
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.visibility_off_rounded,
                    title: Localization.getText('ad_info_block_banner', languageCode),
                    subtitle: Localization.getText('ad_info_block_banner_desc', languageCode) + ' ' + (_bannerBlockTimeLeft.isNotEmpty ? _bannerBlockTimeLeft : Localization.getText('ad_info_none', languageCode)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on_rounded, color: _coins >= bannerBlockCost ? Constants.kykPrimary : Constants.kykGray400, size: 18),
                        const SizedBox(width: 4),
                        Text('$bannerBlockCost', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _coins >= bannerBlockCost ? Constants.kykPrimary : Constants.kykGray400)),
                      ],
                    ),
                    onTap: _isLoadingCoin || _coins < bannerBlockCost || _isBannerBlocked ? null : () async {
                      await _blockBannerAds();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(Localization.getText('ad_info_block_banner_success', languageCode)),
                            backgroundColor: Constants.kykSuccess,
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  // --- Geçiş Reklamı Engelle ---
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.block,
                    title: Localization.getText('ad_info_block_interstitial', languageCode),
                    subtitle: Localization.getText('ad_info_block_interstitial_desc', languageCode) + ' ' + (_interstitialBlockTimeLeft.isNotEmpty ? _interstitialBlockTimeLeft : Localization.getText('ad_info_none', languageCode)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on_rounded, color: _coins >= interstitialBlockCost ? Constants.kykPrimary : Constants.kykGray400, size: 18),
                        const SizedBox(width: 4),
                        Text('$interstitialBlockCost', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _coins >= interstitialBlockCost ? Constants.kykPrimary : Constants.kykGray400)),
                      ],
                    ),
                    onTap: _isLoadingCoin || _coins < interstitialBlockCost || _isInterstitialBlocked ? null : () async {
                      await _blockInterstitialAds();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(Localization.getText('ad_info_block_interstitial_success', languageCode)),
                            backgroundColor: Constants.kykSuccess,
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  // --- Açılış Reklamı Engelle ---
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.fullscreen_exit_rounded,
                    title: Localization.getText('ad_info_block_app_open', languageCode),
                    subtitle: Localization.getText('ad_info_block_app_open_desc', languageCode) + ' ' + (_appOpenBlockTimeLeft.isNotEmpty ? _appOpenBlockTimeLeft : Localization.getText('ad_info_none', languageCode)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on_rounded, color: _coins >= appOpenBlockCost ? Constants.kykPrimary : Constants.kykGray400, size: 18),
                        const SizedBox(width: 4),
                        Text('$appOpenBlockCost', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _coins >= appOpenBlockCost ? Constants.kykPrimary : Constants.kykGray400)),
                      ],
                    ),
                    onTap: _isLoadingCoin || _coins < appOpenBlockCost || _isAppOpenBlocked ? null : () async {
                      await _blockAppOpenAds();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(Localization.getText('ad_info_block_app_open_success', languageCode)),
                            backgroundColor: Constants.kykSuccess,
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  // --- Reklam Engelleme Sürelerini Sıfırla ---
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.refresh_rounded,
                    title: Localization.getText('ad_info_reset', languageCode),
                    subtitle: Localization.getText('ad_info_reset_confirm', languageCode),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(Localization.getText('ad_info_reset', languageCode)),
                          content: Text(Localization.getText('ad_info_reset_confirm', languageCode)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(Localization.getText('cancel', languageCode)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(Localization.getText('ad_info_reset', languageCode)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _resetAdBlocks();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(Localization.getText('ad_info_reset_success', languageCode))),
                          );
                        }
                      }
                    },
                  ),
                  // --- Reklam Yönetimi Butonu ---
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.settings_rounded,
                    title: Localization.getText('ad_info_manage_ads', languageCode),
                    subtitle: Localization.getText('ad_info_manage_ads', languageCode),
                    onTap: () async {
                      await AdService.showInterstitialAd();
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdsScreen()));
                      _loadCoinState();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: Constants.space4),
            // 4. Geliştirici
            _buildSectionTitle(context, Localization.getText('developer_section', languageCode)),
            const SizedBox(height: Constants.space3),
            _buildSettingsCard(
              context: context,
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.person_rounded,
                    title: Localization.getText('developer', languageCode),
                    subtitle: AppConfig.developerName,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showDeveloperInfo(context, languageProvider);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.business_rounded,
                    title: Localization.getText('company', languageCode),
                    subtitle: AppConfig.developerCompany,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _launchDeveloperWebsite();
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.email_rounded,
                    title: Localization.getText('contact', languageCode),
                    subtitle: AppConfig.developerEmail,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _launchEmail();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: Constants.space4),
            // 5. Uygulama Bilgileri
            _buildSectionTitle(context, Localization.getText('app_info_section', languageCode)),
            const SizedBox(height: Constants.space3),
            _buildSettingsCard(
              context: context,
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.info_rounded,
                    title: Localization.getText('app_version', languageCode),
                    subtitle: '${AppConfig.appVersion} (${AppConfig.appBuildNumber})',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showVersionInfo(context, languageProvider);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.privacy_tip_rounded,
                    title: Localization.getText('privacy_policy', languageCode),
                    subtitle: Localization.getText('terms_of_use', languageCode),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showPrivacyPolicy(context, languageProvider);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    context: context,
                    isDark: isDark,
                    icon: Icons.bug_report_rounded,
                    title: Localization.getText('report_bug', languageCode),
                    subtitle: Localization.getText('report_issue', languageCode),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _reportBug(context, languageProvider);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: Constants.space6),
            // Banner Reklam
            const Center(child: BannerAdWidget()),
            const SizedBox(height: Constants.space4),
            // Alt bilgi
            Center(
              child: Column(
                children: [
                  Text(
                    '${AppConfig.appName} v${AppConfig.appVersion}',
                    style: GoogleFonts.inter(
                      fontSize: Constants.textSm,
                      color: isDark ? Constants.kykGray400 : Constants.kykGray500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2025 ${AppConfig.developerCompany}',
                    style: GoogleFonts.inter(
                      fontSize: Constants.textXs,
                      color: isDark ? Constants.kykGray500 : Constants.kykGray400,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark, LanguageProvider languageProvider) {
    return AppBar(
      backgroundColor: isDark ? Constants.kykGray800 : Constants.kykPrimary,
      elevation: 0,
      centerTitle: true,
              title: Text(
          Localization.getText('settings', languageProvider.currentLanguageCode),
        style: GoogleFonts.inter(
          fontSize: Constants.textLg,
          fontWeight: FontWeight.w600,
          color: Constants.white,
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Constants.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_back_ios,
            color: Constants.white,
            size: 18,
          ),
        ),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: Constants.textLg,
        fontWeight: FontWeight.w700,
        color: isDark ? Constants.kykGray200 : Constants.kykGray800,
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Constants.kykGray800 : Constants.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Constants.kykGray700 : Constants.kykGray200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Constants.kykGray400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(Constants.space4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.kykPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Constants.kykPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: Constants.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: Constants.textBase,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Constants.kykGray200 : Constants.kykGray800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: Constants.textSm,
                        color: isDark ? Constants.kykGray400 : Constants.kykGray600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (onTap != null && trailing == null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Constants.kykGray400 : Constants.kykGray500,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
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
                  Localization.getText('select_language', languageProvider.currentLanguageCode),
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

  void _showVersionInfo(BuildContext context, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Constants.kykGray800 : Constants.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          Localization.getText('app_info', languageProvider.currentLanguageCode),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Constants.kykGray200 : Constants.kykGray800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Localization.getText('name', languageProvider.currentLanguageCode), AppConfig.appName),
            _buildInfoRow(Localization.getText('version', languageProvider.currentLanguageCode), AppConfig.appVersion),
            _buildInfoRow(Localization.getText('build', languageProvider.currentLanguageCode), AppConfig.appBuildNumber),
            _buildInfoRow(Localization.getText('developer', languageProvider.currentLanguageCode), AppConfig.developerName),
            _buildInfoRow(Localization.getText('platform', languageProvider.currentLanguageCode), 'Flutter'),
            _buildInfoRow(Localization.getText('license', languageProvider.currentLanguageCode), 'MIT'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tamam',
              style: GoogleFonts.inter(
                color: Constants.kykPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: Constants.textSm,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: Constants.textSm,
              fontWeight: FontWeight.w600,
              color: Constants.kykPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Constants.kykGray800 : Constants.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          Localization.getText('privacy_policy', languageProvider.currentLanguageCode),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Constants.kykGray200 : Constants.kykGray800,
          ),
        ),
        content: Text(
          'YurttaYe uygulaması, kullanıcı gizliliğinizi korumaya önem verir. Kişisel verileriniz güvenli bir şekilde saklanır ve üçüncü taraflarla paylaşılmaz.',
          style: GoogleFonts.inter(
            fontSize: Constants.textSm,
            color: isDark ? Constants.kykGray300 : Constants.kykGray700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              Localization.getText('understood', languageProvider.currentLanguageCode),
              style: GoogleFonts.inter(
                color: Constants.kykPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeveloperInfo(BuildContext context, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Constants.kykGray800 : Constants.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          Localization.getText('developer_info', languageProvider.currentLanguageCode),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Constants.kykGray200 : Constants.kykGray800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Localization.getText('name', languageProvider.currentLanguageCode), AppConfig.developerName),
            _buildInfoRow(Localization.getText('company', languageProvider.currentLanguageCode), AppConfig.developerCompany),
            _buildInfoRow(Localization.getText('email', languageProvider.currentLanguageCode), AppConfig.developerEmail),
            _buildInfoRow('Website', 'yurttaye.onrender.com'),
            _buildInfoRow('GitHub', 'github.com/bulutsoft-dev'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tamam',
              style: GoogleFonts.inter(
                color: Constants.kykPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWebsite() async {
    if (await canLaunchUrl(Uri.parse(AppConfig.websiteUrl))) {
      await launchUrl(Uri.parse(AppConfig.websiteUrl));
    }
  }

  Future<void> _launchGitHub() async {
    if (await canLaunchUrl(Uri.parse(AppConfig.githubUrl))) {
      await launchUrl(Uri.parse(AppConfig.githubUrl));
    }
  }

  Future<void> _launchGooglePlay() async {
    if (await canLaunchUrl(Uri.parse(AppConfig.googlePlayUrl))) {
      await launchUrl(Uri.parse(AppConfig.googlePlayUrl));
    }
  }

  Future<void> _launchDeveloperWebsite() async {
    if (await canLaunchUrl(Uri.parse(AppConfig.websiteUrl))) {
      await launchUrl(Uri.parse(AppConfig.websiteUrl));
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: AppConfig.developerEmail,
      query: 'subject=YurttaYe Uygulama Desteği',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _reportBug(BuildContext context, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Constants.kykGray800 : Constants.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hata Bildir',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Constants.kykGray200 : Constants.kykGray800,
          ),
        ),
        content: Text(
          'Hata bildirimi için GitHub üzerinden issue açabilir veya e-posta gönderebilirsiniz.',
          style: GoogleFonts.inter(
            fontSize: Constants.textSm,
            color: isDark ? Constants.kykGray300 : Constants.kykGray700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'İptal',
              style: GoogleFonts.inter(
                color: isDark ? Constants.kykGray400 : Constants.kykGray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchGitHub();
            },
            child: Text(
              'GitHub',
              style: GoogleFonts.inter(
                color: Constants.kykPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchEmail();
            },
            child: Text(
              'E-posta',
              style: GoogleFonts.inter(
                color: Constants.kykPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareApp() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final languageCode = languageProvider.currentLanguageCode;
    final String shareText = '${Localization.getText('share_text', languageCode)} ${AppConfig.googlePlayUrl}';
    
    try {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Localization.getText('share_copied', languageCode)),
            backgroundColor: Constants.kykPrimary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Localization.getText('share_copy_error', languageCode)} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDonationDialog(BuildContext context, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = languageProvider.currentLanguageCode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Constants.kykGray800 : Constants.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          Localization.getText('donation_title', languageCode),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Constants.kykGray200 : Constants.kykGray800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Localization.getText('donation_desc', languageCode),
              style: GoogleFonts.inter(
                fontSize: Constants.textSm,
                color: isDark ? Constants.kykGray300 : Constants.kykGray700,
              ),
            ),
            const SizedBox(height: 12),
            _buildDonationOption(
              context,
              isDark,
              Localization.getText('coffee_donation', languageCode),
              Localization.getText('coffee_amount', languageCode),
              () => _launchDonation(5),
            ),
            const SizedBox(height: 8),
            _buildDonationOption(
              context,
              isDark,
              Localization.getText('pizza_donation', languageCode),
              Localization.getText('pizza_amount', languageCode),
              () => _launchDonation(25),
            ),
            const SizedBox(height: 8),
            _buildDonationOption(
              context,
              isDark,
              Localization.getText('special_donation', languageCode),
              Localization.getText('special_amount', languageCode),
              () => _launchDonation(50),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              Localization.getText('cancel', languageCode),
              style: GoogleFonts.inter(
                color: isDark ? Constants.kykGray400 : Constants.kykGray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationOption(BuildContext context, bool isDark, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Constants.kykGray700 : Constants.kykGray100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Constants.kykGray600 : Constants.kykGray300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: Constants.textSm,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Constants.kykGray200 : Constants.kykGray800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: Constants.textXs,
                      color: isDark ? Constants.kykGray400 : Constants.kykGray600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Constants.kykGray400 : Constants.kykGray600,
            ),
          ],
        ),
      ),
    );
  }

  void _launchDonation(int amount) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final languageCode = languageProvider.currentLanguageCode;
    Navigator.of(context).pop();
    await AdService.showRewardedAd(
      onRewarded: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
            content: Text(Localization.getText('thank_you_for_support', languageCode)),
            backgroundColor: Constants.kykSuccess,
      ),
        );
      },
      onClosed: () {
        // Reklam kapatıldı ama ödül kazanılmadıysa istersen burada başka bir mesaj gösterebilirsin.
      },
    );
  }

  Future<void> _testNotification() async {
    try {
      await _notificationService.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test bildirimi gönderildi!'),
            backgroundColor: Constants.kykSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test bildirimi gönderilemedi: $e'),
            backgroundColor: Constants.kykError,
          ),
        );
      }
    }
  }

  Future<void> _showPendingNotifications() async {
    try {
      final pendingNotifications = await _notificationService.getPendingNotifications();
      
      if (!mounted) return;
      
      final languageCode = Provider.of<LanguageProvider>(context, listen: false).currentLanguageCode;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? Constants.kykGray800 : Constants.white,
          title: Text(
            Localization.getText('pending_notifications', languageCode),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isDark ? Constants.kykGray200 : Constants.kykGray800,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: pendingNotifications.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off_rounded,
                        size: 48,
                        color: isDark ? Constants.kykGray400 : Constants.kykGray500,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Localization.getText('no_pending_notifications', languageCode),
                        style: GoogleFonts.inter(
                          fontSize: Constants.textBase,
                          color: isDark ? Constants.kykGray400 : Constants.kykGray600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: pendingNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = pendingNotifications[index];
                      return ListTile(
                        leading: Icon(
                          Icons.notifications_rounded,
                          color: Constants.kykPrimary,
                        ),
                        title: Text(
                          notification.title ?? 'Bildirim',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Constants.kykGray200 : Constants.kykGray800,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${notification.id}',
                          style: GoogleFonts.inter(
                            fontSize: Constants.textSm,
                            color: isDark ? Constants.kykGray400 : Constants.kykGray600,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                Localization.getText('close', languageCode),
                style: GoogleFonts.inter(
                  color: Constants.kykPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirimler getirilemedi: $e'),
            backgroundColor: Constants.kykError,
          ),
        );
      }
    }
  }

  Future<void> _rescheduleNotifications() async {
    try {
      // Menü provider'dan menüleri al
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      final menus = menuProvider.menus;
      
      if (menus.isEmpty) {
        // Eğer menü yoksa API'den çek
        await menuProvider.fetchMenus();
      }
      
      await _notificationService.rescheduleNotifications(menuProvider.menus);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirimler yeniden planlandı!'),
            backgroundColor: Constants.kykSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirimler yeniden planlanamadı: $e'),
            backgroundColor: Constants.kykError,
          ),
        );
      }
    }
  }

  void _showNotificationPermissionDialog(BuildContext context, LanguageProvider languageProvider) {
    final languageCode = languageProvider.currentLanguageCode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Localization.getText('notification_permission', languageCode)),
        content: Text(Localization.getText('notification_permission_dialog', languageCode)),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: Text(Localization.getText('allow', languageCode)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Localization.getText('later', languageCode)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSettingsItem({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(Constants.space4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.kykPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Constants.kykPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: Constants.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: Constants.textBase,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Constants.kykGray200 : Constants.kykGray800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: Constants.textSm,
                        color: isDark ? Constants.kykGray400 : Constants.kykGray600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Constants.kykPrimary,
                activeTrackColor: Constants.kykPrimary.withOpacity(0.3),
                inactiveThumbColor: isDark ? Constants.kykGray400 : Constants.kykGray300,
                inactiveTrackColor: isDark ? Constants.kykGray600 : Constants.kykGray200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSettingsItem({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String currentLanguage,
    required ValueChanged<String> onLanguageChanged,
  }) {
    final languageName = currentLanguage == 'tr' 
        ? Localization.getText('turkish', currentLanguage)
        : Localization.getText('english', currentLanguage);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLanguageSelector(context, Provider.of<LanguageProvider>(context, listen: false)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(Constants.space4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.kykPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Constants.kykPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: Constants.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: Constants.textBase,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Constants.kykGray200 : Constants.kykGray800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: Constants.textSm,
                        color: isDark ? Constants.kykGray400 : Constants.kykGray600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    languageName,
                    style: GoogleFonts.inter(
                      fontSize: Constants.textSm,
                      fontWeight: FontWeight.w500,
                      color: Constants.kykPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Constants.kykGray400 : Constants.kykGray500,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 

class AdInfoScreen extends StatelessWidget {
  const AdInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final languageCode = languageProvider.currentLanguageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Constants.kykGray800 : Constants.kykPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          Localization.getText('ad_info_title', languageCode),
          style: GoogleFonts.inter(
            fontSize: Constants.textLg,
            fontWeight: FontWeight.w600,
            color: Constants.white,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Constants.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Constants.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(Constants.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.campaign_rounded, color: Constants.kykPrimary, size: 64),
            const SizedBox(height: 16),
            Text(
              Localization.getText('ad_info_heading', languageCode),
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Constants.kykGray100 : Constants.kykGray900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              Localization.getText('ad_info_desc', languageCode),
              style: GoogleFonts.inter(fontSize: 16, color: isDark ? Constants.kykGray300 : Constants.kykGray700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.kykPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 28),
              label: Text(Localization.getText('ad_info_watch_button', languageCode)),
              onPressed: () async {
                await AdService.showInterstitialAd();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Localization.getText('thank_you_for_support', languageCode)),
                      backgroundColor: Constants.kykSuccess,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            Text(
              Localization.getText('ad_info_note', languageCode),
              style: GoogleFonts.inter(fontSize: 14, color: isDark ? Constants.kykGray400 : Constants.kykGray600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 