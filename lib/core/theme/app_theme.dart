import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // ─── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: DarkColors.backgroundStart,
      colorScheme: const ColorScheme.dark(
        primary: DarkColors.accent,
        secondary: DarkColors.accentSecondary,
        surface: DarkColors.cardSurface,
        error: DarkColors.expenseRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DarkColors.textPrimary,
      ),
      textTheme: _buildTextTheme(DarkColors.textPrimary, DarkColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: DarkColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: DarkColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: _buildInputTheme(
        DarkColors.glassSurface,
        DarkColors.glassBorder,
        DarkColors.textPrimary,
        DarkColors.textSecondary,
        DarkColors.accent,
      ),
      dividerTheme: const DividerThemeData(color: DarkColors.divider, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0F1428),
        modalBackgroundColor: Color(0xFF0F1428),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1F3A),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: DarkColors.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: LightColors.backgroundStart,
      colorScheme: const ColorScheme.light(
        primary: LightColors.accent,
        secondary: LightColors.accentSecondary,
        surface: LightColors.cardSurface,
        error: LightColors.expenseRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: LightColors.textPrimary,
      ),
      textTheme: _buildTextTheme(LightColors.textPrimary, LightColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: LightColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: LightColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LightColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: _buildInputTheme(
        LightColors.glassSurface,
        LightColors.glassBorder,
        LightColors.textPrimary,
        LightColors.textSecondary,
        LightColors.accent,
      ),
      dividerTheme: const DividerThemeData(color: LightColors.divider, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFF8FAFF),
        modalBackgroundColor: Color(0xFFF8FAFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.white,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: LightColors.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Shared Text Theme ───────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 57, fontWeight: FontWeight.w700, color: primary),
      displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 45, fontWeight: FontWeight.w700, color: primary),
      displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 36, fontWeight: FontWeight.w700, color: primary),
      headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w700, color: primary),
      headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w600, color: primary),
      titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w700, color: primary),
      titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }

  // ─── Shared Input Theme ──────────────────────────────────────────────────────
  static InputDecorationTheme _buildInputTheme(
    Color fill,
    Color border,
    Color text,
    Color hint,
    Color focus,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: focus, width: 1.8),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(color: hint, fontSize: 14),
      labelStyle: GoogleFonts.plusJakartaSans(color: hint, fontSize: 14),
    );
  }
}
