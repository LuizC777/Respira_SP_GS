import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/zones_data.dart';
import '../data/repositories/territory_repository.dart';
import '../domain/models/zone_snapshot.dart';
import 'core_providers.dart';
import 'settings_providers.dart';

/// ESTADO GLOBAL: dados do território (todas as zonas), com
/// carregamento/erro tratados via AsyncValue.
class TerritoryNotifier extends AsyncNotifier<TerritoryData> {
  @override
  Future<TerritoryData> build() {
    final useSample =
        ref.watch(settingsProvider.select((s) => s.useSampleData));
    return ref.read(territoryRepositoryProvider).load(useSampleData: useSample);
  }
}

/// Recarrega os dados mantendo os anteriores visíveis durante a busca
/// (AsyncValue.isRefreshing). Usado no "puxar para atualizar".
Future<void> refreshTerritory(WidgetRef ref) =>
    ref.refresh(territoryProvider.future);

final territoryProvider =
    AsyncNotifierProvider<TerritoryNotifier, TerritoryData>(
  TerritoryNotifier.new,
);

/// Snapshot de uma zona específica.
final zoneSnapshotProvider =
    Provider.family<AsyncValue<ZoneSnapshot?>, String>((ref, zoneId) {
  return ref
      .watch(territoryProvider)
      .whenData((data) => data.snapshots[zoneId]);
});

/// ESTADO GLOBAL: zona selecionada (compartilhada entre home e dashboards).
class SelectedZoneNotifier extends Notifier<String> {
  @override
  String build() => kZones.first.id;

  void select(String zoneId) => state = zoneId;
}

final selectedZoneProvider =
    NotifierProvider<SelectedZoneNotifier, String>(SelectedZoneNotifier.new);
