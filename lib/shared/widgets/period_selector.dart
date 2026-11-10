import 'package:flutter/material.dart';

import '../../domain/engine/statistics.dart';
import '../../domain/models/alert.dart';
import '../../domain/models/hourly_point.dart';

/// Janela de tempo dos gráficos (histórico + previsão) e agregação.
enum ChartPeriod {
  h48('48 h', Duration(hours: 24), Duration(hours: 24), Duration(hours: 1)),
  d7('7 dias', Duration(days: 7), Duration(days: 5), Duration(hours: 3)),
  d30('30 dias', Duration(days: 30), Duration(days: 5), Duration(days: 1));

  const ChartPeriod(this.label, this.back, this.forward, this.bucket);
  final String label;
  final Duration back;
  final Duration forward;
  final Duration bucket;

  /// Recorta e agrega os pontos do período.
  List<HourlyPoint> slice(List<HourlyPoint> points, DateTime now) {
    final from = now.subtract(back);
    final to = now.add(forward);
    final window = points
        .where((p) => !p.time.isBefore(from) && !p.time.isAfter(to))
        .toList();
    return Stats.aggregate(window, bucket);
  }

  static List<SeriesPoint> series(
    List<HourlyPoint> points,
    double? Function(HourlyPoint) selector,
  ) =>
      [
        for (final p in points)
          if (selector(p) != null) SeriesPoint(p.time, selector(p)!),
      ];
}

/// Seletor de período — ESTADO LOCAL da tela (não precisa ser global).
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key, required this.value, required this.onChanged});

  final ChartPeriod value;
  final ValueChanged<ChartPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ChartPeriod>(
      showSelectedIcon: false,
      segments: [
        for (final p in ChartPeriod.values)
          ButtonSegment(
            value: p,
            label: Text(p.label),
            tooltip: 'Mostrar ${p.label}',
          ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
