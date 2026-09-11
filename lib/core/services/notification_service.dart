import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../network/api_config.dart';
import '../../features/inventory/presentation/screens/receive_order_screen.dart';

import '../../main.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin
      _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // ----------------------------------------------------------
    // 1. BACKGROUND FCM HANDLER
    // ----------------------------------------------------------

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // ----------------------------------------------------------
    // 2. LOCAL NOTIFICATION INITIALIZATION
    // ----------------------------------------------------------

    const AndroidInitializationSettings
        initializationSettingsAndroid =
        AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          _onLocalNotificationTap,
    );

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      'high_importance_channel',
      'Stock Management Notifications',
      description:
          'Channel for stock management app notifications',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // ----------------------------------------------------------
    // 3. REQUEST PUSH PERMISSION
    // ----------------------------------------------------------

    final NotificationSettings settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
      await _messaging
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // --------------------------------------------------------
      // FOREGROUND FCM
      // --------------------------------------------------------

      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          _showFcmForegroundNotification(message);
        },
      );

      // --------------------------------------------------------
      // APP WAS IN BACKGROUND AND USER TAPPED FCM
      // --------------------------------------------------------

      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          _handleNotificationNavigation(message.data);
        },
      );

      // --------------------------------------------------------
      // APP WAS TERMINATED AND USER TAPPED FCM
      // --------------------------------------------------------

      final RemoteMessage? initialMessage =
          await _messaging.getInitialMessage();

      if (initialMessage != null) {
        // Wait until MaterialApp has created the navigator.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationNavigation(
            initialMessage.data,
          );
        });
      }
    }
  }

  // ------------------------------------------------------------
  // REGISTER FCM TOKEN
  // ------------------------------------------------------------

  static Future<void> registerFcmToken(int userId) async {
    try {
      final String? token =
          await _messaging.getToken();

      if (token != null) {
        await _postTokenToBackend(
          userId,
          token,
        );
      }

      _messaging.onTokenRefresh.listen(
        (newToken) {
          _postTokenToBackend(
            userId,
            newToken,
          );
        },
      );
    } catch (e) {
      // Keep existing behaviour:
      // token registration failure must not break the app.
    }
  }

  // ------------------------------------------------------------
  // SAVE FCM TOKEN
  // ------------------------------------------------------------

  static Future<void> _postTokenToBackend(
    int userId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.saveFcmToken),
      headers: ApiConfig.jsonHeaders,
      body: jsonEncode({
        'user_id': userId,
        'fcm_token': token,
        'device_type': 'android',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to save FCM token. '
        'HTTP ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(
        data['message'] ??
            'Failed to save FCM token',
      );
    }
  }

  // ------------------------------------------------------------
  // FOREGROUND NOTIFICATION
  // ------------------------------------------------------------

  static Future<void> _showFcmForegroundNotification(
    RemoteMessage message,
  ) async {
    final RemoteNotification? notification =
        message.notification;

    if (notification == null) {
      return;
    }

    final String title =
        notification.title ??
            '⚠️ Low Stock Alert';

    final String body =
        notification.body ??
            'An item in your inventory is running low.';

    // Backend notification ID.
    final String? notificationId =
        message.data['notification_id']?.toString();

    final int androidNotificationId =
        notificationId != null &&
                notificationId.isNotEmpty
            ? int.tryParse(notificationId) ??
                message.hashCode
            : message.hashCode;

    await _notificationsPlugin.show(
      androidNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Stock Management Notifications',
          channelDescription:
              'Channel for inventory alerts and notifications',
          icon: '@mipmap/launcher_icon',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation:
              BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText:
                'Stock Management',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Store the entire backend data payload.
      payload: jsonEncode(message.data),
    );
  }

  // ------------------------------------------------------------
  // LOCAL NOTIFICATION TAP
  // ------------------------------------------------------------

  static void _onLocalNotificationTap(
    NotificationResponse response,
  ) {
    final String? payload =
        response.payload;

    if (payload == null ||
        payload.isEmpty) {
      return;
    }

    try {
      final dynamic decoded =
          jsonDecode(payload);

      if (decoded is Map) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(decoded);

        _handleNotificationNavigation(data);
      }
    } catch (e) {
      // Ignore invalid local notification payload.
    }
  }

  // ------------------------------------------------------------
  // NOTIFICATION NAVIGATION
  // ------------------------------------------------------------

  static void _handleNotificationNavigation(
    Map<String, dynamic> data,
  ) {
    final String module =
        data['module']?.toString().toLowerCase().trim() ?? '';

    if (module != 'purchaseorder' &&
        module != 'purchase_order' &&
        module != 'purchase-order') {
      return;
    }

    final dynamic rawPurchaseId =
        data['purchase_id'];

    final int? purchaseId =
        int.tryParse(
      rawPurchaseId?.toString() ?? '',
    );

    if (purchaseId == null || purchaseId <= 0) {
      return;
    }

    final NavigatorState? navigator =
        navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ReceiveOrderScreen(
          poId: purchaseId,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BACKUP NOTIFICATION
  // ------------------------------------------------------------

  static Future<void> showBackupNotification() async {
    const AndroidNotificationDetails
        androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'stock_management_channel',
      'Stock Management Notifications',
      channelDescription:
          'Channel for stock management app notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: 'ic_notification',
      color: Color(0xFF0033A0),
    );

    const NotificationDetails
        platformChannelSpecifics =
        NotificationDetails(
      android:
          androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      'Backup Complete',
      'Your data has been successfully backed up to Google Drive.',
      platformChannelSpecifics,
    );
  }
}