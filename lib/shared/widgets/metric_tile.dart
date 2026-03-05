import 'package:flutter/material.dart';
import 'package:easy_film/app/theme/app_theme.dart';

/// A compact metric card for dashboards.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: iconColor ?? colors.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
