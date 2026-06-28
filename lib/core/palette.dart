import 'package:flutter/material.dart';

/// Selectable color themes for KidKat.
enum ThemeId { defaultPurple, candyBright, ocean, sunset, forest }

/// A complete color palette + brand gradient for a theme.
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.ink,
    required this.bg,
    required this.gradient,
  });

  final ThemeId id;
  final String name;
  final String emoji;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color ink;
  final Color bg;
  final List<Color> gradient;

  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient,
      );
}

const Map<ThemeId, AppPalette> kPalettes = {
  ThemeId.defaultPurple: AppPalette(
    id: ThemeId.defaultPurple,
    name: 'Purple Pop',
    emoji: '💜',
    primary: Color(0xFF7C4DFF),
    secondary: Color(0xFFFF9A2E),
    accent: Color(0xFFFFD23F),
    ink: Color(0xFF2D2150),
    bg: Color(0xFFF6F3FF),
    gradient: [Color(0xFF7C4DFF), Color(0xFF5C7CFA), Color(0xFF19C8FF)],
  ),
  ThemeId.candyBright: AppPalette(
    id: ThemeId.candyBright,
    name: 'Candy Bright',
    emoji: '🍭',
    primary: Color(0xFFEC4899),
    secondary: Color(0xFF8B5CF6),
    accent: Color(0xFFFBBF24),
    ink: Color(0xFF831843),
    bg: Color(0xFFFDF4FF),
    gradient: [Color(0xFFEC4899), Color(0xFFA855F7), Color(0xFF8B5CF6)],
  ),
  ThemeId.ocean: AppPalette(
    id: ThemeId.ocean,
    name: 'Ocean',
    emoji: '🌊',
    primary: Color(0xFF0EA5E9),
    secondary: Color(0xFF14B8A6),
    accent: Color(0xFFFACC15),
    ink: Color(0xFF0C4A6E),
    bg: Color(0xFFECFEFF),
    gradient: [Color(0xFF0EA5E9), Color(0xFF06B6D4), Color(0xFF14B8A6)],
  ),
  ThemeId.sunset: AppPalette(
    id: ThemeId.sunset,
    name: 'Sunset',
    emoji: '🌅',
    primary: Color(0xFFFB7185),
    secondary: Color(0xFFF97316),
    accent: Color(0xFFFACC15),
    ink: Color(0xFF7C2D12),
    bg: Color(0xFFFFF7ED),
    gradient: [Color(0xFFF97316), Color(0xFFFB7185), Color(0xFFA855F7)],
  ),
  ThemeId.forest: AppPalette(
    id: ThemeId.forest,
    name: 'Forest',
    emoji: '🌳',
    primary: Color(0xFF16A34A),
    secondary: Color(0xFF84CC16),
    accent: Color(0xFFFACC15),
    ink: Color(0xFF14532D),
    bg: Color(0xFFF0FDF4),
    gradient: [Color(0xFF16A34A), Color(0xFF22C55E), Color(0xFF84CC16)],
  ),
};

AppPalette paletteFor(ThemeId id) =>
    kPalettes[id] ?? kPalettes[ThemeId.defaultPurple]!;
