import 'dart:ui';
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

  static const double barTopRadius = 16;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    final destinations = [
      DomfixNavDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      DomfixNavDestination(
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        label: 'Messages',
        badgeCount: unreadMessages,
      ),
      DomfixNavDestination(
        icon: Icons.engineering_outlined,
        selectedIcon: Icons.engineering,
        label: 'Pros',
      ),
      DomfixNavDestination(
        icon: Icons.wb_incandescent_outlined,
        selectedIcon: Icons.wb_incandescent,
        label: 'Control',
      ),
      DomfixNavDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Settings',
      ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(barTopRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101419).withOpacity(0.65),
            border: Border(
              top: BorderSide(
                color: AppColors.neonAccent.withOpacity(0.08),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonAccent.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                bottom > 0 ? bottom : 18,
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

class _NavTab extends StatefulWidget {
  const _NavTab({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final DomfixNavDestination data;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  bool _pressed = false;

  static const inactive = Color(0xFFE0E2EA);

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    final color = selected
        ? AppColors.neonAccent
        : inactive.withOpacity(0.5);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? AppColors.neonAccent.withOpacity(0.1)
                : Colors.transparent,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.neonAccent.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected
                        ? widget.data.selectedIcon
                        : widget.data.icon,
                    color: color,
                    size: 22,
                  ),

                  if (widget.data.badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '${widget.data.badgeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 3),

              Text(
                widget.data.label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
