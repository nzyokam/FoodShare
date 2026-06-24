import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widgets/app_snackbar.dart';
import 'api_client.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // No-op: FCM displays the system notification automatically for data+notification messages.
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static BuildContext? _context;

  /// Call once after Firebase.initializeApp() in main().
  static Future<void> initialize(BuildContext context) async {
    _context = context;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Request permission (iOS / web — Android grants by default)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Web requires an explicit VAPID key — set yours from Firebase Console →
    // Project Settings → Cloud Messaging → Web Push certificates → Key pair
    String? token;
    if (kIsWeb) {
      token = await _messaging.getToken(
        vapidKey: 'BBxt_1fesZe8PvqNNirWYcKXsXz4SnSHmEwTLoIp4VhrQEr_01JA4oUP8v7vxPcdYIkJv1HcHLTEZ94w18nXMVg',
      );
    } else {
      token = await _messaging.getToken();
    }

    if (token != null) await _saveToken(token);

    // Refresh token whenever it rotates
    _messaging.onTokenRefresh.listen(_saveToken);

    // Foreground message handler — show in-app snackbar
    FirebaseMessaging.onMessage.listen((message) {
      final ctx = _context;
      if (ctx == null || !ctx.mounted) return;
      final notification = message.notification;
      if (notification != null) {
        final title = notification.title ?? '';
        final body = notification.body ?? '';
        AppSnackBar.showInfo(ctx, body.isNotEmpty ? body : title);
      }
    });
  }

  static Future<void> _saveToken(String token) async {
    try {
      await ApiClient.post('/auth/fcm-token', body: {'token': token});
    } catch (_) {}
  }

  static void updateContext(BuildContext context) => _context = context;
}
