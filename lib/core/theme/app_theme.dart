import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs core
  static const Color background = Color(0xFF080808);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceHigh = Color(0xFF1C1C1C);

  // Accent — blanc void
  static const Color primary = Color(0xFFE8E8F0);
  static const Color primaryDeep = Color(0xFF4040FF);
  static const Color primaryDim = Color(0xFF2A2A3A);

  // Feedback
  static const Color correct = Color(0xFF00E676);
  static const Color wrong = Color(0xFFFF1744);
  static const Color hint = Color(0xFFFFAB00);

  // Texte
  static const Color textPrimary = Color(0xFFE8E8F0);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textTertiary = Color(0xFF444458);

  static TextTheme get _textTheme => GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
    headlineLarge: GoogleFonts.inter(
      color: textPrimary,
      fontSize: 32,
      fontWeight: FontWeight.w500,
      letterSpacing: -1,
    ),
    headlineMedium: GoogleFonts.inter(
      color: textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.5,
    ),
    bodyLarge: GoogleFonts.inter(
      color: textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: GoogleFonts.inter(
      color: textSecondary,
      fontSize: 14,
    ),
  );

  static ThemeData get dark => ThemeData(
    fontFamily: GoogleFonts.inter().fontFamily,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      surface: surface,
      error: wrong,
    ),
    textTheme: _textTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: background,
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(2),
          ),
        ),
        elevation: 0,
      ),
    ),
  );

  // Border radius asymétriques
  static const BorderRadius cardRadius = BorderRadius.only(
    topLeft: Radius.circular(2),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(2),
  );

  static const BorderRadius chipRadius = BorderRadius.only(
    topLeft: Radius.circular(0),
    topRight: Radius.circular(10),
    bottomLeft: Radius.circular(10),
    bottomRight: Radius.circular(0),
  );

  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(4),
  );

  static const BorderRadius neutralRadius = BorderRadius.all(
    Radius.circular(6),
  );

  static const BorderRadius squareRadius = BorderRadius.zero;

  static TextStyle inter({
    Color color = textPrimary,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }
}