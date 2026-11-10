import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:respira_sp/core/constants/app_constants.dart';
import 'package:respira_sp/core/theme/app_theme.dart';
import 'package:respira_sp/domain/models/alert.dart';
import 'package:respira_sp/shared/widgets/human_decision_banner.dart';
import 'package:respira_sp/shared/widgets/severity_badge.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('selo de severidade mostra texto e ícone, não só cor', (tester) async {
    await tester.pumpWidget(_wrap(const SeverityBadge(severity: AlertSeverity.critical)));
    expect(find.text('Crítico'), findsOneWidget);
    expect(find.byIcon(AlertSeverity.critical.icon), findsOneWidget);
  });

  testWidgets('selo sem severidade indica "Sem alerta"', (tester) async {
    await tester.pumpWidget(_wrap(const SeverityBadge(severity: null)));
    expect(find.text('Sem alerta'), findsOneWidget);
  });

  testWidgets('aviso de decisão humana é exibido e acessível', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const HumanDecisionBanner()));
    expect(find.text(AppConstants.humanDecisionNotice), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('não substituem, a decisão humana')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('componentes funcionam no tema escuro', (tester) async {
    await tester.pumpWidget(_wrap(
      const SeverityBadge(severity: AlertSeverity.high),
      theme: AppTheme.dark(),
    ));
    expect(find.text('Alto'), findsOneWidget);
  });
}
