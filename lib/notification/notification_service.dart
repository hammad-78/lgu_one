import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzlib;
import 'package:lgu_one/collaboration/join_collaboration.dart';
import 'package:lgu_one/Lost_Found/listing_screen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

class NotificationService {
  static const _androidChannelId = 'high_importance_channel';
  static const _androidChannelName = 'High Importance Notifications';
  static const _androidChannelDescription =
      'Important updates from LGU Connect.';

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  bool _isRequestingPermission = false;

  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<bool> requestNotificationPermission() async {
    if (_isRequestingPermission) return false;
    _isRequestingPermission = true;

    try {
      // FCM Permission request
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional: true,
        sound: true,
      );

      // Local Notifications Permission request for Android 13+
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint("User Granted Permission");
        return true;
      } else
      if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint("User granted provisional permission");
        return true;
      } else {
        debugPrint("Permission Denied");
        return false;
      }
    } catch (e) {
      debugPrint("Error requesting permission: $e");
      return false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<void> initLocalNotification(BuildContext context) async {
    // Initialize timezone data for scheduled notifications
    tz.initializeTimeZones();
    tzlib.setLocalLocation(tzlib.getLocation('Asia/Karachi'));

    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );

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
        AndroidFlutterLocalNotificationsPlugin>();
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
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem, // 'android' or 'ios'
      'userId': user?.uid,
    }, SetOptions(
        merge: true)); // merge so createdAt isn't overwritten on refresh
  }

  void isTokenRefreshed() {
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint("Token Refresh: $newToken");
      _saveTokenToFirestore(newToken);
    });
  }

  void handleMessageByPayload(BuildContext context, String? payload) {
    if (payload == 'collaboration') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const JoinCollaborationScreen()),
      );
    } else if (payload == 'lost_found') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ListingsScreen()),
      );
    }
  }

  void handleMessage(BuildContext context, RemoteMessage message) {
    final type = message.data['type'];
    if (type == 'collaboration') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const JoinCollaborationScreen()),
      );
    } else if (type == 'lost_found') {
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
