import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'severity_colors.dart';

/// Tema central do app (claro e escuro). Telas e widgets leem cores,
/// tipografia e severidades daqui — sem estilos repetidos tela a tela.
abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green700,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.green700,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.green100,
      onPrimaryContainer: AppColors.green900,
      secondary: AppColors.green800,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.green50,
      onSecondaryContainer: AppColors.green900,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.mint,
      surfaceContainer: AppColors.green50,
      surfaceContainerHigh: AppColors.green50,
      surfaceContainerHighest: AppColors.green100,
      outline: AppColors.outline,
      outlineVariant: AppColors.outline,
    );
    return _base(scheme, SeverityColors.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green700,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.green300,
      onPrimary: AppColors.green900,
      primaryContainer: AppColors.green800,
      onPrimaryContainer: AppColors.green50,
      secondary: AppColors.green100,
      onSecondary: AppColors.green900,
      secondaryContainer: AppColors.darkSurfaceHigh,
      onSecondaryContainer: AppColors.darkInk,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkInk,
      onSurfaceVariant: AppColors.darkInkMuted,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurfaceHigh,
      surfaceContainerHigh: AppColors.darkSurfaceHigh,
      surfaceContainerHighest: AppColors.darkOutline,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutline,
    );
    return _base(scheme, SeverityColors.dark);
  }

  static ThemeData _base(ColorScheme scheme, SeverityColors severity) {
    final textTheme = _textTheme(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.brightness == Brightness.light
          ? AppColors.white
          : AppColors.darkBackground,
      textTheme: textTheme,
      dividerColor: scheme.outline,
      visualDensity: VisualDensity.standard,
      extensions: [severity],
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = scheme.brightness == Brightness.light
        ? Typography.material2021().black
        : Typography.material2021().white;
    return base
        .copyWith(
          headlineSmall: base.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}
