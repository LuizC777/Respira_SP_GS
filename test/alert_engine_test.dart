import 'package:flutter_test/flutter_test.dart';
import 'package:respira_sp/core/constants/zones_data.dart';
import 'package:respira_sp/data/services/sample_data_generator.dart';
import 'package:respira_sp/domain/engine/alert_engine.dart';
import 'package:respira_sp/domain/models/alert.dart';
import 'package:respira_sp/domain/models/hourly_point.dart';
import 'package:respira_sp/domain/models/thresholds.dart';
import 'package:respira_sp/domain/models/zone_snapshot.dart';

/// Cria uma série horária de [daysBack] dias atrás até [daysAhead] à frente.
ZoneSnapshot buildSnapshot({
  required DateTime now,
  double Function(DateTime t)? pm25,
  double Function(DateTime t)? apparent,
  int daysBack = 8,
  int daysAhead = 4,
  DataOrigin origin = DataOrigin.api,
  DateTime? fetchedAt,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final points = <HourlyPoint>[];
  for (var d = -daysBack; d <= daysAhead; d++) {
    for (var h = 0; h < 24; h++) {
      final t = today.add(Duration(days: d, hours: h));
      points.add(HourlyPoint(
        time: t,
        pm25: pm25?.call(t) ?? 8,
        apparentTemperature: apparent?.call(t) ?? 26,
      ));
    }
  }
  return ZoneSnapshot(
    zoneId: 'leste',
    points: points,
    fetchedAt: fetchedAt ?? now,
    origin: origin,
  );
}

void main() {
  const engine = AlertEngine();
  final zone = zoneById('leste');
  final now = DateTime(2026, 11, 10, 9);
  final tomorrow = DateTime(2026, 11, 11);
  const thresholds = Thresholds();

  List<Alert> run(ZoneSnapshot s, [Thresholds t = thresholds]) =>
      engine.evaluate(zone: zone, snapshot: s, thresholds: t, now: now);

  group('Regras de alerta', () {
    test('ar limpo e temperatura amena não geram alertas', () {
      expect(run(buildSnapshot(now: now)), isEmpty);
    });

    test('PM2.5 médio acima do limiar amanhã gera alerta de ar', () {
      final s = buildSnapshot(
        now: now,
        pm25: (t) => t.day == tomorrow.day ? 25 : 8,
      );
      final alerts = run(s);
      expect(alerts, hasLength(1));
      final a = alerts.single;
      expect(a.type, AlertType.airQuality);
      expect(a.severity, AlertSeverity.high); // 25/15 = 1,67×
      expect(a.evidence.first.value, closeTo(25, 0.01));
      expect(a.evidence.first.exceeds, isTrue);
      expect(a.limitations, isNotEmpty);
      expect(a.status, AlertStatus.pending);
    });

    test('severidade crítica quando PM2.5 ≥ 2,5× o limiar', () {
      final s =
          buildSnapshot(now: now, pm25: (t) => t.day == tomorrow.day ? 40 : 8);
      expect(run(s).single.severity, AlertSeverity.critical);
    });

    test('calor por horas suficientes gera alerta de calor', () {
      final s = buildSnapshot(
        now: now,
        apparent: (t) =>
            t.day == tomorrow.day && t.hour >= 12 && t.hour < 16 ? 37 : 26,
      );
      final a = run(s).single;
      expect(a.type, AlertType.heat);
      expect(a.evidence[1].value, 4); // 4 horas acima
    });

    test('calor por poucas horas NÃO gera alerta', () {
      final s = buildSnapshot(
        now: now,
        apparent: (t) => t.day == tomorrow.day && t.hour == 14 ? 40 : 26,
      );
      expect(run(s), isEmpty);
    });

    test('ar ruim + calor no mesmo dia vira um único alerta combinado crítico',
        () {
      final s = buildSnapshot(
        now: now,
        pm25: (t) => t.day == tomorrow.day ? 20 : 8,
        apparent: (t) =>
            t.day == tomorrow.day && t.hour >= 11 && t.hour < 17 ? 38 : 26,
      );
      final alerts = run(s);
      expect(alerts, hasLength(1));
      expect(alerts.single.type, AlertType.combined);
      expect(alerts.single.severity, AlertSeverity.critical);
    });

    test('tendência de alta nos últimos 7 dias gera alerta de tendência', () {
      final today = DateTime(now.year, now.month, now.day);
      final s = buildSnapshot(
        now: now,
        pm25: (t) {
          final daysAgo =
              today.difference(DateTime(t.year, t.month, t.day)).inDays;
          if (daysAgo <= 0) return 13; // hoje e futuro abaixo do limiar
          return 14 - daysAgo * 1.7; // subida linear até ontem
        },
      );
      final a = run(s).single;
      expect(a.type, AlertType.worseningTrend);
      expect(a.evidence.first.value, closeTo(1.7, 0.05)); // inclinação
      expect(a.evidence[1].value, greaterThan(0.9)); // R²
    });

    test('mudar o limiar recalcula os alertas', () {
      final s =
          buildSnapshot(now: now, pm25: (t) => t.day == tomorrow.day ? 12 : 8);
      expect(run(s), isEmpty);
      expect(run(s, const Thresholds(pm25Daily: 10)), hasLength(1));
    });

    test('ids são estáveis entre recálculos (decisão humana não se perde)', () {
      final s =
          buildSnapshot(now: now, pm25: (t) => t.day == tomorrow.day ? 25 : 8);
      expect(run(s).single.id, run(s).single.id);
      expect(run(s).single.id, 'leste-airQuality-20261111');
    });
  });

  group('Nível de confiança', () {
    double spike(DateTime t) => t.day == tomorrow.day ? 40.0 : 8.0;

    test('dados ao vivo e evento próximo → confiança alta', () {
      final a = run(buildSnapshot(now: now, pm25: spike)).single;
      expect(a.confidence.level, ConfidenceLevel.high);
    });

    test('dados sintéticos reduzem a confiança', () {
      final live = run(buildSnapshot(now: now, pm25: spike)).single;
      final sample = run(buildSnapshot(
        now: now,
        pm25: spike,
        origin: DataOrigin.sample,
      )).single;
      expect(sample.confidence.score, lessThan(live.confidence.score));
      expect(sample.confidence.reasons.join(), contains('sintéticos'));
    });

    test('cache antigo reduz a confiança e entra nas limitações', () {
      final a = run(buildSnapshot(
        now: now,
        pm25: spike,
        origin: DataOrigin.cache,
        fetchedAt: now.subtract(const Duration(hours: 12)),
      )).single;
      expect(a.confidence.reasons.join(), contains('mais de 6 h'));
      expect(a.limitations.join(), contains('offline'));
    });

    test('previsão distante tem menos confiança que a próxima', () {
      final far = DateTime(2026, 11, 14);
      final near = run(buildSnapshot(now: now, pm25: spike)).single;
      final distant = run(buildSnapshot(
        now: now,
        pm25: (t) => t.day == far.day ? 40 : 8,
      )).single;
      expect(distant.confidence.score, lessThan(near.confidence.score));
    });

    test('valor muito próximo do limiar perde pontos', () {
      final a = run(buildSnapshot(
        now: now,
        pm25: (t) => t.day == tomorrow.day ? 16 : 8,
      )).single;
      expect(a.confidence.reasons.join(), contains('próximo do limiar'));
    });
  });

  group('Histórico e dados de exemplo', () {
    test('histórico marca os dias passados acima do limiar', () {
      final yesterday = DateTime(2026, 11, 9);
      final s =
          buildSnapshot(now: now, pm25: (t) => t.day == yesterday.day ? 30 : 8);
      final h = engine.historicalExceedances(
        snapshot: s,
        thresholds: thresholds,
        now: now,
      );
      expect(h.where((d) => d.air).map((d) => d.day), [yesterday]);
    });

    test('dados de exemplo exercitam todas as regras', () {
      const gen = SampleDataGenerator();
      Set<AlertType> typesFor(String id) => engine
          .evaluate(
            zone: zoneById(id),
            snapshot: gen.generate(zoneById(id), now: now),
            thresholds: thresholds,
            now: now,
          )
          .map((a) => a.type)
          .toSet();

      expect(typesFor('leste'), contains(AlertType.airQuality));
      expect(typesFor('sul'), contains(AlertType.combined));
      expect(typesFor('centro'), contains(AlertType.heat));
      expect(typesFor('norte'), contains(AlertType.worseningTrend));
      expect(typesFor('oeste'), isEmpty);
    });
  });
}
