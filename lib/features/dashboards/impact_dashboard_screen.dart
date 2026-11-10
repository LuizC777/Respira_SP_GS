import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/zones_data.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/severity_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/engine/statistics.dart';
import '../../domain/models/alert.dart';
import '../../domain/models/citizen_report.dart';
import '../../providers/alert_providers.dart';
import '../../providers/report_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/dashboard_scaffold.dart';
import '../../shared/widgets/grouped_bar_chart.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/section_header.dart';
import 'zone_alerts_section.dart';

/// Dashboard 3 — Impacto social: quem é afetado, histórico de dias
/// críticos e ocorrências dos cidadãos.
class ImpactDashboardScreen extends ConsumerWidget {
  const ImpactDashboardScreen({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = zoneById(zoneId);
    final colors = context.severityColors;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final alerts = ref.watch(zoneAlertsProvider(zoneId));
    final allAlerts = (ref.watch(alertsProvider).valueOrNull ?? const <Alert>[])
        .where((a) => a.zoneId == zoneId)
        .toList();
    final history = ref.watch(exceedanceHistoryProvider(zoneId));
    final reports =
        ref.watch(reportsProvider).where((r) => r.zoneId == zoneId).toList();

    final highRisk = alerts.any((a) => a.severity != AlertSeverity.moderate);
    final exposed = highRisk ? zone.population : 0;

    // Agrupa o histórico de 30 dias em semanas (da mais antiga à atual).
    final now = DateTime.now();
    final weeks = <BarGroup>[];
    for (var w = 4; w >= 0; w--) {
      final from = Stats.dateOnly(now).subtract(Duration(days: 7 * (w + 1)));
      final to = from.add(const Duration(days: 7));
      final inWeek = history.where((d) => !d.day.isBefore(from) && d.day.isBefore(to));
      weeks.add(BarGroup(
        w == 0 ? 'Últ. 7d' : '-${w}sem',
        [
          inWeek.where((d) => d.air).length.toDouble(),
          inWeek.where((d) => d.heat).length.toDouble(),
        ],
      ));
    }
    final totalAir = history.where((d) => d.air).length;
    final totalHeat = history.where((d) => d.heat).length;

    return DashboardScaffold(
      kind: DashboardKind.impact,
      title: 'Impacto',
      zoneId: zoneId,
      builder: (context, snapshot) => [
        AppCard(
          color: scheme.primaryContainer,
          borderColor: scheme.primaryContainer,
          semanticLabel: highRisk
              ? 'Cerca de ${Fmt.compact(exposed)} pessoas potencialmente expostas '
                  'a risco alto em ${zone.name}.'
              : 'Nenhuma exposição a risco alto prevista em ${zone.name}.',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pessoas potencialmente expostas',
                    style: text.labelLarge?.copyWith(color: scheme.onPrimaryContainer)),
                AppSpacing.gapXs,
                Text(
                  highRisk ? '≈ ${Fmt.compact(exposed)}' : 'Nenhuma',
                  style: text.headlineMedium?.copyWith(color: scheme.onPrimaryContainer),
                ),
                Text(
                  highRisk
                      ? 'Há alerta alto ou crítico ativo. Avisar com antecedência '
                          'reduz idas evitáveis a prontos-socorros.'
                      : 'Sem alerta alto ou crítico ativo nesta zona.',
                  style: text.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        const SectionHeader('Estrutura da zona', subtitle: 'Estimativas sintéticas'),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'População',
              value: zone.population.toDouble(),
              unit: 'hab.',
              icon: Icons.groups_outlined,
            ),
            MetricCard(
              label: 'Escolas',
              value: zone.schools.toDouble(),
              unit: '',
              icon: Icons.school_outlined,
              caption: highRisk ? 'Podem adaptar atividades ao ar livre' : null,
            ),
            MetricCard(
              label: 'Unidades básicas de saúde',
              value: zone.healthUnits.toDouble(),
              unit: '',
              icon: Icons.local_hospital_outlined,
              caption: highRisk ? 'Podem reforçar a escala' : null,
            ),
            MetricCard(
              label: 'Alertas confirmados',
              value: allAlerts
                  .where((a) => a.status == AlertStatus.confirmed)
                  .length
                  .toDouble(),
              unit: '',
              icon: Icons.task_alt,
              caption: '${allAlerts.where((a) => a.status == AlertStatus.pending).length} '
                  'aguardando análise',
            ),
          ],
        ),
        SectionHeader(
          'Dias acima dos limiares (30 dias)',
          subtitle: '$totalAir dia(s) de ar ruim · $totalHeat dia(s) de calor extremo',
        ),
        AppCard(
          child: GroupedBarChart(
            unit: 'dias',
            seriesLabels: const ['Ar ruim', 'Calor extremo'],
            seriesColors: [colors.critical, colors.high],
            groups: weeks,
            semanticLabel: 'Histórico semanal: ${[
              for (final w in weeks)
                '${w.label}: ${w.values[0].toInt()} dias de ar ruim e '
                    '${w.values[1].toInt()} de calor',
            ].join('; ')}.',
          ),
        ),
        const SectionHeader(
          'Ocorrências dos cidadãos',
          subtitle: 'Registros anônimos feitos neste aparelho',
        ),
        AppCard(
          child: GroupedBarChart(
            unit: 'registros',
            seriesLabels: const ['Ocorrências'],
            seriesColors: [scheme.primary],
            height: 180,
            groups: [
              for (final t in ReportType.values)
                BarGroup(
                  _short(t),
                  [reports.where((r) => r.type == t).length.toDouble()],
                ),
            ],
            semanticLabel: 'Ocorrências por tipo: ${[
              for (final t in ReportType.values)
                '${t.label}: ${reports.where((r) => r.type == t).length}',
            ].join(', ')}.',
          ),
        ),
        ZoneAlertsSection(zoneId: zoneId),
      ],
    );
  }

  static String _short(ReportType t) => switch (t) {
        ReportType.smoke => 'Fumaça',
        ReportType.odor => 'Odor',
        ReportType.symptom => 'Sintoma',
        ReportType.heat => 'Calor',
      };
}
