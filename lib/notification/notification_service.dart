import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lgu_one/auth/lgu_email_gate.dart';
import 'package:lgu_one/ventures/ventures_screen.dart';
import 'package:lgu_one/esociety/esociety_portal_signin.dart';
import 'package:lgu_one/Lost_Found/listing_screen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

class NotificationService {
  static const _esocietyIdeaType = 'esociety_idea';
  static const _esocietyPortalType = 'esociety_portal';
  static const _androidChannelId = 'high_importance_channel';
  static const _androidChannelName = 'High Importance Notifications';
  static const _androidChannelDescription =
      'Important updates from LGU Connect.';

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  bool _isRequestingPermission = false;

  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Returns true if notification permission is currently granted.
  Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Requests notification permission.
  ///
  /// This only requests the permission. Opening the system settings page is
  /// handled by the calling screen (see HomeScreen._enableNotifications), so
  /// settings never open unexpectedly at app launch.
  Future<bool> requestNotificationPermission() async {
    if (_isRequestingPermission) return false;
    _isRequestingPermission = true;

    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) return false;

      if (Platform.isAndroid) {
        final updated = await Permission.notification.request();
        return updated.isGranted;
      }

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint("Error requesting permission: $e");
      return false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<void> initLocalNotification(BuildContext context) async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification tapped: ${response.payload}");
        handleMessageByPayload(context, response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Android notification channels are persistent. Create one stable channel
    // that matches the channel configured for FCM in AndroidManifest.xml.
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
      ),
    );

    debugPrint("Local notifications initialized");
  }

  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("Message title: ${message.notification?.title}");
      debugPrint("Message body: ${message.notification?.body}");
      debugPrint("Message data: ${message.data.toString()}");
      debugPrint("Message data Type: ${message.data['type']}");
      debugPrint("Message data id: ${message.data['id']}");

      showNotification(message);
    });
  }

  static Future<void> showNotification(RemoteMessage message) async {
    debugPrint("showNotification called: ${message.notification?.title}");
    final int id = Random.secure().nextInt(100000);
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: notificationDetails,
      payload: message.data['type'],
    );
  }

  Future<String?> getDeviceToken() async {
    String? token = await messaging.getToken();
    if (token != null) {
      debugPrint("Device Token: $token");
      await _saveTokenToFirestore(token);
    } else {
      debugPrint("FCM token is null — permission may not be granted");
    }
    return token;
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('device_tokens')
        .doc(token) // token as doc ID = auto deduplication
        .set(
          {
            'token': token,
            'createdAt': FieldValue.serverTimestamp(),
            'platform': Platform.operatingSystem, // 'android' or 'ios'
            // Only set when someone is signed in: at launch the session may
            // not be restored yet, and writing null here would unlink the
            // student. Sign-out clears it through linkTokenToUser(null).
            if (user != null) 'userId': user.uid,
          },
          SetOptions(merge: true),
        ); // merge so createdAt isn't overwritten on refresh
  }

  /// Points this device's token at [uid] (or at nobody when null), so
  /// personal notifications such as E-Society meeting times reach the
  /// signed-in student or society member and stop after they sign out. Never prompts for permission.
  static Future<void> linkTokenToUser(String? uid) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('device_tokens')
          .doc(token)
          .set({
            'token': token,
            'platform': Platform.operatingSystem,
            'userId': uid,
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Could not link device token: $e');
    }
  }

  void isTokenRefreshed() {
    // Keeps this device linked to whoever is signed in, including a session
    // restored at launch, so personal notifications (E-Society meeting
    // times) reach students who signed in before or on another app run.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) linkTokenToUser(user.uid);
    });
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint("Token Refresh: $newToken");
      _saveTokenToFirestore(newToken);
    });
  }

  /// Opens the screen an E-Society notification is about: the student's
  /// ventures, or the portal for society members.
  static bool _openEsociety(BuildContext context, String? type) {
    final Widget? screen = switch (type) {
      _esocietyIdeaType => const VenturesScreen(initialTab: VenturesTab.mine),
      _esocietyPortalType => const EsocietyPortalEntry(),
      _ => null,
    };
    if (screen == null) return false;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    return true;
  }

  Future<void> handleMessageByPayload(
    BuildContext context,
    String? payload,
  ) async {
    if (_openEsociety(context, payload)) return;
    if (payload == 'collaboration') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VenturesScreen()),
      );
    } else if (payload == 'lost_found') {
      if (!await LguEmailGate.ensureVerified(context)) return;
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ListingsScreen()),
      );
    }
  }

  Future<void> handleMessage(
    BuildContext context,
    RemoteMessage message,
  ) async {
    final type = message.data['type'];
    if (_openEsociety(context, type)) return;
    if (type == 'collaboration') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VenturesScreen()),
      );
    } else if (type == 'lost_found') {
      if (!await LguEmailGate.ensureVerified(context)) return;
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ListingsScreen()),
      );
    }
  }

  Future<void> setupInteractMessage(BuildContext context) async {
    // terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          handleMessage(context, initialMessage);
        }
      });
    }

    // background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (context.mounted) {
        handleMessage(context, message);
      }
    });
  }
}
