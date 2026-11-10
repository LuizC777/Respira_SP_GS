import 'package:flutter/material.dart';

enum ReportType {
  smoke('Fumaça ou queimada', Icons.local_fire_department_outlined),
  odor('Odor forte / poluição visível', Icons.cloud_outlined),
  symptom('Sintoma respiratório', Icons.masks_outlined),
  heat('Calor excessivo em local público', Icons.wb_sunny_outlined);

  const ReportType(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Ocorrência registrada pelo cidadão. ANÔNIMA por design:
/// não guarda nome, documento, contato nem localização exata — só a zona.
class CitizenReport {
  const CitizenReport({
    required this.id,
    required this.type,
    required this.zoneId,
    required this.description,
    required this.occurredOn,
    required this.createdAt,
  });

  final String id;
  final ReportType type;
  final String zoneId;
  final String description;
  final DateTime occurredOn;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'zoneId': zoneId,
        'description': description,
        'occurredOn': occurredOn.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CitizenReport.fromJson(Map<String, dynamic> json) => CitizenReport(
        id: json['id'] as String,
        type: ReportType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => ReportType.smoke,
        ),
        zoneId: json['zoneId'] as String,
        description: json['description'] as String? ?? '',
        occurredOn: DateTime.parse(json['occurredOn'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
