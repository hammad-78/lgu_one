import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/admin/admin_session.dart';
import 'package:lgu_one/admin/share_import/share_import_screen.dart';
import 'package:lgu_one/utils/utils.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Root navigator, so shares can open screens from anywhere in the app.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Receives posts shared into the app from WhatsApp (or any app) on Android
/// and, for a signed-in admin, turns them into a news or job draft.
class ShareIntake {
  ShareIntake._();

  static List<SharedMediaFile>? _pending;
  static bool _ready = false;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Call once at startup. A share that launched the app is held until
  /// [markReady] (the splash screen has finished).
  static Future<void> start() async {
    if (!_supported) return;
    try {
      ReceiveSharingIntent.instance.getMediaStream().listen(
        _receive,
        onError: (e) => debugPrint('Share stream error: $e'),
      );
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initial.isNotEmpty) _receive(initial);
    } catch (e) {
      debugPrint('Share intake unavailable: $e');
    }
  }

  /// Called once the first real screen is showing.
  static void markReady() {
    _ready = true;
    final pending = _pending;
    _pending = null;
    if (pending != null) _handle(pending);
  }

  static void _receive(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    ReceiveSharingIntent.instance.reset();
    if (_ready) {
      _handle(files);
    } else {
      _pending = files;
    }
  }

  static Future<void> _handle(List<SharedMediaFile> files) async {
    final texts = <String>[];
    File? image;
    for (final f in files) {
      switch (f.type) {
        case SharedMediaType.text:
        case SharedMediaType.url:
          texts.add(f.path);
        case SharedMediaType.image:
          image ??= File(f.path);
          if (f.message?.trim().isNotEmpty ?? false) texts.add(f.message!);
        default:
          if (f.message?.trim().isNotEmpty ?? false) texts.add(f.message!);
      }
    }
    final text = texts.join('\n\n').trim();
    if (text.isEmpty && image == null) return;

    if (!await AdminSession.isAdminSignedIn()) {
      Utils().toastMessage('Sign in as admin to post shared news or jobs.');
      return;
    }

    appNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) =>
            ShareImportScreen(text: text.isEmpty ? null : text, image: image),
      ),
    );
  }
}
