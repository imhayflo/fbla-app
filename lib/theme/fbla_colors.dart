import 'package:flutter/material.dart';

class FblaColors {
  FblaColors._();

  static const Color navy = Color(0xFF003B6F);
  static const Color navyDark = Color(0xFF002447);
  static const Color gold = Color(0xFFFFC72C);
  static const Color goldDeep = Color(0xFFC99700);
  static const Color crimson = Color(0xFFC8102E);
  static const Color paper = Color(0xFFF7F5F0);

  static ColorScheme schemeDefault() {
    return ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: gold,
      tertiary: crimson,
      surface: Colors.white,
      brightness: Brightness.light,
    ).copyWith(
      primaryContainer: const Color(0xFFD4E4F7),
      secondaryContainer: const Color(0xFFFFF3CC),
      tertiaryContainer: const Color(0xFFF8D7DC),
    );
  }

  static ColorScheme schemeColorblindFriendly() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF005A9C),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFCCE4FF),
      onPrimaryContainer: Color(0xFF001E3D),
      secondary: Color(0xFFE69F00),
      onSecondary: Color(0xFF1A1200),
      secondaryContainer: Color(0xFFFFE7B8),
      onSecondaryContainer: Color(0xFF3D2A00),
      tertiary: Color(0xFF5C3D9E),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE8DDFF),
      onTertiaryContainer: Color(0xFF1F0D45),
      error: Color(0xFFB00020),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFFCFCFC),
      onSurface: Color(0xFF1A1C1E),
      onSurfaceVariant: Color(0xFF42474E),
      outline: Color(0xFF72787F),
      outlineVariant: Color(0xFFC2C7CE),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2F3033),
      onInverseSurface: Color(0xFFF1F0F4),
      inversePrimary: Color(0xFF9ECAFF),
      surfaceTint: Color(0xFF005A9C),
    );
  }

  static ColorScheme schemeHighContrast(ColorScheme base) {
    return base.copyWith(
      onSurface: const Color(0xFF000000),
      onSurfaceVariant: const Color(0xFF000000),
      outline: const Color(0xFF000000),
      surface: Colors.white,
      primary: navyDark,
      onPrimary: Colors.white,
    );
  }

  static List<Color> statPaletteDefault() => [
        navy,
        goldDeep,
        const Color(0xFFD97706),
        const Color(0xFF047857),
      ];

  static List<Color> statPaletteAccessible() => [
        const Color(0xFF005A9C),
        const Color(0xFFE69F00),
        const Color(0xFF7C3AED),
        const Color(0xFF0D9488),
      ];
}
