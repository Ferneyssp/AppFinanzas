import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Encapsula la configuración y el disparo de notificaciones locales.
/// Mantenerlo en un servicio dedicado permite que el resto de la app
/// (providers, pantallas) no conozca los detalles del plugin.
class NotificacionService {
  NotificacionService._internal();
  static final NotificacionService instance = NotificacionService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;

  Future<void> inicializar() async {
    if (_inicializado) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    // En Android 13+ se requiere solicitar el permiso de notificaciones
    // explícitamente en tiempo de ejecución.
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _inicializado = true;
  }

  Future<void> mostrarAlertaCritica(String mensaje) async {
    if (!_inicializado) await inicializar();
    const androidDetails = AndroidNotificationDetails(
      'presupuesto_critico',
      'Alertas de presupuesto',
      channelDescription:
          'Notificaciones cuando el presupuesto mensual está casi agotado',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    try {
      await _plugin.show(
        1001,
        '🚨 Presupuesto crítico',
        mensaje,
        details,
      );
    } catch (_) {
      // Si la notificación falla (por ejemplo, permisos denegados),
      // la aplicación no debe interrumpirse: el estado crítico igual
      // se refleja visualmente en el dashboard.
    }
  }
}
