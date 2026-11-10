import 'alert.dart';

/// Decisão registrada pelo gestor sobre um alerta.
class HumanDecision {
  const HumanDecision({
    required this.alertId,
    required this.status,
    required this.justification,
    required this.decidedAt,
  });

  final String alertId;
  final AlertStatus status;
  final String justification;
  final DateTime decidedAt;

  Map<String, dynamic> toJson() => {
        'alertId': alertId,
        'status': status.name,
        'justification': justification,
        'decidedAt': decidedAt.toIso8601String(),
      };

  factory HumanDecision.fromJson(Map<String, dynamic> json) => HumanDecision(
        alertId: json['alertId'] as String,
        status: AlertStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => AlertStatus.pending,
        ),
        justification: json['justification'] as String? ?? '',
        decidedAt: DateTime.parse(json['decidedAt'] as String),
      );
}
