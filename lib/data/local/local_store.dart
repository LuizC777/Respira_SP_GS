import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/citizen_report.dart';
import '../../domain/models/human_decision.dart';
import '../../domain/models/thresholds.dart';
import '../../domain/models/zone_snapshot.dart';

/// Acesso centralizado à persistência local (Hive).
/// Os objetos são salvos como JSON (String), sem geração de código.
class LocalStore {
  LocalStore._();

  static final LocalStore instance = LocalStore._();

  static Future<void> init() async {
    await Hive.initFlutter();
    for (final name in HiveBoxes.all) {
      await Hive.openBox<String>(name);
    }
  }

  Box<String> get _cache => Hive.box<String>(HiveBoxes.cache);
  Box<String> get _settings => Hive.box<String>(HiveBoxes.settings);
  Box<String> get _reports => Hive.box<String>(HiveBoxes.reports);
  Box<String> get _decisions => Hive.box<String>(HiveBoxes.decisions);
  Box<String> get _notified => Hive.box<String>(HiveBoxes.notified);

  // ------------------------------------------------------- cache offline

  Future<void> saveSnapshot(ZoneSnapshot s) =>
      _cache.put('snapshot_${s.zoneId}', jsonEncode(s.toJson()));

  ZoneSnapshot? readSnapshot(String zoneId) {
    final raw = _cache.get('snapshot_$zoneId');
    if (raw == null) return null;
    try {
      return ZoneSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        origin: DataOrigin.cache,
      );
    } catch (_) {
      return null; // cache corrompido é ignorado
    }
  }

  // ----------------------------------------------------- configurações

  AppSettings readSettings() => _readJson(
        _settings.get('app'),
        AppSettings.fromJson,
        const AppSettings(),
      );

  Future<void> saveSettings(AppSettings s) =>
      _settings.put('app', jsonEncode(s.toJson()));

  Thresholds readThresholds() => _readJson(
        _settings.get('thresholds'),
        Thresholds.fromJson,
        const Thresholds(),
      );

  Future<void> saveThresholds(Thresholds t) =>
      _settings.put('thresholds', jsonEncode(t.toJson()));

  // ----------------------------------------------------------- ocorrências

  List<CitizenReport> readReports() {
    final list = <CitizenReport>[];
    for (final raw in _reports.values) {
      try {
        list.add(CitizenReport.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // registro inválido é ignorado
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveReport(CitizenReport r) =>
      _reports.put(r.id, jsonEncode(r.toJson()));

  Future<void> deleteReport(String id) => _reports.delete(id);

  // -------------------------------------------------- decisões do gestor

  Map<String, HumanDecision> readDecisions() {
    final map = <String, HumanDecision>{};
    for (final raw in _decisions.values) {
      try {
        final d = HumanDecision.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        map[d.alertId] = d;
      } catch (_) {
        // registro inválido é ignorado
      }
    }
    return map;
  }

  Future<void> saveDecision(HumanDecision d) =>
      _decisions.put(d.alertId, jsonEncode(d.toJson()));

  Future<void> deleteDecision(String alertId) => _decisions.delete(alertId);

  // ------------------------------------------- notificações já enviadas

  bool wasNotified(String alertId) => _notified.containsKey(alertId);

  Future<void> markNotified(String alertId) =>
      _notified.put(alertId, DateTime.now().toIso8601String());

  // ------------------------------------------------------------ privacidade

  /// "Apagar meus dados": remove tudo o que foi gerado pelo usuário.
  Future<void> clearUserData() async {
    await Future.wait([
      _reports.clear(),
      _decisions.clear(),
      _notified.clear(),
      _cache.clear(),
      _settings.clear(),
    ]);
  }

  T _readJson<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
    T fallback,
  ) {
    if (raw == null) return fallback;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return fallback;
    }
  }
}
