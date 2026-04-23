import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

/// Shimmer skeleton shown while usage data is loading.
class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:      context.colors.elevated,
      highlightColor: context.colors.border,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShimBox(width: 160, height: 24),
                _ShimBox(width: 40,  height: 40, radius: 20),
              ],
            ),
            const SizedBox(height: 8),
            _ShimBox(width: 120, height: 14),
            const SizedBox(height: 48),
            // Gauge
            const Center(child: _ShimBox(width: 200, height: 150, radius: 100)),
            const SizedBox(height: 48),
            // Stat pills
            Row(
              children: [
                Expanded(child: _ShimBox(height: 64)),
                const SizedBox(width: 12),
                Expanded(child: _ShimBox(height: 64)),
                const SizedBox(width: 12),
                Expanded(child: _ShimBox(height: 64)),
              ],
            ),
            const SizedBox(height: 40),
            _ShimBox(width: 180, height: 12),
            const SizedBox(height: 20),
            ...List.generate(5, (i) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _ShimBox(height: 60),
            )),
          ],
        ),
      ),
    );
  }
}

class _ShimBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _ShimBox({this.width, required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  width,
      height: height,
      decoration: BoxDecoration(
        color:        context.colors.elevated,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
