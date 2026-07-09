import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium, opinionated minimal dark theme for Phantom.
///
/// Design system inspired by Linear, Arc, and Things 3.
/// Features a rich graphite charcoal base, sharp geometric borders,
/// a single strategic ice-blue accent, and custom tabular figures
/// for numerical data tracking.
class AppTheme {
  AppTheme._();

  // ─── Color Palette ───────────────────────────────────────────────────

  static const Color _scaffoldBackground = Color(0xFF0B0C0E); // Graphite Base
  static const Color _surface = Color(0xFF121316);            // Dark Slate Card
  static const Color _surfaceVariant = Color(0xFF18191D);     // Subtle Layering
  static const Color _border = Color(0xFF202226);             // Crisp Border Line
  
  static const Color _primary = Color(0xFF38BDF8);            // Ice Blue Accent
  static const Color _primaryContainer = Color(0xFF0F2D4A);   // Deep Ice Blue
  static const Color _onPrimary = Color(0xFF0B0C0E);          // Contrast Dark On Light
  
  static const Color _secondary = Color(0xFF475569);          // Muted Slate Gray
  static const Color _onSurface = Color(0xFFF1F5F9);          // Off-White Primary
  static const Color _onSurfaceVariant = Color(0xFF94A3B8);   // Muted Slate Gray
  static const Color _error = Color(0xFFF87171);              // Soft Alert Coral

  // ─── Status Colors & Indicators ──────────────────────────────────────

  /// Emerald green — On Track
  static const Color onTrack = Color(0xFF34D399);

  /// Amber orange — Behind
  static const Color behind = Color(0xFFF59E0B);

  /// Soft coral red — Falling Off
  static const Color fallingOff = Color(0xFFF87171);

  /// Returns the appropriate status color.
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ontrack':
      case 'on track':
        return onTrack;
      case 'behind':
        return behind;
      case 'fallingoff':
      case 'falling off':
        return fallingOff;
      default:
        return _secondary;
    }
  }

  /// Returns a specific shape indicator icon based on tracking status.
  static IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'ontrack':
      case 'on track':
        return Icons.arrow_upward; // Upwards shape indicator
      case 'behind':
        return Icons.arrow_forward; // Horizontal steady shape
      case 'fallingoff':
      case 'falling off':
        return Icons.arrow_downward; // Downwards alert shape
      default:
        return Icons.remove;
    }
  }

  // ─── Design Tokens ───────────────────────────────────────────────────

  /// Spacing Scale base (e.g. scale * 2 = 8, scale * 3 = 12)
  static const double spacingScale = 4.0;

  /// Card border radius (Things 3 / Linear compact look)
  static const double cardRadius = 8.0;

  /// Button and input fields border radius
  static const double controlRadius = 6.0;

  // ─── Typography ──────────────────────────────────────────────────────

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 56,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.0,
        color: _onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 44,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        color: _onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: _onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: _onSurface,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: _onSurface,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _onSurface,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: _onSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: _onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: _onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: _onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: _onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: _onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: _onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: _onSurfaceVariant,
      ),
    );
  }

  // ─── Theme Data ──────────────────────────────────────────────────────

  /// The application's dark theme.
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme();

    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: _primary,
      primaryContainer: _primaryContainer,
      onPrimary: _onPrimary,
      secondary: _secondary,
      onSecondary: _onSurface,
      surface: _surface,
      surfaceContainerHighest: _surfaceVariant,
      onSurface: _onSurface,
      onSurfaceVariant: _onSurfaceVariant,
      error: _error,
      onError: _onPrimary,
      outline: _border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _scaffoldBackground,
      textTheme: textTheme,

      // ── AppBar ──────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: _scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _onSurface,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: _onSurface, size: 20),
      ),

      // ── Card ────────────────────────────────────────────────────────
      cardTheme: CardTheme(
        color: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: _border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input Decoration ────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: _primary, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: _error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: _error, width: 1.0),
        ),
        hintStyle: const TextStyle(
          color: _secondary,
          fontSize: 13,
        ),
        labelStyle: const TextStyle(color: _onSurfaceVariant, fontSize: 13),
      ),

      // ── ElevatedButton ──────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _onSurface, // Monochromatic default
          foregroundColor: _scaffoldBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Bottom Navigation ───────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surface,
        selectedItemColor: _primary,
        unselectedItemColor: _secondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
      ),

      // ── Divider ─────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: _border,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceVariant,
        selectedColor: _primaryContainer,
        disabledColor: _surfaceVariant,
        labelStyle: textTheme.labelMedium!,
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Dialog ──────────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: _border),
        ),
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius)),
        ),
      ),
    );
  }
}
