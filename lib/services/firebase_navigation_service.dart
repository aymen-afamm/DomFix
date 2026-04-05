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

  /// Single entry: Firebase session + Firestore `users/{uid}`.
  static Future<void> navigateBasedOnAuth(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (!context.mounted) return;

    if (user == null) {
      await LocalStorageService.clearAll();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      final userData = await _userService.getUserData(user.uid);

      if (!context.mounted) return;

      if (userData == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
        return;
      }

      final role = UserService.parseRole(userData);
      final onboardingDone = UserService.parseOnboardingCompleted(userData);

      await LocalStorageService.setLoggedIn(true);

      if (!context.mounted) return;

      if (role == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
        return;
      }

      if (role == 'client') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
        );
        return;
      }

      if (role == 'technician') {
        if (!onboardingDone) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (routeContext) => Scaffold(
                backgroundColor: AppColors.background,
                body: TechnicianOnboardingFlow(
                  onComplete: (data) async {
                    await _onTechnicianOnboardingComplete(
                      routeContext,
                      user.uid,
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
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    } catch (e, st) {
      debugPrint('navigateBasedOnAuth error: $e\n$st');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load your profile. Check connection and try again.'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  static Future<void> _onTechnicianOnboardingComplete(
    BuildContext routeContext,
    String uid,
  ) async {
    try {
      await _userService.updateOnboardingStatus(uid, true);
    } catch (e, st) {
      debugPrint('Onboarding Firestore update failed: $e\n$st');
      if (routeContext.mounted) {
        ScaffoldMessenger.of(routeContext).showSnackBar(
          SnackBar(
            content: Text('Could not save onboarding: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      return;
    }

    if (!routeContext.mounted) return;

    Navigator.of(routeContext, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TechnicianHomeScreen()),
      (route) => false,
    );
  }

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
