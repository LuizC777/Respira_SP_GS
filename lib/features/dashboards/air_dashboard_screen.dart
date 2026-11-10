import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/severity_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/engine/statistics.dart';
import '../../domain/models/alert.dart';
import '../../domain/models/aqi.dart';
import '../../domain/models/hourly_point.dart';
import '../../domain/models/zone_snapshot.dart';
import '../../providers/settings_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dashboard_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/period_selector.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/severity_badge.dart';
import '../../shared/widgets/trend_chart.dart';
import 'zone_alerts_section.dart';

/// Dashboard 1 — Qualidade do ar.
class AirDashboardScreen extends ConsumerStatefulWidget {
  const AirDashboardScreen({super.key, required this.zoneId});

  final String zoneId;

  @override
  ConsumerState<AirDashboardScreen> createState() => _AirDashboardScreenState();
}

class _AirDashboardScreenState extends ConsumerState<AirDashboardScreen> {
  ChartPeriod _period = ChartPeriod.h48; // estado local

  @override
  Widget build(BuildContext context) {
    final thresholds = ref.watch(thresholdsProvider);
    return DashboardScaffold(
      kind: DashboardKind.air,
      title: 'Qualidade do ar',
      zoneId: widget.zoneId,
      builder: (context, snapshot) {
        final now = DateTime.now();
        final current = snapshot.current(now);
        final dayAgo = _pointAt(snapshot, now.subtract(const Duration(hours: 24)));
        final category = AqiCategory.of(current?.usAqi);
        final points = _period.slice(snapshot.points, now);
        final pmSeries = ChartPeriod.series(points, (p) => p.pm25);
        final forecastDays = Stats.dailyValues(
          snapshot.points.where((p) => !p.time.isBefore(Stats.dateOnly(now))).toList(),
          (p) => p.pm25,
        );

        return [
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Índice de qualidade do ar (US AQI)',
                          style: Theme.of(context).textTheme.labelLarge),
                      AppSpacing.gapXs,
                      Text(Fmt.number(current?.usAqi),
                          style: Theme.of(context).textTheme.displaySmall),
                    ],
                  ),
                ),
                SeverityBadge(severity: category.severity, label: category.label),
              ],
            ),
          ),
          const SectionHeader('Agora', subtitle: 'Seta compara com 24 h atrás'),
          ResponsiveGrid(
            children: [
              MetricCard(
                label: 'PM2.5',
                value: current?.pm25,
                unit: 'µg/m³',
                icon: Icons.blur_on,
                decimals: 1,
                trend: MetricCard.trendOf(current?.pm25, dayAgo?.pm25),
                severity: (current?.pm25 ?? 0) > thresholds.pm25Daily
                    ? AqiCategory.of(current?.usAqi).severity
                    : null,
              ),
              MetricCard(
                label: 'PM10',
                value: current?.pm10,
                unit: 'µg/m³',
                icon: Icons.grain,
                decimals: 1,
                trend: MetricCard.trendOf(current?.pm10, dayAgo?.pm10),
              ),
              MetricCard(
                label: 'Ozônio (O₃)',
                value: current?.ozone,
                unit: 'µg/m³',
                icon: Icons.wb_twilight,
                trend: MetricCard.trendOf(current?.ozone, dayAgo?.ozone),
              ),
              MetricCard(
                label: 'Dióxido de nitrogênio (NO₂)',
                value: current?.no2,
                unit: 'µg/m³',
                icon: Icons.directions_car_outlined,
                trend: MetricCard.trendOf(current?.no2, dayAgo?.no2),
              ),
            ],
          ),
          SectionHeader(
            'PM2.5 — histórico e previsão',
            subtitle: 'Limiar: média diária de ${Fmt.number(thresholds.pm25Daily)} µg/m³',
          ),
          PeriodSelector(
            value: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          AppSpacing.gapSm,
          AppCard(
            child: TrendChart(
              now: now,
              unit: 'µg/m³',
              decimals: 1,
              threshold: thresholds.pm25Daily,
              thresholdLabel: 'Limiar',
              series: [
                ChartSeries(
                  label: 'PM2.5',
                  color: Theme.of(context).colorScheme.primary,
                  points: pmSeries,
                ),
              ],
              semanticLabel: _describe(pmSeries, thresholds.pm25Daily),
            ),
          ),
          const SectionHeader('Próximos dias', subtitle: 'Média diária prevista de PM2.5'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final d in forecastDays)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _DayChip(
                      day: d.day,
                      value: d.mean,
                      exceeds: d.mean > thresholds.pm25Daily,
                    ),
                  ),
              ],
            ),
          ),
          ZoneAlertsSection(zoneId: widget.zoneId),
        ];
      },
    );
  }

  HourlyPoint? _pointAt(ZoneSnapshot s, DateTime t) {
    HourlyPoint? best;
    for (final p in s.points) {
      if (p.time.isAfter(t)) break;
      best = p;
    }
    return best;
  }

  String _describe(List<SeriesPoint> series, double threshold) {
    final values = series.map((p) => p.value).toList();
    if (values.isEmpty) return 'Gráfico de PM2.5 sem dados.';
    final max = values.reduce((a, b) => a > b ? a : b);
    final over = values.where((v) => v > threshold).length;
    return 'Gráfico de PM2.5 do período ${_period.label}. Máximo de '
        '${Fmt.number(max, decimals: 1)} microgramas por metro cúbico. '
        '$over de ${values.length} pontos acima do limiar de '
        '${Fmt.number(threshold)}.';
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.value, required this.exceeds});

  final DateTime day;
  final double value;
  final bool exceeds;

  @override
  Widget build(BuildContext context) {
    final colors = context.severityColors;
    final text = Theme.of(context).textTheme;
    final color = exceeds ? colors.high : colors.good;
    return Semantics(
      label: '${Fmt.weekday(day)}: ${Fmt.number(value, decimals: 1)} '
          'microgramas, ${exceeds ? 'acima' : 'abaixo'} do limiar',
      excludeSemantics: true,
      child: AppCard(
        borderColor: color,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          children: [
            Text(Fmt.weekday(day), style: text.labelMedium),
            AppSpacing.gapXs,
            Text(Fmt.number(value, decimals: 1), style: text.titleLarge),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  exceeds ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(exceeds ? 'Acima' : 'OK', style: text.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
