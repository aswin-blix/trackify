import 'package:flutter/material.dart';

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
