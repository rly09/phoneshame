import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationPlatformHelper {
  static Future<void> requestPermissions(FlutterLocalNotificationsPlugin notifications) async {
    if (Platform.isAndroid) {
      final androidPlugin = notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final dynamic plugin = androidPlugin;
        try {
          await plugin.requestNotificationsPermission();
        } catch (_) {
          try {
            await plugin.requestPermission();
          } catch (_) {
            // Ignore
          }
        }
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      // We use dynamic here to avoid compile errors on non-Apple platforms
      // even though this file is only used on IO platforms.
      final dynamic plugin = notifications;
      final darwinPlugin = plugin.resolvePlatformSpecificImplementation();
      await darwinPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
}
