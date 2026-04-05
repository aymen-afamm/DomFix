import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/client_home_screen.dart';
import '../screens/technician_home_screen.dart';
import '../screens/onboarding/technician_onboarding_flow.dart';
import '../theme/app_colors.dart';
import 'preferences_service.dart';

class NavigationService {
  static Future<void> navigateBasedOnRole(BuildContext context) async {
    final userRole = await PreferencesService.getUserRole();
    final onboardingCompleted = await PreferencesService.isOnboardingCompleted();

    if (!context.mounted) return;

    if (userRole == null || userRole.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    } else if (userRole == 'client') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
      );
    } else if (userRole == 'technician') {
      if (!onboardingCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: AppColors.background,
              body: TechnicianOnboardingFlow(
                onComplete: (data) async {
                  await PreferencesService.setOnboardingCompleted(true);
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const TechnicianHomeScreen()),
                  );
                },
              ),
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TechnicianHomeScreen()),
        );
      }
    }
  }

  static Future<void> logout(BuildContext context) async {
    if (!context.mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
