import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'home_screen_content.dart';
import 'ai_chat_screen_content.dart';
import 'find_pros_screen_content.dart';
import 'control_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialPage;
  
  const MainScreen({super.key, this.initialPage = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isAnimating = false;

  final List<Widget> _screens = const [
    HomeScreenContent(),
    AIChatScreenContent(),
    FindProsScreenContent(),
    ControlScreen(),
    SettingsScreen(),
  ];

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'HOME'),
    NavItem(icon: Icons.psychology_outlined, activeIcon: Icons.psychology, label: 'AI CHAT'),
    NavItem(icon: Icons.engineering_outlined, activeIcon: Icons.engineering, label: 'PROS'),
    NavItem(icon: Icons.settings_remote_outlined, activeIcon: Icons.settings_remote, label: 'CONTROL'),
    NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'SETTINGS'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _onNavItemTapped(int index) {
    if (_currentIndex != index && !_isAnimating) {
      HapticFeedback.lightImpact();
      setState(() {
        _isAnimating = true;
      });
      
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _navItems.length,
          (index) => Expanded(
            child: _buildNavItem(index),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
