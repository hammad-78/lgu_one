import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lgu_one/auth/lgu_email_gate.dart';
import 'package:lgu_one/notification/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown with a message that is safe to show to the user.
class StudentAuthException implements Exception {
  final String message;
  const StudentAuthException(this.message);

  @override
  String toString() => message;
}

/// Google sign-in for students. Only LGU emails (`...lgu.edu.pk`) are accepted;
/// anything else is signed out again immediately.
class StudentAuthService {
  StudentAuthService._();
  static final StudentAuthService instance = StudentAuthService._();

  /// Web OAuth client (client_type 3 in google-services.json). Needed by
  /// google_sign_in on Android to obtain the ID token Firebase verifies.
  static const String _serverClientId =
      '100691841842-ftr4i05a7p6kkojfb19nibliqkbi4118.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<void>? _googleInit;

  bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// The signed-in student, or null. Admin accounts (email/password) are not
  /// students, so they are ignored here.
  User? get currentStudent {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    final email = user.email;
    if (email == null || !LguEmailGate.isValid(email)) return null;
    return user;
  }

  Future<void> _ensureGoogleInit() {
    return _googleInit ??= GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId,
    );
  }

  /// Signs in (or signs up, on first use) with Google. Returns the user.
  /// Returns null if the student dismissed the Google account picker.
  Future<User?> signInWithGoogle() async {
    if (!isSupported) {
      throw const StudentAuthException(
        'Google sign-in is not available on this platform yet.',
      );
    }

    try {
      final UserCredential credential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        credential = await _auth.signInWithPopup(provider);
      } else {
        await _ensureGoogleInit();
        final account = await GoogleSignIn.instance.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken == null) {
          throw const StudentAuthException(
            'Google did not return a sign-in token. Please try again.',
          );
        }
        credential = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }

      final user = credential.user;
      final email = user?.email;
      if (user == null || email == null || !LguEmailGate.isValid(email)) {
        await signOut();
        throw const StudentAuthException(
          'Only LGU email addresses ending in .lgu.edu.pk can sign in.',
        );
      }

      await _saveProfile(user, isNew: credential.additionalUserInfo?.isNewUser);

      // Lets Lost & Found and Collaboration open without asking again.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LguEmailGate.prefsKey, email);
      // So E-Society replies reach this phone.
      unawaited(NotificationService.linkTokenToUser(user.uid));
      return user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw StudentAuthException('Google sign-in failed (${e.code.name}).');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return null;
      }
      throw StudentAuthException(e.message ?? 'Sign-in failed (${e.code}).');
    }
  }

  Future<void> _saveProfile(User user, {bool? isNew}) async {
    final ref = _db.collection('users').doc(user.uid);
    final data = <String, dynamic>{
      'name': user.displayName ?? '',
      'email': user.email,
      'photoUrl': user.photoURL,
      'role': 'student',
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
    final existing = await ref.get();
    if (!existing.exists || isNew == true) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    // Keep a name the student has edited; Google's is only the default.
    final savedName = (existing.data()?['name'] ?? '').toString();
    if (savedName.isNotEmpty) data.remove('name');
    // Same for a photo the student uploaded themselves.
    if (existing.data()?['customPhoto'] == true) data.remove('photoUrl');
    await ref.set(data, SetOptions(merge: true));
  }

  /// Live profile document for the signed-in student.
  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream(String uid) =>
      _db.collection('users').doc(uid).snapshots();

  /// Saves the editable parts of the profile.
  Future<void> updateProfile(
    String uid, {
    required String name,
    required String degree,
    required int? semester,
    required String bio,
  }) {
    return _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'degree': degree.trim(),
      'semester': semester,
      'bio': bio.trim(),
      // Saving the profile counts as finishing first-time setup.
      'setupDone': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Marks first-time setup as done without saving any details (Skip).
  Future<void> skipSetup(String uid) {
    return _db.collection('users').doc(uid).set({
      'setupDone': true,
    }, SetOptions(merge: true));
  }

  /// True when a student has not finished or skipped first-time setup.
  /// Profiles from before setup existed count as done if they have details.
  static bool needsSetup(Map<String, dynamic> data) {
    if (data['setupDone'] == true) return false;
    final hasDegree = (data['degree'] ?? '').toString().trim().isNotEmpty;
    return !hasDegree && data['semester'] == null;
  }

  /// Uploads a new profile photo and stores its URL on the profile.
  /// Returns the download URL.
  Future<String> uploadProfilePhoto(String uid, Uint8List bytes) async {
    final ref = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    // Same path on every upload, so mark the version to avoid a stale cache.
    final url =
        '${await ref.getDownloadURL()}&v=${DateTime.now().millisecondsSinceEpoch}';
    await _db.collection('users').doc(uid).set({
      'photoUrl': url,
      'customPhoto': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  /// Deletes the uploaded photo from Storage, then clears it from the profile.
  /// `customPhoto` stays true so the next Google sign-in does not bring the
  /// Google photo back. Throws if Storage refuses the delete, so the profile
  /// never points at "no photo" while the file still exists.
  Future<void> removeProfilePhoto(String uid) async {
    try {
      await FirebaseStorage.instance.ref('profile_photos/$uid.jpg').delete();
    } on FirebaseException catch (e) {
      // Nothing uploaded (the photo was the Google one): nothing to delete.
      if (e.code != 'object-not-found') {
        debugPrint('Profile photo delete error: ${e.code} ${e.message}');
        rethrow;
      }
    }
    await _db.collection('users').doc(uid).set({
      'photoUrl': null,
      'customPhoto': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    // Stop personal notifications on this device before the session ends.
    if (_auth.currentUser != null) {
      await NotificationService.linkTokenToUser(null);
    }
    try {
      if (!kIsWeb && isSupported) {
        await _ensureGoogleInit();
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
    await LguEmailGate.clear();
  }
}
