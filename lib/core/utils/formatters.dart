import 'package:intl/intl.dart';

/// Formatação padronizada (pt-BR) de datas e números.
abstract final class Fmt {
  static final _dayMonth = DateFormat('dd/MM', 'pt_BR');
  static final _dateTime = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');
  static final _fullDate = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _weekday = DateFormat('EEE dd/MM', 'pt_BR');
  static final _hour = DateFormat('HH:mm', 'pt_BR');

  static String dayMonth(DateTime d) => _dayMonth.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);
  static String fullDate(DateTime d) => _fullDate.format(d);
  static String weekday(DateTime d) => _weekday.format(d);
  static String hour(DateTime d) => _hour.format(d);

  static String number(double? v, {int decimals = 0}) {
    if (v == null || v.isNaN) return '—';
    return NumberFormat.decimalPatternDigits(
      locale: 'pt_BR',
      decimalDigits: decimals,
    ).format(v);
  }

  /// 2300000 -> "2,3 mi"; 45000 -> "45 mil".
  static String compact(num v) {
    if (v >= 1000000) return '${number(v / 1000000, decimals: 1)} mi';
    if (v >= 1000) return '${number(v / 1000)} mil';
    return v.toString();
  }

  static String relative(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return 'em ${dateTime(d)}';
  }
}
