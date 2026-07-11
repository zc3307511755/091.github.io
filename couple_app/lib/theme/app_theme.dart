import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _rose = Color(0xFFBA0034);
  static const _mint = Color(0xFF00694B);
  static const _amber = Color(0xFFFF9F0A);
  static const _ink = Color(0xFF1A1B1F);
  static const _line = Color(0xFFE5E2E7);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _rose,
      brightness: Brightness.light,
    ).copyWith(
      primary: _rose,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFDADA),
      onPrimaryContainer: const Color(0xFF40000C),
      secondary: _mint,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDDF6FA),
      onSecondaryContainer: const Color(0xFF0A3D46),
      tertiary: _amber,
      onTertiary: const Color(0xFF422100),
      tertiaryContainer: const Color(0xFFFFEFD5),
      onTertiaryContainer: const Color(0xFF4B2900),
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFE3E2E7),
      outlineVariant: _line,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFAF9FE),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          color: _ink,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: _ink,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: _ink,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: _ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: _ink),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF5D3F40),
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          color: _ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xF7FAF9FE),
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? _rose
                : const Color(0xFF9B8D91),
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? _rose
                : const Color(0xFF9B8D91),
            size: 22,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _rose, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _rose,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 46),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _rose,
          minimumSize: const Size(64, 46),
          side: const BorderSide(color: _rose),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: _line,
        thickness: 0.5,
        space: 1,
      ),
    );
  }
}
