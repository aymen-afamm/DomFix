import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'settings_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TechnicianDashboard(),
    TechnicianJobsScreen(),
    TechnicianProfileScreen(),
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
          _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'DASHBOARD', 0),
          _buildNavItem(Icons.work_outline, Icons.work, 'JOBS', 1),
          _buildNavItem(Icons.person_outline, Icons.person, 'PROFILE', 2),
          _buildNavItem(Icons.settings_outlined, Icons.settings, 'SETTINGS', 3),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class TechnicianDashboard extends StatelessWidget {
  const TechnicianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildStatsCards(),
            const SizedBox(height: 30),
            _buildActiveJobsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TECHNICIAN DASHBOARD',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome Back',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Active Jobs', '3', Icons.work_outline)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Completed', '47', Icons.check_circle_outline)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryContainer, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVE JOBS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        _buildJobCard('AC Repair', 'Downtown', '\$120'),
        const SizedBox(height: 12),
        _buildJobCard('Plumbing Fix', 'Uptown', '\$85'),
      ],
    );
  }

  Widget _buildJobCard(String title, String location, String price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.build_outlined, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  location,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class TechnicianJobsScreen extends StatelessWidget {
  const TechnicianJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Jobs',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Text(
                  'No new jobs available',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TechnicianProfileScreen extends StatelessWidget {
  const TechnicianProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Profile',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Professional Technician',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
