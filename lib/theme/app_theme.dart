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
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.primary.withOpacity(0.12),
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
        color: const Color(0xFF2C2C2E),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: const Color(0xFF1C1C1E),
        indicatorColor: scheme.primaryContainer,
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
          side: BorderSide(color: scheme.primary, width: a.highContrast ? 2 : 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
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
          borderSide: BorderSide(color: scheme.primary, width: a.highContrast ? 3 : 2),
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
        elevation: a.highContrast ? 1 : 0,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: a.highContrast
              ? BorderSide(color: scheme.outline, width: 1.5)
              : BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
        ),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        backgroundColor: Colors.white,
        indicatorColor: scheme.primaryContainer,
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
          side: BorderSide(color: scheme.primary, width: a.highContrast ? 2 : 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
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
          borderSide: BorderSide(color: scheme.primary, width: a.highContrast ? 3 : 2),
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
