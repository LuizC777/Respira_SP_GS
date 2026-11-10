import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/severity_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/alert.dart';
import 'app_card.dart';

enum TrendDirection { up, down, stable }

/// Indicador numérico com unidade, tendência e severidade opcional.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.decimals = 0,
    this.trend,
    this.trendHint,
    this.severity,
    this.caption,
    this.higherIsWorse = true,
  });

  final String label;
  final double? value;
  final String unit;
  final IconData icon;
  final int decimals;
  final TrendDirection? trend;

  /// Ex.: "vs. média das últimas 24 h".
  final String? trendHint;
  final AlertSeverity? severity;
  final String? caption;
  final bool higherIsWorse;

  /// Compara valor atual com referência (±5% = estável).
  static TrendDirection? trendOf(double? current, double? reference) {
    if (current == null || reference == null || reference == 0) return null;
    final change = (current - reference) / reference.abs();
    if (change > 0.05) return TrendDirection.up;
    if (change < -0.05) return TrendDirection.down;
    return TrendDirection.stable;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final valueText = Fmt.number(value, decimals: decimals);
    final trendWord = switch (trend) {
      TrendDirection.up => 'subindo',
      TrendDirection.down => 'caindo',
      TrendDirection.stable => 'estável',
      null => null,
    };
    final semantic = [
      '$label: $valueText $unit',
      if (trendWord != null) 'tendência $trendWord',
      if (severity != null) 'nível ${severity!.label}',
      if (caption != null) caption!,
    ].join(', ');

    return AppCard(
      semanticLabel: semantic,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (severity != null)
                  Icon(
                    severity!.icon,
                    size: 18,
                    color: context.severityColors.of(severity),
                  ),
              ],
            ),
            AppSpacing.gapSm,
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: AppSpacing.xs,
              children: [
                Text(valueText, style: text.headlineSmall),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit, style: text.bodyMedium),
                ),
                if (trend != null) _TrendIcon(trend!, higherIsWorse: higherIsWorse),
              ],
            ),
            if (caption != null || trendHint != null) ...[
              AppSpacing.gapXs,
              Text(
                caption ?? trendHint!,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendIcon extends StatelessWidget {
  const _TrendIcon(this.trend, {required this.higherIsWorse});

  final TrendDirection trend;
  final bool higherIsWorse;

  @override
  Widget build(BuildContext context) {
    final colors = context.severityColors;
    final (icon, color) = switch (trend) {
      TrendDirection.up => (
          Icons.arrow_upward,
          higherIsWorse ? colors.high : colors.good
        ),
      TrendDirection.down => (
          Icons.arrow_downward,
          higherIsWorse ? colors.good : colors.high
        ),
      TrendDirection.stable => (
          Icons.trending_flat,
          Theme.of(context).colorScheme.onSurfaceVariant
        ),
    };
    return Icon(icon, size: 20, color: color);
  }
}
