import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {}

// Channel ID must match _ANDROID_CHANNEL_ID in the backend notifications.py
const _channelId = 'foodshare_default';
const _channelName = 'FoodShare';
const _channelDesc = 'Donation requests, messages, and updates';

const _androidChannel = AndroidNotificationChannel(
  _channelId,
  _channelName,
  description: _channelDesc,
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

final _localNotifications = kIsWeb ? null : FlutterLocalNotificationsPlugin();

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Request FCM permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    if (!kIsWeb && _localNotifications != null) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotifications!.initialize(
        const InitializationSettings(android: androidSettings),
      );

      final androidPlugin = _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // Create the high-importance channel; must be done before any notification fires
      await androidPlugin?.createNotificationChannel(_androidChannel);

      // Explicitly request POST_NOTIFICATIONS permission on Android 13+ (API 33+)
      await androidPlugin?.requestNotificationsPermission();
    }

    String? token;
    if (kIsWeb) {
      token = await _messaging.getToken(
        vapidKey: 'BBxt_1fesZe8PvqNNirWYcKXsXz4SnSHmEwTLoIp4VhrQEr_01JA4oUP8v7vxPcdYIkJv1HcHLTEZ94w18nXMVg',
      );
    } else {
      token = await _messaging.getToken();
    }
    if (token != null) await _saveToken(token);

    _messaging.onTokenRefresh.listen(_saveToken);

    // Foreground: show a system banner for ALL notification types.
    // Background / terminated: FCM delivers the notification automatically using
    // the channel_id we set in the backend, which maps to _androidChannel above.
    FirebaseMessaging.onMessage.listen((message) {
      if (kIsWeb) return;
      final notification = message.notification;
      if (notification == null) return;
      final chatId = message.data['chat_id'] as String?;
      final notifId = chatId != null
          ? chatId.hashCode.abs() % 100000
          : DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _localNotifications?.show(
        notifId,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            tag: chatId,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    });
  }

  static Future<void> _saveToken(String token) async {
    try {
      await ApiClient.post('/auth/fcm-token', body: {'token': token});
    } catch (_) {}
  }

  static Future<void> saveTokenAfterLogin() async {
    try {
      String? token;
      if (kIsWeb) {
        token = await _messaging.getToken(
          vapidKey: 'BBxt_1fesZe8PvqNNirWYcKXsXz4SnSHmEwTLoIp4VhrQEr_01JA4oUP8v7vxPcdYIkJv1HcHLTEZ94w18nXMVg',
        );
      } else {
        token = await _messaging.getToken();
      }
      if (token != null) await _saveToken(token);
    } catch (_) {}
  }

  /// Dismiss any pending notifications for this chat from the notification centre.
  static Future<void> cancelChatNotifications(String chatId) async {
    if (kIsWeb || _localNotifications == null) return;
    final androidPlugin = _localNotifications!
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    final active = await androidPlugin.getActiveNotifications();
    for (final n in active) {
      if (n.tag == chatId) {
        await _localNotifications!.cancel(n.id ?? 0, tag: n.tag);
      }
    }
  }
}
