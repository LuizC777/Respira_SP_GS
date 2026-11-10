import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/alert.dart';

/// Uma série de linha do gráfico.
class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.color,
    required this.points,
  });

  final String label;
  final Color color;
  final List<SeriesPoint> points;
}

/// Gráfico de linha com histórico (linha cheia) e previsão (tracejada),
/// linha de limiar e marcador de "agora". Inclui descrição para leitores
/// de tela, já que o gráfico em si não é acessível.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.series,
    required this.unit,
    required this.semanticLabel,
    this.now,
    this.threshold,
    this.thresholdLabel = 'Limiar',
    this.height = 220,
    this.decimals = 0,
    this.minYZero = true,
  });

  final List<ChartSeries> series;
  final String unit;
  final String semanticLabel;
  final DateTime? now;
  final double? threshold;
  final String thresholdLabel;
  final double height;
  final int decimals;
  final bool minYZero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final allPoints = [for (final s in series) ...s.points];
    if (allPoints.isEmpty) {
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

    final start = allPoints.map((p) => p.time).reduce((a, b) => a.isBefore(b) ? a : b);
    final end = allPoints.map((p) => p.time).reduce((a, b) => a.isAfter(b) ? a : b);
    double x(DateTime t) => t.difference(start).inMinutes / 60;

    final values = allPoints.map((p) => p.value).toList();
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    if (threshold != null) {
      minY = math.min(minY, threshold!);
      maxY = math.max(maxY, threshold!);
    }
    final pad = math.max(1.0, (maxY - minY) * 0.12);
    minY = minYZero ? 0 : (minY - pad).floorToDouble();
    maxY = (maxY + pad).ceilToDouble();

    final spanHours = math.max(1.0, x(end));
    final nowX = now == null ? null : x(now!).clamp(0.0, spanHours).toDouble();

    final bars = <LineChartBarData>[];
    for (final s in series) {
      final sorted = [...s.points]..sort((a, b) => a.time.compareTo(b.time));
      final history = now == null
          ? sorted
          : sorted.where((p) => !p.time.isAfter(now!)).toList();
      final forecast = now == null
          ? <SeriesPoint>[]
          : [
              if (history.isNotEmpty) history.last,
              ...sorted.where((p) => p.time.isAfter(now!)),
            ];
      if (history.isNotEmpty) {
        bars.add(_bar(history.map((p) => FlSpot(x(p.time), p.value)).toList(),
            s.color, dashed: false));
      }
      if (forecast.length > 1) {
        bars.add(_bar(forecast.map((p) => FlSpot(x(p.time), p.value)).toList(),
            s.color, dashed: true));
      }
    }

    final labelStyle = text.labelSmall?.copyWith(color: scheme.onSurfaceVariant);

    final chart = LineChart(
      LineChartData(
        minX: 0,
        maxX: spanHours,
        minY: minY,
        maxY: maxY,
        lineBarsData: bars,
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Text(
                    Fmt.number(value),
                    style: labelStyle,
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: math.max(1.0, spanHours / 4),
              getTitlesWidget: (value, meta) {
                if (value == meta.max && value != 0) {
                  return const SizedBox.shrink();
                }
                final t = start.add(Duration(minutes: (value * 60).round()));
                final label = spanHours <= 48 ? Fmt.hour(t) : Fmt.dayMonth(t);
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(label, style: labelStyle),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (threshold != null)
              HorizontalLine(
                y: threshold!,
                color: scheme.error,
                strokeWidth: 1.5,
                dashArray: const [5, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: text.labelSmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                  labelResolver: (_) =>
                      '$thresholdLabel ${Fmt.number(threshold, decimals: decimals)}',
                ),
              ),
          ],
          verticalLines: [
            if (nowX != null && nowX > 0 && nowX < spanHours)
              VerticalLine(
                x: nowX,
                color: scheme.onSurfaceVariant,
                strokeWidth: 1,
                dashArray: const [2, 3],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.topLeft,
                  style: labelStyle,
                  labelResolver: (_) => 'agora',
                ),
              ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) => spots.map((spot) {
              final t = start.add(Duration(minutes: (spot.x * 60).round()));
              return LineTooltipItem(
                '${Fmt.dateTime(t)}\n'
                '${Fmt.number(spot.y, decimals: decimals)} $unit',
                TextStyle(color: scheme.onInverseSurface, fontSize: 12),
              );
            }).toList(),
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
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  right: AppSpacing.sm,
                ),
                child: chart,
              ),
            ),
          ),
        ),
        AppSpacing.gapSm,
        ExcludeSemantics(
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              for (final s in series) _Legend(color: s.color, label: s.label),
              if (now != null)
                _Legend(
                  color: scheme.onSurfaceVariant,
                  label: 'Previsão (tracejado)',
                  dashed: true,
                ),
              if (threshold != null)
                _Legend(color: scheme.error, label: thresholdLabel, dashed: true),
            ],
          ),
        ),
      ],
    );
  }

  LineChartBarData _bar(List<FlSpot> spots, Color color, {required bool dashed}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.2,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dashArray: dashed ? const [6, 4] : null,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: !dashed,
        color: color.withValues(alpha: 0.10),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.dashed = false});

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 3,
          child: dashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    3,
                    (_) => Container(width: 4, height: 3, color: color),
                  ),
                )
              : ColoredBox(color: color),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
