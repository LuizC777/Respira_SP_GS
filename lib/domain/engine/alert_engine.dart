import '../../core/constants/app_constants.dart';
import '../models/alert.dart';
import '../models/hourly_point.dart';
import '../models/thresholds.dart';
import '../models/zone.dart';
import '../models/zone_snapshot.dart';
import 'statistics.dart';

/// Dias passados em que os limiares foram ultrapassados (histórico).
class DayExceedance {
  const DayExceedance({
    required this.day,
    required this.air,
    required this.heat,
  });
  final DateTime day;
  final bool air;
  final bool heat;
}

/// Motor de alertas: regras + estatística simples sobre os dados.
///
/// Princípios:
/// - Toda saída é um ALERTA INFORMATIVO com evidência, confiança e
///   limitações. O motor nunca executa ações: a decisão é humana.
/// - É Dart puro (sem Flutter/IO), determinístico e testável.
class AlertEngine {
  const AlertEngine();

  /// Variação mínima (µg/m³ por dia) para considerar tendência de piora.
  static const trendMinSlope = 1.5;
  static const trendMinR2 = 0.3;
  static const trendProjectionDays = 3;

  List<Alert> evaluate({
    required Zone zone,
    required ZoneSnapshot snapshot,
    required Thresholds thresholds,
    required DateTime now,
  }) {
    if (snapshot.points.isEmpty) return const [];

    final today = Stats.dateOnly(now);
    final upcoming =
        snapshot.points.where((p) => !p.time.isBefore(today)).toList();

    final airDays = Stats.dailyValues(upcoming, (p) => p.pm25)
        .where((d) => d.mean > thresholds.pm25Daily)
        .toList();
    final heatDays = _heatDays(upcoming, thresholds);

    final heatByDay = {for (final h in heatDays) h.day: h};
    final combinedDays =
        airDays.where((a) => heatByDay.containsKey(a.day)).toList();
    final combinedSet = combinedDays.map((d) => d.day).toSet();

    final alerts = <Alert>[];

    if (combinedDays.isNotEmpty) {
      final air = combinedDays.first;
      alerts.add(_combinedAlert(
        zone: zone,
        snapshot: snapshot,
        thresholds: thresholds,
        now: now,
        air: air,
        heat: heatByDay[air.day]!,
        extraDays: combinedDays.length - 1,
      ));
    }

    final airOnly = airDays.where((d) => !combinedSet.contains(d.day)).toList();
    if (airOnly.isNotEmpty) {
      alerts.add(_airAlert(
        zone: zone,
        snapshot: snapshot,
        thresholds: thresholds,
        now: now,
        day: airOnly.first,
        extraDays: airOnly.length - 1,
      ));
    }

    final heatOnly =
        heatDays.where((d) => !combinedSet.contains(d.day)).toList();
    if (heatOnly.isNotEmpty) {
      alerts.add(_heatAlert(
        zone: zone,
        snapshot: snapshot,
        thresholds: thresholds,
        now: now,
        day: heatOnly.first,
        extraDays: heatOnly.length - 1,
      ));
    }

    // A tendência só é útil quando ainda não há alerta de ar.
    if (airDays.isEmpty) {
      final trend = _trendAlert(
        zone: zone,
        snapshot: snapshot,
        thresholds: thresholds,
        now: now,
      );
      if (trend != null) alerts.add(trend);
    }

    return alerts;
  }

  /// Histórico de dias (antes de hoje) que ultrapassaram os limiares.
  List<DayExceedance> historicalExceedances({
    required ZoneSnapshot snapshot,
    required Thresholds thresholds,
    required DateTime now,
  }) {
    final today = Stats.dateOnly(now);
    final past = snapshot.points.where((p) => p.time.isBefore(today)).toList();
    final air = {
      for (final d in Stats.dailyValues(past, (p) => p.pm25))
        d.day: d.mean > thresholds.pm25Daily,
    };
    final heat = {for (final h in _heatDays(past, thresholds)) h.day: true};
    final days = air.keys.toList()..sort();
    return [
      for (final d in days)
        DayExceedance(day: d, air: air[d] ?? false, heat: heat[d] ?? false),
    ];
  }

  // ---------------------------------------------------------------- regras

  Alert _airAlert({
    required Zone zone,
    required ZoneSnapshot snapshot,
    required Thresholds thresholds,
    required DateTime now,
    required DailyValue day,
    required int extraDays,
  }) {
    final ratio = day.mean / thresholds.pm25Daily;
    final severity = ratio >= 2.5
        ? AlertSeverity.critical
        : ratio >= 1.5
            ? AlertSeverity.high
            : AlertSeverity.moderate;
    final start = _eventStart(day.day, now);

    return Alert(
      id: _id(zone, AlertType.airQuality, day.day),
      zoneId: zone.id,
      type: AlertType.airQuality,
      severity: severity,
      title: 'Ar ruim previsto — ${zone.name}',
      summary: 'Média de PM2.5 prevista em ${_date(day.day)}: '
          '${_num(day.mean)} µg/m³, ${_num(ratio)}× o limiar'
          '${_extra(extraDays)}. Grupos sensíveis (crianças, idosos e '
          'pessoas com doenças respiratórias) são os mais afetados.',
      rule: 'Média diária prevista de PM2.5 > ${_num(thresholds.pm25Daily)} µg/m³',
      evidence: [
        EvidenceItem(
          label: 'PM2.5 médio previsto (${_date(day.day)})',
          value: day.mean,
          unit: 'µg/m³',
          threshold: thresholds.pm25Daily,
        ),
        EvidenceItem(label: 'Pico horário de PM2.5', value: day.max, unit: 'µg/m³'),
      ],
      confidence: _confidence(
        snapshot: snapshot,
        now: now,
        eventStart: start,
        value: day.mean,
        threshold: thresholds.pm25Daily,
        missingRatio: day.missingRatio,
        coarseAirModel: true,
      ),
      limitations: [..._airLimitations, ..._dataLimitations(snapshot, now)],
      windowStart: day.day,
      windowEnd: day.day.add(const Duration(days: 1)),
      generatedAt: now,
      series: _series(snapshot, day.day, (p) => p.pm25),
      seriesLabel: 'PM2.5 horário',
      seriesUnit: 'µg/m³',
      seriesThreshold: thresholds.pm25Daily,
    );
  }

  Alert _heatAlert({
    required Zone zone,
    required ZoneSnapshot snapshot,
    required Thresholds thresholds,
    required DateTime now,
    required _HeatDay day,
    required int extraDays,
  }) {
    final over = day.max - thresholds.apparentTemp;
    final severity = over >= 8
        ? AlertSeverity.critical
        : (over >= 5 || day.hours >= 8)
            ? AlertSeverity.high
            : AlertSeverity.moderate;
    final start = _eventStart(day.day, now);

    return Alert(
      id: _id(zone, AlertType.heat, day.day),
      zoneId: zone.id,
      type: AlertType.heat,
      severity: severity,
      title: 'Calor extremo previsto — ${zone.name}',
      summary: 'Em ${_date(day.day)}, sensação térmica de até '
          '${_num(day.max)} °C, com ${day.hours} h acima de '
          '${_num(thresholds.apparentTemp)} °C${_extra(extraDays)}. '
          'Idosos, crianças e trabalhadores ao ar livre são os mais expostos.',
      rule: 'Sensação térmica ≥ ${_num(thresholds.apparentTemp)} °C por '
          '${thresholds.heatMinHours} h ou mais no dia',
      evidence: [
        EvidenceItem(
          label: 'Sensação térmica máxima',
          value: day.max,
          unit: '°C',
          threshold: thresholds.apparentTemp,
        ),
        EvidenceItem(
          label: 'Horas acima do limiar (mínimo: ${thresholds.heatMinHours} h)',
          value: day.hours.toDouble(),
          unit: 'h',
        ),
      ],
      confidence: _confidence(
        snapshot: snapshot,
        now: now,
        eventStart: start,
        value: day.max,
        threshold: thresholds.apparentTemp,
        missingRatio: day.missingRatio,
        heatModel: true,
      ),
      limitations: [..._heatLimitations, ..._dataLimitations(snapshot, now)],
      windowStart: day.day,
      windowEnd: day.day.add(const Duration(days: 1)),
      generatedAt: now,
      series: _series(snapshot, day.day, (p) => p.apparentTemperature),
      seriesLabel: 'Sensação térmica',
      seriesUnit: '°C',
      seriesThreshold: thresholds.apparentTemp,
    );
  }

  Alert _combinedAlert({
    required Zone zone,
    required ZoneSnapshot snapshot,
    required Thresholds thresholds,
    required DateTime now,
    required DailyValue air,
    required _HeatDay heat,
    required int extraDays,
  }) {
    final start = _eventStart(air.day, now);
    final airConf = _confidence(
      snapshot: snapshot,
      now: now,
      eventStart: start,
      value: air.mean,
      threshold: thresholds.pm25Daily,
      missingRatio: air.missingRatio,
      coarseAirModel: true,
    );
    final heatConf = _confidence(
      snapshot: snapshot,
      now: now,
      eventStart: start,
      value: heat.max,
      threshold: thresholds.apparentTemp,
      missingRatio: heat.missingRatio,
      heatModel: true,
    );
    // A confiança do conjunto é limitada pela parte mais incerta.
    final weakest = airConf.score <= heatConf.score ? airConf : heatConf;

    return Alert(
      id: _id(zone, AlertType.combined, air.day),
      zoneId: zone.id,
      type: AlertType.combined,
      severity: AlertSeverity.critical,
      title: 'Ar ruim + calor extremo — ${zone.name}',
      summary: 'Em ${_date(air.day)}, PM2.5 médio previsto de '
          '${_num(air.mean)} µg/m³ e sensação térmica de até '
          '${_num(heat.max)} °C${_extra(extraDays)}. Calor e poluição juntos '
          'aumentam o risco à saúde de grupos sensíveis.',
      rule: 'Regra de ar E regra de calor atendidas no mesmo dia',
      evidence: [
        EvidenceItem(
          label: 'PM2.5 médio previsto',
          value: air.mean,
          unit: 'µg/m³',
          threshold: thresholds.pm25Daily,
        ),
        EvidenceItem(
          label: 'Sensação térmica máxima',
          value: heat.max,
          unit: '°C',
          threshold: thresholds.apparentTemp,
        ),
        EvidenceItem(
          label: 'Horas acima do limiar de calor',
          value: heat.hours.toDouble(),
          unit: 'h',
        ),
      ],
      confidence: Confidence(
        score: weakest.score,
        reasons: {...airConf.reasons, ...heatConf.reasons}.toList(),
      ),
      limitations: [
        ..._airLimitations,
        ..._heatLimitations,
        ..._dataLimitations(snapshot, now),
      ],
      windowStart: air.day,
      windowEnd: air.day.add(const Duration(days: 1)),
      generatedAt: now,
      series: _series(snapshot, air.day, (p) => p.pm25),
      seriesLabel: 'PM2.5 horário',
      seriesUnit: 'µg/m³',
      seriesThreshold: thresholds.pm25Daily,
    );
  }

  /// Regressão linear sobre a média diária de PM2.5 dos últimos 7 dias.
  /// Se a reta projeta ultrapassar o limiar em até 3 dias, gera alerta.
  Alert? _trendAlert({
    required Zone zone,
    required ZoneSnapshot snapshot,
    required Thresholds thresholds,
    required DateTime now,
  }) {
    final today = Stats.dateOnly(now);
    final weekAgo = today.subtract(const Duration(days: 7));
    final past = snapshot.points
        .where((p) => !p.time.isBefore(weekAgo) && p.time.isBefore(today))
        .toList();
    final daily = Stats.dailyValues(past, (p) => p.pm25);
    if (daily.length < 5) return null;

    final xs = [for (final d in daily) d.day.difference(weekAgo).inDays.toDouble()];
    final ys = [for (final d in daily) d.mean];
    final trend = Stats.linearRegression(xs, ys);
    if (trend == null) return null;

    final todayX = today.difference(weekAgo).inDays.toDouble();
    final projected = trend.predict(todayX + trendProjectionDays);
    if (trend.slope < trendMinSlope ||
        trend.r2 < trendMinR2 ||
        projected <= thresholds.pm25Daily) {
      return null;
    }

    final series = [
      for (final d in daily) SeriesPoint(d.day, d.mean),
      for (var i = 0; i <= trendProjectionDays; i++)
        SeriesPoint(
          today.add(Duration(days: i)),
          trend.predict(todayX + i),
        ),
    ];

    return Alert(
      id: _id(zone, AlertType.worseningTrend, today),
      zoneId: zone.id,
      type: AlertType.worseningTrend,
      severity: AlertSeverity.moderate,
      title: 'Qualidade do ar piorando — ${zone.name}',
      summary: 'Nos últimos 7 dias o PM2.5 médio subiu cerca de '
          '${_num(trend.slope)} µg/m³ por dia. Mantida a tendência, pode '
          'chegar a ${_num(projected)} µg/m³ em $trendProjectionDays dias, '
          'acima do limiar.',
      rule: 'Regressão linear (7 dias): inclinação ≥ '
          '${_num(trendMinSlope)} µg/m³/dia, R² ≥ ${_num(trendMinR2)} e '
          'projeção > limiar',
      evidence: [
        EvidenceItem(
          label: 'Inclinação da tendência',
          value: trend.slope,
          unit: 'µg/m³/dia',
          threshold: trendMinSlope,
        ),
        EvidenceItem(label: 'R² da regressão', value: trend.r2, unit: ''),
        EvidenceItem(
          label: 'PM2.5 projetado em $trendProjectionDays dias',
          value: projected,
          unit: 'µg/m³',
          threshold: thresholds.pm25Daily,
        ),
      ],
      confidence: _confidence(
        snapshot: snapshot,
        now: now,
        eventStart: today.add(const Duration(days: trendProjectionDays)),
        value: projected,
        threshold: thresholds.pm25Daily,
        coarseAirModel: true,
        r2: trend.r2,
      ),
      limitations: [
        'Regressão linear simples: não antecipa mudanças bruscas '
            '(frente fria, chuva, inversão térmica).',
        'Extrapolar a tendência além de $trendProjectionDays dias não é confiável.',
        ..._airLimitations,
        ..._dataLimitations(snapshot, now),
      ],
      windowStart: today,
      windowEnd: today.add(const Duration(days: trendProjectionDays)),
      generatedAt: now,
      series: series,
      seriesLabel: 'PM2.5 médio diário (com projeção)',
      seriesUnit: 'µg/m³',
      seriesThreshold: thresholds.pm25Daily,
    );
  }

  // ------------------------------------------------------------ confiança

  /// Confiança por pontos: começa em 100 e perde pontos por fator de
  /// incerteza. Cada fator vira um motivo legível na tela de detalhe.
  Confidence _confidence({
    required ZoneSnapshot snapshot,
    required DateTime now,
    required DateTime eventStart,
    double? value,
    double? threshold,
    double missingRatio = 0,
    bool coarseAirModel = false,
    bool heatModel = false,
    double? r2,
  }) {
    var score = 100;
    final reasons = <String>[];

    final horizonH = eventStart.difference(now).inHours;
    if (horizonH > 96) {
      score -= 35;
      reasons.add('Previsão para daqui a mais de 4 dias: incerteza alta (−35)');
    } else if (horizonH > 48) {
      score -= 20;
      reasons.add('Previsão para daqui a mais de 2 dias (−20)');
    } else {
      reasons.add('Evento nas próximas 48 h: previsão mais confiável');
    }

    switch (snapshot.origin) {
      case DataOrigin.sample:
        score -= 40;
        reasons.add('Dados de exemplo (sintéticos), não medições reais (−40)');
      case DataOrigin.cache:
        score -= 10;
        reasons.add('Sem conexão: usando dados salvos no aparelho (−10)');
      case DataOrigin.api:
        break;
    }
    if (snapshot.origin != DataOrigin.sample &&
        snapshot.isStale(now, AppConstants.staleAfter)) {
      score -= 15;
      reasons.add('Dados com mais de 6 h desde a última atualização (−15)');
    }

    if (value != null && threshold != null && threshold != 0) {
      final margin = (value - threshold).abs() / threshold;
      if (margin < 0.15) {
        score -= 15;
        reasons.add('Valor muito próximo do limiar: pequena variação '
            'mudaria o resultado (−15)');
      } else if (margin >= 0.5) {
        reasons.add('Valor bem acima do limiar');
      }
    }

    if (missingRatio > 0.5) {
      score -= 15;
      reasons.add('Lacunas nos dados do período (−15)');
    }

    if (coarseAirModel) {
      score -= 10;
      reasons.add('Modelo de qualidade do ar com resolução de ~45 km (−10)');
    }
    if (heatModel) {
      score -= 5;
      reasons.add('Modelo meteorológico não capta ilhas de calor locais (−5)');
    }

    if (r2 != null) {
      if (r2 < 0.5) {
        score -= 20;
        reasons.add('Tendência pouco consistente (R² = ${_num(r2)}) (−20)');
      } else {
        reasons.add('Tendência consistente (R² = ${_num(r2)})');
      }
    }

    return Confidence(score: score.clamp(5, 100).toInt(), reasons: reasons);
  }

  // ----------------------------------------------------------- auxiliares

  static const _airLimitations = [
    'Modelo global CAMS (~45 km): o valor representa a zona inteira, '
        'não um bairro ou rua.',
    'Não substitui as estações oficiais de monitoramento (ex.: CETESB).',
  ];

  static const _heatLimitations = [
    'Sensação térmica estimada por modelo: não considera ilhas de calor '
        'de quarteirão nem ambientes internos.',
  ];

  List<String> _dataLimitations(ZoneSnapshot snapshot, DateTime now) => [
        if (snapshot.origin == DataOrigin.sample)
          'Dados sintéticos: use apenas para demonstração.',
        if (snapshot.origin == DataOrigin.cache)
          'Exibindo dados salvos em ${_date(snapshot.fetchedAt)} '
              '${_time(snapshot.fetchedAt)} (offline).',
      ];

  List<_HeatDay> _heatDays(List<HourlyPoint> points, Thresholds t) {
    final byDay = <DateTime, List<double>>{};
    final slots = <DateTime, int>{};
    for (final p in points) {
      final day = Stats.dateOnly(p.time);
      slots[day] = (slots[day] ?? 0) + 1;
      final v = p.apparentTemperature;
      if (v != null) (byDay[day] ??= []).add(v);
    }
    final days = byDay.keys.toList()..sort();
    final result = <_HeatDay>[];
    for (final d in days) {
      final values = byDay[d]!;
      final hours = values.where((v) => v >= t.apparentTemp).length;
      if (hours >= t.heatMinHours) {
        result.add(_HeatDay(
          day: d,
          hours: hours,
          max: values.reduce((a, b) => a > b ? a : b),
          missingRatio: 1 - values.length / slots[d]!,
        ));
      }
    }
    return result;
  }

  /// Pontos do dia do evento (e 12 h antes) para o mini-gráfico.
  List<SeriesPoint> _series(
    ZoneSnapshot snapshot,
    DateTime day,
    double? Function(HourlyPoint) selector,
  ) {
    final from = day.subtract(const Duration(hours: 12));
    final to = day.add(const Duration(days: 1));
    return [
      for (final p in snapshot.points)
        if (!p.time.isBefore(from) && p.time.isBefore(to) && selector(p) != null)
          SeriesPoint(p.time, selector(p)!),
    ];
  }

  DateTime _eventStart(DateTime day, DateTime now) =>
      day.isBefore(now) ? now : day;

  String _id(Zone zone, AlertType type, DateTime day) =>
      '${zone.id}-${type.name}-${day.year}'
      '${day.month.toString().padLeft(2, '0')}'
      '${day.day.toString().padLeft(2, '0')}';

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  static String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String _num(double v) {
    final decimals = v.abs() >= 10 ? 0 : 1;
    return v.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  static String _extra(int n) => n <= 0
      ? ''
      : ' (e mais $n dia${n > 1 ? 's' : ''} na previsão)';
}

class _HeatDay {
  const _HeatDay({
    required this.day,
    required this.hours,
    required this.max,
    required this.missingRatio,
  });
  final DateTime day;
  final int hours;
  final double max;
  final double missingRatio;
}
