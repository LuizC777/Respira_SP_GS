import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/zones_data.dart';
import '../domain/engine/alert_engine.dart';
import '../domain/models/alert.dart';
import '../domain/models/human_decision.dart';
import 'core_providers.dart';
import 'settings_providers.dart';
import 'territory_providers.dart';

/// ESTADO GLOBAL: decisões humanas sobre os alertas.
class DecisionsNotifier extends Notifier<Map<String, HumanDecision>> {
  @override
  Map<String, HumanDecision> build() =>
      ref.read(localStoreProvider).readDecisions();

  Future<void> decide({
    required String alertId,
    required AlertStatus status,
    required String justification,
  }) async {
    final decision = HumanDecision(
      alertId: alertId,
      status: status,
      justification: justification.trim(),
      decidedAt: DateTime.now(),
    );
    state = {...state, alertId: decision};
    await ref.read(localStoreProvider).saveDecision(decision);
  }

  /// Desfaz a decisão (o alerta volta a "aguardando análise").
  Future<void> undo(String alertId) async {
    state = {...state}..remove(alertId);
    await ref.read(localStoreProvider).deleteDecision(alertId);
  }

  void resetToDefaults() => state = const {};
}

final decisionsProvider =
    NotifierProvider<DecisionsNotifier, Map<String, HumanDecision>>(
  DecisionsNotifier.new,
);

/// Todos os alertas do território, recalculados sempre que os dados,
/// os limiares ou as decisões mudam. Ordenados por severidade.
final alertsProvider = Provider<AsyncValue<List<Alert>>>((ref) {
  final territory = ref.watch(territoryProvider);
  final thresholds = ref.watch(thresholdsProvider);
  final decisions = ref.watch(decisionsProvider);
  final engine = ref.watch(alertEngineProvider);

  return territory.whenData((data) {
    final now = DateTime.now();
    final alerts = <Alert>[
      for (final zone in kZones)
        if (data.snapshots[zone.id] != null)
          ...engine.evaluate(
            zone: zone,
            snapshot: data.snapshots[zone.id]!,
            thresholds: thresholds,
            now: now,
          ),
    ].map((a) {
      final decision = decisions[a.id];
      return decision == null ? a : a.withStatus(decision.status);
    }).toList()
      ..sort((a, b) {
        final bySeverity = b.severity.index.compareTo(a.severity.index);
        return bySeverity != 0
            ? bySeverity
            : a.windowStart.compareTo(b.windowStart);
      });
    return alerts;
  });
});

/// Alertas ativos (não descartados) de uma zona.
final zoneAlertsProvider =
    Provider.family<List<Alert>, String>((ref, zoneId) {
  final alerts = ref.watch(alertsProvider).valueOrNull ?? const [];
  return alerts.where((a) => a.zoneId == zoneId && a.isActive).toList();
});

/// Um alerta pelo id (null se não existir mais, ex.: após mudar limiares).
final alertByIdProvider = Provider.family<AsyncValue<Alert?>, String>(
  (ref, id) => ref.watch(alertsProvider).whenData(
        (alerts) => alerts.where((a) => a.id == id).firstOrNull,
      ),
);

/// Histórico de dias acima dos limiares de uma zona (dashboard de impacto).
final exceedanceHistoryProvider =
    Provider.family<List<DayExceedance>, String>((ref, zoneId) {
  final snap = ref.watch(zoneSnapshotProvider(zoneId)).valueOrNull;
  if (snap == null) return const [];
  return ref.watch(alertEngineProvider).historicalExceedances(
        snapshot: snap,
        thresholds: ref.watch(thresholdsProvider),
        now: DateTime.now(),
      );
});
