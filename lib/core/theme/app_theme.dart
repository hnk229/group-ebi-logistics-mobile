import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'typography.dart';

/// Thème global EBI : palette + typo + composants Material 3.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: EbiColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: EbiColors.blue,
        primary: EbiColors.blue,
        onPrimary: EbiColors.white,
        secondary: EbiColors.blueDark,
        surface: EbiColors.white,
        onSurface: EbiColors.ink,
        error: EbiColors.danger,
        onError: EbiColors.white,
        outline: EbiColors.border,
      ),
      textTheme: EbiTypography.buildTextTheme(),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: EbiColors.white,
        foregroundColor: EbiColors.ink,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: EbiColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: EbiColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EbiColors.blue,
          foregroundColor: EbiColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600, color: EbiColors.white,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EbiColors.ink,
          side: const BorderSide(color: EbiColors.border),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EbiColors.blueDark,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EbiColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: EbiColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: EbiColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: EbiColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: EbiColors.danger),
        ),
        labelStyle: base.textTheme.labelMedium,
        hintStyle: base.textTheme.bodyMedium?.copyWith(color: EbiColors.ink3),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: EbiColors.white,
        selectedItemColor: EbiColors.blue,
        unselectedItemColor: EbiColors.ink3,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),

      dividerTheme: const DividerThemeData(
        color: EbiColors.border, thickness: 1, space: 1,
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: EbiColors.ink,
        contentTextStyle: TextStyle(color: EbiColors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
