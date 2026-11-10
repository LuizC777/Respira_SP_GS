import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/models/alert.dart';
import '../local/local_store.dart';

/// Notificações locais para alertas ALTOS e CRÍTICOS (diferencial).
/// A notificação só informa e abre o detalhe do alerta; nenhuma ação é
/// executada sem o gestor.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Chamado quando o usuário toca numa notificação (payload = id do alerta).
  void Function(String alertId)? onOpenAlert;

  /// Id do alerta que abriu o app (app estava fechado).
  String? launchAlertId;

  static const _channelId = 'alertas_respira_sp';
  static const _channelName = 'Alertas de risco';
  static const _channelDescription =
      'Alertas altos e críticos de qualidade do ar e calor extremo.';

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          final id = response.payload;
          if (id != null && id.isNotEmpty) onOpenAlert?.call(id);
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        launchAlertId = launch!.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e) {
      debugPrint('Notificações indisponíveis: $e');
    }
  }

  /// Pede permissão (Android 13+ e iOS). Retorna true se concedida.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
    } catch (e) {
      debugPrint('Falha ao pedir permissão de notificação: $e');
    }
    return false;
  }

  /// Notifica alertas altos/críticos ainda não notificados e pendentes.
  Future<int> notifyNewAlerts(List<Alert> alerts, LocalStore store) async {
    if (!_ready) return 0;
    var count = 0;
    for (final alert in alerts) {
      final relevant = alert.severity != AlertSeverity.moderate &&
          alert.status == AlertStatus.pending;
      if (!relevant || store.wasNotified(alert.id)) continue;
      await show(alert);
      await store.markNotified(alert.id);
      count++;
    }
    return count;
  }

  Future<void> show(Alert alert) async {
    if (!_ready) return;
    await _plugin.show(
      alert.id.hashCode & 0x7fffffff,
      '${alert.severity.label}: ${alert.title}',
      'Confiança ${alert.confidence.level.label.toLowerCase()}. '
          'Toque para ver a evidência — a decisão é sua.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: alert.id,
    );
  }
}
