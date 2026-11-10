import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/severity_colors.dart';
import '../../domain/models/alert.dart';

/// Nível de confiança (Alta/Média/Baixa) com barra e pontuação.
class ConfidenceMeter extends StatelessWidget {
  const ConfidenceMeter({super.key, required this.confidence, this.compact = false});

  final Confidence confidence;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.severityColors;
    final scheme = Theme.of(context).colorScheme;
    final color = switch (confidence.level) {
      ConfidenceLevel.high => colors.good,
      ConfidenceLevel.medium => colors.moderate,
      ConfidenceLevel.low => colors.high,
    };
    final label = 'Confiança ${confidence.level.label.toLowerCase()}';

    if (compact) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      );
    }

    return Semantics(
      label: '$label, ${confidence.score} de 100 pontos',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(
                '${confidence.score}/100',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          AppSpacing.gapSm,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: confidence.score / 100,
              minHeight: 10,
              color: color,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
