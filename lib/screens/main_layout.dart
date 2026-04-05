import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/domfix_glass_bottom_nav.dart';
import 'ai_chat_screen_content.dart';
import 'control_screen.dart';
import 'find_pros_screen_content.dart';
import 'home_screen_content.dart';
import 'settings_screen.dart';

/// Exposes tab switching to descendants (e.g. home shortcuts) without pushing routes.
class MainLayoutScope extends InheritedWidget {
  const MainLayoutScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final ValueChanged<int> selectTab;

  static MainLayoutScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<MainLayoutScope>();
  }

  @override
  bool updateShouldNotify(MainLayoutScope oldWidget) => false;
}

/// Single app shell: persistent glass bottom nav + tab bodies with preserved state.
class MainLayout extends StatefulWidget {
  const MainLayout({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _tabAnimating = false;

  static const List<Widget> _tabBodies = [
    HomeScreenContent(),
    AIChatScreenContent(),
    FindProsScreenContent(),
    ControlScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex.clamp(0, _tabBodies.length - 1);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: 1,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _onTabSelected(int index) async {
    if (index == _currentIndex || _tabAnimating) return;
    _tabAnimating = true;
    try {
      await _fadeController.animateTo(0, curve: Curves.easeInOut);
      if (!mounted) return;
      setState(() => _currentIndex = index);
      await _fadeController.animateTo(1, curve: Curves.easeInOut);
    } finally {
      if (mounted) _tabAnimating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayoutScope(
      selectTab: _onTabSelected,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: IndexedStack(
            index: _currentIndex,
            sizing: StackFit.expand,
            children: _tabBodies,
          ),
        ),
        bottomNavigationBar: DomfixGlassBottomNav(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}
