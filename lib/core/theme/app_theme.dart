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
      textTheme:
          _buildTextTheme(DarkColors.textPrimary, DarkColors.textSecondary),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  // ─── HUD Theme ───────────────────────────────────────────────────────────────
  static ThemeData hud() {
    final base = ThemeData.dark();
    const line = BorderSide(color: HudColors.glassBorder, width: 1.2);
    BeveledRectangleBorder cut(double r, [BorderSide side = BorderSide.none]) =>
        BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(r), side: side);
    final buttonText = GoogleFonts.orbitron(
        fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 2);
    return base.copyWith(
      scaffoldBackgroundColor: HudColors.backgroundStart,
      colorScheme: const ColorScheme.dark(
        primary: HudColors.accent,
        secondary: HudColors.accentSecondary,
        surface: HudColors.cardSurface,
        error: HudColors.expenseRed,
        onPrimary: HudColors.onAccent,
        onSecondary: HudColors.onAccent,
        onSurface: HudColors.textPrimary,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(base.textTheme).apply(
        bodyColor: HudColors.textPrimary,
        displayColor: HudColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.orbitron(
          color: HudColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: HudColors.accent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HudColors.accent,
          foregroundColor: HudColors.onAccent,
          disabledBackgroundColor: HudColors.glassBorder,
          shape: cut(8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HudColors.accent,
          textStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HudColors.textPrimary,
          side: line,
          shape: cut(8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: HudColors.accentSecondary,
        foregroundColor: const Color(0xFF2A1500),
        elevation: 0,
        shape: cut(12),
        extendedTextStyle: buttonText,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HudColors.cardSurface,
        selectedColor: HudColors.accent.withValues(alpha: 0.22),
        side: line,
        shape: cut(7),
        showCheckmark: false,
        labelStyle: GoogleFonts.rajdhani(
          color: HudColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: HudColors.accent,
        linearTrackColor: HudColors.divider,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: HudColors.cardSurface,
        shape: cut(8, line),
      ),
      inputDecorationTheme: _buildInputTheme(
        HudColors.glassSurface,
        HudColors.glassBorder,
        HudColors.textPrimary,
        HudColors.textSecondary,
        HudColors.accent,
        hud: true,
      ),
      dividerTheme: const DividerThemeData(color: HudColors.divider, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: HudColors.backgroundEnd,
        modalBackgroundColor: HudColors.backgroundEnd,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: HudColors.cardSurface,
        shape: cut(14, line),
        titleTextStyle: GoogleFonts.orbitron(
          color: HudColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HudColors.cardSurface,
        contentTextStyle: GoogleFonts.rajdhani(
          color: HudColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: cut(8, line),
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
      textTheme:
          _buildTextTheme(LightColors.textPrimary, LightColors.textSecondary),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      dividerTheme:
          const DividerThemeData(color: LightColors.divider, space: 1),
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
    Color focus, {
    bool hud = false,
  }) {
    final radius = BorderRadius.circular(hud ? 3 : 14);
    final hintStyle = hud
        ? GoogleFonts.rajdhani(
            color: hint, fontSize: 15, fontWeight: FontWeight.w600)
        : GoogleFonts.plusJakartaSans(color: hint, fontSize: 14);
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: focus, width: 1.8),
      ),
      hintStyle: hintStyle,
      labelStyle: hintStyle,
    );
  }
}
