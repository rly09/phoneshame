import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Lightweight score display card (used as fallback / in share contexts).
/// The main home screen uses AnimatedRotRing instead.
class RotScoreWidget extends StatelessWidget {
  final int    score;
  final String totalTimeStr;

  const RotScoreWidget({
    super.key,
    required this.score,
    required this.totalTimeStr,
  });

  @override
  Widget build(BuildContext context) {
    final color = ScoreColors.scoreColor(context, score.toDouble());
    final label = ScoreColors.rotLabel(score);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:        context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: context.colors.border),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: AppColors.cDarkest.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            'ROT SCORE',
            style: GoogleFonts.poppins(
              fontSize:      11,
              fontWeight:    FontWeight.w600,
              letterSpacing: 1.5,
              color:         context.colors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            score.toString(),
            style: GoogleFonts.poppins(
              fontSize:   72,
              fontWeight: FontWeight.w800,
              color:      color,
              height:     1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text(
            'Total today: $totalTimeStr',
            style: GoogleFonts.poppins(color: context.colors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
