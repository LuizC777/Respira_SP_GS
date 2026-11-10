import 'package:flutter/material.dart';

/// Preferências do usuário persistidas localmente.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.notificationsEnabled = true,
    this.consentGiven = false,
    this.consentDate,
    this.useSampleData = false,
  });

  final ThemeMode themeMode;

  /// Multiplicador extra de fonte (somado à configuração do sistema).
  final double textScale;
  final bool notificationsEnabled;
  final bool consentGiven;
  final DateTime? consentDate;

  /// Modo demonstração: força os dados sintéticos (útil para apresentar
  /// todas as regras de alerta mesmo em dias de ar limpo).
  final bool useSampleData;

  static const textScaleMin = 1.0;
  static const textScaleMax = 1.6;

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? notificationsEnabled,
    bool? consentGiven,
    DateTime? consentDate,
    bool? useSampleData,
    bool clearConsentDate = false,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        textScale: textScale ?? this.textScale,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        consentGiven: consentGiven ?? this.consentGiven,
        consentDate: clearConsentDate ? null : (consentDate ?? this.consentDate),
        useSampleData: useSampleData ?? this.useSampleData,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'textScale': textScale,
        'notificationsEnabled': notificationsEnabled,
        'consentGiven': consentGiven,
        'consentDate': consentDate?.toIso8601String(),
        'useSampleData': useSampleData,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values.firstWhere(
          (m) => m.name == json['themeMode'],
          orElse: () => ThemeMode.system,
        ),
        textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        consentGiven: json['consentGiven'] as bool? ?? false,
        consentDate: json['consentDate'] == null
            ? null
            : DateTime.tryParse(json['consentDate'] as String),
        useSampleData: json['useSampleData'] as bool? ?? false,
      );
}
