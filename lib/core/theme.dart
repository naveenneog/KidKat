import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KidKat brand palette and Material theme. Bright, rounded and friendly.
class KidColors {
  static const Color purple = Color(0xFF7C4DFF);
  static const Color blue = Color(0xFF5C7CFA);
  static const Color sky = Color(0xFF19C8FF);
  static const Color orange = Color(0xFFFF9A2E);
  static const Color sunny = Color(0xFFFFD23F);
  static const Color ink = Color(0xFF2D2150);
  static const Color bg = Color(0xFFF6F3FF);
  static const Color pink = Color(0xFFFF6FA5);
  static const Color green = Color(0xFF2EC4A6);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, blue, sky],
  );
}

ThemeData buildKidKatTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: KidColors.purple,
      primary: KidColors.purple,
      secondary: KidColors.orange,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: KidColors.bg,
    useMaterial3: true,
  );

  final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.baloo2(
      textStyle: base.textTheme.displayLarge,
      fontWeight: FontWeight.w800,
      color: KidColors.ink,
    ),
    headlineMedium: GoogleFonts.baloo2(
      fontWeight: FontWeight.w800,
      color: KidColors.ink,
    ),
    titleLarge: GoogleFonts.baloo2(
      fontWeight: FontWeight.w700,
      color: KidColors.ink,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: KidColors.ink,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KidColors.purple,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.baloo2(fontSize: 20, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        elevation: 4,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
