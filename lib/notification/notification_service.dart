import 'dart:io';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lgu_one/collaboration/collaboration_screen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<bool> requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User Granted Permission");
      return true;
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print("User granted provisional permission");
      return true;
    } else {
      print("Permission Denied");
      AppSettings.openAppSettings();
      return false;
    }
  }

  Future<void> initLocalNotification(BuildContext context) async {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification tapped: ${response.payload}");
        handleMessageByPayload(context, response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    print("Local notifications initialized");
  }

  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      print("Message title: ${message.notification?.title}");
      print("Message body: ${message.notification?.body}");
      print("Message data: ${message.data.toString()}");
      print("Message data Type: ${message.data['type']}");
      print("Message data id: ${message.data['id']}");

      showNotification(message);
    });
    // onMessageOpenedApp removed — handled in setupInteractMessage
  }

  static Future<void> showNotification(RemoteMessage message) async {
    print("showNotification called: ${message.notification?.title}");
    final int id = Random.secure().nextInt(100000);
    final String channelId = id.toString();

    final AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      channelId,
      'High Importance Notifications',
      channelDescription: 'Your Channel Description',
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
      print("Device Token: $token");
      await _saveTokenToFirestore(token);
    } else {
      print("FCM token is null — permission may not be granted");
    }
    return token;
  }

  Future<void> _saveTokenToFirestore(String token) async {
    await FirebaseFirestore.instance
        .collection('device_tokens')
        .doc(token) // token as doc ID = auto deduplication
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem, // 'android' or 'ios'
    }, SetOptions(merge: true)); // merge so createdAt isn't overwritten on refresh
  }

  void isTokenRefreshed() {
    messaging.onTokenRefresh.listen((newToken) {
      print("Token Refresh: $newToken");
      _saveTokenToFirestore(newToken);
    });
  }

  void handleMessageByPayload(BuildContext context, String? payload) {
    if (payload == 'collaboration') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CollaborationScreen()),
      );
    }
  }

  void handleMessage(BuildContext context, RemoteMessage message) {
    if (message.data['type'] == 'collaboration') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CollaborationScreen()),
      );
    }
  }

  Future<void> setupInteractMessage(BuildContext context) async {
    // terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleMessage(context, initialMessage);
      });
    }

    // background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(context, message);
    });
  }
}