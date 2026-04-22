import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class AnimatedShameRing extends StatefulWidget {
  final int score;
  final String totalTimeStr;

  const AnimatedShameRing({
    super.key,
    required this.score,
    required this.totalTimeStr,
  });

  @override
  State<AnimatedShameRing> createState() => _AnimatedShameRingState();
}

class _AnimatedShameRingState extends State<AnimatedShameRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedShameRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score.toDouble()).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double currentScore) {
    if (currentScore <= 400) return AppColors.green;
    if (currentScore <= 700) return AppColors.amber;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = _animation.value;
        final currentColor = _getScoreColor(currentScore);

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _ShameRingPainter(
                  score: currentScore,
                  color: currentColor,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentScore.toInt().toString(),
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "SHAME SCORE",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(150),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ShameRingPainter extends CustomPainter {
  final double score;
  final Color color;

  _ShameRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;
    
    // Draw background ring
    final bgPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
      
    canvas.drawCircle(center, radius, bgPaint);
    
    // Draw progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
      
    final sweepAngle = (score / 1000).clamp(0.0, 1.0) * 2 * pi;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShameRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
