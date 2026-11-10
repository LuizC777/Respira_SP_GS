import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:respira_sp/core/constants/zones_data.dart';
import 'package:respira_sp/data/services/open_meteo_service.dart';
import 'package:respira_sp/domain/models/zone_snapshot.dart';

void main() {
  final airJson = {
    'hourly': {
      'time': ['2026-11-10T00:00', '2026-11-10T01:00'],
      'pm2_5': [12.5, null],
      'pm10': [20.0, 21.0],
      'ozone': [40, 42],
      'nitrogen_dioxide': [18.0, 17.0],
      'us_aqi': [52, 53],
    },
  };
  final weatherJson = {
    'hourly': {
      'time': ['2026-11-10T00:00', '2026-11-10T01:00'],
      'temperature_2m': [22.1, 21.8],
      'apparent_temperature': [23.0, 22.5],
      'relative_humidity_2m': [80, 82],
      'uv_index': [0, 0],
    },
  };

  test('converte e une as séries de ar e clima pelo horário', () async {
    final client = MockClient((request) async {
      final body = request.url.host.startsWith('air') ? airJson : weatherJson;
      expect(request.url.queryParameters['timezone'], 'America/Sao_Paulo');
      expect(request.url.queryParameters['timeformat'], 'unixtime');
      return http.Response(jsonEncode(body), 200);
    });
    final service = OpenMeteoService(client: client);
    final snap = await service.fetchZone(zoneById('centro'));

    expect(snap.origin, DataOrigin.api);
    expect(snap.points, hasLength(2));
    final first = snap.points.first;
    expect(first.pm25, 12.5);
    expect(first.ozone, 40.0);
    expect(first.temperature, 22.1);
    expect(first.apparentTemperature, 23.0);
    expect(snap.points[1].pm25, isNull); // valor nulo na API é preservado
  });

  test('aceita horários em unixtime', () {
    final points = OpenMeteoService.parseAir({
      'hourly': {
        'time': [1762743600],
        'pm2_5': [10],
      },
    });
    expect(points.single.time.toUtc(), DateTime.utc(2025, 11, 10, 3));
    expect(points.single.pm25, 10.0);
  });

  test('erro HTTP vira OpenMeteoException', () async {
    final client = MockClient((_) async => http.Response('erro', 500));
    final service = OpenMeteoService(client: client);
    expect(
      () => service.fetchZone(zoneById('centro')),
      throwsA(isA<OpenMeteoException>()),
    );
  });

  test('resposta com error=true vira OpenMeteoException', () async {
    final client = MockClient((_) async =>
        http.Response(jsonEncode({'error': true, 'reason': 'Parâmetro inválido'}), 400));
    final service = OpenMeteoService(client: client);
    expect(
      () => service.fetchZone(zoneById('centro')),
      throwsA(isA<OpenMeteoException>()),
    );
  });
}
