import 'package:flutter/material.dart';

/// Circular icon button used in screen headers (close, back, calendar, menu, add).
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? colors.primary,
          size: size * 0.55,
          semanticLabel: icon.toString(),
        ),
      ),
    );
  }
}
