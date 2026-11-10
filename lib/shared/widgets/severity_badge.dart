import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/severity_colors.dart';
import '../../domain/models/alert.dart';

/// Selo de severidade: cor + ícone + texto (nunca só cor).
/// `severity == null` representa "sem risco".
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({
    super.key,
    required this.severity,
    this.label,
    this.compact = false,
  });

  final AlertSeverity? severity;

  /// Texto alternativo (ex.: categoria do AQI).
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.severityColors;
    final bg = colors.of(severity);
    final text = label ?? severity?.label ?? 'Sem alerta';
    final icon = severity?.icon ?? Icons.check_circle_outline;
    return Semantics(
      label: 'Nível: $text',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.sm + 2,
          vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 14 : 16, color: colors.onSeverity),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSeverity,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
