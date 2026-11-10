import 'package:flutter_test/flutter_test.dart';
import 'package:respira_sp/core/utils/validators.dart';

void main() {
  group('Descrição da ocorrência', () {
    test('aceita texto válido', () {
      expect(Validators.reportDescription('Fumaça forte perto da escola.'), isNull);
    });

    test('rejeita vazio, curto e longo', () {
      expect(Validators.reportDescription(''), isNotNull);
      expect(Validators.reportDescription('   '), isNotNull);
      expect(Validators.reportDescription('curto'), isNotNull);
      expect(Validators.reportDescription('a' * 301), isNotNull);
    });

    test('bloqueia dados pessoais (privacidade)', () {
      expect(
        Validators.reportDescription('Me liga no (11) 98765-4321 por favor'),
        contains('telefone'),
      );
      expect(
        Validators.reportDescription('Meu e-mail é joao@exemplo.com, ok?'),
        contains('e-mail'),
      );
      expect(
        Validators.reportDescription('CPF 123.456.789-00 para contato'),
        isNotNull,
      );
    });

    test('permite números curtos (ex.: horários)', () {
      expect(Validators.reportDescription('Fumaça desde as 7h, piorou às 10h.'), isNull);
    });
  });

  group('Data do ocorrido', () {
    final now = DateTime(2026, 11, 10, 15);

    test('hoje é válido', () {
      expect(Validators.occurredOn(DateTime(2026, 11, 10), now: now), isNull);
    });

    test('rejeita nula, futura e muito antiga', () {
      expect(Validators.occurredOn(null, now: now), isNotNull);
      expect(Validators.occurredOn(DateTime(2026, 11, 11), now: now), isNotNull);
      expect(Validators.occurredOn(DateTime(2026, 10, 1), now: now), isNotNull);
    });
  });

  group('Limiares numéricos', () {
    String? pm(String v) =>
        Validators.numberInRange(v, min: 5, max: 150, unit: 'µg/m³');

    test('aceita vírgula e ponto', () {
      expect(pm('15'), isNull);
      expect(pm('15,5'), isNull);
      expect(pm('15.5'), isNull);
    });

    test('rejeita vazio, texto e fora da faixa', () {
      expect(pm(''), isNotNull);
      expect(pm('abc'), 'Digite apenas números.');
      expect(pm('4'), contains('entre 5 e 150'));
      expect(pm('151'), isNotNull);
    });

    test('exige inteiro quando pedido', () {
      expect(
        Validators.numberInRange('3,5', min: 1, max: 12, unit: 'h', integer: true),
        'Use um número inteiro.',
      );
    });
  });

  group('Outros', () {
    test('consentimento obrigatório', () {
      expect(Validators.consent(false), isNotNull);
      expect(Validators.consent(null), isNotNull);
      expect(Validators.consent(true), isNull);
    });

    test('justificativa da decisão', () {
      expect(Validators.justification('ok'), isNotNull);
      expect(Validators.justification('Avisar as escolas da zona.'), isNull);
    });

    test('campo obrigatório', () {
      expect(Validators.required(null, 'a zona'), 'Selecione a zona.');
      expect(Validators.required('leste', 'a zona'), isNull);
    });
  });
}
