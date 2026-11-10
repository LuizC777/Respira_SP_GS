import 'dart:async' show TimeoutException;
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../domain/models/hourly_point.dart';
import '../../domain/models/zone.dart';
import '../../domain/models/zone_snapshot.dart';

class OpenMeteoException implements Exception {
  const OpenMeteoException(this.message);
  final String message;
  @override
  String toString() => 'OpenMeteoException: $message';
}

/// Cliente das APIs públicas da Open-Meteo (sem chave de API).
/// - Qualidade do ar: modelo CAMS (Copernicus)
/// - Clima: previsão meteorológica
class OpenMeteoService {
  OpenMeteoService({http.Client? client, this.timeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static const _airHost = 'air-quality-api.open-meteo.com';
  static const _weatherHost = 'api.open-meteo.com';

  static const airVariables = 'pm2_5,pm10,ozone,nitrogen_dioxide,us_aqi';
  static const weatherVariables =
      'temperature_2m,apparent_temperature,relative_humidity_2m,uv_index';

  Future<ZoneSnapshot> fetchZone(Zone zone) async {
    final results = await Future.wait([
      _get(_airHost, '/v1/air-quality', zone, airVariables),
      _get(_weatherHost, '/v1/forecast', zone, weatherVariables),
    ]);
    final air = parseAir(results[0]);
    final weather = parseWeather(results[1]);
    return ZoneSnapshot(
      zoneId: zone.id,
      points: mergeSeries(air, weather),
      fetchedAt: DateTime.now(),
      origin: DataOrigin.api,
    );
  }

  Future<Map<String, dynamic>> _get(
    String host,
    String path,
    Zone zone,
    String hourly,
  ) async {
    final uri = Uri.https(host, path, {
      'latitude': zone.latitude.toString(),
      'longitude': zone.longitude.toString(),
      'hourly': hourly,
      'past_days': AppConstants.pastDays.toString(),
      'forecast_days': AppConstants.forecastDays.toString(),
      'timezone': AppConstants.timezone,
      // Epoch em segundos: converte certo para o fuso do aparelho/emulador.
      'timeformat': 'unixtime',
    });
    final response = await _send(uri);
    if (response.statusCode != 200) {
      throw OpenMeteoException('HTTP ${response.statusCode} em $path');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw const OpenMeteoException('Resposta em formato inesperado.');
    }
    if (body['error'] == true) {
      throw OpenMeteoException(body['reason']?.toString() ?? 'Erro na API.');
    }
    return body;
  }

  Future<http.Response> _send(Uri uri) async {
    try {
      return await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const OpenMeteoException('Tempo de resposta esgotado.');
    } catch (e) {
      throw OpenMeteoException('Falha de conexão: $e');
    }
  }

  // ------------------------------------------------------------- parsing
  // Métodos estáticos e públicos para poderem ser testados isoladamente.

  static List<HourlyPoint> parseAir(Map<String, dynamic> json) {
    final h = _hourly(json);
    final times = _times(h);
    return [
      for (var i = 0; i < times.length; i++)
        HourlyPoint(
          time: times[i],
          pm25: _at(h['pm2_5'], i),
          pm10: _at(h['pm10'], i),
          ozone: _at(h['ozone'], i),
          no2: _at(h['nitrogen_dioxide'], i),
          usAqi: _at(h['us_aqi'], i),
        ),
    ];
  }

  static List<HourlyPoint> parseWeather(Map<String, dynamic> json) {
    final h = _hourly(json);
    final times = _times(h);
    return [
      for (var i = 0; i < times.length; i++)
        HourlyPoint(
          time: times[i],
          temperature: _at(h['temperature_2m'], i),
          apparentTemperature: _at(h['apparent_temperature'], i),
          humidity: _at(h['relative_humidity_2m'], i),
          uvIndex: _at(h['uv_index'], i),
        ),
    ];
  }

  /// Une as duas séries pelo horário.
  static List<HourlyPoint> mergeSeries(
    List<HourlyPoint> a,
    List<HourlyPoint> b,
  ) {
    final byTime = <DateTime, HourlyPoint>{};
    for (final p in [...a, ...b]) {
      byTime[p.time] = byTime[p.time]?.merge(p) ?? p;
    }
    final times = byTime.keys.toList()..sort();
    return [for (final t in times) byTime[t]!];
  }

  static Map<String, dynamic> _hourly(Map<String, dynamic> json) {
    final h = json['hourly'];
    if (h is! Map) throw const OpenMeteoException('Resposta sem "hourly".');
    return Map<String, dynamic>.from(h);
  }

  static List<DateTime> _times(Map<String, dynamic> h) {
    final raw = h['time'];
    if (raw is! List) throw const OpenMeteoException('Resposta sem horários.');
    return raw.map((t) {
      if (t is num) {
        return DateTime.fromMillisecondsSinceEpoch(t.toInt() * 1000);
      }
      return DateTime.parse(t as String);
    }).toList();
  }

  static double? _at(Object? list, int i) {
    if (list is! List || i >= list.length) return null;
    final v = list[i];
    return v is num ? v.toDouble() : null;
  }
}
