import '../../core/constants/zones_data.dart';
import '../../domain/models/zone_snapshot.dart';
import '../local/local_store.dart';
import '../services/open_meteo_service.dart';
import '../services/sample_data_generator.dart';

/// Resultado de um carregamento do território.
class TerritoryData {
  const TerritoryData({
    required this.snapshots,
    required this.loadedAt,
    this.failures = const {},
  });

  final Map<String, ZoneSnapshot> snapshots;
  final DateTime loadedAt;

  /// Zonas cuja busca na API falhou (id -> motivo).
  final Map<String, String> failures;

  bool get isOffline => failures.isNotEmpty;

  /// Origem "pior" entre as zonas (sample > cache > api).
  DataOrigin get origin {
    final origins = snapshots.values.map((s) => s.origin).toSet();
    if (origins.contains(DataOrigin.sample)) return DataOrigin.sample;
    if (origins.contains(DataOrigin.cache)) return DataOrigin.cache;
    return DataOrigin.api;
  }

  DateTime? get oldestFetch => snapshots.values.isEmpty
      ? null
      : snapshots.values
          .map((s) => s.fetchedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
}

/// Estratégia de dados: API → cache local → dados de exemplo.
/// Assim o app continua útil sem conexão.
class TerritoryRepository {
  TerritoryRepository({
    required OpenMeteoService service,
    required LocalStore store,
    SampleDataGenerator sample = const SampleDataGenerator(),
  })  : _service = service,
        _store = store,
        _sample = sample;

  final OpenMeteoService _service;
  final LocalStore _store;
  final SampleDataGenerator _sample;

  Future<TerritoryData> load({bool useSampleData = false}) async {
    final now = DateTime.now();
    if (useSampleData) {
      return TerritoryData(
        snapshots: {for (final z in kZones) z.id: _sample.generate(z, now: now)},
        loadedAt: now,
      );
    }

    final snapshots = <String, ZoneSnapshot>{};
    final failures = <String, String>{};

    await Future.wait(kZones.map((zone) async {
      try {
        final snap = await _service.fetchZone(zone);
        snapshots[zone.id] = snap;
        await _store.saveSnapshot(snap);
      } catch (e) {
        failures[zone.id] = e is OpenMeteoException ? e.message : e.toString();
        snapshots[zone.id] =
            _store.readSnapshot(zone.id) ?? _sample.generate(zone, now: now);
      }
    }));

    return TerritoryData(
      snapshots: snapshots,
      loadedAt: now,
      failures: failures,
    );
  }
}
