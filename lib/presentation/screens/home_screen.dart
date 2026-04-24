import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/score_calculator.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/models/app_usage_model.dart';
import '../../data/services/home_widget_service.dart';
import '../../providers/usage_provider.dart';
import '../../providers/theme_provider.dart';
import '../widgets/animated_rot_ring.dart';
import '../widgets/roast_bottom_sheet.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/usage_bar_widget.dart';
import 'streak_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  Timer? _midnightTimer;
  ProviderSubscription<AsyncValue<List<AppUsageModel>>>? _usageSubscription;

  String _vsYesterdayStr       = '—';
  bool   _vsYesterdayPositive  = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _usageSubscription = ref.listenManual<AsyncValue<List<AppUsageModel>>>(
      usageProvider,
      (_, next) {
        next.whenData((apps) {
          unawaited(HomeWidgetService.syncUsageSummary(apps));
        });
      },
    );
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _usageSubscription?.close();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(usageProvider);
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now         = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      ref.invalidate(usageProvider);
      _scheduleMidnightRefresh();
    });
  }

  Future<void> _calculateVsYesterday(int todayMinutes) async {
    final prefs    = await SharedPreferences.getInstance();
    final today    = DateTime.now();
    final dateKey  = '${today.year}-${today.month}-${today.day}';
    final lastDate = prefs.getString('last_saved_date');

    if (lastDate == dateKey) {
      final yest = prefs.getInt('yesterday_minutes') ?? todayMinutes;
      _setVs(todayMinutes, yest);
    } else {
      final last = prefs.getInt('last_saved_minutes');
      if (last != null) await prefs.setInt('yesterday_minutes', last);
      await prefs.setString('last_saved_date', dateKey);
      final yest = prefs.getInt('yesterday_minutes') ?? todayMinutes;
      _setVs(todayMinutes, yest);
    }
    await prefs.setInt('last_saved_minutes', todayMinutes);

    // Persist today's score for streak screen
    final score = ScoreCalculator.calculateRotScore(todayMinutes);
    await prefs.setInt(
        'score_${today.year}_${today.month}_${today.day}', score);
  }

  void _setVs(int today, int yesterday) {
    if (!mounted) return;
    final diff = today - yesterday;
    setState(() {
      _vsYesterdayPositive = diff >= 0;
      _vsYesterdayStr = diff == 0
          ? '±0'
          : '${diff >= 0 ? '+' : ''}${TimeFormatter.formatMinutesToHours(diff.abs())}';
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'good morning,';
    if (h < 17) return 'still scrolling?';
    if (h < 21) return 'put it down.';
    return 'go to sleep.';
  }

  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(usageProvider);
    final dateStr    = DateFormat('EEEE, d MMMM').format(DateTime.now()).toLowerCase();
    final isDark     = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color:       context.colors.purple,
          strokeWidth: 2.5,
          onRefresh: () async => ref.invalidate(usageProvider),
          child: usageAsync.when(
            loading: () => const HomeSkeletonLoader(),
            error:   (e, _) => _ErrorView(error: e.toString()),
            data:    (apps) {
              final totalMins  = apps.fold<int>(0, (s, a) => s + a.totalTimeInMinutes);
              final score      = ScoreCalculator.calculateRotScore(totalMins);
              final totalStr   = TimeFormatter.formatMinutesToHours(totalMins);
              final topApp     = apps.isNotEmpty ? apps.first.appName : 'none';

              _calculateVsYesterday(totalMins);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Top bar ───────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: GoogleFonts.poppins(
                                  color:      context.colors.textPrimary,
                                  fontSize:   22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: GoogleFonts.poppins(
                                  color:   context.colors.textTertiary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Theme toggle button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(themeProvider.notifier).toggleTheme();
                          },
                          child: Container(
                            width:  44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:  context.colors.surface,
                              shape:  BoxShape.circle,
                              border: Border.all(color: context.colors.border),
                              boxShadow: isDark ? null : [
                                BoxShadow(
                                  color: AppColors.cDarkest.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) => RotationTransition(
                                  turns: child.key == const ValueKey('moon') 
                                    ? Tween<double>(begin: 0.5, end: 1).animate(anim)
                                    : Tween<double>(begin: 0.5, end: 1).animate(anim),
                                  child: FadeTransition(opacity: anim, child: child),
                                ),
                                child: isDark
                                    ? const Icon(Icons.nightlight_round, key: ValueKey('moon'), size: 20, color: AppColors.cLight)
                                    : const Icon(Icons.wb_sunny_rounded, key: ValueKey('sun'), size: 20, color: AppColors.cPrimary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Streak button
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:        (_, __, ___) => const StreakScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 200),
                            ),
                          ),
                          child: Container(
                            width:  44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:  context.colors.surface,
                              shape:  BoxShape.circle,
                              border: Border.all(color: context.colors.border),
                              boxShadow: isDark ? null : [
                                BoxShadow(
                                  color: AppColors.cDarkest.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: const Center(
                              child: Text('📊', style: TextStyle(fontSize: 20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // ── Shame ring ────────────────────────────────────────
                    Center(
                      child: AnimatedRotRing(
                        score:       score,
                        totalTimeStr: totalStr,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Stats strip ───────────────────────────────────────
                    Row(
                      children: [
                        Expanded(child: _StatPill(label: 'today',       value: totalStr)),
                        const SizedBox(width: 10),
                        Expanded(child: _StatPill(label: 'top app',     value: topApp)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label:      'vs yesterday',
                            value:      _vsYesterdayStr,
                            valueColor: _vsYesterdayPositive
                                ? context.colors.red
                                : context.colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // ── Usage list ────────────────────────────────────────
                    UsageBarWidget(apps: apps),
                    const SizedBox(height: 40),

                    // ── Roast CTA ─────────────────────────────────────────
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder:   (_, child) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      ),
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            showModalBottomSheet(
                              context:           context,
                              isScrollControlled: true,
                              backgroundColor:   Colors.transparent,
                              builder:           (_) => const RoastBottomSheet(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            shadowColor: context.colors.purple.withAlpha(isDark ? 100 : 50),
                          ).copyWith(
                            // Glow via box decoration override via shadow
                            elevation: WidgetStateProperty.all(0),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:      context.colors.purple.withAlpha(isDark ? 100 : 50),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'roast me',
                                  style: GoogleFonts.poppins(
                                    color:      context.colors.bg,
                                    fontSize:   16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('🔥', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Stat pill card ───────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatPill({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color:        context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: context.colors.border),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: AppColors.cDarkest.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize:      9,
              fontWeight:    FontWeight.w600,
              letterSpacing: 1,
              color:         context.colors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:      valueColor ?? context.colors.textPrimary,
            ),
            textAlign:  TextAlign.center,
            maxLines:   1,
            overflow:   TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💀', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'something broke',
              style: GoogleFonts.poppins(
                color:      context.colors.textPrimary,
                fontSize:   20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.poppins(
                color:   context.colors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
