import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/models/alert.dart';
import '../../providers/alert_providers.dart';
import '../../providers/territory_providers.dart';
import '../../shared/widgets/alert_tile.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/data_status_bar.dart';
import '../../shared/widgets/human_decision_banner.dart';

enum _StatusFilter {
  pending('Pendentes'),
  confirmed('Confirmados'),
  dismissed('Descartados'),
  all('Todos');

  const _StatusFilter(this.label);
  final String label;

  bool matches(Alert a) => switch (this) {
        _StatusFilter.pending => a.status == AlertStatus.pending,
        _StatusFilter.confirmed => a.status == AlertStatus.confirmed,
        _StatusFilter.dismissed => a.status == AlertStatus.dismissed,
        _StatusFilter.all => true,
      };
}

/// Lista de alertas preditivos com filtros (estado local).
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  _StatusFilter _status = _StatusFilter.pending;
  final Set<AlertSeverity> _severities = AlertSeverity.values.toSet();

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas preditivos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshTerritory(ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HumanDecisionBanner(compact: true),
                  AppSpacing.gapSm,
                  const Align(alignment: Alignment.centerLeft, child: DataStatusBar()),
                  AppSpacing.gapSm,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<_StatusFilter>(
                      showSelectedIcon: false,
                      segments: [
                        for (final f in _StatusFilter.values)
                          ButtonSegment(value: f, label: Text(f.label)),
                      ],
                      selected: {_status},
                      onSelectionChanged: (s) => setState(() => _status = s.first),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final s in AlertSeverity.values)
                        FilterChip(
                          label: Text(s.label),
                          avatar: Icon(s.icon, size: 18),
                          selected: _severities.contains(s),
                          tooltip: 'Filtrar severidade ${s.label}',
                          onSelected: (on) => setState(() {
                            on ? _severities.add(s) : _severities.remove(s);
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => refreshTerritory(ref),
                child: AsyncStateView<List<Alert>>(
                  value: alerts,
                  onRetry: () => refreshTerritory(ref),
                  isEmpty: (list) => _filter(list).isEmpty,
                  emptyIcon: Icons.notifications_off_outlined,
                  emptyTitle: 'Nenhum alerta neste filtro',
                  emptyMessage: _status == _StatusFilter.pending
                      ? 'Não há alertas aguardando análise. Ajuste os limiares '
                          'em Ajustes para testar outros cenários.'
                      : 'Tente outro filtro de status ou severidade.',
                  builder: (list) {
                    final filtered = _filter(list);
                    return ListView.separated(
                      padding: AppSpacing.screen,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => AppSpacing.gapSm,
                      itemBuilder: (_, i) => AlertTile(alert: filtered[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Alert> _filter(List<Alert> list) => list
      .where((a) => _status.matches(a) && _severities.contains(a.severity))
      .toList();
}
