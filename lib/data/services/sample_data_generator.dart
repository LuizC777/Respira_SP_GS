import 'dart:math' as math;

import '../../domain/models/aqi.dart';
import '../../domain/models/hourly_point.dart';
import '../../domain/models/zone.dart';
import '../../domain/models/zone_snapshot.dart';

/// Gera dados SINTÉTICOS e determinísticos (30 dias de histórico + 5 de
/// previsão) para quando não há conexão nem cache, e para o modo
/// demonstração. Os perfis foram desenhados para exercitar todas as regras:
/// - Leste: pico de PM2.5 amanhã (alerta de ar)
/// - Sul: PM2.5 alto + calor no mesmo dia (alerta combinado)
/// - Centro: calor extremo hoje/amanhã (alerta de calor)
/// - Norte: PM2.5 subindo há 7 dias, ainda abaixo do limiar (tendência)
/// - Oeste: sem alertas
class SampleDataGenerator {
  const SampleDataGenerator();

  ZoneSnapshot generate(Zone zone, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final rnd = math.Random(zone.id.codeUnits.fold<int>(7, (a, b) => a * 31 + b));
    final points = <HourlyPoint>[];

    for (var offset = -30; offset <= 4; offset++) {
      final day = today.add(Duration(days: offset));
      final pmMean = _dailyPm(zone.id, offset);
      final tempMean = _dailyTemp(zone.id, offset);
      for (var h = 0; h < 24; h++) {
        final time = DateTime(day.year, day.month, day.day, h);
        final diurnal = math.sin(2 * math.pi * (h - 3) / 24); // média zero
        final pm25 = math.max(1.0, pmMean * (1 + 0.35 * diurnal) + rnd.nextDouble() - 0.5);
        final temp = tempMean + 5.5 * math.sin(2 * math.pi * (h - 9) / 24);
        final humidity = (75 - 20 * math.sin(2 * math.pi * (h - 9) / 24))
            .clamp(30.0, 98.0)
            .toDouble();
        final apparent = temp + (temp > 27 ? (temp - 27) * 0.45 : 0) + 0.6;
        final uv = h < 6 || h > 18 ? 0.0 : 11 * math.sin(math.pi * (h - 6) / 12);
        points.add(HourlyPoint(
          time: time,
          pm25: _r(pm25),
          pm10: _r(pm25 * 1.8),
          ozone: _r(45 + 35 * math.sin(2 * math.pi * (h - 9) / 24)),
          no2: _r(22 + 10 * math.cos(2 * math.pi * (h - 8) / 12)),
          usAqi: aqiFromPm25(pm25).roundToDouble(),
          temperature: _r(temp),
          apparentTemperature: _r(apparent),
          humidity: _r(humidity),
          uvIndex: _r(uv),
        ));
      }
    }

    return ZoneSnapshot(
      zoneId: zone.id,
      points: points,
      fetchedAt: ref,
      origin: DataOrigin.sample,
    );
  }

  double _dailyPm(String zoneId, int offset) {
    final wave = 1.8 * math.sin(offset * 0.7 + zoneId.length);
    switch (zoneId) {
      case 'leste':
        if (offset == 1) return 34;
        if (offset == 2) return 27;
        if (offset == -12 || offset == -20) return 22;
        return 11 + wave;
      case 'sul':
        if (offset == 2) return 25;
        if (offset == -18) return 19;
        return 10 + wave;
      case 'norte':
        // Subida linear nos últimos 7 dias, sem passar o limiar.
        if (offset >= -7 && offset <= -1) return 4 + (offset + 7) * 1.7;
        if (offset >= 0) return 13.5;
        return 8 + wave;
      case 'centro':
        if (offset == -9) return 18;
        return 9.5 + wave;
      default:
        return 7 + wave;
    }
  }

  double _dailyTemp(String zoneId, int offset) {
    final wave = 1.5 * math.sin(offset * 0.45 + zoneId.length);
    final base = 23 + wave;
    if (zoneId == 'centro' && (offset == 0 || offset == 1)) return 31.5;
    if (zoneId == 'sul' && offset == 2) return 31;
    if (offset == -15 || offset == -6) return 30.5; // ondas de calor passadas
    return base;
  }

  double _r(double v) => (v * 10).roundToDouble() / 10;
}
