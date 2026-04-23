import 'package:flutter/material.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color bg;
  final Color surface;
  final Color elevated;
  final Color border;
  
  final Color red;
  final Color amber;
  final Color green;
  final Color purple;
  
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  const AppThemeColors({
    required this.bg,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.red,
    required this.amber,
    required this.green,
    required this.purple,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  @override
  ThemeExtension<AppThemeColors> copyWith({
    Color? bg,
    Color? surface,
    Color? elevated,
    Color? border,
    Color? red,
    Color? amber,
    Color? green,
    Color? purple,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
  }) {
    return AppThemeColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      border: border ?? this.border,
      red: red ?? this.red,
      amber: amber ?? this.amber,
      green: green ?? this.green,
      purple: purple ?? this.purple,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(
    covariant ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      red: Color.lerp(red, other.red, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      green: Color.lerp(green, other.green, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
    );
  }
}

class AppColors {
  static const Color cLightest = Color(0xFFEAF9E7);
  static const Color cLight    = Color(0xFFC0E6BA);
  static const Color cPrimary  = Color(0xFF4CA771);
  static const Color cDarkest  = Color(0xFF013237);

  static const lightPalette = AppThemeColors(
    bg: cLightest,
    surface: cLightest, // Used for cards. Wait, let's use cLightest for bg and surface, and cLight for elevated?
    // Let's use bg: cLightest, surface: cLight. That gives cards a distinct color.
    elevated: cLight,
    border: cPrimary,
    red: cDarkest,
    amber: cPrimary,
    green: cLight,
    purple: cPrimary, // primary button color
    textPrimary: cDarkest,
    textSecondary: cPrimary,
    textTertiary: cPrimary,
  );

  static const darkPalette = AppThemeColors(
    bg: cDarkest,
    surface: cDarkest,
    elevated: cPrimary,
    border: cPrimary,
    red: cPrimary,
    amber: cLight,
    green: cLightest,
    purple: cPrimary,
    textPrimary: cLightest,
    textSecondary: cLight,
    textTertiary: cLight,
  );

  // Helper extension to get colors easily
  // Usage: context.colors.bg
}

extension AppThemeColorsExtension on BuildContext {
  AppThemeColors get colors => Theme.of(this).extension<AppThemeColors>()!;
}

class ScoreColors {
  /// Interpolate shame color for a score 0–1000.
  static Color scoreColor(BuildContext context, double score) {
    final colors = context.colors;
    final t = (score / 1000).clamp(0.0, 1.0);
    if (t <= 0.5) {
      return Color.lerp(colors.green, colors.amber, t * 2)!;
    } else {
      return Color.lerp(colors.amber, colors.red, (t - 0.5) * 2)!;
    }
  }

  static List<Color> scoreGradient(BuildContext context) {
    final colors = context.colors;
    return [colors.green, colors.amber, colors.red];
  }

  /// Shame label for a score 0–1000.
  static String rotLabel(int score) {
    if (score <= 300) return "you're fine 👌";
    if (score <= 600) return "concerning 👀";
    if (score <= 850) return "yikes 😬";
    return "certified addict 💀";
  }
}
