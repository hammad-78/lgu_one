import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Gemini runs in a separate, billing-free Firebase project (lgu-one-ai) so
/// it stays on the Gemini Developer API free tier. The main project is on
/// Blaze, which would put Gemini on the paid, prepaid-credit tier.
class AiFirebase {
  AiFirebase._();

  static const _name = 'gemini-ai';

  static const _android = FirebaseOptions(
    apiKey: 'AIzaSyB2kYHSP848ZCVeNSlSNF1e0RMjSA7LDzk',
    appId: '1:293340814827:android:01897b2fc094b4d3ef4dae',
    messagingSenderId: '293340814827',
    projectId: 'lgu-one-ai',
    storageBucket: 'lgu-one-ai.firebasestorage.app',
  );

  static Future<FirebaseApp>? _app;

  /// The Firebase app for the AI project, with App Check active. Firebase
  /// requires App Check for AI Logic: debug builds use a debug token (added
  /// under App Check > Apps > Manage debug tokens in lgu-one-ai), Play Store
  /// builds use Play Integrity.
  static Future<FirebaseApp> get app => _app ??= _init();

  static Future<FirebaseApp> _init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('AI import is only set up for Android.');
    }
    final app = Firebase.apps.any((a) => a.name == _name)
        ? Firebase.app(_name)
        : await Firebase.initializeApp(name: _name, options: _android);
    await FirebaseAppCheck.instanceFor(app: app).activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
    return app;
  }
}
