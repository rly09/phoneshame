import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_usage_model.dart';
import './usage_stats_service.dart';
import '../../core/utils/score_calculator.dart';
import 'platform_notifications_helper_stub.dart'
    if (dart.library.io) 'platform_notifications_helper_io.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final _random = Random();

  static const String _yesterdayScoreKey = 'yesterday_shame_score';
  static const int nudgeId = 3;
  static const int morningId = 1;
  static const int eveningId = 2;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC or let it be if it fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    
    if (kIsWeb || !Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await NotificationPlatformHelper.requestPermissions(_notifications);
  }

  Future<void> scheduleAllNotifications() async {
    if (kIsWeb || !Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) return;
    
    final prefs = await SharedPreferences.getInstance();
    final yesterdayScore = prefs.getInt(_yesterdayScoreKey) ?? 0;
    
    final usageService = UsageStatsService();
    final todayUsage = await usageService.getTodayUsage();
    final totalMinutes = todayUsage.fold<int>(0, (sum, app) => sum + app.totalTimeInMinutes);
    final todayScore = ScoreCalculator.calculateRotScore(totalMinutes);
    
    // Save today's score to be used as yesterday's score for the next morning notification
    await prefs.setInt(_yesterdayScoreKey, todayScore);

    await _scheduleMorningMotivation(yesterdayScore);
    await _scheduleEveningReport(todayScore, totalMinutes);
    await _scheduleNudge();
  }

  Future<void> _scheduleMorningMotivation(int yesterdayScore) async {
    String body;
    if (yesterdayScore < 500) {
      body = "yesterday you scored $yesterdayScore. can you do worse today?";
    } else {
      body = "yesterday: $yesterdayScore shame points. today is a fresh start.";
    }

    await _scheduleDailyNotification(
      id: morningId,
      title: "good morning 👋",
      body: body,
      hour: 8,
      minute: 0,
    );
  }

  Future<void> _scheduleEveningReport(int score, int totalMinutes) async {
    final timeStr = _formatMinutes(totalMinutes);
    final messages = [
      "shame score: $score. you rotted for $timeStr today. impressive.",
      "$timeStr gone forever. your score: $score 💀",
      "certified rotter behavior. $score/1000 today.",
    ];
    final body = messages[_random.nextInt(messages.length)];

    await _scheduleDailyNotification(
      id: eveningId,
      title: "your daily rot report 📊",
      body: body,
      hour: 21,
      minute: 0,
    );
  }

  Future<void> _scheduleNudge() async {
    final messages = [
      "you haven't checked your rot today. scared?",
      "open the app. we both know you've been on your phone.",
      "daily rot report waiting. coward behavior.",
    ];
    final body = messages[_random.nextInt(messages.length)];

    await _scheduleDailyNotification(
      id: nudgeId,
      title: "hey. 👀",
      body: body,
      hour: 22,
      minute: 0,
    );
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notifications',
          'Daily Notifications',
          channelDescription: 'Daily shame and motivation notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours == 0) return "$mins mins";
    if (mins == 0) return "$hours hrs";
    return "$hours hrs $mins mins";
  }

  Future<void> cancelNudge() async {
    if (kIsWeb || !Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) return;
    await _notifications.cancel(nudgeId);
  }
}
