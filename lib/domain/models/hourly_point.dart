/// Uma observação/previsão horária combinando qualidade do ar e clima.
/// Campos podem ser nulos quando a fonte não tem o dado para aquele horário.
class HourlyPoint {
  const HourlyPoint({
    required this.time,
    this.pm25,
    this.pm10,
    this.ozone,
    this.no2,
    this.usAqi,
    this.temperature,
    this.apparentTemperature,
    this.humidity,
    this.uvIndex,
  });

  final DateTime time;

  // Qualidade do ar (µg/m³; AQI adimensional)
  final double? pm25;
  final double? pm10;
  final double? ozone;
  final double? no2;
  final double? usAqi;

  // Clima
  final double? temperature; // °C
  final double? apparentTemperature; // °C
  final double? humidity; // %
  final double? uvIndex;

  HourlyPoint merge(HourlyPoint other) => HourlyPoint(
        time: time,
        pm25: pm25 ?? other.pm25,
        pm10: pm10 ?? other.pm10,
        ozone: ozone ?? other.ozone,
        no2: no2 ?? other.no2,
        usAqi: usAqi ?? other.usAqi,
        temperature: temperature ?? other.temperature,
        apparentTemperature: apparentTemperature ?? other.apparentTemperature,
        humidity: humidity ?? other.humidity,
        uvIndex: uvIndex ?? other.uvIndex,
      );

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        'pm25': pm25,
        'pm10': pm10,
        'o3': ozone,
        'no2': no2,
        'aqi': usAqi,
        'temp': temperature,
        'app': apparentTemperature,
        'hum': humidity,
        'uv': uvIndex,
      };

  factory HourlyPoint.fromJson(Map<String, dynamic> json) => HourlyPoint(
        time: DateTime.parse(json['t'] as String),
        pm25: _d(json['pm25']),
        pm10: _d(json['pm10']),
        ozone: _d(json['o3']),
        no2: _d(json['no2']),
        usAqi: _d(json['aqi']),
        temperature: _d(json['temp']),
        apparentTemperature: _d(json['app']),
        humidity: _d(json['hum']),
        uvIndex: _d(json['uv']),
      );

  static double? _d(Object? v) => v is num ? v.toDouble() : null;
}
