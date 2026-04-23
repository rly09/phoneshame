import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'arc_gauge_widget.dart';

/// The animated shame ring — delegates to ArcGaugeWidget.
/// Retains the same public API (score + totalTimeStr) so home_screen
/// doesn't need to change its call site.
class AnimatedRotRing extends StatefulWidget {
  final int    score;
  final String totalTimeStr;

  const AnimatedRotRing({
    super.key,
    required this.score,
    required this.totalTimeStr,
  });

  @override
  State<AnimatedRotRing> createState() => _AnimatedRotRingState();
}

class _AnimatedRotRingState extends State<AnimatedRotRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scoreAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );
    _scoreAnim = Tween<double>(begin: 0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedRotRing old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _scoreAnim = Tween<double>(
        begin: _scoreAnim.value,
        end:   widget.score.toDouble(),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scoreAnim,
      builder:   (context, _) {
        final current = _scoreAnim.value;
        final color   = ScoreColors.scoreColor(context, current);
        final label   = ScoreColors.rotLabel(current.toInt());

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ArcGaugeWidget(animatedScore: current, size: 260),
                // Score text overlaid inside the arc
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24), // push down from arc top
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          current.toInt().toString(),
                          style: GoogleFonts.poppins(
                            fontSize:      72,
                            fontWeight:    FontWeight.w800,
                            color:         color,
                            height:        1.0,
                            letterSpacing: -3,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            ' / 1000',
                            style: GoogleFonts.poppins(
                              fontSize:   16,
                              fontWeight: FontWeight.w500,
                              color:      context.colors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      color,
              ),
            ),
          ],
        );
      },
    );
  }
}
