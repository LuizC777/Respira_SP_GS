import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/zones_data.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../domain/models/citizen_report.dart';
import '../../providers/report_providers.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_dropdown_field.dart';
import '../../shared/widgets/async_state_view.dart';
import '../../shared/widgets/section_header.dart';

/// Formulário de ocorrência do cidadão (anônimo), com validação.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, this.initialZoneId});

  final String? initialZoneId;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _dateText = TextEditingController();

  // Estado LOCAL do formulário.
  ReportType? _type;
  String? _zoneId;
  DateTime? _date;
  bool _consent = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _zoneId = widget.initialZoneId;
    _setDate(DateTime.now());
  }

  @override
  void dispose() {
    _description.dispose();
    _dateText.dispose();
    super.dispose();
  }

  void _setDate(DateTime? d) {
    _date = d;
    _dateText.text = d == null ? '' : Fmt.fullDate(d);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
      helpText: 'Data do ocorrido',
    );
    if (picked != null) setState(() => _setDate(picked));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os campos destacados.')),
      );
      return;
    }
    setState(() => _submitting = true);
    await ref.read(reportsProvider.notifier).add(
          type: _type!,
          zoneId: _zoneId!,
          description: _description.text,
          occurredOn: _date!,
        );
    if (!mounted) return;
    // reset() limpa os campos; depois restauramos a data padrão (hoje).
    _formKey.currentState?.reset();
    setState(() {
      _submitting = false;
      _type = null;
      _consent = false;
      _description.clear();
      _setDate(DateTime.now());
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ocorrência registrada de forma anônima. Obrigado!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ocorrência')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            AppCard(
              color: scheme.secondaryContainer,
              borderColor: scheme.secondaryContainer,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.privacy_tip_outlined, color: scheme.onSecondaryContainer),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Registro anônimo: não informe nome, telefone, e-mail, '
                      'documentos ou endereço. Guardamos apenas o tipo, a zona, '
                      'a data e a descrição.',
                      style: text.bodyMedium?.copyWith(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapMd,
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDropdownField<ReportType>(
                    key: const Key('report_type'),
                    label: 'Tipo de ocorrência *',
                    value: _type,
                    items: [
                      for (final t in ReportType.values)
                        DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(t.icon, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(child: Text(t.label)),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _type = v),
                    validator: (v) => Validators.required(v, 'o tipo de ocorrência'),
                  ),
                  AppSpacing.gapMd,
                  AppDropdownField<String>(
                    key: const Key('report_zone'),
                    label: 'Zona *',
                    helperText: 'Usamos só a zona, nunca o endereço.',
                    value: _zoneId,
                    items: [
                      for (final z in kZones)
                        DropdownMenuItem(value: z.id, child: Text(z.name)),
                    ],
                    onChanged: (v) => setState(() => _zoneId = v),
                    validator: (v) => Validators.required(v, 'a zona'),
                  ),
                  AppSpacing.gapMd,
                  TextFormField(
                    key: const Key('report_date'),
                    controller: _dateText,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Data do ocorrido *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (_) => Validators.occurredOn(_date),
                  ),
                  AppSpacing.gapMd,
                  TextFormField(
                    key: const Key('report_description'),
                    controller: _description,
                    maxLines: 4,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Descrição *',
                      hintText: 'Ex.: fumaça forte perto da avenida desde cedo.',
                      helperText: 'Entre 10 e 300 caracteres.',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: Validators.reportDescription,
                  ),
                  AppSpacing.gapSm,
                  FormField<bool>(
                    initialValue: _consent,
                    validator: (_) => Validators.consent(_consent),
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          key: const Key('report_consent'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _consent,
                          onChanged: (v) {
                            setState(() => _consent = v ?? false);
                            field.didChange(v);
                          },
                          title: const Text(
                            'Autorizo o uso anônimo desta ocorrência para apoiar '
                            'a análise de risco da minha região. *',
                          ),
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.md),
                            child: Text(
                              field.errorText!,
                              style: text.bodySmall?.copyWith(color: scheme.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.gapMd,
                  FilledButton.icon(
                    key: const Key('report_submit'),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text('Enviar ocorrência'),
                    ),
                  ),
                ],
              ),
            ),
            SectionHeader(
              'Minhas ocorrências',
              subtitle: '${reports.length} registro(s) neste aparelho',
            ),
            if (reports.isEmpty)
              const AppCard(
                child: EmptyStateView(
                  icon: Icons.edit_note,
                  title: 'Nenhuma ocorrência ainda',
                  message: 'Os registros que você enviar aparecem aqui.',
                ),
              )
            else
              for (final r in reports)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(r.type.icon, color: scheme.primary),
                      title: Text(r.type.label),
                      subtitle: Text(
                        '${zoneById(r.zoneId).name} · ${Fmt.fullDate(r.occurredOn)}\n'
                        '${r.description}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'Apagar esta ocorrência',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            ref.read(reportsProvider.notifier).remove(r.id),
                      ),
                    ),
                  ),
                ),
            AppSpacing.gapLg,
          ],
        ),
      ),
    );
  }
}
