import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Helpers for generating and hashing the secret codes used to gate
/// edit/delete access on Lost & Found listings.
///
/// The plain code is shown to the user exactly once, right after they
/// post an item. Only [hash] of it is ever written to Firestore — there
/// is no way to recover a lost code, by design.
class SecretKeyUtil {
  SecretKeyUtil._();

  // Excludes 0/O and 1/I so codes are easy to read and re-type correctly.
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();

  /// Generates a readable 8-character code, e.g. "K7F2QXTM".
  /// 33^8 (~1.4 trillion combinations) makes brute-forcing impractical.
  static String generate() {
    return List.generate(8, (_) => _chars[_random.nextInt(_chars.length)])
        .join();
  }

  /// One-way SHA-256 hash of the code. Trims and uppercases first so a
  /// stray space or lowercase letter at entry time doesn't fail a
  /// legitimate match.
  static String hash(String key) {
    final normalized = key.trim().toUpperCase();
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }
}