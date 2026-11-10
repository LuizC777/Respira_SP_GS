import 'package:flutter/material.dart';

enum AlertType {
  airQuality('Qualidade do ar', Icons.air),
  heat('Calor extremo', Icons.thermostat),
  combined('Risco combinado: ar + calor', Icons.warning_amber_rounded),
  worseningTrend('Tendência de piora do ar', Icons.trending_up);

  const AlertType(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum AlertSeverity {
  moderate('Moderado', Icons.info_outline),
  high('Alto', Icons.error_outline),
  critical('Crítico', Icons.report_gmailerrorred);

  const AlertSeverity(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum ConfidenceLevel {
  high('Alta'),
  medium('Média'),
  low('Baixa');

  const ConfidenceLevel(this.label);
  final String label;
}

/// Situação do alerta em relação à decisão humana.
enum AlertStatus {
  pending('Aguardando análise'),
  confirmed('Confirmado pelo gestor'),
  dismissed('Descartado pelo gestor');

  const AlertStatus(this.label);
  final String label;
}

/// Nível de confiança calculado por pontos, com os motivos explícitos.
class Confidence {
  const Confidence({required this.score, required this.reasons});

  /// 0 a 100.
  final int score;

  /// Fatores que reduziram (ou sustentam) a confiança.
  final List<String> reasons;

  ConfidenceLevel get level => score >= 70
      ? ConfidenceLevel.high
      : score >= 45
          ? ConfidenceLevel.medium
          : ConfidenceLevel.low;
}

/// Uma evidência numérica que sustenta o alerta.
class EvidenceItem {
  const EvidenceItem({
    required this.label,
    required this.value,
    required this.unit,
    this.threshold,
  });

  final String label;
  final double value;
  final String unit;
  final double? threshold;

  bool get exceeds => threshold != null && value > threshold!;
}

class SeriesPoint {
  const SeriesPoint(this.time, this.value);
  final DateTime time;
  final double value;
}

/// Alerta preditivo gerado pelo AlertEngine. Nunca aciona nada sozinho:
/// apenas informa o gestor, que decide.
class Alert {
  const Alert({
    required this.id,
    required this.zoneId,
    required this.type,
    required this.severity,
    required this.title,
    required this.summary,
    required this.rule,
    required this.evidence,
    required this.confidence,
    required this.limitations,
    required this.windowStart,
    required this.windowEnd,
    required this.generatedAt,
    required this.series,
    required this.seriesLabel,
    required this.seriesUnit,
    this.seriesThreshold,
    this.status = AlertStatus.pending,
  });

  /// Determinístico (zona + tipo + dia) para que a decisão humana
  /// continue associada ao mesmo alerta após recálculos.
  final String id;
  final String zoneId;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String summary;

  /// Regra em linguagem simples ("PM2.5 médio previsto > limiar").
  final String rule;
  final List<EvidenceItem> evidence;
  final Confidence confidence;
  final List<String> limitations;
  final DateTime windowStart;
  final DateTime windowEnd;
  final DateTime generatedAt;

  /// Série usada no mini-gráfico de evidência.
  final List<SeriesPoint> series;
  final String seriesLabel;
  final String seriesUnit;
  final double? seriesThreshold;

  final AlertStatus status;

  bool get isActive => status != AlertStatus.dismissed;

  Alert withStatus(AlertStatus newStatus) => Alert(
        id: id,
        zoneId: zoneId,
        type: type,
        severity: severity,
        title: title,
        summary: summary,
        rule: rule,
        evidence: evidence,
        confidence: confidence,
        limitations: limitations,
        windowStart: windowStart,
        windowEnd: windowEnd,
        generatedAt: generatedAt,
        series: series,
        seriesLabel: seriesLabel,
        seriesUnit: seriesUnit,
        seriesThreshold: seriesThreshold,
        status: newStatus,
      );
}
