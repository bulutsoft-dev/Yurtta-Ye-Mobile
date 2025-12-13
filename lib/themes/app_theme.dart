import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yurttaye_mobile/utils/constants.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    primaryColor: Constants.kykPrimary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Constants.kykPrimary,
      brightness: Brightness.light,
      primary: Constants.kykPrimary,
      secondary: Constants.kykSecondary,
      tertiary: Constants.kykAccent,
      surface: Constants.white,
      surfaceContainerHighest: Constants.kykGray50,
      error: Constants.kykError,
      onPrimary: Constants.white,
      onSecondary: Constants.white,
      onSurface: Constants.kykGray800,
    ),
    scaffoldBackgroundColor: Constants.kykGray50,
    textTheme: GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: Constants.text2xl,
          fontWeight: FontWeight.w700,
          color: Constants.kykGray800,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: Constants.textXl,
          fontWeight: FontWeight.w600,
          color: Constants.kykGray800,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: Constants.textLg,
          fontWeight: FontWeight.w600,
          color: Constants.kykGray800,
        ),
        headlineLarge: TextStyle(
          fontSize: Constants.textLg,
          fontWeight: FontWeight.w600,
          color: Constants.kykPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: Constants.textBase,
          fontWeight: FontWeight.w600,
          color: Constants.kykPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: Constants.textBase,
          color: Constants.kykGray800,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: Constants.textSm,
          color: Constants.kykGray600,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: Constants.textXs,
          color: Constants.kykGray500,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontSize: Constants.textSm,
          fontWeight: FontWeight.w500,
          color: Constants.kykPrimary,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: Constants.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Constants.kykGray200,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(
        vertical: Constants.space2,
        horizontal: Constants.space4,
      ),
      shadowColor: Constants.kykGray400.withOpacity(0.1),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Constants.kykPrimary,
        foregroundColor: Constants.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Constants.space4,
          vertical: Constants.space3,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: Constants.textBase,
          fontWeight: FontWeight.w600,
        ),
        elevation: 2,
        shadowColor: Constants.kykPrimary.withOpacity(0.25),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Constants.kykPrimary,
        side: BorderSide(color: Constants.kykPrimary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Constants.space4,
          vertical: Constants.space3,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: Constants.textBase,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Constants.kykGray100,
      selectedColor: Constants.kykAccent,
      checkmarkColor: Constants.white,
      labelStyle: GoogleFonts.inter(
        fontSize: Constants.textSm,
        color: Constants.kykGray800,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Constants.space3,
        vertical: Constants.space2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Constants.kykGray200),
      ),
      elevation: 1,
      pressElevation: 2,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Constants.kykPrimary,
      foregroundColor: Constants.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: Constants.textXl,
        fontWeight: FontWeight.w600,
        color: Constants.white,
        letterSpacing: -0.25,
      ),
      iconTheme: const IconThemeData(
        color: Constants.white,
        size: Constants.textXl,
      ),
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Constants.white,
      selectedItemColor: Constants.kykPrimary,
      unselectedItemColor: Constants.kykGray400,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: Constants.textXs,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: Constants.textXs,
        fontWeight: FontWeight.w500,
      ),
      showUnselectedLabels: true,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    iconTheme: IconThemeData(
      color: Constants.kykGray600,
      size: Constants.textBase,
    ),
    dividerTheme: DividerThemeData(
      color: Constants.kykGray200,
      thickness: 1,
      space: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    primaryColor: Constants.kykSecondary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Constants.kykSecondary,
      brightness: Brightness.dark,
      primary: Constants.kykSecondary,
      secondary: Constants.kykAccent,
      tertiary: Constants.kykSuccess,
      surface: Constants.darkSurface,
      surfaceContainerHighest: Constants.darkBackground,
      error: Constants.kykError,
      onPrimary: Constants.white,
      onSecondary: Constants.darkBackground,
      onSurface: Constants.darkTextPrimary,
    ),
    scaffoldBackgroundColor: Constants.darkBackground,
    textTheme: GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: Constants.text2xl,
          fontWeight: FontWeight.w700,
          color: Constants.white,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: Constants.textXl,
          fontWeight: FontWeight.w600,
          color: Constants.white,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: Constants.textLg,
          fontWeight: FontWeight.w600,
          color: Constants.white,
        ),
        headlineLarge: TextStyle(
          fontSize: Constants.textLg,
          fontWeight: FontWeight.w600,
          color: Constants.kykSecondary,
        ),
        headlineMedium: TextStyle(
          fontSize: Constants.textBase,
          fontWeight: FontWeight.w600,
          color: Constants.kykSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: Constants.textBase,
          color: Constants.white,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: Constants.textSm,
          color: Constants.darkTextSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: Constants.textXs,
          color: Constants.darkTextTertiary,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontSize: Constants.textSm,
          fontWeight: FontWeight.w500,
          color: Constants.kykSecondary,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      color: Constants.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Constants.darkBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(
        vertical: Constants.space2,
        horizontal: Constants.space4,
      ),
      shadowColor: Constants.black.withOpacity(0.3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Constants.kykSecondary,
        foregroundColor: Constants.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Constants.space4,
          vertical: Constants.space3,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: Constants.textBase,
          fontWeight: FontWeight.w600,
        ),
        elevation: 4,
        shadowColor: Constants.kykSecondary.withOpacity(0.4),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Constants.kykSecondary,
        side: BorderSide(color: Constants.kykSecondary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Constants.space4,
          vertical: Constants.space3,
        ),
        textStyle: GoogleFonts.inter(
          fontSize: Constants.textBase,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Constants.darkGray,
      selectedColor: Constants.kykAccent,
      checkmarkColor: Constants.white,
      labelStyle: GoogleFonts.inter(
        fontSize: Constants.textSm,
        color: Constants.darkTextPrimary,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Constants.space3,
        vertical: Constants.space2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Constants.darkBorder),
      ),
      elevation: 2,
      pressElevation: 4,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Constants.darkSurface,
      foregroundColor: Constants.darkTextPrimary,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: Constants.textXl,
        fontWeight: FontWeight.w600,
        color: Constants.darkTextPrimary,
        letterSpacing: -0.25,
      ),
      iconTheme: const IconThemeData(
        color: Constants.darkTextPrimary,
        size: Constants.textXl,
      ),
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Constants.darkSurface,
      selectedItemColor: Constants.kykSecondary,
      unselectedItemColor: Constants.darkTextTertiary,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: Constants.textXs,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: Constants.textXs,
        fontWeight: FontWeight.w500,
      ),
      showUnselectedLabels: true,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    iconTheme: IconThemeData(
      color: Constants.darkTextSecondary,
      size: Constants.textBase,
    ),
    dividerTheme: DividerThemeData(
      color: Constants.darkDivider,
      thickness: 1,
      space: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // Theme-aware custom styles
  static TextStyle mealTitleStyle(BuildContext context) => GoogleFonts.poppins(
    fontSize: Constants.text2xl,
    fontWeight: FontWeight.w700,
    color: Constants.white, // White for gradient background
  );

  static TextStyle mealSubtitleStyle(BuildContext context) => GoogleFonts.poppins(
    fontSize: Constants.textBase,
    fontWeight: FontWeight.w400,
    color: Constants.white.withOpacity(0.9),
  );

  static TextStyle categoryTitleStyle(BuildContext context) => GoogleFonts.poppins(
    fontSize: Constants.textLg,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).brightness == Brightness.dark
        ? Constants.kykYellow400
        : Constants.kykBlue600,
  );

  static BoxDecoration gradientDecoration(BuildContext context) => BoxDecoration(
    gradient: LinearGradient(
      colors: [Constants.kykBlue600, const Color(0xFF0D9488)], // Blue to teal
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.zero, // Square corners
  );

  static BoxDecoration cardHoverDecoration(BuildContext context) => BoxDecoration(
    borderRadius: BorderRadius.zero, // Square corners
    boxShadow: [
      BoxShadow(
        color: Constants.kykYellow400.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.25,
        ),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Yemek türüne özel gradient'ler
  static BoxDecoration getMealTypeGradient(String mealType, {bool isDark = false}) {
    switch (mealType.toLowerCase()) {
      case Constants.breakfastType:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Constants.breakfastGradientStart,
              Constants.breakfastGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case Constants.lunchType:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Constants.lunchGradientStart,
              Constants.lunchGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case Constants.dinnerType:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Constants.dinnerGradientStart,
              Constants.dinnerGradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      default:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Constants.kykBlue600,
              const Color(0xFF0D9488),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }

  // Yemek türüne özel sadece Gradient döndüren fonksiyon
  static LinearGradient getMealTypeLinearGradient(String mealType) {
    switch (mealType.toLowerCase()) {
      case Constants.breakfastType:
        return LinearGradient(
          colors: [
            Constants.breakfastGradientStart,
            Constants.breakfastGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Constants.lunchType:
        return LinearGradient(
          colors: [
            Constants.lunchGradientStart,
            Constants.lunchGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case Constants.dinnerType:
        return LinearGradient(
          colors: [
            Constants.dinnerGradientStart,
            Constants.dinnerGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [
            Constants.kykBlue600,
            const Color(0xFF0D9488),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  // Yemek türüne özel renkler
  static Color getMealTypePrimaryColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case Constants.breakfastType:
        return Constants.breakfastPrimary;
      case Constants.lunchType:
        return Constants.lunchPrimary;
      case Constants.dinnerType:
        return Constants.dinnerPrimary;
      default:
        return Constants.kykPrimary;
    }
  }

  static Color getMealTypeSecondaryColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case Constants.breakfastType:
        return Constants.breakfastSecondary;
      case Constants.lunchType:
        return Constants.lunchSecondary;
      case Constants.dinnerType:
        return Constants.dinnerSecondary;
      default:
        return Constants.kykSecondary;
    }
  }

  static Color getMealTypeAccentColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case Constants.breakfastType:
        return Constants.breakfastAccent;
      case Constants.lunchType:
        return Constants.lunchAccent;
      case Constants.dinnerType:
        return Constants.dinnerAccent;
      default:
        return Constants.kykAccent;
    }
  }

  // Yemek türüne özel metin stilleri
  static TextStyle getMealTypeTitleStyle(String mealType, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.poppins(
      fontSize: Constants.text2xl,
      fontWeight: FontWeight.w700,
      color: Constants.white,
      shadows: [
        Shadow(
          offset: const Offset(0, 2),
          blurRadius: 4,
          color: Colors.black.withOpacity(0.3),
        ),
      ],
    );
  }

  static TextStyle getMealTypeSubtitleStyle(String mealType, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.poppins(
      fontSize: Constants.textBase,
      fontWeight: FontWeight.w400,
      color: Constants.white.withOpacity(0.9),
      shadows: [
        Shadow(
          offset: const Offset(0, 1),
          blurRadius: 2,
          color: Colors.black.withOpacity(0.2),
        ),
      ],
    );
  }

  // Yemek türüne özel kart dekorasyonu
  static BoxDecoration getMealTypeCardDecoration(String mealType, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseDecoration = getMealTypeGradient(mealType, isDark: isDark);
    
    return baseDecoration.copyWith(
      boxShadow: [
        BoxShadow(
          color: getMealTypePrimaryColor(mealType).withOpacity(isDark ? 0.4 : 0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // Yemek türüne özel chip dekorasyonu
  static BoxDecoration getMealTypeChipDecoration(String mealType, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: getMealTypePrimaryColor(mealType).withOpacity(isDark ? 0.2 : 0.1),
      border: Border.all(
        color: getMealTypePrimaryColor(mealType).withOpacity(0.3),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(20),
    );
  }

  // Yemek türüne özel chip metin stili
  static TextStyle getMealTypeChipTextStyle(String mealType, BuildContext context) {
    return GoogleFonts.inter(
      fontSize: Constants.textSm,
      fontWeight: FontWeight.w600,
      color: getMealTypePrimaryColor(mealType),
    );
  }
}