import 'package:flutter/material.dart';

/// App-wide constants.
abstract final class AppConfig {
  static const String appName = 'Pondok Ikhwan';
  static const int totalRooms = 19;

  static int paymentDueSoonDays = 30;
  static int bathroomDueDays = 7;
  static int airConDueDays = 180;
  static int maintenanceDueDays = 730;
}

/// App color palette — light mode with light-blue accents.
abstract final class AppColors {
  static const Color primary = Color(0xFF5B9BD5);
  static const Color primaryLight = Color(0xFFDCEEFB);
  static const Color background = Color(0xFFF4F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1B2A38);
  static const Color onSurfaceMuted = Color(0xFF6B7C8C);
  static const Color success = Color(0xFF4CAF7D);
  static const Color warning = Color(0xFFE8A33D);
  static const Color danger = Color(0xFFD95B5B);
}

/// App theme.
abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, color: AppColors.onSurface),
        ),
      ),
    );
  }
}
