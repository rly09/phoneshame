import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class NotificationPlatformHelper {
  static Future<void> requestPermissions(FlutterLocalNotificationsPlugin notifications) async {
    // Stub implementation for Windows/Web
  }
}
