import 'package:flutter/material.dart';

/// Campo de seleção integrado ao Form (validação + mensagem de erro),
/// com o mesmo visual dos campos de texto.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.helperText,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      // A chave muda com o valor para o FormField acompanhar o estado externo.
      key: ValueKey<T?>(value),
      initialValue: value,
      validator: validator,
      builder: (field) => InputDecorator(
        isEmpty: field.value == null,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          errorText: field.errorText,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: field.value,
            isDense: true,
            isExpanded: true,
            items: items,
            onChanged: (v) {
              field.didChange(v);
              onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}
