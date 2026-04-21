import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/roast_model.dart';
import '../data/services/roast_service.dart';
import 'usage_provider.dart';

final roastServiceProvider = Provider((ref) => RoastService());

final roastProvider = FutureProvider<RoastModel?>((ref) async {
  final usageData = await ref.watch(usageProvider.future);
  if (usageData.isEmpty) return null;

  final totalMinutes = usageData.fold<int>(0, (sum, item) => sum + item.totalTimeInMinutes);
  
  final service = ref.watch(roastServiceProvider);
  return await service.getRoast(usageData, totalMinutes);
});
