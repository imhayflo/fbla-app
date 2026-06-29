// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fbla_member_app/services/accessibility_controller.dart';
import 'fbla_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark(AccessibilityController a) {
    ColorScheme scheme = a.colorblindFriendly
        ? FblaColors.schemeDarkColorblindFriendly()
        : FblaColors.schemeDark();
    if (a.highContrast) {
      scheme = FblaColors.schemeDarkHighContrast(scheme);
    }

    final statColors = a.colorblindFriendly
        ? FblaColors.statPaletteAccessible()
        : FblaColors.statPaletteDefault();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF08111F),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: a.highContrast ? 1 : 0,
        shadowColor: Colors.black54,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: a.highContrast
              ? BorderSide(color: scheme.outline, width: 1.5)
              : BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
        ),
        color: const Color(0xFF111827),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: const Color(0xFF1E3A8A),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side:
              BorderSide(color: scheme.primary, width: a.highContrast ? 2 : 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: scheme.primary, width: a.highContrast ? 3 : 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: a.highContrast ? 2 : 1,
      ),
      extensions: <ThemeExtension<dynamic>>[
        FblaStatColors(statColors),
      ],
    );
  }

  static ThemeData light(AccessibilityController a) {
    ColorScheme scheme = a.colorblindFriendly
        ? FblaColors.schemeColorblindFriendly()
        : FblaColors.schemeDefault();
    if (a.highContrast) {
      scheme = FblaColors.schemeHighContrast(scheme);
    }

    final statColors = a.colorblindFriendly
        ? FblaColors.statPaletteAccessible()
        : FblaColors.statPaletteDefault();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: FblaColors.paper,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: a.highContrast ? 1 : 2,
        shadowColor: FblaColors.navy.withOpacity(0.10),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: a.highContrast
              ? BorderSide(color: scheme.outline, width: 1.5)
              : BorderSide(color: FblaColors.line.withOpacity(0.78)),
        ),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: Colors.white,
        indicatorColor: FblaColors.mist,
        shadowColor: FblaColors.navy.withOpacity(0.12),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FblaColors.navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side:
              BorderSide(color: scheme.primary, width: a.highContrast ? 2 : 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FblaColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FblaColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: scheme.primary, width: a.highContrast ? 3 : 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: a.highContrast ? 2 : 1,
      ),
      extensions: <ThemeExtension<dynamic>>[
        FblaStatColors(statColors),
      ],
    );
  }
}

class FblaStatColors extends ThemeExtension<FblaStatColors> {
  final List<Color> colors;

  const FblaStatColors(this.colors);

  Color get events => colors[0];
  Color get competitions => colors[1];
  Color get points => colors[2];
  Color get rank => colors[3];

  @override
  FblaStatColors copyWith({List<Color>? colors}) {
    return FblaStatColors(colors ?? this.colors);
  }

  @override
  ThemeExtension<FblaStatColors> lerp(
    ThemeExtension<FblaStatColors>? other,
    double t,
  ) {
    if (other is! FblaStatColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension FblaStatColorsX on ThemeData {
  FblaStatColors get fblaStats =>
      extension<FblaStatColors>() ??
      FblaStatColors(FblaColors.statPaletteDefault());
}
