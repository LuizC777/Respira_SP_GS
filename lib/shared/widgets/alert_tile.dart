import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/zones_data.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/severity_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/alert.dart';
import 'app_card.dart';
import 'confidence_meter.dart';
import 'severity_badge.dart';

/// Item de lista de alerta. Toque abre o detalhe (rota com parâmetro).
class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = context.severityColors.of(alert.severity);
    final dismissed = alert.status == AlertStatus.dismissed;

    return Opacity(
      opacity: dismissed ? 0.6 : 1,
      child: AppCard(
        borderColor: color.withValues(alpha: 0.6),
        semanticLabel: 'Alerta ${alert.severity.label}: ${alert.title}. '
            '${alert.status.label}. Toque para ver evidência e confiança.',
        onTap: () => context.pushNamed(
          AppRoutes.alertDetail,
          pathParameters: {'alertId': alert.id},
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(alert.type.icon, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SeverityBadge(severity: alert.severity, compact: true),
                  ConfidenceMeter(confidence: alert.confidence, compact: true),
                  Text(
                    '${zoneById(alert.zoneId).name} · ${Fmt.weekday(alert.windowStart)}',
                    style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              if (alert.status != AlertStatus.pending) ...[
                AppSpacing.gapSm,
                Row(
                  children: [
                    Icon(
                      alert.status == AlertStatus.confirmed
                          ? Icons.task_alt
                          : Icons.do_not_disturb_on_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(alert.status.label, style: text.labelMedium),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
