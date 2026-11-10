import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/zones_data.dart';
import '../domain/models/alert.dart';
import '../domain/models/citizen_report.dart';
import 'alert_providers.dart';
import 'core_providers.dart';

/// ESTADO GLOBAL: ocorrências anônimas registradas neste aparelho.
class ReportsNotifier extends Notifier<List<CitizenReport>> {
  @override
  List<CitizenReport> build() => ref.read(localStoreProvider).readReports();

  Future<void> add({
    required ReportType type,
    required String zoneId,
    required String description,
    required DateTime occurredOn,
  }) async {
    final now = DateTime.now();
    final report = CitizenReport(
      // id aleatório local — não identifica o usuário
      id: '${now.microsecondsSinceEpoch}',
      type: type,
      zoneId: zoneId,
      description: description.trim(),
      occurredOn: occurredOn,
      createdAt: now,
    );
    state = [report, ...state];
    await ref.read(localStoreProvider).saveReport(report);
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    await ref.read(localStoreProvider).deleteReport(id);
  }

  void resetToDefaults() => state = const [];
}

final reportsProvider =
    NotifierProvider<ReportsNotifier, List<CitizenReport>>(ReportsNotifier.new);

/// Indicadores de benefício social exibidos no app.
class SocialImpact {
  const SocialImpact({
    required this.peopleInAlertZones,
    required this.schoolsInAlertZones,
    required this.healthUnitsInAlertZones,
    required this.zonesWithAlerts,
    required this.pendingAlerts,
    required this.confirmedAlerts,
    required this.reports,
  });

  /// População estimada em zonas com alerta ativo (alto ou crítico).
  final int peopleInAlertZones;
  final int schoolsInAlertZones;
  final int healthUnitsInAlertZones;
  final int zonesWithAlerts;
  final int pendingAlerts;
  final int confirmedAlerts;
  final int reports;
}

final socialImpactProvider = Provider<SocialImpact>((ref) {
  final alerts = ref.watch(alertsProvider).valueOrNull ?? const [];
  final reports = ref.watch(reportsProvider);
  final active = alerts.where(
    (a) => a.isActive && a.severity != AlertSeverity.moderate,
  );
  final zoneIds = active.map((a) => a.zoneId).toSet();
  final zones = zoneIds.map(zoneById);
  return SocialImpact(
    peopleInAlertZones: zones.fold(0, (sum, z) => sum + z.population),
    schoolsInAlertZones: zones.fold(0, (sum, z) => sum + z.schools),
    healthUnitsInAlertZones: zones.fold(0, (sum, z) => sum + z.healthUnits),
    zonesWithAlerts: zoneIds.length,
    pendingAlerts: alerts.where((a) => a.status == AlertStatus.pending).length,
    confirmedAlerts:
        alerts.where((a) => a.status == AlertStatus.confirmed).length,
    reports: reports.length,
  );
});
