import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text styles that follow the active look.
///
/// The dark theme is the HUD look (Rajdhani body, Orbitron display, Share
/// Tech Mono read-outs); the light theme keeps Plus Jakarta Sans. [hud] is
/// set from the app's root builder on every theme change, before any screen
/// builds, so widgets can ask for a style without a BuildContext.
class AppFonts {
  AppFonts._();

  static bool hud = false;

  /// Body text. Drop-in for `GoogleFonts.plusJakartaSans(...)`.
  static TextStyle body({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    List<Shadow>? shadows,
  }) {
    if (!hud) {
      return GoogleFonts.plusJakartaSans(
        textStyle: textStyle,
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        height: height,
        decoration: decoration,
        decorationColor: decorationColor,
        shadows: shadows,
      );
    }
    // Rajdhani is narrow and light: one size step and one weight step up
    // keeps it as readable as the font it replaces.
    return GoogleFonts.rajdhani(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize == null ? null : fontSize * 1.1,
      fontWeight: _heavier(fontWeight),
      fontStyle: fontStyle,
      letterSpacing: letterSpacing ?? 0.2,
      wordSpacing: wordSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      shadows: shadows,
    );
  }

  static FontWeight _heavier(FontWeight? w) {
    final v = (w ?? FontWeight.w400).value;
    if (v <= 400) return FontWeight.w500;
    if (v <= 500) return FontWeight.w600;
    return FontWeight.w700;
  }

  /// Headings and big numbers.
  static TextStyle display({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double letterSpacing = 1,
  }) =>
      GoogleFonts.orbitron(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// Small spaced uppercase captions ("AVAILABLE TO SPEND").
  static TextStyle label({Color? color, double fontSize = 10}) =>
      GoogleFonts.orbitron(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 2,
      );

  /// Read-outs: timestamps, percentages, codes.
  static TextStyle mono({Color? color, double fontSize = 12}) =>
      GoogleFonts.shareTechMono(fontSize: fontSize, color: color);
}
