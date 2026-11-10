import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/zones_data.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/zone_snapshot.dart';
import '../../providers/territory_providers.dart';
import 'async_state_view.dart';
import 'data_status_bar.dart';

enum DashboardKind {
  air('Ar', Icons.air, AppRoutes.airDashboard),
  heat('Calor', Icons.wb_sunny_outlined, AppRoutes.heatDashboard),
  impact('Impacto', Icons.diversity_3_outlined, AppRoutes.impactDashboard);

  const DashboardKind(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

/// Estrutura comum dos 3 dashboards: troca de zona, troca de dashboard,
/// status dos dados, puxar para atualizar e estados de carregamento/erro.
class DashboardScaffold extends ConsumerWidget {
  const DashboardScaffold({
    super.key,
    required this.kind,
    required this.title,
    required this.zoneId,
    required this.builder,
  });

  final DashboardKind kind;
  final String title;
  final String zoneId;
  final List<Widget> Function(BuildContext context, ZoneSnapshot snapshot) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = zoneById(zoneId);
    final snapshot = ref.watch(zoneSnapshotProvider(zoneId));

    void go({String? zone, DashboardKind? to}) {
      final target = zone ?? zoneId;
      ref.read(selectedZoneProvider.notifier).select(target);
      context.replaceNamed(
        (to ?? kind).route,
        pathParameters: {'zoneId': target},
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$title · ${zone.name}'),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshTerritory(ref),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => refreshTerritory(ref),
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              SegmentedButton<DashboardKind>(
                showSelectedIcon: false,
                segments: [
                  for (final k in DashboardKind.values)
                    ButtonSegment(
                      value: k,
                      icon: Icon(k.icon),
                      label: Text(k.label),
                      tooltip: 'Dashboard de ${k.label.toLowerCase()}',
                    ),
                ],
                selected: {kind},
                onSelectionChanged: (s) => go(to: s.first),
              ),
              AppSpacing.gapSm,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final z in kZones)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(z.name),
                          selected: z.id == zoneId,
                          onSelected: (_) => go(zone: z.id),
                          tooltip: 'Ver ${z.name}',
                        ),
                      ),
                  ],
                ),
              ),
              AppSpacing.gapSm,
              const Align(
                alignment: Alignment.centerLeft,
                child: DataStatusBar(),
              ),
              AppSpacing.gapSm,
              AsyncStateView<ZoneSnapshot?>(
                value: snapshot,
                onRetry: () => refreshTerritory(ref),
                isEmpty: (s) => s == null || s.points.isEmpty,
                emptyTitle: 'Sem dados para ${zone.name}',
                emptyMessage: 'Tente atualizar em alguns instantes.',
                builder: (s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: builder(context, s!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
