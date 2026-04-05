import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';
import '../services/navigation_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  final _authService = AuthService();
  
  @override
  bool get wantKeepAlive => true;

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHighest,
        title: Text(
          'Logout',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.signOut();
      await PreferencesService.logout();
      if (mounted) {
        await NavigationService.logout(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETTINGS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Settings',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 30),
              _buildSettingItem(
                icon: Icons.person_outline,
                title: 'Profile',
                onTap: () {},
              ),
              _buildSettingItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {},
              ),
              _buildSettingItem(
                icon: Icons.security_outlined,
                title: 'Privacy & Security',
                onTap: () {},
              ),
              _buildSettingItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryContainer, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
