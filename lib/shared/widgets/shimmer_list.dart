import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading placeholder for list items.
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1B26),
      highlightColor: const Color(0xFF252736),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B26),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
