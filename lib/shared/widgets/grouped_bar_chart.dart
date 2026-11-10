import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';

class BarGroup {
  const BarGroup(this.label, this.values);
  final String label;

  /// Um valor por série (mesma ordem de [GroupedBarChart.seriesLabels]).
  final List<double> values;
}

/// Gráfico de barras (simples ou agrupado) com legenda e descrição
/// para leitores de tela.
class GroupedBarChart extends StatelessWidget {
  const GroupedBarChart({
    super.key,
    required this.groups,
    required this.seriesLabels,
    required this.seriesColors,
    required this.unit,
    required this.semanticLabel,
    this.height = 200,
  });

  final List<BarGroup> groups;
  final List<String> seriesLabels;
  final List<Color> seriesColors;
  final String unit;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (groups.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Sem dados para o período.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }
    final maxValue = groups
        .expand((g) => g.values)
        .fold<double>(0, (a, b) => math.max(a, b));
    final rodWidth = groups.length > 6 ? 8.0 : 14.0;
    final labelStyle = text.labelSmall?.copyWith(color: scheme.onSurfaceVariant);

    final chart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: math.max(1.0, (maxValue * 1.2).ceilToDouble()),
        barGroups: [
          for (var i = 0; i < groups.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                for (var j = 0; j < groups[i].values.length; j++)
                  BarChartRodData(
                    toY: groups[i].values[j],
                    color: seriesColors[j % seriesColors.length],
                    width: rodWidth,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
              ],
            ),
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outline, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return Text(Fmt.number(value), style: labelStyle);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= groups.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(groups[i].label, style: labelStyle),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${groups[groupIndex].label}\n'
              '${seriesLabels[rodIndex % seriesLabels.length]}: '
              '${Fmt.number(rod.toY)} $unit',
              TextStyle(color: scheme.onInverseSurface, fontSize: 12),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: semanticLabel,
          image: true,
          child: ExcludeSemantics(
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: chart,
              ),
            ),
          ),
        ),
        if (seriesLabels.length > 1) ...[
          AppSpacing.gapSm,
          ExcludeSemantics(
            child: Wrap(
              spacing: AppSpacing.md,
              children: [
                for (var j = 0; j < seriesLabels.length; j++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: seriesColors[j % seriesColors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(seriesLabels[j], style: text.labelSmall),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
