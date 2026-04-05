import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'home_screen_content.dart';
import 'ai_chat_screen_content.dart';
import 'find_pros_screen_content.dart';
import 'control_screen.dart';
import 'settings_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreenContent(),
    AIChatScreenContent(),
    FindProsScreenContent(),
    ControlScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      HapticFeedback.lightImpact();
    }
  }

  void _onNavItemTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, Icons.home, 'HOME', 0),
          _buildNavItem(Icons.psychology_outlined, Icons.psychology, 'AI CHAT', 1),
          _buildNavItem(Icons.engineering_outlined, Icons.engineering, 'PROS', 2),
          _buildNavItem(Icons.settings_remote_outlined, Icons.settings_remote, 'CONTROL', 3),
          _buildNavItem(Icons.settings_outlined, Icons.settings, 'SETTINGS', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
