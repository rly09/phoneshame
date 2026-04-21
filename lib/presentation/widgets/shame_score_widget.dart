import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ShameScoreWidget extends StatelessWidget {
  final int score;
  final String totalTimeStr;

  const ShameScoreWidget({
    super.key,
    required this.score,
    required this.totalTimeStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.lightPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "YOUR SHAME SCORE",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score.toString(),
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Out of 1000",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary.withAlpha(180),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                "Total today: $totalTimeStr",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
