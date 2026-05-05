import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // 1. Request permission for push notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional permission for notifications');
      } else {
        print('User declined or has not accepted permission for notifications');
      }
    }

    // 2. Retrieve the device's FCM Token
    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      // TODO: Save this token to the user's Firestore profile later
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving FCM Token: $e');
      }
    }

    // 3. Set up a listener for foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received a foreground notification!');
        if (message.notification != null) {
          print('Title: ${message.notification?.title}');
          print('Body: ${message.notification?.body}');
        }
      }
      // Optional: Add logic to show a local notification snackbar or alert
    });
  }
}
