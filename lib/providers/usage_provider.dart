import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_usage_model.dart';
import '../data/services/usage_stats_service.dart';

final usageStatsServiceProvider = Provider((ref) => UsageStatsService());

final usageProvider = FutureProvider<List<AppUsageModel>>((ref) async {
  final service = ref.watch(usageStatsServiceProvider);
  final hasPermission = await service.checkPermission();
  if (!hasPermission) {
    return [];
  }
  return await service.getTodayUsage();
});
