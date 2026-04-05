import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/client_home_screen.dart';
import '../screens/technician_home_screen.dart';
import '../screens/onboarding/technician_onboarding_flow.dart';
import '../theme/app_colors.dart';
import 'user_service.dart';
import 'local_storage_service.dart';

class NavigationService {
  static final UserService _userService = UserService();

  // Navigate based on Firebase authentication and Firestore data
  static Future<void> navigateBasedOnAuth(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (!context.mounted) return;

    // Not logged in - go to login
    if (user == null) {
      await LocalStorageService.clearAll();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // User is logged in - fetch data from Firestore
    try {
      final userData = await _userService.getUserData(user.uid);

      if (!context.mounted) return;

      // User document doesn't exist - need to select role
      if (userData == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
        return;
      }

      // Get role and onboarding status from Firestore
      final role = userData['role'] as String?;
      final onboardingDone = userData['onboarding_done'] as bool? ?? false;

      // Save to local storage for quick access
      if (role != null) {
        await LocalStorageService.saveUserSession(
          role: role,
          onboardingDone: onboardingDone,
        );
      }

      if (!context.mounted) return;

      // Navigate based on role
      if (role == null || role.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      } else if (role == 'client') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
        );
      } else if (role == 'technician') {
        if (!onboardingDone) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: AppColors.background,
                body: TechnicianOnboardingFlow(
                  onComplete: (data) async {
                    // Update Firestore
                    await _userService.updateOnboardingStatus(user.uid, true);
                    // Update local storage
                    await LocalStorageService.setOnboardingDone(true);
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
    } catch (e) {
      debugPrint('Error navigating based on auth: $e');
      if (!context.mounted) return;
      // On error, go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // Logout
  static Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await LocalStorageService.clearAll();
    
    if (!context.mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
