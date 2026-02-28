import 'package:flutter/material.dart';

/// Category row with icon, name, progress bar, amount, and percentage.
class CategoryProgressItem extends StatelessWidget {
  const CategoryProgressItem({
    super.key,
    required this.icon,
    required this.name,
    required this.progressValue,
    required this.progressColor,
    required this.amountLabel,
    required this.percentLabel,
    this.subtitleLabel,
    this.amountColor,
    this.onTap,
  });

  final IconData icon;
  final String name;
  final double progressValue; // 0.0 – 1.0+
  final Color progressColor;
  final String amountLabel;
  final String percentLabel;
  final String? subtitleLabel;
  final Color? amountColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              _CategoryIcon(icon: icon, colors: colors),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: text.titleSmall),
                    if (subtitleLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleLabel!,
                        style: text.bodySmall?.copyWith(
                          color: progressValue > 1.0
                              ? colors.error
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountLabel,
                    style: text.titleSmall?.copyWith(
                      color: amountColor ?? colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    percentLabel,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colors.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.icon, required this.colors});

  final IconData icon;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: colors.onSurfaceVariant, size: 22),
    );
  }
}
