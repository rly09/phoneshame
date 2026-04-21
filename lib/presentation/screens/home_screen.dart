import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/score_calculator.dart';
import '../../core/utils/time_formatter.dart';
import '../../providers/usage_provider.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/shame_score_widget.dart';
import '../widgets/usage_bar_widget.dart';
import 'roast_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(usageProvider);

    return Scaffold(
      appBar: const PhoneShameAppBar(title: "PhoneShame"),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(usageProvider);
        },
        child: usageAsync.when(
          data: (apps) {
            final totalMinutes = apps.fold<int>(0, (sum, item) => sum + item.totalTimeInMinutes);
            final score = ScoreCalculator.calculateShameScore(totalMinutes);
            final totalTimeStr = TimeFormatter.formatMinutesToHours(totalMinutes);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShameScoreWidget(
                    score: score,
                    totalTimeStr: totalTimeStr,
                  ),
                  const SizedBox(height: 40),
                  UsageBarWidget(apps: apps),
                  const SizedBox(height: 48),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RoastScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Roast Me",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text("Error: $err")),
        ),
      ),
    );
  }
}
