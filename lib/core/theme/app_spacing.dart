import 'package:flutter/widgets.dart';

/// Espaçamentos padronizados — nenhuma tela usa valores soltos.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const EdgeInsets screen = EdgeInsets.all(md);
  static const EdgeInsets card = EdgeInsets.all(md);

  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);

  /// Largura a partir da qual o layout passa a usar 2 colunas.
  static const double wideBreakpoint = 700;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}
