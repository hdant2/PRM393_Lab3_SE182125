import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF7F7F7);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF0F0F0);
  static const border = Color(0xFFE4E4E4);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textTertiary = Color(0xFF999999);
  static const badge = Color(0xFF111111);
  static const error = Color(0xFFB00020);
}

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.light(
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    primary: AppColors.textPrimary,
    onPrimary: Colors.white,
    secondary: AppColors.textSecondary,
    outline: AppColors.border,
    error: AppColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: colorScheme,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.surfaceMuted,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          size: 22,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.2),
      ),
    ),
    dividerColor: AppColors.border,
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.textPrimary
              : AppColors.textSecondary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.surface
              : Colors.transparent;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.border),
        ),
      ),
    ),
  );
}
