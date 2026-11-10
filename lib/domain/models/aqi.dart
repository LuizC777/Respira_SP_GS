import 'alert.dart';

/// Categorias do índice de qualidade do ar (US AQI / EPA).
enum AqiCategory {
  good('Boa', null),
  moderate('Moderada', AlertSeverity.moderate),
  sensitive('Ruim para grupos sensíveis', AlertSeverity.high),
  unhealthy('Ruim', AlertSeverity.high),
  veryUnhealthy('Muito ruim', AlertSeverity.critical),
  hazardous('Perigosa', AlertSeverity.critical);

  const AqiCategory(this.label, this.severity);
  final String label;

  /// Severidade equivalente (null = sem risco) para reaproveitar as cores.
  final AlertSeverity? severity;

  static AqiCategory of(double? aqi) {
    if (aqi == null) return AqiCategory.good;
    if (aqi <= 50) return AqiCategory.good;
    if (aqi <= 100) return AqiCategory.moderate;
    if (aqi <= 150) return AqiCategory.sensitive;
    if (aqi <= 200) return AqiCategory.unhealthy;
    if (aqi <= 300) return AqiCategory.veryUnhealthy;
    return AqiCategory.hazardous;
  }
}

/// Converte concentração de PM2.5 (µg/m³) em US AQI (faixas EPA 2024).
double aqiFromPm25(double pm) {
  const bp = [
    // [cLow, cHigh, iLow, iHigh]
    [0.0, 9.0, 0.0, 50.0],
    [9.1, 35.4, 51.0, 100.0],
    [35.5, 55.4, 101.0, 150.0],
    [55.5, 125.4, 151.0, 200.0],
    [125.5, 225.4, 201.0, 300.0],
    [225.5, 500.0, 301.0, 500.0],
  ];
  final c = (pm * 10).floorToDouble() / 10;
  for (final b in bp) {
    if (c <= b[1]) {
      return ((b[3] - b[2]) / (b[1] - b[0])) * (c - b[0]) + b[2];
    }
  }
  return 500;
}
