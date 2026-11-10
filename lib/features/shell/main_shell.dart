import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../domain/models/alert.dart';
import '../../providers/alert_providers.dart';

/// Navegação inferior entre as seções principais.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = [
    (path: '/home', route: AppRoutes.home),
    (path: '/alerts', route: AppRoutes.alerts),
    (path: '/report', route: AppRoutes.report),
    (path: '/settings', route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _tabs
        .indexWhere((t) => location.startsWith(t.path))
        .clamp(0, _tabs.length - 1)
        .toInt();
    final pending = (ref.watch(alertsProvider).valueOrNull ?? const <Alert>[])
        .where((a) => a.status == AlertStatus.pending)
        .length;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.goNamed(_tabs[i].route),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Visão geral',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertas',
            tooltip: '$pending alertas aguardando análise',
          ),
          const NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Ocorrência',
          ),
          const NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
