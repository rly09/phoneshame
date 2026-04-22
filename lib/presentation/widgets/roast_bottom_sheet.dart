import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/score_calculator.dart';
import '../../providers/roast_provider.dart';
import '../../providers/usage_provider.dart';
import '../screens/share_screen.dart';

class RoastBottomSheet extends ConsumerStatefulWidget {
  const RoastBottomSheet({super.key});

  @override
  ConsumerState<RoastBottomSheet> createState() => _RoastBottomSheetState();
}

class _RoastBottomSheetState extends ConsumerState<RoastBottomSheet> {
  String _displayedText = "";
  Timer? _timer;
  int _charIndex = 0;
  String _fullText = "";

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTypewriter(String text) {
    if (_fullText == text) return;
    
    setState(() {
      _fullText = text;
      _displayedText = "";
      _charIndex = 0;
    });
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_charIndex < _fullText.length) {
        setState(() {
          _displayedText += _fullText[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roastAsync = ref.watch(roastProvider);
    final usageAsync = ref.watch(usageProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "your roast 🔥",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      child: roastAsync.when(
                        data: (roast) {
                          final text = roast?.text ?? "Couldn't generate a roast. You got lucky today.";
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _startTypewriter(text);
                          });
                          
                          return Text(
                            _displayedText,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          );
                        },
                        loading: () => Shimmer.fromColors(
                          baseColor: AppColors.accent,
                          highlightColor: AppColors.lightPurple,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 16, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 8)),
                              Container(height: 16, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 8)),
                              Container(height: 16, width: 200, color: Colors.white),
                            ],
                          ),
                        ),
                        error: (e, st) => Text(
                          "Error: $e",
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),
                    usageAsync.when(
                      data: (apps) {
                        final totalMins = apps.fold<int>(0, (s, a) => s + a.totalTimeInMinutes);
                        final alternatives = ScoreCalculator.getAlternatives(totalMins);
                        
                        if (alternatives.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "instead you could have...",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...alternatives.map((alt) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  const Text("💡", style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 16),
                                  Expanded(child: Text(alt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
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
                      child: ElevatedButton(
                        onPressed: roastAsync.isLoading 
                          ? null 
                          : () {
                              final apps = usageAsync.valueOrNull ?? [];
                              final String topApp = apps.isNotEmpty ? apps.first.appName : 'Unknown';
                              final totalTimeMins = apps.fold<int>(0, (s, a) => s + a.totalTimeInMinutes);
                              final score = ScoreCalculator.calculateShameScore(totalTimeMins);
                              final roastText = ref.read(roastProvider).valueOrNull?.text ?? '';
                              final roastSnippet = roastText.split('.').first + '.';

                              Navigator.pop(context); // Close bottom sheet
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "share my shame",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
