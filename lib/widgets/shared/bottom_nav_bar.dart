import 'package:flutter/material.dart';

/// Reusable bottom navigation bar with configurable tabs and optional center FAB.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.showCenterFab = false,
    this.onFabTap,
  });

  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showCenterFab;
  final VoidCallback? onFabTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: colors.outline, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 8,
            left: 16,
            right: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildItems(colors, theme.textTheme),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItems(ColorScheme colors, TextTheme text) {
    final widgets = <Widget>[];
    final midIndex = items.length ~/ 2;

    for (var i = 0; i < items.length; i++) {
      if (showCenterFab && i == midIndex) {
        widgets.add(
          SizedBox(
            width: 64,
            child: onFabTap != null
                ? _CenterFab(onTap: onFabTap!, color: colors.primary)
                : const SizedBox.shrink(),
          ),
        );
      }

      final isActive = i == currentIndex;
      widgets.add(
        Expanded(
          child: _NavItem(
            icon: isActive
                ? (items[i].filledIcon ?? items[i].icon)
                : items[i].icon,
            label: items[i].label,
            isActive: isActive,
            activeColor: colors.primary,
            inactiveColor: colors.onSurfaceVariant,
            onTap: () => onTap(i),
          ),
        ),
      );
    }

    return widgets;
  }
}

class BottomNavItem {
  const BottomNavItem({
    required this.icon,
    required this.label,
    this.filledIcon,
  });

  final IconData icon;
  final String label;
  final IconData? filledIcon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.onTap, required this.color});

  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 32,
          ),
        ),
      ),
    );
  }
}
