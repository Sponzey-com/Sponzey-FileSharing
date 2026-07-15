import 'package:flutter/material.dart';
import 'package:sponzey_file_sharing/app/theme/app_colors.dart';
import 'package:sponzey_file_sharing/app/theme/app_radius.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Noto Sans KR',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.techBlue,
        primary: AppColors.techBlue,
        secondary: AppColors.techCyan,
        surface: AppColors.paper,
      ),
      scaffoldBackgroundColor: AppColors.techBackground,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: AppColors.ink,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.25,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.35,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.6,
          color: AppColors.body,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.57,
          color: AppColors.body,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: AppColors.ink,
        ),
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: const BorderSide(color: AppColors.techBorder),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.borderSoft,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.techInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.techBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.techBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.techBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.paper,
          backgroundColor: AppColors.techBlue,
          disabledForegroundColor: AppColors.techTextMuted,
          disabledBackgroundColor: const Color(0xFFE8EEF6),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.techBorderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.techInput,
        side: const BorderSide(color: AppColors.techBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          AppColors.techTextMuted.withValues(alpha: 0.7),
        ),
        trackColor: const WidgetStatePropertyAll(AppColors.techInput),
        trackBorderColor: const WidgetStatePropertyAll(AppColors.borderSoft),
        radius: const Radius.circular(AppRadius.pill),
        thickness: const WidgetStatePropertyAll(8),
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(true),
      ),
    );
  }
}
