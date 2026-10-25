import 'package:flutter/material.dart';

abstract final class AppColors {
  static const forest = Color(0xFF214C3D);
  static const deepForest = Color(0xFF17382E);
  static const paper = Color(0xFFF6F1E6);
  static const card = Color(0xFFFFFCF6);
  static const ink = Color(0xFF1E3028);
  static const muted = Color(0xFF53645B);
  static const line = Color(0xFFD8D8C9);
  static const orange = Color(0xFFB84D27);
  static const moss = Color(0xFFDDE7D6);
  static const sky = Color(0xFFDCEBE8);
  static const leaf = Color(0xFF6E925F);
  static const grass = Color(0xFFAABD7B);
  static const soil = Color(0xFFB87952);
  static const sunlight = Color(0xFFEBCB78);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.forest,
    onPrimary: AppColors.card,
    secondary: AppColors.orange,
    onSecondary: AppColors.card,
    tertiary: AppColors.leaf,
    onTertiary: Colors.white,
    error: Color(0xFF9D2F22),
    onError: Colors.white,
    surface: AppColors.card,
    onSurface: AppColors.ink,
    surfaceContainerHighest: AppColors.moss,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.forest, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.moss,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.deepForest : AppColors.muted,
        );
      }),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(color: AppColors.ink, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
    ),
  );
}
