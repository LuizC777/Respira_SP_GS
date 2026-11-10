import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/local_store.dart';
import '../data/repositories/territory_repository.dart';
import '../data/services/open_meteo_service.dart';
import '../domain/engine/alert_engine.dart';

/// Dependências (injeção via Riverpod — podem ser sobrescritas em testes).
final localStoreProvider = Provider<LocalStore>((ref) => LocalStore.instance);

final openMeteoServiceProvider =
    Provider<OpenMeteoService>((ref) => OpenMeteoService());

final territoryRepositoryProvider = Provider<TerritoryRepository>(
  (ref) => TerritoryRepository(
    service: ref.watch(openMeteoServiceProvider),
    store: ref.watch(localStoreProvider),
  ),
);

final alertEngineProvider = Provider<AlertEngine>((ref) => const AlertEngine());
