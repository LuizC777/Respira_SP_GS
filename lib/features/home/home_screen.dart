import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/zones_data.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/territory_repository.dart';
import '../../domain/models/alert.dart';
import '../../providers/alert_providers.dart';
import '../../providers/report_providers.dart';
import '../../providers/territory_providers.dart';
import '../../shared/widgets/alert_tile.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/data_status_bar.dart';
import '../../shared/widgets/human_decision_banner.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/zone_card.dart';

/// Visão geral do território: benefício social, alertas e zonas.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final territory = ref.watch(territoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Sobre os dados e limitações',
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.pushNamed(AppRoutes.aboutData),
          ),
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshTerritory(ref),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => refreshTerritory(ref),
          child: AsyncStateView<TerritoryData>(
            value: territory,
            onRetry: () => refreshTerritory(ref),
            builder: (_) => const _HomeContent(),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider).valueOrNull ?? const <Alert>[];
    final active = alerts.where((a) => a.status == AlertStatus.pending).toList();

    return ListView(
      padding: AppSpacing.screen,
      children: [
        Text(
          'Monitoramento das 5 zonas de São Paulo',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        AppSpacing.gapSm,
        const Align(alignment: Alignment.centerLeft, child: DataStatusBar()),
        AppSpacing.gapMd,
        const _SocialImpactCard(),
        AppSpacing.gapMd,
        const HumanDecisionBanner(compact: true),
        SectionHeader(
          'Alertas aguardando análise',
          subtitle: active.isEmpty
              ? null
              : '${active.length} no total · mais graves primeiro',
          trailing: TextButton(
            onPressed: () => context.goNamed(AppRoutes.alerts),
            child: const Text('Ver todos'),
          ),
        ),
        if (active.isEmpty)
          const AppCard(
            child: EmptyStateView(
              icon: Icons.celebration_outlined,
              title: 'Nenhum alerta pendente',
              message: 'Com os limiares atuais, não há risco previsto '
                  'que precise de análise.',
            ),
          )
        else
          ...active.take(3).map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AlertTile(alert: a),
                ),
              ),
        const SectionHeader('Zonas', subtitle: 'Toque em Ar, Calor ou Impacto'),
        ResponsiveGrid(
          minItemWidth: 320,
          maxColumns: 2,
          children: [for (final z in kZones) ZoneCard(zone: z)],
        ),
        AppSpacing.gapLg,
      ],
    );
  }
}

/// Indicador de benefício social (obrigatório no critério 8).
class _SocialImpactCard extends ConsumerWidget {
  const _SocialImpactCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impact = ref.watch(socialImpactProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasRisk = impact.zonesWithAlerts > 0;

    return AppCard(
      color: scheme.primaryContainer,
      borderColor: scheme.primaryContainer,
      semanticLabel: hasRisk
          ? 'Benefício social: cerca de ${Fmt.compact(impact.peopleInAlertZones)} '
              'pessoas em ${impact.zonesWithAlerts} zonas com alerta alto ou '
              'crítico. ${impact.schoolsInAlertZones} escolas e '
              '${impact.healthUnitsInAlertZones} unidades de saúde podem ser '
              'avisadas com antecedência.'
          : 'Benefício social: nenhuma zona com alerta alto ou crítico agora.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volunteer_activism_outlined,
                    color: scheme.onPrimaryContainer),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Benefício social',
                  style: text.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Text(
              hasRisk ? '≈ ${Fmt.compact(impact.peopleInAlertZones)} pessoas' : 'Sem risco alto previsto',
              style: text.headlineSmall?.copyWith(color: scheme.onPrimaryContainer),
            ),
            Text(
              hasRisk
                  ? 'em ${impact.zonesWithAlerts} zona(s) com alerta alto ou crítico — '
                      'podem ser avisadas com antecedência.'
                  : 'Nenhuma zona com alerta alto ou crítico no momento.',
              style: text.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
            ),
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _Stat(Icons.school_outlined, '${impact.schoolsInAlertZones}', 'escolas a avisar'),
                _Stat(Icons.local_hospital_outlined, '${impact.healthUnitsInAlertZones}', 'UBSs a preparar'),
                _Stat(Icons.task_alt, '${impact.confirmedAlerts}', 'alertas confirmados'),
                _Stat(Icons.edit_note, '${impact.reports}', 'ocorrências'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(value, style: text.titleMedium?.copyWith(color: color)),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: text.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
