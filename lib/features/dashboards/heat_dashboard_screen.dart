import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/severity_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/engine/statistics.dart';
import '../../domain/models/alert.dart';
import '../../domain/models/hourly_point.dart';
import '../../domain/models/thresholds.dart';
import '../../providers/settings_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dashboard_scaffold.dart';
import '../../shared/widgets/grouped_bar_chart.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/period_selector.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/trend_chart.dart';
import 'zone_alerts_section.dart';

/// Dashboard 2 — Calor e clima.
class HeatDashboardScreen extends ConsumerStatefulWidget {
  const HeatDashboardScreen({super.key, required this.zoneId});

  final String zoneId;

  @override
  ConsumerState<HeatDashboardScreen> createState() =>
      _HeatDashboardScreenState();
}

class _HeatDashboardScreenState extends ConsumerState<HeatDashboardScreen> {
  ChartPeriod _period = ChartPeriod.h48; // estado local

  @override
  Widget build(BuildContext context) {
    final thresholds = ref.watch(thresholdsProvider);
    final colors = context.severityColors;
    final scheme = Theme.of(context).colorScheme;

    return DashboardScaffold(
      kind: DashboardKind.heat,
      title: 'Calor',
      zoneId: widget.zoneId,
      builder: (context, snapshot) {
        final now = DateTime.now();
        final today = Stats.dateOnly(now);
        final current = snapshot.current(now);
        final dayAgo = snapshot.points
            .where((p) => !p.time.isAfter(now.subtract(const Duration(hours: 24))))
            .lastOrNull;
        final todayPoints = snapshot.points
            .where((p) => Stats.dateOnly(p.time) == today)
            .toList();
        final uvMax = _max(todayPoints, (p) => p.uvIndex);
        final appMax = _max(todayPoints, (p) => p.apparentTemperature);

        final points = _period.slice(snapshot.points, now);
        final tempSeries = ChartPeriod.series(points, (p) => p.temperature);
        final appSeries = ChartPeriod.series(points, (p) => p.apparentTemperature);

        final upcoming = snapshot.points.where((p) => !p.time.isBefore(today));
        final hoursByDay = <DateTime, int>{};
        for (final p in upcoming) {
          final d = Stats.dateOnly(p.time);
          hoursByDay.putIfAbsent(d, () => 0);
          if ((p.apparentTemperature ?? -99) >= thresholds.apparentTemp) {
            hoursByDay[d] = hoursByDay[d]! + 1;
          }
        }
        final days = hoursByDay.keys.toList()..sort();

        return [
          ResponsiveGrid(
            children: [
              MetricCard(
                label: 'Temperatura',
                value: current?.temperature,
                unit: '°C',
                icon: Icons.thermostat,
                decimals: 1,
                trend: MetricCard.trendOf(current?.temperature, dayAgo?.temperature),
              ),
              MetricCard(
                label: 'Sensação térmica',
                value: current?.apparentTemperature,
                unit: '°C',
                icon: Icons.local_fire_department_outlined,
                decimals: 1,
                trend: MetricCard.trendOf(
                    current?.apparentTemperature, dayAgo?.apparentTemperature),
                severity: (current?.apparentTemperature ?? 0) >= thresholds.apparentTemp
                    ? AlertSeverity.high
                    : null,
              ),
              MetricCard(
                label: 'Umidade relativa',
                value: current?.humidity,
                unit: '%',
                icon: Icons.water_drop_outlined,
                higherIsWorse: false,
                trend: MetricCard.trendOf(current?.humidity, dayAgo?.humidity),
              ),
              MetricCard(
                label: 'UV máximo hoje',
                value: uvMax,
                unit: '',
                icon: Icons.wb_sunny_outlined,
                decimals: 1,
                caption: _uvLabel(uvMax),
                severity: (uvMax ?? 0) >= 8 ? AlertSeverity.high : null,
              ),
            ],
          ),
          SectionHeader(
            'Temperatura e sensação térmica',
            subtitle: 'Limiar de calor: ${Fmt.number(thresholds.apparentTemp)} °C · '
                'máx. hoje ${Fmt.number(appMax, decimals: 1)} °C',
          ),
          PeriodSelector(
            value: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          AppSpacing.gapSm,
          AppCard(
            child: TrendChart(
              now: now,
              unit: '°C',
              decimals: 1,
              minYZero: false,
              threshold: thresholds.apparentTemp,
              series: [
                ChartSeries(label: 'Temperatura', color: scheme.primary, points: tempSeries),
                ChartSeries(label: 'Sensação térmica', color: colors.high, points: appSeries),
              ],
              semanticLabel: _describe(appSeries, thresholds),
            ),
          ),
          SectionHeader(
            'Horas de calor extremo por dia',
            subtitle: 'Horas com sensação ≥ ${Fmt.number(thresholds.apparentTemp)} °C '
                '(alerta a partir de ${thresholds.heatMinHours} h)',
          ),
          AppCard(
            child: GroupedBarChart(
              unit: 'h',
              seriesLabels: const ['Horas de calor extremo'],
              seriesColors: [colors.high],
              groups: [
                for (final d in days)
                  BarGroup(Fmt.dayMonth(d), [hoursByDay[d]!.toDouble()]),
              ],
              semanticLabel: 'Horas de calor extremo previstas: ${[
                for (final d in days) '${Fmt.weekday(d)} ${hoursByDay[d]} horas',
              ].join(', ')}.',
            ),
          ),
          ZoneAlertsSection(zoneId: widget.zoneId),
        ];
      },
    );
  }

  double? _max(List<HourlyPoint> ps, double? Function(HourlyPoint) f) {
    final vs = ps.map(f).whereType<double>();
    return vs.isEmpty ? null : vs.reduce((a, b) => a > b ? a : b);
  }

  String? _uvLabel(double? uv) {
    if (uv == null) return null;
    if (uv < 3) return 'Baixo';
    if (uv < 6) return 'Moderado';
    if (uv < 8) return 'Alto';
    if (uv < 11) return 'Muito alto — evite sol entre 10 h e 16 h';
    return 'Extremo — evite exposição ao sol';
  }

  String _describe(List<SeriesPoint> series, Thresholds t) {
    if (series.isEmpty) return 'Gráfico de sensação térmica sem dados.';
    final max = series.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    return 'Gráfico de temperatura e sensação térmica, período '
        '${_period.label}. Sensação máxima de ${Fmt.number(max, decimals: 1)} '
        'graus; limiar de ${Fmt.number(t.apparentTemp)} graus.';
  }
}
