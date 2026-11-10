/// Validações puras (sem Flutter) usadas pelos formulários.
/// Retornam `null` quando o valor é válido, ou a mensagem de erro.
abstract final class Validators {
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');

  /// 8 ou mais dígitos, permitindo espaços, pontos, hífens e parênteses
  /// entre eles (telefones, CPF, RG...).
  static final _longNumber = RegExp(r'(?:\d[\s().-]*){8,}');

  static String? required(Object? value, String field) {
    if (value == null) return 'Selecione $field.';
    if (value is String && value.trim().isEmpty) return 'Informe $field.';
    return null;
  }

  /// Descrição de ocorrência: 10–300 caracteres e SEM dados pessoais.
  static String? reportDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Descreva o que aconteceu.';
    if (text.length < 10) return 'Use pelo menos 10 caracteres.';
    if (text.length > 300) return 'Use no máximo 300 caracteres.';
    if (_email.hasMatch(text)) {
      return 'Para proteger sua privacidade, não inclua e-mail.';
    }
    if (_longNumber.hasMatch(text)) {
      return 'Para proteger sua privacidade, não inclua telefone ou documentos.';
    }
    return null;
  }

  /// Data do ocorrido: obrigatória, não futura, até 30 dias atrás.
  static String? occurredOn(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Informe a data do ocorrido.';
    final today = _dateOnly(now ?? DateTime.now());
    final day = _dateOnly(value);
    if (day.isAfter(today)) return 'A data não pode estar no futuro.';
    if (today.difference(day).inDays > 30) {
      return 'Registre ocorrências de até 30 dias atrás.';
    }
    return null;
  }

  static String? consent(bool? value) =>
      value == true ? null : 'É preciso concordar para enviar.';

  /// Justificativa da decisão do gestor.
  static String? justification(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 10) {
      return 'Explique a decisão em pelo menos 10 caracteres.';
    }
    if (text.length > 280) return 'Use no máximo 280 caracteres.';
    return null;
  }

  /// Número dentro da faixa. Aceita vírgula ou ponto decimal.
  static String? numberInRange(
    String? value, {
    required double min,
    required double max,
    required String unit,
    bool integer = false,
  }) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return 'Informe um valor.';
    final number = double.tryParse(text);
    if (number == null) return 'Digite apenas números.';
    if (integer && number != number.roundToDouble()) {
      return 'Use um número inteiro.';
    }
    if (number < min || number > max) {
      return 'Use um valor entre ${_fmt(min)} e ${_fmt(max)} $unit.';
    }
    return null;
  }

  static double? parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
