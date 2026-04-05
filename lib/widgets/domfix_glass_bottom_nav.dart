import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Bottom navigation matching design: frosted bar, neon accent, rounded top, glow on active.
class DomfixGlassBottomNav extends StatelessWidget {
  const DomfixGlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double barTopRadius = 12;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final destinations = _destinations;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(barTopRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF101419).withValues(alpha: 0.6),
            border: Border(
              top: BorderSide(
                color: AppColors.neonAccent.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonAccent.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom > 0 ? bottom : 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

List<DomfixNavDestination> get _destinations => const [
      DomfixNavDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      DomfixNavDestination(
        icon: Icons.psychology_outlined,
        selectedIcon: Icons.psychology,
        label: 'AI Chat',
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

class _NavTabState extends State<_NavTab> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  static const _inactive = Color(0xFFE0E2EA);
  static const _inactiveOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final iconColor = selected
        ? AppColors.neonAccent
        : _inactive.withValues(alpha: _inactiveOpacity);
    final textColor = selected
        ? AppColors.neonAccent
        : _inactive.withValues(alpha: _inactiveOpacity);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.neonAccent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.neonAccent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppColors.neonAccent.withValues(alpha: 0.12),
                      blurRadius: 8,
                      spreadRadius: -2,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? widget.data.selectedIcon : widget.data.icon,
                size: 22,
                color: iconColor,
              ),
              const SizedBox(height: 2),
              Text(
                widget.data.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
