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

  String _getLabelForScore() {
    if (score <= 400) return "not bad 👀";
    if (score <= 700) return "needs help 😬";
    return "certified addict 💀";
  }

  Color _getColorForScore() {
    if (score <= 400) return AppColors.green;
    if (score <= 700) return AppColors.amber;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Current date format manually to avoid adding intl if not explicitly set in format
    // But since we can use standard DateTime, let's just do that
    final dateStr = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 400,
        height: 600,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1535), Color(0xFF26215C)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ]
        ),
        child: Stack(
          children: [
            Positioned(
              top: 24,
              left: 24,
              child: Text(
                "phoneshame",
                style: TextStyle(
                  color: AppColors.lightPurple.withAlpha(150),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getColorForScore().withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getColorForScore().withAlpha(100)),
                    ),
                    child: Text(
                      _getLabelForScore(),
                      style: TextStyle(
                        color: _getColorForScore(),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: 320,
                    height: 1,
                    color: Colors.white.withAlpha(20),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(label: "time", value: totalTime),
                      Container(height: 30, width: 1, color: Colors.white.withAlpha(30)),
                      _StatItem(label: "top app", value: topApp),
                      Container(height: 30, width: 1, color: Colors.white.withAlpha(30)),
                      _StatItem(label: "date", value: dateStr),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      '"$roastSnippet"',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.lightPurple.withAlpha(200),
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Text(
                "what's your score? #phoneshame",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.lightPurple.withAlpha(100),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(), 
          style: TextStyle(
            color: Colors.white.withAlpha(150), 
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          )
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
