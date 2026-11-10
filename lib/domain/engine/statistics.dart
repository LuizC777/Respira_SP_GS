import 'dart:math' as math;

import '../models/hourly_point.dart';

/// Média diária de uma variável, por dia do calendário.
class DailyValue {
  const DailyValue({
    required this.day,
    required this.mean,
    required this.max,
    required this.samples,
    required this.expectedSamples,
  });

  final DateTime day;
  final double mean;
  final double max;
  final int samples;
  final int expectedSamples;

  /// Fração de horas sem dado (0 = completo).
  double get missingRatio =>
      expectedSamples == 0
          ? 1.0
          : 1.0 - (samples / expectedSamples).clamp(0.0, 1.0).toDouble();
}

/// Resultado de uma regressão linear simples (mínimos quadrados).
class LinearTrend {
  const LinearTrend({
    required this.slope,
    required this.intercept,
    required this.r2,
    required this.n,
  });

  /// Variação por unidade de x (aqui: por dia).
  final double slope;
  final double intercept;

  /// Coeficiente de determinação (0–1): quão bem a reta explica os dados.
  final double r2;
  final int n;

  double predict(double x) => intercept + slope * x;
}

abstract final class Stats {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Agrupa pontos horários por dia e calcula média e máximo.
  static List<DailyValue> dailyValues(
    List<HourlyPoint> points,
    double? Function(HourlyPoint) selector,
  ) {
    final byDay = <DateTime, List<double>>{};
    final hoursPerDay = <DateTime, int>{};
    for (final p in points) {
      final day = dateOnly(p.time);
      hoursPerDay[day] = (hoursPerDay[day] ?? 0) + 1;
      final v = selector(p);
      if (v != null && !v.isNaN) (byDay[day] ??= []).add(v);
    }
    final days = hoursPerDay.keys.toList()..sort();
    return [
      for (final day in days)
        if ((byDay[day] ?? const []).isNotEmpty)
          DailyValue(
            day: day,
            mean: mean(byDay[day]!),
            max: byDay[day]!.reduce(math.max),
            samples: byDay[day]!.length,
            expectedSamples: hoursPerDay[day]!,
          ),
    ];
  }

  static double mean(List<double> values) =>
      values.isEmpty ? double.nan : values.reduce((a, b) => a + b) / values.length;

  /// Regressão linear y = a + b·x. Retorna null com menos de 3 pontos.
  static LinearTrend? linearRegression(List<double> xs, List<double> ys) {
    final n = math.min(xs.length, ys.length);
    if (n < 3) return null;
    final mx = mean(xs.sublist(0, n));
    final my = mean(ys.sublist(0, n));
    var sxy = 0.0, sxx = 0.0, syy = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = xs[i] - mx, dy = ys[i] - my;
      sxy += dx * dy;
      sxx += dx * dx;
      syy += dy * dy;
    }
    if (sxx == 0) return null;
    final slope = sxy / sxx;
    final intercept = my - slope * mx;
    final r2 = syy == 0 ? 0.0 : (sxy * sxy) / (sxx * syy);
    return LinearTrend(slope: slope, intercept: intercept, r2: r2, n: n);
  }

  /// Agrega pontos em "baldes" de tempo (ex.: 3h, 1 dia) pela média.
  static List<HourlyPoint> aggregate(
    List<HourlyPoint> points,
    Duration bucket,
  ) {
    if (bucket <= const Duration(hours: 1) || points.isEmpty) return points;
    final groups = <int, List<HourlyPoint>>{};
    final origin = points.first.time;
    for (final p in points) {
      final key = p.time.difference(origin).inMinutes ~/ bucket.inMinutes;
      (groups[key] ??= []).add(p);
    }
    final keys = groups.keys.toList()..sort();
    return [
      for (final k in keys)
        HourlyPoint(
          time: groups[k]!.first.time,
          pm25: _avg(groups[k]!, (p) => p.pm25),
          pm10: _avg(groups[k]!, (p) => p.pm10),
          ozone: _avg(groups[k]!, (p) => p.ozone),
          no2: _avg(groups[k]!, (p) => p.no2),
          usAqi: _avg(groups[k]!, (p) => p.usAqi),
          temperature: _avg(groups[k]!, (p) => p.temperature),
          apparentTemperature: _avg(groups[k]!, (p) => p.apparentTemperature),
          humidity: _avg(groups[k]!, (p) => p.humidity),
          uvIndex: _avg(groups[k]!, (p) => p.uvIndex),
        ),
    ];
  }

  static double? _avg(List<HourlyPoint> ps, double? Function(HourlyPoint) f) {
    final vs = ps.map(f).whereType<double>().toList();
    return vs.isEmpty ? null : mean(vs);
  }
}
