import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/alert_providers.dart';
import '../../shared/widgets/alert_tile.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/section_header.dart';

/// Lista os alertas ativos da zona no fim de cada dashboard
/// (fluxo: dashboard → alerta → detalhe).
class ZoneAlertsSection extends ConsumerWidget {
  const ZoneAlertsSection({super.key, required this.zoneId});

  final String zoneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(zoneAlertsProvider(zoneId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Alertas desta zona'),
        if (alerts.isEmpty)
          const AppCard(
            child: EmptyStateView(
              icon: Icons.check_circle_outline,
              title: 'Nenhum alerta ativo',
              message: 'Os dados atuais não ultrapassam os limiares configurados.',
            ),
          )
        else
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AlertTile(alert: a),
            ),
        AppSpacing.gapLg,
      ],
    );
  }
}
