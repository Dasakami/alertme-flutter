import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

class AppRadius {
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double full = 999.0;
}

class AppColors {
  static const deepBlue = Color(0xFF1A3DFF);
  static const navyBlack = Color(0xFF0D0D1A);
  static const sosRed = Color(0xFFFF3939);
  static const softCyan = Color(0xFF53D6FF);
  static const darkGrey = Color(0xFF121212);
  static const lightGrey = Color(0xFFF2F2F2);
  static const cardDark = Color(0xFF1A1A1A);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderDark = Color(0xFF2A2A2A);
  static const borderLight = Color(0xFFE5E5E5);
  static const textPrimary = Color(0xFF0D0D1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textPrimaryDark = Color(0xFFF2F2F2);
  static const textSecondaryDark = Color(0xFFB0B0B0);
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightGrey,
  colorScheme: const ColorScheme.light(
    primary: AppColors.deepBlue,
    onPrimary: Colors.white,
    secondary: AppColors.softCyan,
    onSecondary: AppColors.navyBlack,
    error: AppColors.sosRed,
    onError: Colors.white,
    surface: AppColors.cardLight,
    onSurface: AppColors.textPrimary,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: AppColors.cardLight,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: const BorderSide(color: AppColors.borderLight, width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.deepBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.deepBlue,
      side: const BorderSide(color: AppColors.deepBlue, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.deepBlue,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.sosRed, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),
  textTheme: _buildTextTheme(Brightness.light),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkGrey,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.deepBlue,
    onPrimary: Colors.white,
    secondary: AppColors.softCyan,
    onSecondary: AppColors.navyBlack,
    error: AppColors.sosRed,
    onError: Colors.white,
    surface: AppColors.cardDark,
    onSurface: AppColors.textPrimaryDark,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textPrimaryDark,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
      letterSpacing: -0.5,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: AppColors.cardDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: const BorderSide(color: AppColors.borderDark, width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.deepBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.deepBlue,
      side: const BorderSide(color: AppColors.deepBlue, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.softCyan,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.sosRed, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),
  textTheme: _buildTextTheme(Brightness.dark),
);

TextTheme _buildTextTheme(Brightness brightness) {
  final baseColor = brightness == Brightness.light ? AppColors.textPrimary : AppColors.textPrimaryDark;
  final secondaryColor = brightness == Brightness.light ? AppColors.textSecondary : AppColors.textSecondaryDark;

  return TextTheme(
    displayLarge: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w700, color: baseColor, letterSpacing: -1),
    displayMedium: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w700, color: baseColor, letterSpacing: -0.5),
    displaySmall: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600, color: baseColor, letterSpacing: -0.5),
    headlineLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, color: baseColor, letterSpacing: -0.5),
    headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: baseColor, letterSpacing: -0.25),
    headlineSmall: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: baseColor, letterSpacing: 0),
    titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: baseColor, letterSpacing: 0),
    titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: baseColor, letterSpacing: 0.1),
    titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: baseColor, letterSpacing: 0.1),
    bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: baseColor, letterSpacing: 0.15, height: 1.5),
    bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: baseColor, letterSpacing: 0.25, height: 1.5),
    bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondaryColor, letterSpacing: 0.4, height: 1.5),
    labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: baseColor, letterSpacing: 0.1),
    labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryColor, letterSpacing: 0.5),
    labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: secondaryColor, letterSpacing: 0.5),
  );
}
