import 'package:flutter/material.dart'; // Added for the Color class
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Android initialization settings using your default launcher icon
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showBackupNotification() async {
    const AndroidNotificationDetails
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'stock_management_channel',
      'Stock Management Notifications',
      channelDescription: 'Channel for stock management app notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',

      // 1. Point to your transparent silhouette icon file
      // (Placed in: android/app/src/main/res/drawable/ic_notification.png)
      icon: 'ic_notification',

      // 2. Set the background circle color (using the dark blue from your logo)
      color: Color(0xFF0033A0),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      'Backup Complete',
      'Your data has been successfully backed up to Google Drive.',
      platformChannelSpecifics,
    );
  }
}
