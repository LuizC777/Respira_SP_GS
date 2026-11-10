import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'domain/models/alert.dart';
import 'providers/alert_providers.dart';
import 'providers/core_providers.dart';
import 'providers/settings_providers.dart';

class RespiraApp extends ConsumerStatefulWidget {
  const RespiraApp({super.key});

  @override
  ConsumerState<RespiraApp> createState() => _RespiraAppState();
}

class _RespiraAppState extends ConsumerState<RespiraApp> {
  @override
  void initState() {
    super.initState();
    final notifications = NotificationService.instance;
    notifications.onOpenAlert = _openAlert;
    // Se o app foi aberto tocando numa notificação, vai direto ao alerta.
    final launchId = notifications.launchAlertId;
    if (launchId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAlert(launchId));
      notifications.launchAlertId = null;
    }
  }

  void _openAlert(String alertId) {
    if (!ref.read(settingsProvider).consentGiven) return;
    ref.read(routerProvider).pushNamed(
      AppRoutes.alertDetail,
      pathParameters: {'alertId': alertId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    // Novos alertas altos/críticos viram notificação local (se ativado).
    ref.listen<AsyncValue<List<Alert>>>(alertsProvider, (previous, next) {
      final alerts = next.valueOrNull;
      if (alerts == null || !ref.read(settingsProvider).notificationsEnabled) {
        return;
      }
      NotificationService.instance
          .notifyNewAlerts(alerts, ref.read(localStoreProvider));
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Fonte: respeita a configuração do sistema e aplica o ajuste do app.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final systemFactor = media.textScaler.scale(14) / 14;
        final factor =
            (systemFactor * settings.textScale).clamp(1.0, 2.2).toDouble();
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(factor)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
