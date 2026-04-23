import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/score_calculator.dart';
import '../../core/utils/time_formatter.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  List<_DayData> _days = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs  = await SharedPreferences.getInstance();
    final today  = DateTime.now();
    final result = <_DayData>[];

    for (int i = 6; i >= 0; i--) {
      final d    = today.subtract(Duration(days: i));
      final key  = 'score_${d.year}_${d.month}_${d.day}';
      final sc   = prefs.getInt(key) ?? 0;
      final label = DateFormat('EEE').format(d);
      result.add(_DayData(label: label, score: sc, date: d));
    }

    setState(() { _days = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final avg     = _days.isEmpty ? 0 : _days.fold(0, (s, d) => s + d.score) ~/ _days.length;
    final worst   = _days.isEmpty ? null : _days.reduce((a, b) => a.score > b.score ? a : b);

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.bg,
        elevation:       0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '7-day streak',
          style: GoogleFonts.poppins(
            color:      context.colors.textPrimary,
            fontSize:   18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.purple))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: '7-DAY AVG',
                            value: avg.toString(),
                            color: ScoreColors.scoreColor(context, avg.toDouble()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'WORST DAY',
                            value: worst != null && worst.score > 0
                                ? '${DateFormat('EEE').format(worst.date)} · ${worst.score}'
                                : '—',
                            color: context.colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'WHERE YOUR WEEK WENT',
                      style: GoogleFonts.poppins(
                        fontSize:      11,
                        fontWeight:    FontWeight.w600,
                        letterSpacing: 1.5,
                        color:         context.colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bar chart
                    Expanded(
                      child: _BarChart(days: _days),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<_DayData> days;
  const _BarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final maxScore = days.isEmpty ? 1 : days.map((d) => d.score).reduce(math.max);
    final safeMax  = maxScore > 0 ? maxScore : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days.map((d) {
        final fraction = d.score / safeMax;
        final color    = ScoreColors.scoreColor(context, d.score.toDouble());
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (d.score > 0)
                  Text(
                    d.score.toString(),
                    style: GoogleFonts.poppins(
                      fontSize:   10,
                      color:      context.colors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration:     const Duration(milliseconds: 600),
                  curve:        Curves.easeOutCubic,
                  height:       math.max(fraction * 200, d.score > 0 ? 8.0 : 0),
                  decoration: BoxDecoration(
                    color:        d.score > 0 ? color : context.colors.border,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  d.label,
                  style: GoogleFonts.poppins(
                    fontSize:   12,
                    color:      context.colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        context.colors.surface,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize:      11,
              fontWeight:    FontWeight.w600,
              letterSpacing: 1.2,
              color:         context.colors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize:   20,
              fontWeight: FontWeight.w700,
              color:      color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayData {
  final String   label;
  final int      score;
  final DateTime date;
  const _DayData({required this.label, required this.score, required this.date});
}
