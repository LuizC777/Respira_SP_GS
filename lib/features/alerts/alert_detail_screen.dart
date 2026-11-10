import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/zones_data.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/severity_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../domain/models/alert.dart';
import '../../providers/alert_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/confidence_meter.dart';
import '../../shared/widgets/human_decision_banner.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/severity_badge.dart';
import '../../shared/widgets/trend_chart.dart';

/// Detalhe do alerta: evidência, confiança, limitações e decisão humana.
class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(alertByIdProvider(alertId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: SafeArea(
        child: AsyncStateView<Alert?>(
          value: alert,
          isEmpty: (a) => a == null,
          emptyIcon: Icons.notifications_off_outlined,
          emptyTitle: 'Este alerta não está mais ativo',
          emptyMessage: 'Os dados ou os limiares mudaram e a regra deixou de ser '
              'atendida. Volte para a lista de alertas.',
          builder: (a) => _AlertDetailBody(alert: a!),
        ),
      ),
    );
  }
}

class _AlertDetailBody extends ConsumerWidget {
  const _AlertDetailBody({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = context.severityColors.of(alert.severity);
    final decision = ref.watch(decisionsProvider)[alert.id];

    return ListView(
      padding: AppSpacing.screen,
      children: [
        // Cabeçalho
        Row(
          children: [
            Icon(alert.type.icon, color: color, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(alert.type.label, style: text.labelLarge),
            ),
            SeverityBadge(severity: alert.severity),
          ],
        ),
        AppSpacing.gapSm,
        Semantics(
          header: true,
          child: Text(alert.title, style: text.headlineSmall),
        ),
        AppSpacing.gapXs,
        Text(
          '${zoneById(alert.zoneId).name} · período ${Fmt.weekday(alert.windowStart)}'
          '${alert.windowEnd.difference(alert.windowStart).inDays > 1 ? ' a ${Fmt.weekday(alert.windowEnd)}' : ''}'
          ' · gerado ${Fmt.dateTime(alert.generatedAt)}',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        AppSpacing.gapMd,
        Text(alert.summary, style: text.bodyLarge),
        AppSpacing.gapMd,
        const HumanDecisionBanner(),

        // Evidência
        const SectionHeader('Evidência', subtitle: 'Os dados que dispararam a regra'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.rule, size: 20, color: scheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('Regra: ${alert.rule}',
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const Divider(height: AppSpacing.lg),
              for (final e in alert.evidence) _EvidenceRow(item: e),
              AppSpacing.gapSm,
              TrendChart(
                height: 180,
                unit: alert.seriesUnit,
                decimals: 1,
                minYZero: alert.seriesUnit != '°C',
                now: DateTime.now(),
                threshold: alert.seriesThreshold,
                series: [
                  ChartSeries(
                    label: alert.seriesLabel,
                    color: color,
                    points: alert.series,
                  ),
                ],
                semanticLabel: 'Gráfico de ${alert.seriesLabel} no período do alerta, '
                    'com limiar de ${Fmt.number(alert.seriesThreshold, decimals: 1)} '
                    '${alert.seriesUnit}.',
              ),
            ],
          ),
        ),

        // Confiança
        const SectionHeader('Nível de confiança',
            subtitle: 'Calculado por pontos — cada fator abaixo explica o resultado'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConfidenceMeter(confidence: alert.confidence),
              AppSpacing.gapMd,
              for (final r in alert.confidence.reasons)
                _Bullet(
                  icon: r.contains('(−') ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  text: r,
                ),
            ],
          ),
        ),

        // Limitações
        const SectionHeader('Limitações',
            subtitle: 'Quando esta previsão pode não ser confiável'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final l in alert.limitations)
                _Bullet(icon: Icons.report_problem_outlined, text: l),
            ],
          ),
        ),

        // Decisão humana
        const SectionHeader('Decisão do gestor',
            subtitle: 'O app não executa nenhuma ação automaticamente'),
        if (decision == null)
          _DecisionButtons(alert: alert)
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      decision.status == AlertStatus.confirmed
                          ? Icons.task_alt
                          : Icons.do_not_disturb_on_outlined,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(decision.status.label, style: text.titleMedium),
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                Text('Justificativa: ${decision.justification}'),
                AppSpacing.gapXs,
                Text(
                  'Registrada em ${Fmt.dateTime(decision.decidedAt)}',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                AppSpacing.gapSm,
                TextButton.icon(
                  onPressed: () => ref.read(decisionsProvider.notifier).undo(alert.id),
                  icon: const Icon(Icons.undo),
                  label: const Text('Revisar decisão'),
                ),
              ],
            ),
          ),
        AppSpacing.gapLg,
      ],
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.item});

  final EvidenceItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.severityColors;
    final value = '${Fmt.number(item.value, decimals: item.value.abs() < 10 ? 1 : 0)}'
        '${item.unit.isEmpty ? '' : ' ${item.unit}'}';
    final thr = item.threshold == null
        ? null
        : 'limiar ${Fmt.number(item.threshold, decimals: 1)}';
    return Semantics(
      label: '${item.label}: $value${thr == null ? '' : ', $thr'}'
          '${item.exceeds ? ', acima do limiar' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              item.exceeds ? Icons.arrow_upward : Icons.circle,
              size: item.exceeds ? 18 : 8,
              color: item.exceeds ? colors.high : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(item.label, style: text.bodyMedium)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (thr != null) Text(thr, style: text.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _DecisionButtons extends ConsumerWidget {
  const _DecisionButtons({required this.alert});

  final Alert alert;

  Future<void> _decide(BuildContext context, WidgetRef ref, AlertStatus status) async {
    final justification = await showDialog<String>(
      context: context,
      builder: (_) => _JustificationDialog(status: status),
    );
    if (justification == null) return;
    await ref.read(decisionsProvider.notifier).decide(
          alertId: alert.id,
          status: status,
          justification: justification,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Decisão registrada: ${status.label.toLowerCase()}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _decide(context, ref, AlertStatus.confirmed),
          icon: const Icon(Icons.task_alt),
          label: const Text('Confirmar e acompanhar'),
        ),
        AppSpacing.gapSm,
        OutlinedButton.icon(
          onPressed: () => _decide(context, ref, AlertStatus.dismissed),
          icon: const Icon(Icons.do_not_disturb_on_outlined),
          label: const Text('Descartar alerta'),
        ),
      ],
    );
  }
}

/// Formulário curto com validação: toda decisão exige justificativa.
class _JustificationDialog extends StatefulWidget {
  const _JustificationDialog({required this.status});

  final AlertStatus status;

  @override
  State<_JustificationDialog> createState() => _JustificationDialogState();
}

class _JustificationDialogState extends State<_JustificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirming = widget.status == AlertStatus.confirmed;
    return AlertDialog(
      title: Text(confirming ? 'Confirmar alerta' : 'Descartar alerta'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 280,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: Validators.justification,
          decoration: InputDecoration(
            labelText: 'Justificativa',
            hintText: confirming
                ? 'Ex.: avisar escolas da zona e reforçar UBSs.'
                : 'Ex.: estação oficial mostra valores normais.',
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Registrar')),
      ],
    );
  }
}
