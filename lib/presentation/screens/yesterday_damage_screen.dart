import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/score_calculator.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/services/daily_roast_service.dart';

/// The "Yesterday's Damage" screen — shown when the user taps the morning roast notification.
class YesterdayDamageScreen extends StatefulWidget {
  const YesterdayDamageScreen({super.key});

  @override
  State<YesterdayDamageScreen> createState() => _YesterdayDamageScreenState();
}

class _YesterdayDamageScreenState extends State<YesterdayDamageScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;

  // Typewriter state
  String _displayedText = '';
  Timer? _typewriterTimer;
  int _charIndex = 0;
  bool _roastDone = false;

  late AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreAnim = CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _scoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await DailyRoastService.getCachedRoastData();
    if (!mounted) return;
    setState(() {
      _data    = data;
      _loading = false;
    });
    if (data != null) {
      _scoreCtrl.forward();
      _startTypewriter(data['text'] as String);
    }
  }

  void _startTypewriter(String text) {
    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 22), (t) {
      if (_charIndex < text.length) {
        setState(() {
          _displayedText += text[_charIndex];
          _charIndex++;
        });
      } else {
        t.cancel();
        setState(() => _roastDone = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.bg,
        elevation:       0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.colors.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "yesterday's damage",
          style: GoogleFonts.poppins(
            color:      context.colors.textPrimary,
            fontSize:   18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.purple))
          : _data == null
              ? _NoDataView()
              : _buildContent(isDark),
    );
  }

  Widget _buildContent(bool isDark) {
    final totalMinutes = (_data!['totalMinutes'] as int?) ?? 0;
    final score        = (_data!['score'] as int?) ?? 0;
    final topApp       = (_data!['topApp'] as String?) ?? '—';
    final totalStr     = TimeFormatter.formatMinutesToHours(totalMinutes);
    final scoreColor   = ScoreColors.scoreColor(context, score.toDouble());
    final label        = ScoreColors.rotLabel(score);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score card
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (_, __) => Transform.scale(
              scale: 0.8 + (_scoreAnim.value * 0.2),
              child: Opacity(
                opacity: _scoreAnim.value.clamp(0.0, 1.0),
                child: _ScoreCard(
                  score:     score,
                  label:     label,
                  color:     scoreColor,
                  totalStr:  totalStr,
                  topApp:    topApp,
                  isDark:    isDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Section header
          Text(
            'WHAT THE AI THINKS',
            style: GoogleFonts.poppins(
              fontSize:      11,
              fontWeight:    FontWeight.w600,
              letterSpacing: 1.5,
              color:         context.colors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),

          // Roast text bubble — typewriter effect
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.elevated,
              borderRadius: const BorderRadius.only(
                topRight:    Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft:  Radius.circular(16),
              ),
              border: Border(
                left: BorderSide(color: context.colors.red, width: 3),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color:      AppColors.cDarkest.withAlpha(10),
                        blurRadius: 12,
                        offset:     const Offset(0, 4),
                      )
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayedText.isEmpty ? '...' : _displayedText,
                  style: GoogleFonts.poppins(
                    color:     context.colors.textPrimary,
                    fontSize:  15,
                    fontStyle: FontStyle.italic,
                    height:    1.6,
                  ),
                ),
                if (!_roastDone && _displayedText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color:       context.colors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Alternatives section (fades in after roast done)
          AnimatedOpacity(
            opacity:  _roastDone ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: _AlternativesSection(
              alternatives: (_data!['alternatives'] as List?)?.cast<String>() ?? [],
              totalMinutes: totalMinutes,
            ),
          ),
          const SizedBox(height: 28),

          // Share / close CTA
          if (_roastDone) ...[
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.surface,
                  shape:           RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side:         BorderSide(color: context.colors.border),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "noted. won't happen again.",
                  style: GoogleFonts.poppins(
                    color:      context.colors.textPrimary,
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }
}

// ── Score summary card ────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final int    score;
  final String label;
  final Color  color;
  final String totalStr;
  final String topApp;
  final bool   isDark;

  const _ScoreCard({
    required this.score,
    required this.label,
    required this.color,
    required this.totalStr,
    required this.topApp,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:        context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: context.colors.border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color:      AppColors.cDarkest.withAlpha(8),
                  blurRadius: 16,
                  offset:     const Offset(0, 6),
                )
              ],
      ),
      child: Column(
        children: [
          Text(
            'YESTERDAY',
            style: GoogleFonts.poppins(
              fontSize:      11,
              fontWeight:    FontWeight.w600,
              letterSpacing: 1.5,
              color:         context.colors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            score.toString(),
            style: GoogleFonts.poppins(
              fontSize:   72,
              fontWeight: FontWeight.w800,
              color:      color,
              height:     1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize:   14,
              fontWeight: FontWeight.w600,
              color:      color,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(label: 'TOTAL TIME', value: totalStr),
              Container(width: 1, height: 32, color: context.colors.border),
              _Stat(label: 'TOP APP', value: topApp),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize:      9,
            fontWeight:    FontWeight.w600,
            letterSpacing: 1,
            color:         context.colors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize:   14,
            fontWeight: FontWeight.w700,
            color:      context.colors.textPrimary,
          ),
          maxLines:  1,
          overflow:  TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Alternatives section ──────────────────────────────────────────────────────

class _AlternativesSection extends StatelessWidget {
  final List<String> alternatives;
  final int totalMinutes;
  const _AlternativesSection({required this.alternatives, required this.totalMinutes});

  @override
  Widget build(BuildContext context) {
    // Use cached AI alternatives if available; fall back to score calculator
    final items = alternatives.isNotEmpty
        ? alternatives
        : ScoreCalculator.getAlternatives(totalMinutes);

    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOU COULD HAVE',
          style: GoogleFonts.poppins(
            fontSize:      11,
            fontWeight:    FontWeight.w600,
            letterSpacing: 1.5,
            color:         context.colors.textTertiary,
          ),
        ),
        const SizedBox(height: 14),
        ...items.asMap().entries.map((entry) {
          final i   = entry.key;
          final alt = entry.value;
          return TweenAnimationBuilder<double>(
            tween:    Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + i * 120),
            curve:    Curves.easeOutCubic,
            builder:  (_, v, child) => Opacity(
              opacity: v,
              child:   Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alt,
                      style: GoogleFonts.poppins(
                        color:    context.colors.textPrimary,
                        fontSize: 15,
                        height:   1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── No data fallback ──────────────────────────────────────────────────────────

class _NoDataView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌙', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            Text(
              'no roast yet',
              style: GoogleFonts.poppins(
                color:      context.colors.textPrimary,
                fontSize:   22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "check back after your first full day in the app. we're watching.",
              style: GoogleFonts.poppins(
                color:    context.colors.textSecondary,
                fontSize: 14,
                height:   1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
