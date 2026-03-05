import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design spacing constants for consistent layouts.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppTheme {
  // Accent colors
  static const _seedColor = Color(0xFF6C63FF);
  static const _accentCyan = Color(0xFF4DD0E1);

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      secondary: _accentCyan,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      surface: const Color(0xFF0F1118),
      onSurface: const Color(0xFFE8E8EC),
    );

    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFF0F1118),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F1118),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A1B26),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _seedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1A1B26),
        selectedColor: _seedColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: colorScheme.onSurface, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1B26),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _seedColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF141520),
        surfaceTintColor: Colors.transparent,
        indicatorColor: _seedColor.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: _seedColor, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurface.withValues(alpha: 0.5), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _seedColor);
          }
          return GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5));
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.15),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1B26),
        contentTextStyle: GoogleFonts.inter(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _seedColor,
        linearTrackColor: _seedColor.withValues(alpha: 0.15),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
