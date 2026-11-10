import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/app_settings.dart';
import '../domain/models/thresholds.dart';
import 'core_providers.dart';

/// ESTADO GLOBAL: preferências (tema, fonte, notificações, consentimento).
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(localStoreProvider).readSettings();

  Future<void> _save(AppSettings s) async {
    state = s;
    await ref.read(localStoreProvider).saveSettings(s);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _save(state.copyWith(themeMode: mode));

  Future<void> setTextScale(double scale) => _save(state.copyWith(
        textScale: scale
            .clamp(AppSettings.textScaleMin, AppSettings.textScaleMax)
            .toDouble(),
      ));

  Future<void> setNotifications(bool enabled) =>
      _save(state.copyWith(notificationsEnabled: enabled));

  Future<void> setUseSampleData(bool value) =>
      _save(state.copyWith(useSampleData: value));

  Future<void> giveConsent() =>
      _save(state.copyWith(consentGiven: true, consentDate: DateTime.now()));

  /// Após "apagar meus dados" volta ao estado inicial (sem consentimento).
  void resetToDefaults() => state = const AppSettings();
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// ESTADO GLOBAL: limiares de alerta configurados pelo gestor.
class ThresholdsNotifier extends Notifier<Thresholds> {
  @override
  Thresholds build() => ref.read(localStoreProvider).readThresholds();

  Future<void> update(Thresholds t) async {
    state = t;
    await ref.read(localStoreProvider).saveThresholds(t);
  }

  Future<void> restoreDefaults() => update(const Thresholds());

  void resetToDefaults() => state = const Thresholds();
}

final thresholdsProvider =
    NotifierProvider<ThresholdsNotifier, Thresholds>(ThresholdsNotifier.new);
