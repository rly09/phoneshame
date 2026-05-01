import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/score_calculator.dart';
import '../../data/services/daily_roast_service.dart';
import '../../providers/roast_provider.dart';
import '../../providers/usage_provider.dart';
import '../screens/share_screen.dart';

class RoastBottomSheet extends ConsumerStatefulWidget {
  const RoastBottomSheet({super.key});

  @override
  ConsumerState<RoastBottomSheet> createState() => _RoastBottomSheetState();
}

class _RoastBottomSheetState extends ConsumerState<RoastBottomSheet> {
  String _displayedText = '';
  Timer? _timer;
  int    _charIndex = 0;
  String _fullText  = '';
  bool   _roastDone = false;

  List<String>? _alternatives;
  bool          _altLoading = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTypewriter(String text) {
    if (_fullText == text) return;
    setState(() {
      _fullText      = text;
      _displayedText = '';
      _charIndex     = 0;
      _roastDone     = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (_charIndex < _fullText.length) {
        setState(() {
          _displayedText += _fullText[_charIndex];
          _charIndex++;
        });
      } else {
        t.cancel();
        setState(() => _roastDone = true);
        // Start loading AI alternatives once roast finishes typing
        _loadAlternatives();
      }
    });
  }

  Future<void> _loadAlternatives() async {
    if (_alternatives != null || _altLoading) return;
    setState(() => _altLoading = true);
    final apps = ref.read(usageProvider).valueOrNull ?? [];
    final totalMins = apps.fold<int>(0, (s, a) => s + a.totalTimeInMinutes);
    final topApps = apps.take(3).map((a) => a.appName).toList();
    final result = await AlternativesService.generate(
      totalMinutes: totalMins,
      topApps: topApps,
    );
    if (mounted) setState(() { _alternatives = result; _altLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final roastAsync = ref.watch(roastProvider);
    final usageAsync = ref.watch(usageProvider);
    final isDark     = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color:        context.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                child: Center(
                  child: Container(
                    width:  36,
                    height: 4,
                    decoration: BoxDecoration(
                      color:        context.colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'your roast',
                      style: GoogleFonts.poppins(
                        color:      context.colors.textPrimary,
                        fontSize:   18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Roast card
                    roastAsync.when(
                      data: (roast) {
                        final text = roast?.text ??
                            "Couldn't generate a roast. You got lucky today.";
                        WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _startTypewriter(text));

                        return Container(
                          padding:    const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:  context.colors.elevated,
                            borderRadius: const BorderRadius.only(
                              topRight:    Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border(
                              left: BorderSide(color: context.colors.red, width: 3),
                            ),
                            boxShadow: isDark ? null : [
                              BoxShadow(
                                color: AppColors.cDarkest.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Text(
                            _displayedText,
                            style: GoogleFonts.poppins(
                              color:     context.colors.textPrimary,
                              fontSize:  15,
                              fontStyle: FontStyle.italic,
                              height:    1.6,
                            ),
                          ),
                        );
                      },
                      loading: () => Shimmer.fromColors(
                        baseColor:      context.colors.elevated,
                        highlightColor: context.colors.border,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 14, width: double.infinity,
                                color: context.colors.elevated,
                                margin: const EdgeInsets.only(bottom: 10)),
                            Container(height: 14, width: double.infinity,
                                color: context.colors.elevated,
                                margin: const EdgeInsets.only(bottom: 10)),
                            Container(height: 14, width: 200,
                                color: context.colors.elevated),
                          ],
                        ),
                      ),
                      error: (e, _) => Text('Error: $e',
                          style: TextStyle(color: context.colors.red)),
                    ),

                    const SizedBox(height: 32),

                    // Alternatives section
                    if (_roastDone || roastAsync.hasError)
                      usageAsync.when(
                        data: (apps) {
                          // Show shimmer while AI is generating
                          if (_altLoading) {
                            return Shimmer.fromColors(
                              baseColor:      context.colors.elevated,
                              highlightColor: context.colors.border,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(height: 11, width: 130, color: context.colors.elevated,
                                      margin: const EdgeInsets.only(bottom: 16)),
                                  ...List.generate(3, (_) => Container(
                                    height: 14, width: double.infinity,
                                    color: context.colors.elevated,
                                    margin: const EdgeInsets.only(bottom: 14),
                                  )),
                                ],
                              ),
                            );
                          }

                          final totalMins = apps.fold<int>(0, (s, a) => s + a.totalTimeInMinutes);
                          final items = _alternatives ?? ScoreCalculator.getAlternatives(totalMins);
                          if (items.isEmpty) return const SizedBox();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INSTEAD YOU COULD HAVE',
                                style: GoogleFonts.poppins(
                                  fontSize:      11,
                                  fontWeight:    FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color:         context.colors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...items.asMap().entries.map((entry) {
                                final i   = entry.key;
                                final alt = entry.value;
                                return TweenAnimationBuilder<double>(
                                  tween:    Tween(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 300 + i * 120),
                                  curve:    Curves.easeOutCubic,
                                  builder:  (ctx, v, child) => Opacity(
                                    opacity: v,
                                    child:   Transform.translate(
                                      offset: Offset(0, 14 * (1 - v)),
                                      child:  child,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('✨', style: TextStyle(fontSize: 20)),
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
                        },
                        loading: () => const SizedBox(),
                        error:   (_, __) => const SizedBox(),
                      ),

                    const SizedBox(height: 32),

                    // Share button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: roastAsync.isLoading
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                final apps = usageAsync.valueOrNull ?? [];
                                final totalMins = apps.fold<int>(
                                    0, (s, a) => s + a.totalTimeInMinutes);
                                final score = ScoreCalculator
                                    .calculateRotScore(totalMins);
                                final topApp = apps.isNotEmpty
                                    ? apps.first.appName
                                    : 'Unknown';
                                final roastText =
                                    ref.read(roastProvider).valueOrNull?.text ??
                                        '';

                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) => ShareScreen(
                                      score:        score,
                                      topApp:       topApp,
                                      totalTimeStr:
                                          '${totalMins ~/ 60}h ${totalMins % 60}m',
                                      roastSnippet: roastText,
                                    ),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        FadeTransition(
                                            opacity: anim, child: child),
                                    transitionDuration:
                                        const Duration(milliseconds: 200),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: context.colors.red.withAlpha(isDark ? 100 : 50),
                        ).copyWith(
                          elevation: WidgetStateProperty.all(0),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:      context.colors.red.withAlpha(isDark ? 100 : 50),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'spread the rot',
                                style: GoogleFonts.poppins(
                                  color:      context.colors.bg,
                                  fontSize:   16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('→',
                                  style: TextStyle(
                                      color: context.colors.bg,
                                      fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
