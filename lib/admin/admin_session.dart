import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Admin sessions persist through Firebase Auth until the admin logs out.
/// This checks whether the restored session belongs to an admin.
class AdminSession {
  AdminSession._();

  /// True when an admin account is signed in on this device.
  /// Waits for Firebase to restore a saved session on app start.
  static Future<bool> isAdminSignedIn() async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ??
          await auth
              .authStateChanges()
              .first
              .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (user == null || user.isAnonymous) return false;

      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      if (!doc.exists) return false;
      return isAdminData(doc.data());
    } catch (_) {
      return false;
    }
  }

  /// Handles bool, string, and role-style admin flags.
  static bool isAdminData(Map<String, dynamic>? data) =>
      data?['isAdmin'] == true ||
      data?['isAdmin']?.toString().toLowerCase() == 'true' ||
      data?['role']?.toString().toLowerCase() == 'admin';
}
