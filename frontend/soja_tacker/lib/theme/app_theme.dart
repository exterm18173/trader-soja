import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightScheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: _lightScheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: _lightScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _lightScheme.outlineVariant),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: _lightScheme.outlineVariant,
        thickness: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _lightScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _lightScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _lightScheme.primary, width: 1.6),
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: _lightScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 10,
        contentPadding: EdgeInsets.symmetric(horizontal: 14),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _lightScheme.surface,
        indicatorColor: _lightScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _lightScheme.inverseSurface,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: _lightScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // Botões modernos
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: _lightScheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkScheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: _darkScheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: _darkScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _darkScheme.outlineVariant),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: _darkScheme.outlineVariant,
        thickness: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _darkScheme.primary, width: 1.6),
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: _darkScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 10,
        contentPadding: EdgeInsets.symmetric(horizontal: 14),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _darkScheme.surface,
        indicatorColor: _darkScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _darkScheme.inverseSurface,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: _darkScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: _darkScheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ColorScheme: Light
  static final ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.seedGreen,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFD7F3EA),
    onPrimaryContainer: const Color(0xFF083A30),

    secondary: AppColors.seedGreen2,
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFCFF4E7),
    onSecondaryContainer: const Color(0xFF083A30),

    tertiary: AppColors.amber,
    onTertiary: const Color(0xFF2B1B00),
    tertiaryContainer: const Color(0xFFFFE7B3),
    onTertiaryContainer: const Color(0xFF2B1B00),

    error: const Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: const Color(0xFFF9DEDC),
    onErrorContainer: const Color(0xFF410E0B),

    surface: AppColors.lightSurface,
    onSurface: AppColors.lightText,
    surfaceContainerLowest: AppColors.lightSurface,
    surfaceContainerLow: const Color(0xFFFAFBFC),
    surfaceContainer: AppColors.lightSurface2,
    surfaceContainerHigh: const Color(0xFFEFF2F6),
    surfaceContainerHighest: const Color(0xFFE9EEF5),

    outline: AppColors.lightBorder,
    outlineVariant: const Color(0xFFD6DCE6),

    shadow: const Color(0x33000000),
    scrim: const Color(0x66000000),

    inverseSurface: const Color(0xFF1B2433),
    onInverseSurface: const Color(0xFFF3F6FB),
    inversePrimary: const Color(0xFF6BE2C0),
  );

  // ColorScheme: Dark
  static final ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF3AD6B0),
    onPrimary: const Color(0xFF052821),
    primaryContainer: const Color(0xFF0E3B31),
    onPrimaryContainer: const Color(0xFFBFF6E7),

    secondary: const Color(0xFF7BE7CA),
    onSecondary: const Color(0xFF052821),
    secondaryContainer: const Color(0xFF103E35),
    onSecondaryContainer: const Color(0xFFBFF6E7),

    tertiary: const Color(0xFFFFD166),
    onTertiary: const Color(0xFF2B1B00),
    tertiaryContainer: const Color(0xFF5A4200),
    onTertiaryContainer: const Color(0xFFFFE7B3),

    error: const Color(0xFFF2B8B5),
    onError: const Color(0xFF601410),
    errorContainer: const Color(0xFF8C1D18),
    onErrorContainer: const Color(0xFFF9DEDC),

    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText,
    surfaceContainerLowest: const Color(0xFF0C121B),
    surfaceContainerLow: AppColors.darkSurface,
    surfaceContainer: AppColors.darkSurface2,
    surfaceContainerHigh: const Color(0xFF1A2536),
    surfaceContainerHighest: const Color(0xFF1F2C40),

    outline: AppColors.darkBorder,
    outlineVariant: const Color(0xFF2F3B52),

    shadow: const Color(0x99000000),
    scrim: const Color(0x99000000),

    inverseSurface: const Color(0xFFE7EEF8),
    onInverseSurface: const Color(0xFF0B1220),
    inversePrimary: const Color(0xFF0F5E4D),
  );
}
