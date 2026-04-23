import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import 'arc_gauge_widget.dart';

class ShareCardWidget extends StatelessWidget {
  final GlobalKey repaintKey;
  final int    score;
  final String totalTime;
  final String topApp;
  final String roastSnippet;
  final String vsYesterday;

  const ShareCardWidget({
    super.key,
    required this.repaintKey,
    required this.score,
    required this.totalTime,
    required this.topApp,
    required this.roastSnippet,
    this.vsYesterday = '',
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = ScoreColors.scoreColor(context, score.toDouble());
    final label      = ScoreColors.rotLabel(score);
    final dateStr    = DateFormat('d MMM yyyy').format(DateTime.now());

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width:  400,
        constraints: const BoxConstraints(minHeight: 700),
        color:  context.colors.bg,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Text(
              'ROT',
              style: GoogleFonts.poppins(
                color:         context.colors.textTertiary,
                fontSize:      11,
                fontWeight:    FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: context.colors.border),
            const SizedBox(height: 28),

            // ── Score block ───────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    score.toString(),
                    style: GoogleFonts.poppins(
                      color:         scoreColor,
                      fontSize:      96,
                      fontWeight:    FontWeight.w800,
                      height:        1.0,
                      letterSpacing: -4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color:      scoreColor,
                      fontSize:   16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'today · $dateStr',
                    style: GoogleFonts.poppins(
                      color:   context.colors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Stats row ─────────────────────────────────────────────────
            Center(
              child: Text(
                '$totalTime  ·  $topApp${vsYesterday.isNotEmpty ? '  ·  $vsYesterday' : ''}',
                style: GoogleFonts.poppins(
                  color:   context.colors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // ── Roast quote ───────────────────────────────────────────────
            if (roastSnippet.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: const BorderRadius.only(
                    topRight:    Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    left: BorderSide(color: context.colors.red, width: 3),
                  ),
                ),
                child: Text(
                  '"$roastSnippet"',
                  style: GoogleFonts.poppins(
                    color:     context.colors.textPrimary,
                    fontSize:  14,
                    fontStyle: FontStyle.italic,
                    height:    1.5,
                  ),
                ),
              ),

            const SizedBox(height: 48),

            // ── Mini gauge ────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  ArcGaugeWidget(animatedScore: score.toDouble(), size: 120),
                  const SizedBox(height: 4),
                  Text(
                    "what's your score?",
                    style: GoogleFonts.poppins(
                      color:   context.colors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#rot',
                    style: GoogleFonts.poppins(
                      color:      context.colors.purple,
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
