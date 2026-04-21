import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ShareCardWidget extends StatelessWidget {
  final GlobalKey repaintKey;
  final int score;
  final String totalTime;
  final String topApp;
  final String roastSnippet;

  const ShareCardWidget({
    super.key,
    required this.repaintKey,
    required this.score,
    required this.totalTime,
    required this.topApp,
    required this.roastSnippet,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_rounded, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text(
              "OFFICIAL SHAME SCORE",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              score.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _InfoRow(label: "Screen Time", value: totalTime),
                  const SizedBox(height: 8),
                  _InfoRow(label: "Biggest Vice", value: topApp),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '"$roastSnippet"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "#PhoneShame",
              style: TextStyle(
                color: AppColors.lightPurple,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: const TextStyle(color: Colors.white70, fontSize: 14)
        ),
        Text(
          value, 
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
