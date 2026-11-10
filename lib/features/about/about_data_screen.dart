import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/engine/alert_engine.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/human_decision_banner.dart';
import '../../shared/widgets/section_header.dart';

/// Transparência: fontes, como os alertas são gerados, métricas,
/// limitações, vieses e quando as previsões não são confiáveis.
class AboutDataScreen extends StatelessWidget {
  const AboutDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre os dados')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screen,
          children: const [
            HumanDecisionBanner(),
            SectionHeader('Fontes'),
            _Block(items: [
              'Qualidade do ar (PM2.5, PM10, O₃, NO₂, US AQI): Open-Meteo Air '
                  'Quality API, modelo global CAMS (Copernicus), ~45 km, a cada 3 h.',
              'Clima (temperatura, sensação térmica, umidade, UV): Open-Meteo '
                  'Forecast API.',
              'Histórico de ${AppConstants.pastDays} dias e previsão de '
                  '${AppConstants.forecastDays} dias por zona.',
              'População, escolas e UBSs por zona: estimativas SINTÉTICAS para fins '
                  'acadêmicos.',
              'Sem conexão: últimos dados salvos no aparelho. Sem cache: dados '
                  'sintéticos claramente identificados.',
            ]),
            SectionHeader('Como os alertas são gerados'),
            _Block(items: [
              'Ar ruim: média diária prevista de PM2.5 acima do limiar (padrão OMS: '
                  '15 µg/m³). Severidade pela razão valor/limiar: ≥1,5× alto, ≥2,5× crítico.',
              'Calor extremo: sensação térmica ≥ limiar (padrão 35 °C) por um mínimo '
                  'de horas no dia (padrão 3 h).',
              'Risco combinado: as duas regras no mesmo dia → sempre crítico.',
              'Tendência de piora: regressão linear sobre as médias diárias de PM2.5 '
                  'dos últimos 7 dias. Alerta se a inclinação ≥ '
                  '${AlertEngine.trendMinSlope} µg/m³/dia, R² ≥ ${AlertEngine.trendMinR2} '
                  'e a projeção em ${AlertEngine.trendProjectionDays} dias passar do limiar.',
            ]),
            SectionHeader('Métricas e nível de confiança'),
            _Block(items: [
              'A confiança começa em 100 pontos e perde pontos por fator de incerteza: '
                  'horizonte (>48 h −20; >96 h −35), dados offline (−10), dados '
                  'desatualizados >6 h (−15), dados sintéticos (−40), valor a menos de '
                  '15% do limiar (−15), lacunas nos dados (−15), resolução do modelo '
                  'de ar (−10), ilhas de calor não captadas (−5) e R² < 0,5 (−20).',
              'Alta: ≥ 70 pontos · Média: 45 a 69 · Baixa: < 45.',
              'R² (coeficiente de determinação) mede o quanto a reta da tendência '
                  'explica os dados: perto de 1 = tendência consistente.',
            ]),
            SectionHeader('Limitações e vieses'),
            _Block(items: [
              'Resolução espacial grossa: um valor representa a zona inteira; '
                  'bairros vizinhos recebem quase o mesmo número.',
              'Não substitui as estações oficiais de monitoramento (ex.: CETESB).',
              'Viés de modelo: o CAMS tende a suavizar picos locais de tráfego e '
                  'queimadas.',
              'Viés de participação: ocorrências dependem de quem tem o app e '
                  'internet; zonas com menos acesso podem parecer "mais tranquilas".',
              'Populações e equipamentos por zona são estimativas, não dados oficiais.',
            ]),
            SectionHeader('Quando NÃO confiar nas previsões'),
            _Block(items: [
              'Previsões além de 3 dias.',
              'Dados offline ou com mais de 6 horas.',
              'Valores muito próximos do limiar.',
              'Eventos bruscos: frentes frias, chuva forte, incêndios próximos.',
              'Modo demonstração (dados sintéticos).',
            ]),
            SectionHeader('Atribuição'),
            _Block(items: [AppConstants.attribution]),
            SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Icon(Icons.circle, size: 6, color: scheme.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
