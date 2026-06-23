import 'package:flutter/material.dart';

class FblaColors {
  FblaColors._();

  static const Color navy = Color(0xFF0A2E7F);
  static const Color navyDark = Color(0xFF061B4D);
  static const Color blue = Color(0xFF1D52BC);
  static const Color cobalt = Color(0xFF226ADD);
  static const Color gold = Color(0xFFF4AB19);
  static const Color goldDeep = Color(0xFFD49313);
  static const Color crimson = Color(0xFFC8102E);
  static const Color paper = Color(0xFFFAF9F6);
  static const Color porcelain = Color(0xFFF5F8FD);
  static const Color ink = Color(0xFF111827);
  static const Color text = Color(0xFF2D2B2B);
  static const Color muted = Color(0xFF6B7280);
  static const Color mist = Color(0xFFEAF1FB);
  static const Color line = Color(0xFFD9E1EC);
  static const Color sky = Color(0xFF4C8BF5);
  static const Color emerald = Color(0xFF12956B);

  static ColorScheme schemeDefault() {
    return ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: gold,
      tertiary: crimson,
      surface: Colors.white,
      brightness: Brightness.light,
    ).copyWith(
      primaryContainer: mist,
      secondaryContainer: const Color(0xFFFFE8B8),
      tertiaryContainer: const Color(0xFFF8D7DC),
      onSurface: text,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: const Color(0xFFE8EDF4),
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

  // Dark mode color scheme
  static ColorScheme schemeDark() {
    return ColorScheme.fromSeed(
      seedColor: navy,
      primary: const Color(0xFF9ECAFF),
      secondary: const Color(0xFFFFE066),
      tertiary: const Color(0xFFFFB3B8),
      surface: const Color(0xFF1A1C1E),
      brightness: Brightness.dark,
    ).copyWith(
      primaryContainer: const Color(0xFF004A77),
      onPrimaryContainer: const Color(0xFFD1E4FF),
      secondaryContainer: const Color(0xFF5C4800),
      onSecondaryContainer: const Color(0xFFFFE266),
      tertiaryContainer: const Color(0xFF8B1F29),
      onTertiaryContainer: const Color(0xFFFFDAD6),
      surfaceContainerHighest: const Color(0xFF42474E),
      onSurface: const Color(0xFFE2E2E6),
      onSurfaceVariant: const Color(0xFFC2C7CE),
      outline: const Color(0xFF8C9198),
      outlineVariant: const Color(0xFF42474E),
    );
  }

  static ColorScheme schemeDarkColorblindFriendly() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF9ECAFF),
      onPrimary: Color(0xFF003258),
      primaryContainer: Color(0xFF00497D),
      onPrimaryContainer: Color(0xFFD1E4FF),
      secondary: Color(0xFFFFCC80),
      onSecondary: Color(0xFF3D2E00),
      secondaryContainer: Color(0xFF584400),
      onSecondaryContainer: Color(0xFFFFDEAD),
      tertiary: Color(0xFFCFBCFF),
      onTertiary: Color(0xFF3B2D69),
      tertiaryContainer: Color(0xFF53447F),
      onTertiaryContainer: Color(0xFFEBE1FF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF1A1C1E),
      onSurface: Color(0xFFE2E2E6),
      onSurfaceVariant: Color(0xFFC2C7CE),
      outline: Color(0xFF8C9198),
      outlineVariant: Color(0xFF42474E),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE2E2E6),
      onInverseSurface: Color(0xFF2F3033),
      inversePrimary: Color(0xFF005A9C),
      surfaceTint: Color(0xFF9ECAFF),
    );
  }

  static ColorScheme schemeDarkHighContrast(ColorScheme base) {
    return base.copyWith(
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white,
      outline: Colors.white,
      surface: const Color(0xFF121212),
      primary: const Color(0xFF9ECAFF),
      onPrimary: const Color(0xFF003258),
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
