import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Loading shimmer skeleton for skill cards.
class SkillCardSkeleton extends StatelessWidget {
  const SkillCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: double.infinity, height: 16),
                  SizedBox(height: 8),
                  _ShimmerBox(width: 120, height: 12),
                  SizedBox(height: 8),
                  _ShimmerBox(width: 80, height: 12),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _ShimmerBox(width: 24, height: 24, circle: true),
                      SizedBox(width: 8),
                      _ShimmerBox(width: 80, height: 12),
                    ],
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

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.circle = false,
  });

  final double width;
  final double height;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(circle ? height / 2 : 4),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}

/// A grid of shimmer skeletons for loading states.
class SkillListSkeleton extends StatelessWidget {
  const SkillListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const SkillCardSkeleton(),
    );
  }
}
