import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable 220° speedometer-style arc gauge.
///
/// [animatedScore] is a 0–1000 value typically driven by an animation.
/// [size]          controls the outer diameter of the arc.
class ArcGaugeWidget extends StatelessWidget {
  final double animatedScore;
  final double size;
  final bool showLabel;

  const ArcGaugeWidget({
    super.key,
    required this.animatedScore,
    this.size = 260,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.75, // clip bottom gap
      child: CustomPaint(
        painter: _ArcGaugePainter(
          score: animatedScore,
          trackColor: context.colors.elevated,
          gradientColors: ScoreColors.scoreGradient(context),
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double score;
  final Color trackColor;
  final List<Color> gradientColors;

  _ArcGaugePainter({
    required this.score,
    required this.trackColor,
    required this.gradientColors,
  });

  // Arc spans 220°, starting from 160° (bottom-left), going clockwise.
  static const double _arcSpanDeg = 220;
  static const double _startDeg   = 160;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + size.height * 0.1;
    final radius = size.width / 2 - 14;

    final startRad = _toRad(_startDeg);
    final spanRad  = _toRad(_arcSpanDeg);

    // ── Track ──────────────────────────────────────────────────────────────
    final trackPaint = Paint()
      ..color       = trackColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap   = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startRad,
      spanRad,
      false,
      trackPaint,
    );

    // ── Fill (gradient shaders need a rect) ───────────────────────────────
    final fraction = (score / 1000).clamp(0.0, 1.0);
    if (fraction <= 0) return;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Build a sweep gradient aligned with the arc start
    final shader = SweepGradient(
      center:     Alignment.center,
      startAngle: startRad,
      endAngle:   startRad + spanRad,
      colors:     gradientColors,
      stops:      const [0.0, 0.5, 1.0],
    ).createShader(rect);

    final fillPaint = Paint()
      ..shader      = shader
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap   = StrokeCap.round;

    canvas.drawArc(rect, startRad, spanRad * fraction, false, fillPaint);
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  @override
  bool shouldRepaint(_ArcGaugePainter old) => 
    old.score != score || old.trackColor != trackColor;
}
