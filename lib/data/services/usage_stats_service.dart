import 'package:flutter/services.dart';
import '../models/app_usage_model.dart';

class UsageStatsService {
  static const MethodChannel _channel = MethodChannel('com.phoneshame/usage_stats');

  Future<List<AppUsageModel>> getTodayUsage() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getTodayUsage');
      return result.map((data) => AppUsageModel.fromMap(data as Map<dynamic, dynamic>)).toList();
    } on PlatformException catch (e) {
      print("Failed to get usage stats: '${e.message}'.");
      return [];
    }
  }

  Future<bool> requestUsageAccess() async {
    // Open settings exactly as requested
    const IntentChannel = MethodChannel('com.phoneshame/usage_stats');
    // We didn't build this intent in Plugin yet, but it's simpler to just use 'android_intent_plus' 
    // or manually open settings in Kotlin. Let's create another method in the plugin for this.
    // Wait, the prompt says "Give Access button opens Android Usage Access settings via platform channel".
    // I should update UsageStatsPlugin to support 'requestUsageAccess' or handle it here via intent.
    try {
      final bool? result = await _channel.invokeMethod('requestUsageAccess');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkPermission() async {
     try {
       final bool? result = await _channel.invokeMethod('checkPermission');
       return result ?? false;
     } catch (e) {
       return false;
     }
  }
}
