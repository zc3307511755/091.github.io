import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _rose = Color(0xFFE94B78);
  static const _mint = Color(0xFF249C98);
  static const _amber = Color(0xFFF19A48);
  static const _ink = Color(0xFF352D38);
  static const _line = Color(0xFFF1DDE4);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _rose,
      brightness: Brightness.light,
    ).copyWith(
      primary: _rose,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFE1EA),
      onPrimaryContainer: const Color(0xFF552034),
      secondary: _mint,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD7F3EF),
      onSecondaryContainer: const Color(0xFF113E3D),
      tertiary: _amber,
      onTertiary: const Color(0xFF422100),
      tertiaryContainer: const Color(0xFFFFE5C5),
      onTertiaryContainer: const Color(0xFF4B2900),
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFFFF2F6),
      outlineVariant: _line,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFFF9FB),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: _ink,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: _ink,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: _ink,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: _ink),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF665866),
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          color: _ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _line),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFFFDCE7),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? _rose
                : const Color(0xFF8A7B86),
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
                : const Color(0xFF8A7B86),
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
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _rose,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: _rose),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
