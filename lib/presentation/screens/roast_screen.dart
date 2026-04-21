import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/score_calculator.dart';
import '../../providers/roast_provider.dart';
import '../../providers/usage_provider.dart';
import '../widgets/app_bar_widget.dart';
import 'share_screen.dart';

class RoastScreen extends ConsumerWidget {
  const RoastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roastAsync = ref.watch(roastProvider);
    final usageAsync = ref.watch(usageProvider);

    return Scaffold(
      appBar: const PhoneShameAppBar(title: "AI Roast"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                   const Icon(Icons.psychology_alt, color: AppColors.lightPurple, size: 48),
                   const SizedBox(height: 16),
                   roastAsync.when(
                    data: (roast) => Text(
                      roast?.text ?? "Couldn't generate a roast. You got lucky today.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                    loading: () => Shimmer.fromColors(
                      baseColor: AppColors.accent,
                      highlightColor: AppColors.lightPurple,
                      child: Column(
                        children: [
                          Container(height: 16, width: double.infinity, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 16, width: double.infinity, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 16, width: 200, color: Colors.white),
                        ],
                      ),
                    ),
                    error: (e, st) => Text(
                      "Error: $e",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            usageAsync.when(
               data: (apps) {
                  final totalMins = apps.fold<int>(0, (s, a) => s + a.totalTimeInMinutes);
                  final alternatives = ScoreCalculator.getAlternatives(totalMins);
                  
                  if (alternatives.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Instead, you could have...",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...alternatives.map((alt) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.accent),
                            const SizedBox(width: 12),
                            Text(alt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )),
                    ],
                  );
               },
               loading: () => const SizedBox(),
               error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 48),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: roastAsync.isLoading 
                  ? null 
                  : () {
                      final apps = usageAsync.valueOrNull ?? [];
                      final String topApp = apps.isNotEmpty ? apps.first.appName : 'Unknown';
                      final totalTimeMins = apps.fold<int>(0, (s, a) => s + a.totalTimeInMinutes);
                      final score = ScoreCalculator.calculateShameScore(totalTimeMins);
                      final roastText = ref.read(roastProvider).valueOrNull?.text ?? '';
                      // take first sentence approx
                      final roastSnippet = roastText.split('.').first + '.';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShareScreen(
                            score: score,
                            topApp: topApp,
                            totalTimeStr: "${totalTimeMins ~/ 60}h ${totalTimeMins % 60}m",
                            roastSnippet: roastSnippet,
                          ),
                        ),
                      );
                    },
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text(
                  "Share My Shame",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
