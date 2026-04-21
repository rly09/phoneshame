class AppUsageModel {
  final String appName;
  final String packageName;
  final int totalTimeInMinutes;

  AppUsageModel({
    required this.appName,
    required this.packageName,
    required this.totalTimeInMinutes,
  });

  factory AppUsageModel.fromMap(Map<dynamic, dynamic> map) {
    return AppUsageModel(
      appName: map['appName'] as String? ?? 'Unknown App',
      packageName: map['packageName'] as String? ?? 'unknown',
      totalTimeInMinutes: (map['totalTimeInMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}
