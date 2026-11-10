import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/settings_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/human_decision_banner.dart';

/// Onboarding + consentimento explícito (LGPD) antes de usar o app.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  // Estado LOCAL: checkboxes desta tela.
  bool _readTerms = false;
  bool _understandAlerts = false;

  bool get _canContinue => _readTerms && _understandAlerts;

  Future<void> _accept() async {
    await ref.read(settingsProvider.notifier).giveConsent();
    if (mounted) context.goNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Icon(Icons.air_rounded, size: 64, color: scheme.primary),
                AppSpacing.gapMd,
                Semantics(
                  header: true,
                  child: Text(
                    AppConstants.appName,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                AppSpacing.gapSm,
                Text(
                  AppConstants.tagline,
                  style: text.titleMedium,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapLg,
                const _Item(
                  icon: Icons.insights_outlined,
                  title: 'O que o app faz',
                  body: 'Combina dados públicos de qualidade do ar e clima para '
                      'antecipar dias de risco nas 5 zonas de São Paulo, com '
                      'evidência, nível de confiança e limitações de cada alerta.',
                ),
                const _Item(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Seus dados',
                  body: 'Não pedimos nome, documento, e-mail, telefone nem '
                      'localização. Ocorrências são anônimas, ficam só neste '
                      'aparelho e podem ser apagadas a qualquer momento em Ajustes.',
                ),
                const _Item(
                  icon: Icons.cloud_outlined,
                  title: 'Fontes',
                  body: 'Open-Meteo e Copernicus (CAMS). Sem internet, o app usa '
                      'os últimos dados salvos e avisa que estão desatualizados.',
                ),
                AppSpacing.gapSm,
                const HumanDecisionBanner(),
                AppSpacing.gapMd,
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _readTerms,
                        onChanged: (v) => setState(() => _readTerms = v ?? false),
                        title: const Text(
                          'Li e concordo com o uso dos dados descrito acima.',
                        ),
                      ),
                      const Divider(height: 1),
                      CheckboxListTile(
                        value: _understandAlerts,
                        onChanged: (v) =>
                            setState(() => _understandAlerts = v ?? false),
                        title: const Text(
                          'Entendo que os alertas são estimativas e que a decisão '
                          'final é sempre de uma pessoa.',
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapLg,
                FilledButton.icon(
                  onPressed: _canContinue ? _accept : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text('Começar'),
                  ),
                ),
                if (!_canContinue) ...[
                  AppSpacing.gapSm,
                  Text(
                    'Marque as duas opções para continuar.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  AppSpacing.gapXs,
                  Text(body, style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
