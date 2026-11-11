import 'package:flutter/material.dart';
import 'app_fonts.dart';

// ─── Dark Mode Colors ─────────────────────────────────────────────────────────
class DarkColors {
  static const Color backgroundStart = Color(0xFF0A0E21);
  static const Color backgroundEnd = Color(0xFF12172E);
  static const Color accent = Color(0xFF6C63FF);
  static const Color accentSecondary = Color(0xFF00D4FF);
  static const Color incomeGreen = Color(0xFF00E5A0);
  static const Color expenseRed = Color(0xFFFF4D6D);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);
  static const Color glassSurface = Color(0x12FFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color cardSurface = Color(0xFF1A1F3A);
  static const Color divider = Color(0x1AFFFFFF);
  static const Color transferColor = Color(0xFFFFB300);
  static const Color debtColor = Color(0xFF4DA3FF);
  static const Color savedColor = Color(0xFF2DD4BF);
}

// ─── HUD Colors ───────────────────────────────────────────────────────────────
class HudColors {
  // The HUD theme (Settings > Theme > HUD): deep teal ground, cyan lines,
  // amber as the second accent. See lib/shared/widgets/hud.dart.
  static const Color backgroundStart = Color(0xFF041418);
  static const Color backgroundEnd = Color(0xFF06191E);
  static const Color accent = Color(0xFF3FF0FF);
  static const Color accentSecondary = Color(0xFFFFB347);
  static const Color incomeGreen = Color(0xFF4DFFB8);
  static const Color expenseRed = Color(0xFFFF8A9C);
  static const Color textPrimary = Color(0xFFEAFCFF);
  static const Color textSecondary = Color(0xFF8FD3DE);
  static const Color glassSurface = Color(0xFF0A2A30);
  static const Color glassBorder = Color(0xFF14707F);
  static const Color cardSurface = Color(0xFF0A2A30);
  static const Color divider = Color(0x2E3FF0FF);
  static const Color transferColor = Color(0xFFFFD166);
  static const Color debtColor = Color(0xFF7FB8FF);
  static const Color savedColor = Color(0xFFFFB347);

  /// Text and icons on top of the bright accent.
  static const Color onAccent = Color(0xFF04252B);
}

// ─── Light Mode Colors ────────────────────────────────────────────────────────
class LightColors {
  static const Color backgroundStart = Color(0xFFF0F4FF);
  static const Color backgroundEnd = Color(0xFFE8EEFF);
  static const Color accent = Color(0xFF5B52F0);
  static const Color accentSecondary = Color(0xFF3DB8F5);
  static const Color incomeGreen = Color(0xFF00B87C);
  static const Color expenseRed = Color(0xFFE8365D);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0x991A1A2E);
  static const Color glassSurface = Color(0xA6FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color divider = Color(0x1A1A1A2E);
  static const Color transferColor = Color(0xFFFF8C00);
  static const Color debtColor = Color(0xFF0A6FD6);
  static const Color savedColor = Color(0xFF0D7F75);
}

// ─── Category Colors ──────────────────────────────────────────────────────────
class CategoryColors {
  static const Color food = Color(0xFFFF6B6B);
  static const Color transport = Color(0xFF4ECDC4);
  static const Color shopping = Color(0xFFFFE66D);
  static const Color bills = Color(0xFF6C5CE7);
  static const Color entertainment = Color(0xFFFD79A8);
  static const Color health = Color(0xFF00B894);
  static const Color salary = Color(0xFF00CEC9);
  static const Color freelance = Color(0xFF55EFC4);
  static const Color investment = Color(0xFF0984E3);
  static const Color others = Color(0xFF636E72);
}

// ─── Gradient Helpers ─────────────────────────────────────────────────────────
LinearGradient darkBackgroundGradient() => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [DarkColors.backgroundStart, DarkColors.backgroundEnd],
    );

LinearGradient lightBackgroundGradient() => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [LightColors.backgroundStart, LightColors.backgroundEnd],
    );

LinearGradient accentGradientDark() => const LinearGradient(
      colors: [DarkColors.accent, DarkColors.accentSecondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

LinearGradient accentGradientLight() => const LinearGradient(
      colors: [LightColors.accent, LightColors.accentSecondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

/// Bright accents (yellow, mint, teal) wash out on the pale light theme.
/// In light mode this darkens any colour too bright to read as text or an
/// icon on a near-white surface; dark mode and already-dark colours pass
/// through unchanged.
Color legibleOn(Color color, Brightness brightness) {
  if (brightness == Brightness.dark) return color;
  if (color.computeLuminance() < 0.25) return color;
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness * 0.6).clamp(0.0, 0.4))
      .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
      .toColor();
}

/// Background of bottom sheets and dialogs on a dark screen, for whichever
/// dark look is active.
Color get darkSheetColor =>
    AppFonts.hud ? HudColors.backgroundEnd : const Color(0xFF0F1428);
Color get darkDialogColor =>
    AppFonts.hud ? HudColors.cardSurface : const Color(0xFF1A1F3A);
