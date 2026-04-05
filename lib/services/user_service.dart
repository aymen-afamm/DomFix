import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Create user document in Firestore
  Future<void> createUser({
    required String uid,
    required String email,
    required String role,
    bool onboardingDone = false,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).set({
        'uid': uid,
        'email': email,
        'role': role,
        'onboarding_done': onboardingDone,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      rethrow;
    }
  }

  // Update user role
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'role': role,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    }
  }

  // Update onboarding status
  Future<void> updateOnboardingStatus(String uid, bool done) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'onboarding_done': done,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating onboarding status: $e');
      rethrow;
    }
  }

  // Check if user document exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return false;
    }
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?['role'] as String?;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  // Get onboarding status
  Future<bool> getOnboardingStatus(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?['onboarding_done'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error getting onboarding status: $e');
      return false;
    }
  }

  // Delete user data (for logout/account deletion)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }
}
