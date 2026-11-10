import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/alert.dart';
import '../../domain/models/aqi.dart';
import '../../domain/models/zone.dart';
import '../../providers/alert_providers.dart';
import '../../providers/territory_providers.dart';
import 'app_card.dart';
import 'severity_badge.dart';

/// Resumo de uma zona na visão geral, com atalhos para os 3 dashboards.
class ZoneCard extends ConsumerWidget {
  const ZoneCard({super.key, required this.zone});

  final Zone zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final snapshot = ref.watch(zoneSnapshotProvider(zone.id)).valueOrNull;
    final alerts = ref.watch(zoneAlertsProvider(zone.id));
    final current = snapshot?.current(DateTime.now());

    AlertSeverity? worst;
    for (final a in alerts) {
      if (worst == null || a.severity.index > worst.index) worst = a.severity;
    }
    final aqi = current?.usAqi;
    final aqiCategory = AqiCategory.of(aqi);

    void open(String route) {
      ref.read(selectedZoneProvider.notifier).select(zone.id);
      context.pushNamed(route, pathParameters: {'zoneId': zone.id});
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(zone.name, style: text.titleMedium),
                ),
              ),
              SeverityBadge(
                severity: worst,
                compact: true,
                label: worst == null
                    ? 'Sem alerta'
                    : '${alerts.length} alerta${alerts.length > 1 ? 's' : ''}',
              ),
            ],
          ),
          AppSpacing.gapSm,
          MergeSemantics(
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                _Inline(
                  icon: Icons.air,
                  text: 'AQI ${Fmt.number(aqi)} · ${aqiCategory.label}',
                ),
                _Inline(
                  icon: Icons.thermostat,
                  text: 'Sensação ${Fmt.number(current?.apparentTemperature)} °C',
                ),
                _Inline(
                  icon: Icons.groups_outlined,
                  text: '${Fmt.compact(zone.population)} hab.',
                ),
              ],
            ),
          ),
          AppSpacing.gapSm,
          Divider(color: scheme.outline, height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ActionChip(
                avatar: const Icon(Icons.air, size: 18),
                label: const Text('Ar'),
                tooltip: 'Dashboard de qualidade do ar da ${zone.name}',
                onPressed: () => open(AppRoutes.airDashboard),
              ),
              ActionChip(
                avatar: const Icon(Icons.wb_sunny_outlined, size: 18),
                label: const Text('Calor'),
                tooltip: 'Dashboard de calor da ${zone.name}',
                onPressed: () => open(AppRoutes.heatDashboard),
              ),
              ActionChip(
                avatar: const Icon(Icons.diversity_3_outlined, size: 18),
                label: const Text('Impacto'),
                tooltip: 'Dashboard de impacto social da ${zone.name}',
                onPressed: () => open(AppRoutes.impactDashboard),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Inline extends StatelessWidget {
  const _Inline({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
