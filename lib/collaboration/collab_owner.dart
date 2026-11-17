import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/auth/student_auth_service.dart';
import 'package:lgu_one/utils/flushbar.dart';

/// Who owns a collaboration post.
///
/// Posts made since student sign-in carry `info.ownerUid` and can only be
/// changed by that student (or an admin). Older posts have no owner and are
/// still unlocked with the secret key they were created with.
class CollabOwner {
  CollabOwner._();

  static String? ownerUid(Map<String, dynamic> info) {
    final uid = info['ownerUid'];
    return uid is String && uid.isNotEmpty ? uid : null;
  }

  /// A post from before owners existed.
  static bool isLegacy(Map<String, dynamic> info) => ownerUid(info) == null;

  /// True when the signed-in student owns [info].
  static bool isMine(Map<String, dynamic> info) {
    final uid = ownerUid(info);
    return uid != null &&
        uid == StudentAuthService.instance.currentStudent?.uid;
  }

  /// The signed-in student, asking them to sign in with their LGU Google
  /// account first if needed. Returns null if they don't.
  static Future<User?> requireStudent(BuildContext context) async {
    final auth = StudentAuthService.instance;
    final current = auth.currentStudent;
    if (current != null) return current;

    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign in to post'),
        content: const Text(
          'Posts are tied to your LGU Google account, so only you can edit '
          'or delete them. No secret key needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign in with Google'),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return null;

    try {
      // Null when the student closed the account picker.
      await auth.signInWithGoogle();
    } catch (e) {
      if (context.mounted) {
        await showFlushbar(
          context,
          e is StudentAuthException
              ? e.message
              : 'Could not sign in. Try again.',
          color: Colors.red.shade900,
        );
      }
      return null;
    }
    return auth.currentStudent;
  }
}
