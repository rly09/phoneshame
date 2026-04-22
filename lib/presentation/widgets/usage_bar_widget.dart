import 'package:flutter/material.dart';
import '../../data/models/app_usage_model.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/constants/app_colors.dart';

class UsageBarWidget extends StatelessWidget {
  final List<AppUsageModel> apps;

  const UsageBarWidget({super.key, required this.apps});

  Color _getScoreColor(int totalMinutes) {
    if (totalMinutes <= 400) return AppColors.green;
    if (totalMinutes <= 700) return AppColors.amber;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Column(
            children: [
              Icon(Icons.hourglass_empty, size: 48, color: AppColors.primary.withAlpha(100)),
              const SizedBox(height: 16),
              Text(
                "open some apps first 😅",
                style: TextStyle(fontSize: 16, color: AppColors.primary.withAlpha(150)),
              ),
            ],
          ),
        ),
      );
    }

    final topApps = apps.take(5).toList();
    final maxUsageStr = topApps.first.totalTimeInMinutes;
    final maxUsage = maxUsageStr > 0 ? maxUsageStr : 1;
    final totalMinutes = apps.fold<int>(0, (sum, item) => sum + item.totalTimeInMinutes);
    final barColor = _getScoreColor(totalMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 24.0),
          child: Text(
            "WHERE YOUR TIME WENT",
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 2,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Column(
            children: topApps.asMap().entries.map((entry) {
              final index = entry.key;
              final app = entry.value;
              final fraction = app.totalTimeInMinutes / maxUsage;
              
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.lightPurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      app.appName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    TimeFormatter.formatMinutesToHours(app.totalTimeInMinutes),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(150),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CustomPaint(
                                size: const Size(double.infinity, 8),
                                painter: BarChartPainter(
                                  fraction: fraction,
                                  color: barColor,
                                  backgroundColor: barColor.withAlpha(30),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < topApps.length - 1)
                    Divider(height: 1, color: Colors.grey.withAlpha(30), indent: 72, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class BarChartPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color backgroundColor;

  BarChartPainter({
    required this.fraction,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final fgWidth = size.width * fraction;
    
    if (fgWidth > 0) {
       final fgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fgWidth, size.height),
        const Radius.circular(4),
      );
      canvas.drawRRect(fgRect, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.fraction != fraction || 
           oldDelegate.color != color ||
           oldDelegate.backgroundColor != backgroundColor;
  }
}
