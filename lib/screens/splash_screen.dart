import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yurttaye_mobile/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yurttaye_mobile/utils/localization.dart';
import 'package:yurttaye_mobile/services/ad_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    
    // Logo animasyonu
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Text animasyonu
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Progress animasyonu
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo scale ve opacity animasyonları
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    // Text slide ve opacity animasyonları
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));
    
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    // Progress animasyonu
    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // App Open reklamını önceden yükle
    AdService.loadAppOpenAd();

    // Animasyonları başlat
    _startAnimations();
  }

  void _startAnimations() async {
    // Logo animasyonunu başlat
    await _logoController.forward();
    
    // Text animasyonunu başlat
    await _textController.forward();
    
    // Progress animasyonunu başlat
    _progressController.forward();
    
    // 2 saniye bekle
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      // App Open reklamını göster, kapanınca home'a git
      await AdService.showAppOpenAd(
        onAdClosed: () {
          if (mounted) {
            context.goNamed('home');
          }
        },
      );
      
      // Reklam gösterilemezse de home'a git (fallback)
      if (mounted && !AdService.isAppOpenAdLoaded) {
        context.goNamed('home');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Localization
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Constants.kykPrimary,
              Constants.kykSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst boşluk
              const Spacer(flex: 2),
              
              // Logo ve başlık
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: Column(
                        children: [
                          // Logo container
                          Container(
                            padding: const EdgeInsets.all(Constants.space6),
                            decoration: BoxDecoration(
                              color: Constants.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Constants.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              size: Constants.text2xl * 3,
                              color: Constants.white,
                            ),
                          ),
                          const SizedBox(height: Constants.space6),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Uygulama adı
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Column(
                    children: [
                      Text(
                        Localization.getText('app_title', languageCode),
                        style: GoogleFonts.inter(
                          fontSize: Constants.text2xl * 1.5,
                          fontWeight: FontWeight.w700,
                          color: Constants.white,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: Constants.space2),
                      Text(
                        Localization.getText('app_subtitle', languageCode),
                        style: GoogleFonts.inter(
                          fontSize: Constants.textLg,
                          fontWeight: FontWeight.w500,
                          color: Constants.white.withOpacity(0.9),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Progress bar
              Padding(
                padding: const EdgeInsets.all(Constants.space6),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _progressValue,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressValue.value,
                          backgroundColor: Constants.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Constants.kykAccent,
                          ),
                          minHeight: 4,
                        );
                      },
                    ),
                    const SizedBox(height: Constants.space4),
                    Text(
                      Localization.getText('loading_text', languageCode),
                      style: GoogleFonts.inter(
                        fontSize: Constants.textSm,
                        fontWeight: FontWeight.w500,
                        color: Constants.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}