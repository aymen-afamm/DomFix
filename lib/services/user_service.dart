import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Handles all Firestore operations for the `users` collection.
/// Firebase is the single source of truth for user data.
class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'users';

  // ─── Create ───────────────────────────────────────────────────────────────

  /// Creates a new user document in Firestore after registration.
  /// Does NOT overwrite if the document already exists (safe for Google sign-in).
  static Future<void> createUserIfNotExists(String uid, String email) async {
    try {
      final docRef = _db.collection(_collection).doc(uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        await docRef.set({
          'uid': uid,
          'email': email,
          'role': null,
          'onboarding_done': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[UserService] createUserIfNotExists error: $e');
      rethrow;
    }
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Fetches user data from Firestore.
  /// Returns null if the document does not exist.
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final snapshot = await _db.collection(_collection).doc(uid).get();
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint('[UserService] getUserData error: $e');
      return null;
    }
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  /// Saves the selected role to Firestore.
  static Future<void> updateRole(String uid, String role) async {
    try {
      await _db.collection(_collection).doc(uid).update({'role': role});
    } catch (e) {
      debugPrint('[UserService] updateRole error: $e');
      rethrow;
    }
  }

  /// Marks onboarding as complete/incomplete in Firestore.
  static Future<void> updateOnboardingDone(String uid, bool done) async {
    try {
      await _db
          .collection(_collection)
          .doc(uid)
          .update({'onboarding_done': done});
    } catch (e) {
      debugPrint('[UserService] updateOnboardingDone error: $e');
      rethrow;
    }
  }
}
