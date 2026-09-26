import 'package:flutter/material.dart';

import 'package:mongez/core/widgets/unread_badge.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> elements;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.elements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: elements.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final selected = currentIndex == i;
              return Expanded(
                child: _NavButton(
                  item: item,
                  selected: selected,
                  onTap: () => onTap(i),
                  selectedColor: cs.primary,
                  unselectedColor: cs.onSurface.withValues(alpha: 0.55),
                  pillColor: cs.primaryContainer,
                  textTheme: tt,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final Color pillColor;
  final TextTheme textTheme;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    required this.pillColor,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? pillColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      item.iconPath,
                      width: 22,
                      height: 22,
                      color: selected ? selectedColor : unselectedColor,
                    ),
                  ),
                  // Anchored to the pill's top-end so the dot reads as part
                  // of the icon; `end` keeps it on the correct side in RTL.
                  PositionedDirectional(
                    top: -2,
                    end: -4,
                    child: UnreadBadge(
                      count: item.badgeCount,
                      semanticsLabel: item.badgeSemanticsLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? selectedColor : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final String label;
  final String iconPath;

  /// Unread count rendered as an overlay badge — 0 hides it.
  final int badgeCount;

  /// What screen readers announce instead of the bare number.
  final String? badgeSemanticsLabel;

  const NavItem({
    required this.label,
    required this.iconPath,
    this.badgeCount = 0,
    this.badgeSemanticsLabel,
  });
}
