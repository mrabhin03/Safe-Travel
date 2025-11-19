import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../api_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static Future<void> saveTokenToDatabase(String? token) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'Version': ApiService.Version,
    }, SetOptions(merge: true));
  }

  static bool _permissionRequestInProgress = false;

  static void initFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground message: ${message.notification?.title}");

      if (message.notification != null) {
        LocalNotificationService.showNotification(
          title: message.notification!.title ?? "New Message",
          body: message.notification!.body ?? "",
        );
      }
    });

    // When user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("🚀 Notification opened");
    });
  }

  static Future<void> printToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    saveTokenToDatabase(token);
    print("🔥 FCM Token: $token");
  }

  static Future<NotificationSettings?> requestPermissionOnce() async {
    if (_permissionRequestInProgress) {
      print('FCM: permission request already in progress, skipping');
      return null;
    }
    _permissionRequestInProgress = true;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      print('FCM: permission result: $settings');
      return settings;
    } catch (e, st) {
      print('FCM: requestPermission failed: $e\n$st');
      return null;
    } finally {
      _permissionRequestInProgress = false;
    }
  }
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_stat_notify'); // your icon

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel', // same channel ID
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(0, title, body, details);
  }
}
