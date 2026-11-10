/// Constantes gerais do app.
abstract final class AppConstants {
  static const appName = 'Respira SP';
  static const tagline =
      'Antecipe dias de risco por poluição e calor nas zonas de São Paulo.';

  static const timezone = 'America/Sao_Paulo';

  /// Dias de histórico e de previsão buscados na API.
  static const pastDays = 30;
  static const forecastDays = 5;

  /// Após esse tempo os dados em cache são considerados desatualizados.
  static const staleAfter = Duration(hours: 6);

  /// Aviso exibido em todas as telas de alertas.
  static const humanDecisionNotice =
      'Os alertas apoiam, mas não substituem, a decisão humana. '
      'Nenhuma ação é tomada automaticamente pelo app.';

  static const attribution =
      'Dados de qualidade do ar: Copernicus Atmosphere Monitoring Service '
      '(CAMS), via Open-Meteo. Dados meteorológicos: Open-Meteo.com (CC BY 4.0).';
}

/// Nomes das caixas Hive (persistência local).
abstract final class HiveBoxes {
  static const cache = 'cache_v1';
  static const settings = 'settings_v1';
  static const reports = 'reports_v1';
  static const decisions = 'decisions_v1';
  static const notified = 'notified_v1';

  static const all = [cache, settings, reports, decisions, notified];
}

/// Diretriz da OMS (2021) para PM2.5 — média de 24h.
abstract final class HealthGuidelines {
  static const pm25Daily = 15.0; // µg/m³
  static const heatApparent = 35.0; // °C de sensação térmica
  static const heatMinHours = 3;
}
