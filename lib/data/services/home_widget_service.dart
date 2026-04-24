import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/utils/score_calculator.dart';
import '../../core/utils/time_formatter.dart';
import '../models/app_usage_model.dart';

class HomeWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'com.phoneshame/home_widget',
  );

  static Future<void> syncUsageSummary(List<AppUsageModel> apps) async {
    final totalMinutes = apps.fold<int>(
      0,
      (sum, item) => sum + item.totalTimeInMinutes,
    );
    final score = ScoreCalculator.calculateRotScore(totalMinutes);
    final topApp = apps.isNotEmpty ? apps.first.appName : 'No data yet';
    final topMinutes = apps.isNotEmpty ? apps.first.totalTimeInMinutes : 0;

    final payload = <String, Object>{
      'totalMinutes': totalMinutes,
      'totalTimeLabel': TimeFormatter.formatMinutesToHours(totalMinutes),
      'score': score,
      'topApp': topApp,
      'topMinutes': topMinutes,
      'topTimeLabel': TimeFormatter.formatMinutesToHours(topMinutes),
      'trackedAppsCount': apps.length,
      'updatedAtEpochMs': DateTime.now().millisecondsSinceEpoch,
      'hasData': apps.isNotEmpty,
    };

    try {
      await _channel.invokeMethod<void>('saveWidgetData', payload);
      await _channel.invokeMethod<void>('refreshWidgets');
    } on PlatformException catch (error) {
      debugPrint('Home widget sync failed: ${error.message}');
    } catch (error) {
      debugPrint('Home widget sync failed: $error');
    }
  }
}
