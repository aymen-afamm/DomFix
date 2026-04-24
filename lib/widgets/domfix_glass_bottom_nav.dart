import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class DomfixGlassBottomNav extends StatelessWidget {
  const DomfixGlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadMessages = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadMessages;

  static const double barTopRadius = 0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    final destinations = [
      DomfixNavDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Home',
      ),
      DomfixNavDestination(
        icon: Icons.chat_bubble_outline_rounded,
        selectedIcon: Icons.chat_bubble_rounded,
        label: 'Messages',
        badgeCount: unreadMessages,
      ),
      DomfixNavDestination(
        icon: Icons.search_rounded,
        selectedIcon: Icons.search_rounded,
        label: 'Find Pro',
      ),
      DomfixNavDestination(
        icon: Icons.devices_other_outlined,
        selectedIcon: Icons.devices_other_rounded,
        label: 'Control',
      ),
      DomfixNavDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: 'Settings',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            8,
            8,
            8,
            bottom > 0 ? 0 : 8,
          ),
          child: Row(
            children: List.generate(
              destinations.length,
              (i) => Expanded(
                child: _NavTab(
                  data: destinations[i],
                  selected: currentIndex == i,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(i);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DomfixNavDestination {
  const DomfixNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final DomfixNavDestination data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.neonAccent
        : AppColors.onSurfaceVariant.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? data.selectedIcon : data.icon,
                  color: color,
                  size: 22,
                ),
                if (data.badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '${data.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
