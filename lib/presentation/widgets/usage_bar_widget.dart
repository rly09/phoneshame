import 'package:flutter/material.dart';
import '../../data/models/app_usage_model.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/constants/app_colors.dart';

class UsageBarWidget extends StatelessWidget {
  final List<AppUsageModel> apps;

  const UsageBarWidget({super.key, required this.apps});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const Center(child: Text("No apps used yet today."));
    }

    final topApps = apps.take(5).toList();
    final maxUsageStr = topApps.first.totalTimeInMinutes;
    final maxUsage = maxUsageStr > 0 ? maxUsageStr : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            "Top Wastes of Time",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...topApps.map((app) {
          final fraction = app.totalTimeInMinutes / maxUsage;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        app.appName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(TimeFormatter.formatMinutesToHours(app.totalTimeInMinutes)),
                  ],
                ),
                const SizedBox(height: 6),
                CustomPaint(
                  size: const Size(double.infinity, 24),
                  painter: BarChartPainter(
                    fraction: fraction,
                    color: AppColors.accent,
                    backgroundColor: AppColors.lightPurple,
                  ),
                ),
              ],
            ),
          );
        }),
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
    
    // Draw background rounded rect
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Draw foreground rounded rect
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final fgWidth = size.width * fraction;
    
    // Only draw if there's width
    if (fgWidth > 0) {
       final fgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fgWidth, size.height),
        const Radius.circular(8),
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
