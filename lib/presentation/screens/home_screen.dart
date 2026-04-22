import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/score_calculator.dart';
import '../../core/utils/time_formatter.dart';
import '../../providers/usage_provider.dart';
import '../widgets/animated_shame_ring.dart';
import '../widgets/roast_bottom_sheet.dart';
import '../widgets/usage_bar_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  String _vsYesterdayStr = "calculating...";
  bool _vsYesterdayIsPositive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _calculateVsYesterday(int todayTotalMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateString = "${today.year}-${today.month}-${today.day}";
    
    final lastSavedDate = prefs.getString('last_saved_date');
    final lastSavedMinutes = prefs.getInt('last_saved_minutes');

    if (lastSavedDate == dateString) {
      // Already saved today, just compare with yesterday's stored value
      final yesterdayMinutes = prefs.getInt('yesterday_minutes') ?? todayTotalMinutes;
      _updateVsYesterdayState(todayTotalMinutes, yesterdayMinutes);
    } else {
      // It's a new day! Shift today's data to yesterday.
      if (lastSavedMinutes != null) {
        await prefs.setInt('yesterday_minutes', lastSavedMinutes);
      }
      await prefs.setString('last_saved_date', dateString);
      final yesterdayMinutes = prefs.getInt('yesterday_minutes') ?? todayTotalMinutes;
      _updateVsYesterdayState(todayTotalMinutes, yesterdayMinutes);
    }
    
    // Always keep today's rolling total updated
    await prefs.setInt('last_saved_minutes', todayTotalMinutes);
  }

  void _updateVsYesterdayState(int todayMinutes, int yesterdayMinutes) {
    if (!mounted) return;
    final diff = todayMinutes - yesterdayMinutes;
    final isPositive = diff >= 0;
    final absDiff = diff.abs();
    
    setState(() {
      _vsYesterdayIsPositive = isPositive;
      _vsYesterdayStr = "${isPositive ? '+' : '-'}${TimeFormatter.formatMinutesToHours(absDiff)}";
    });
  }

  @override
  Widget build(BuildContext context) {
    final usageAsync = ref.watch(usageProvider);
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now()).toLowerCase();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(usageProvider);
          },
          child: usageAsync.when(
            data: (apps) {
              final totalMinutes = apps.fold<int>(0, (sum, item) => sum + item.totalTimeInMinutes);
              final score = ScoreCalculator.calculateShameScore(totalMinutes);
              final totalTimeStr = TimeFormatter.formatMinutesToHours(totalMinutes);
              final topApp = apps.isNotEmpty ? apps.first.appName : 'None';
              
              _calculateVsYesterday(totalMinutes);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "phoneshame",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {
                            // Settings not implemented
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(150),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Shame Score Ring
                    AnimatedShameRing(
                      score: score,
                      totalTimeStr: totalTimeStr,
                    ),
                    const SizedBox(height: 48),
                    
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: "total time",
                            value: totalTimeStr,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: "most used",
                            value: topApp,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: "vs yesterday",
                            value: _vsYesterdayStr,
                            valueColor: _vsYesterdayIsPositive ? AppColors.red : AppColors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    
                    // Usage List
                    UsageBarWidget(apps: apps),
                    const SizedBox(height: 48),
                    
                    // Roast Button
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const RoastBottomSheet(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.primary.withAlpha(100),
                          ),
                          child: const Text(
                            "roast me 🔥",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error: $err")),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _StatCard({required this.title, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(150),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
