import '../../core/constants/app_constants.dart';

/// Limiares configuráveis pelo gestor que disparam os alertas.
class Thresholds {
  const Thresholds({
    this.pm25Daily = HealthGuidelines.pm25Daily,
    this.apparentTemp = HealthGuidelines.heatApparent,
    this.heatMinHours = HealthGuidelines.heatMinHours,
  });

  /// Média diária de PM2.5 (µg/m³).
  final double pm25Daily;

  /// Sensação térmica (°C).
  final double apparentTemp;

  /// Horas mínimas no dia com sensação acima do limiar.
  final int heatMinHours;

  // Faixas válidas (usadas na validação do formulário).
  static const pm25Min = 5.0;
  static const pm25Max = 150.0;
  static const tempMin = 25.0;
  static const tempMax = 50.0;
  static const hoursMin = 1;
  static const hoursMax = 12;

  Thresholds copyWith({
    double? pm25Daily,
    double? apparentTemp,
    int? heatMinHours,
  }) =>
      Thresholds(
        pm25Daily: pm25Daily ?? this.pm25Daily,
        apparentTemp: apparentTemp ?? this.apparentTemp,
        heatMinHours: heatMinHours ?? this.heatMinHours,
      );

  bool get isDefault =>
      pm25Daily == HealthGuidelines.pm25Daily &&
      apparentTemp == HealthGuidelines.heatApparent &&
      heatMinHours == HealthGuidelines.heatMinHours;

  Map<String, dynamic> toJson() => {
        'pm25Daily': pm25Daily,
        'apparentTemp': apparentTemp,
        'heatMinHours': heatMinHours,
      };

  factory Thresholds.fromJson(Map<String, dynamic> json) => Thresholds(
        pm25Daily: (json['pm25Daily'] as num?)?.toDouble() ??
            HealthGuidelines.pm25Daily,
        apparentTemp: (json['apparentTemp'] as num?)?.toDouble() ??
            HealthGuidelines.heatApparent,
        heatMinHours:
            (json['heatMinHours'] as num?)?.toInt() ?? HealthGuidelines.heatMinHours,
      );

  @override
  bool operator ==(Object other) =>
      other is Thresholds &&
      other.pm25Daily == pm25Daily &&
      other.apparentTemp == apparentTemp &&
      other.heatMinHours == heatMinHours;

  @override
  int get hashCode => Object.hash(pm25Daily, apparentTemp, heatMinHours);
}
