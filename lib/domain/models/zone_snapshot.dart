import 'hourly_point.dart';

/// De onde vieram os dados exibidos.
enum DataOrigin {
  api('Dados ao vivo (Open-Meteo)'),
  cache('Dados salvos no aparelho (offline)'),
  sample('Dados de exemplo (sintéticos)');

  const DataOrigin(this.label);
  final String label;
}

/// Série horária (histórico + previsão) de uma zona.
class ZoneSnapshot {
  const ZoneSnapshot({
    required this.zoneId,
    required this.points,
    required this.fetchedAt,
    required this.origin,
  });

  final String zoneId;

  /// Pontos ordenados por horário (passado e futuro).
  final List<HourlyPoint> points;
  final DateTime fetchedAt;
  final DataOrigin origin;

  ZoneSnapshot copyWith({DataOrigin? origin}) => ZoneSnapshot(
        zoneId: zoneId,
        points: points,
        fetchedAt: fetchedAt,
        origin: origin ?? this.origin,
      );

  List<HourlyPoint> history(DateTime now) =>
      points.where((p) => !p.time.isAfter(now)).toList();

  List<HourlyPoint> forecast(DateTime now) =>
      points.where((p) => p.time.isAfter(now)).toList();

  /// Ponto mais próximo do horário atual (último já ocorrido).
  HourlyPoint? current(DateTime now) {
    final past = history(now);
    return past.isEmpty ? (points.isEmpty ? null : points.first) : past.last;
  }

  bool isStale(DateTime now, Duration maxAge) =>
      now.difference(fetchedAt) > maxAge;

  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'fetchedAt': fetchedAt.toIso8601String(),
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory ZoneSnapshot.fromJson(
    Map<String, dynamic> json, {
    DataOrigin origin = DataOrigin.cache,
  }) =>
      ZoneSnapshot(
        zoneId: json['zoneId'] as String,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        points: (json['points'] as List)
            .map((e) => HourlyPoint.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        origin: origin,
      );
}
