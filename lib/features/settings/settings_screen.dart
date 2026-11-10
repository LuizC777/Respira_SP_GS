import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/services/notification_service.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/thresholds.dart';
import '../../providers/alert_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/report_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/territory_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screen,
          children: const [
            SectionHeader(
              'Limiares de alerta',
              subtitle: 'Ao salvar, os alertas são recalculados na hora',
            ),
            _ThresholdsForm(),
            SectionHeader('Aparência e acessibilidade'),
            _AppearanceSection(),
            SectionHeader('Notificações e dados'),
            _NotificationsSection(),
            SectionHeader('Privacidade'),
            _PrivacySection(),
            SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Formulário de limiares com validação de faixa.
class _ThresholdsForm extends ConsumerStatefulWidget {
  const _ThresholdsForm();

  @override
  ConsumerState<_ThresholdsForm> createState() => _ThresholdsFormState();
}

class _ThresholdsFormState extends ConsumerState<_ThresholdsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pm;
  late final TextEditingController _temp;
  late final TextEditingController _hours;

  @override
  void initState() {
    super.initState();
    final t = ref.read(thresholdsProvider);
    _pm = TextEditingController(text: Fmt.number(t.pm25Daily, decimals: 1));
    _temp = TextEditingController(text: Fmt.number(t.apparentTemp, decimals: 1));
    _hours = TextEditingController(text: '${t.heatMinHours}');
  }

  @override
  void dispose() {
    _pm.dispose();
    _temp.dispose();
    _hours.dispose();
    super.dispose();
  }

  void _fill(Thresholds t) {
    _pm.text = Fmt.number(t.pm25Daily, decimals: 1);
    _temp.text = Fmt.number(t.apparentTemp, decimals: 1);
    _hours.text = '${t.heatMinHours}';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final t = Thresholds(
      pm25Daily: Validators.parseNumber(_pm.text)!,
      apparentTemp: Validators.parseNumber(_temp.text)!,
      heatMinHours: Validators.parseNumber(_hours.text)!.toInt(),
    );
    await ref.read(thresholdsProvider.notifier).update(t);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    final count = ref.read(alertsProvider).valueOrNull?.length ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Limiares salvos. $count alerta(s) após o recálculo.')),
    );
  }

  Future<void> _restore() async {
    await ref.read(thresholdsProvider.notifier).restoreDefaults();
    _fill(const Thresholds());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Valores de referência restaurados.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('threshold_pm25'),
              controller: _pm,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'PM2.5 — média diária (µg/m³)',
                helperText: 'Referência OMS: 15 µg/m³ · faixa 5 a 150',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.numberInRange(
                v,
                min: Thresholds.pm25Min,
                max: Thresholds.pm25Max,
                unit: 'µg/m³',
              ),
            ),
            AppSpacing.gapMd,
            TextFormField(
              key: const Key('threshold_temp'),
              controller: _temp,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Sensação térmica (°C)',
                helperText: 'Referência: 35 °C · faixa 25 a 50',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.numberInRange(
                v,
                min: Thresholds.tempMin,
                max: Thresholds.tempMax,
                unit: '°C',
              ),
            ),
            AppSpacing.gapMd,
            TextFormField(
              key: const Key('threshold_hours'),
              controller: _hours,
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Horas mínimas de calor no dia',
                helperText: 'Referência: 3 h · faixa 1 a 12',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.numberInRange(
                v,
                min: Thresholds.hoursMin.toDouble(),
                max: Thresholds.hoursMax.toDouble(),
                unit: 'h',
                integer: true,
              ),
            ),
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: _restore,
                  child: const Text('Restaurar referência'),
                ),
                FilledButton.icon(
                  key: const Key('threshold_save'),
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar limiares'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final text = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tema', style: text.titleSmall),
          AppSpacing.gapSm,
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('Sistema'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Escuro'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => notifier.setThemeMode(s.first),
          ),
          AppSpacing.gapMd,
          Text(
            'Tamanho do texto: ${(settings.textScale * 100).round()}%',
            style: text.titleSmall,
          ),
          Slider(
            value: settings.textScale,
            min: AppSettings.textScaleMin,
            max: AppSettings.textScaleMax,
            divisions: 6,
            label: '${(settings.textScale * 100).round()}%',
            semanticFormatterCallback: (v) => 'Texto em ${(v * 100).round()} por cento',
            onChanged: notifier.setTextScale,
          ),
          Text(
            'Soma-se ao tamanho de fonte do sistema. Todas as telas se adaptam.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          SwitchListTile(
            value: settings.notificationsEnabled,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notificar alertas altos e críticos'),
            subtitle: const Text('Notificação local; tocar abre o detalhe do alerta.'),
            onChanged: (on) async {
              if (on) await NotificationService.instance.requestPermission();
              await notifier.setNotifications(on);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: settings.useSampleData,
            secondary: const Icon(Icons.science_outlined),
            title: const Text('Modo demonstração'),
            subtitle: const Text(
              'Usa dados sintéticos que exercitam todas as regras de alerta. '
              'A confiança dos alertas é reduzida.',
            ),
            onChanged: notifier.setUseSampleData,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre os dados, métricas e limitações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed(AppRoutes.aboutData),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends ConsumerWidget {
  const _PrivacySection();

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar meus dados?'),
        content: const Text(
          'Isso remove ocorrências, decisões, limiares, preferências, cache e o '
          'consentimento deste aparelho. Não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(localStoreProvider).clearUserData();
    ref.read(reportsProvider.notifier).resetToDefaults();
    ref.read(decisionsProvider.notifier).resetToDefaults();
    ref.read(thresholdsProvider.notifier).resetToDefaults();
    ref.read(settingsProvider.notifier).resetToDefaults();
    ref.invalidate(territoryProvider);
    if (context.mounted) context.goNamed(AppRoutes.consent);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Consentimento'),
            subtitle: Text(
              settings.consentDate == null
                  ? 'Não registrado'
                  : 'Aceito em ${Fmt.dateTime(settings.consentDate!)}',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.no_accounts_outlined),
            title: Text('Dados pessoais'),
            subtitle: Text(
              'O app não coleta nome, documento, contato nem localização. '
              'Tudo fica salvo apenas neste aparelho.',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
            title: Text('Apagar meus dados', style: TextStyle(color: scheme.error)),
            subtitle: const Text('Remove tudo e volta à tela de consentimento.'),
            onTap: () => _deleteAll(context, ref),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              '${AppConstants.appName} · Projeto acadêmico FIAP · Global Solution 2026.2',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
