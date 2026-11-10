import 'package:flutter/material.dart';

import '../../domain/models/alert.dart';

/// Cores semânticas de severidade, com variantes para claro/escuro.
/// A severidade NUNCA é comunicada só pela cor: sempre há ícone e texto.
@immutable
class SeverityColors extends ThemeExtension<SeverityColors> {
  const SeverityColors({
    required this.good,
    required this.moderate,
    required this.high,
    required this.critical,
    required this.onSeverity,
  });

  final Color good;
  final Color moderate;
  final Color high;
  final Color critical;

  /// Cor de texto/ícone sobre o fundo de severidade.
  final Color onSeverity;

  static const light = SeverityColors(
    good: Color(0xFF2E7D32),
    moderate: Color(0xFF8A5A00),
    high: Color(0xFFB3261E),
    critical: Color(0xFF6A1B9A),
    onSeverity: Colors.white,
  );

  static const dark = SeverityColors(
    good: Color(0xFF81C784),
    moderate: Color(0xFFFFCC80),
    high: Color(0xFFFF8A80),
    critical: Color(0xFFCE93D8),
    onSeverity: Color(0xFF111111),
  );

  Color of(AlertSeverity? severity) => switch (severity) {
        null => good,
        AlertSeverity.moderate => moderate,
        AlertSeverity.high => high,
        AlertSeverity.critical => critical,
      };

  @override
  SeverityColors copyWith({
    Color? good,
    Color? moderate,
    Color? high,
    Color? critical,
    Color? onSeverity,
  }) {
    return SeverityColors(
      good: good ?? this.good,
      moderate: moderate ?? this.moderate,
      high: high ?? this.high,
      critical: critical ?? this.critical,
      onSeverity: onSeverity ?? this.onSeverity,
    );
  }

  @override
  SeverityColors lerp(ThemeExtension<SeverityColors>? other, double t) {
    if (other is! SeverityColors) return this;
    return SeverityColors(
      good: Color.lerp(good, other.good, t)!,
      moderate: Color.lerp(moderate, other.moderate, t)!,
      high: Color.lerp(high, other.high, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      onSeverity: Color.lerp(onSeverity, other.onSeverity, t)!,
    );
  }
}

extension SeverityColorsX on BuildContext {
  SeverityColors get severityColors =>
      Theme.of(this).extension<SeverityColors>() ?? SeverityColors.light;
}
