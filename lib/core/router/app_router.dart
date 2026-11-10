import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_data_screen.dart';
import '../../features/alerts/alert_detail_screen.dart';
import '../../features/alerts/alerts_screen.dart';
import '../../features/consent/consent_screen.dart';
import '../../features/dashboards/air_dashboard_screen.dart';
import '../../features/dashboards/heat_dashboard_screen.dart';
import '../../features/dashboards/impact_dashboard_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../providers/settings_providers.dart';

/// Nomes das rotas (usados com goNamed/pushNamed).
abstract final class AppRoutes {
  static const consent = 'consent';
  static const home = 'home';
  static const alerts = 'alerts';
  static const alertDetail = 'alertDetail';
  static const report = 'report';
  static const settings = 'settings';
  static const airDashboard = 'airDashboard';
  static const heatDashboard = 'heatDashboard';
  static const impactDashboard = 'impactDashboard';
  static const aboutData = 'aboutData';
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    // Sem consentimento, o usuário sempre vai para a tela de consentimento.
    redirect: (context, state) {
      final consent = ref.read(settingsProvider).consentGiven;
      final atConsent = state.matchedLocation == '/consent';
      if (!consent && !atConsent) return '/consent';
      if (consent && atConsent) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/consent',
        name: AppRoutes.consent,
        builder: (context, state) => const ConsentScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            MainShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/alerts',
            name: AppRoutes.alerts,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AlertsScreen()),
          ),
          GoRoute(
            path: '/report',
            name: AppRoutes.report,
            pageBuilder: (context, state) => NoTransitionPage(
              // Parâmetro opcional: zona pré-selecionada (?zoneId=leste)
              child: ReportScreen(initialZoneId: state.uri.queryParameters['zoneId']),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: AppRoutes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      // Telas de detalhe abrem por cima da navegação inferior.
      GoRoute(
        path: '/zone/:zoneId/air',
        name: AppRoutes.airDashboard,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            AirDashboardScreen(zoneId: state.pathParameters['zoneId']!),
      ),
      GoRoute(
        path: '/zone/:zoneId/heat',
        name: AppRoutes.heatDashboard,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            HeatDashboardScreen(zoneId: state.pathParameters['zoneId']!),
      ),
      GoRoute(
        path: '/zone/:zoneId/impact',
        name: AppRoutes.impactDashboard,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            ImpactDashboardScreen(zoneId: state.pathParameters['zoneId']!),
      ),
      GoRoute(
        path: '/alert/:alertId',
        name: AppRoutes.alertDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            AlertDetailScreen(alertId: state.pathParameters['alertId']!),
      ),
      GoRoute(
        path: '/about-data',
        name: AppRoutes.aboutData,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AboutDataScreen(),
      ),
    ],
  );
});
