import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _appId = "e6e1a5f3-faa1-465e-ab93-a4b1c9c25daa";
  static const String _restApiKey =
      "os_v2_app_43q2l472ufdf5k4tusy4tqs5vj6dym2qa7teut4jkwvxuh6lunqlqj76rtpl7bp6cx2ls66qgl4hmbq7fz47bmhhsox65urtpkvegdy";

  static Future<void> initialize() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.initialize(_appId);

    // Listener: permission changes
    OneSignal.Notifications.addPermissionObserver((granted) {
      debugPrint('[OneSignal] Notification permission granted: $granted');
    });

    // Listener: foreground notifications
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint(
        '[OneSignal] Foreground notification: ${event.notification.title}',
      );
      // Display the notification while app is open
      event.notification.display();
    });

    // Listener: notification tapped
    OneSignal.Notifications.addClickListener((event) {
      debugPrint(
        '[OneSignal] Notification tapped: ${event.notification.additionalData}',
      );
    });

    // Request permission
    final granted = await OneSignal.Notifications.requestPermission(true);
    debugPrint('[OneSignal] Permission requested. Result: $granted');

    // Log subscription status for debugging
    _logSubscriptionStatus();
  }

  static void _logSubscriptionStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    final sub = OneSignal.User.pushSubscription;
    debugPrint('[OneSignal] ==========================================');
    debugPrint('[OneSignal] Subscription ID: ${sub.id}');
    debugPrint('[OneSignal] Subscription Token: ${sub.token}');
    debugPrint('[OneSignal] Subscription OptedIn: ${sub.optedIn}');
    debugPrint('[OneSignal] ==========================================');
  }

  /// Called after login to link the user's Firestore UID to OneSignal
  static Future<void> login(String uid) async {
    try {
      await OneSignal.login(uid);
      debugPrint('[OneSignal] Logged in with external UID: $uid');

      // Log subscription status after login
      await Future.delayed(const Duration(seconds: 2));
      final sub = OneSignal.User.pushSubscription;
      debugPrint('[OneSignal] Post-login Subscription ID: ${sub.id}');
      debugPrint('[OneSignal] Post-login Subscription Token: ${sub.token}');
      debugPrint('[OneSignal] Post-login OptedIn: ${sub.optedIn}');
    } catch (e) {
      debugPrint('[OneSignal] Login Error: $e');
    }
  }

  /// Called after logout
  static Future<void> logout() async {
    try {
      await OneSignal.logout();
      debugPrint('[OneSignal] Logged out');
    } catch (e) {
      debugPrint('[OneSignal] Logout Error: $e');
    }
  }

  /// Sends a push notification to specific users using OneSignal REST API.
  /// Uses include_aliases targeting which requires target_channel: 'push'.
  static Future<void> sendNotification({
    required List<String> receiverIds,
    required String title,
    required String content,
    Map<String, dynamic>? data,
  }) async {
    if (receiverIds.isEmpty) {
      debugPrint(
        '[OneSignal] sendNotification: receiverIds is empty. Skipping.',
      );
      return;
    }

    debugPrint(
      '[OneSignal] Sending notification to external IDs: $receiverIds',
    );
    debugPrint('[OneSignal] Title: $title | Content: $content');

    final payload = {
      'app_id': _appId,
      // FIX: Use include_aliases + target_channel (required in SDK v5+)
      'include_aliases': {'external_id': receiverIds},
      'target_channel': 'push',
      'headings': {'en': title},
      'contents': {'en': content},
      if (data != null) 'data': data,
    };

    debugPrint('[OneSignal] Full request payload: ${jsonEncode(payload)}');

    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      debugPrint('[OneSignal] Response Status: ${response.statusCode}');
      debugPrint('[OneSignal] Response Body: ${response.body}');

      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final id = responseJson['id'] ?? 'N/A';
        final recipients = responseJson['recipients'] ?? 0;
        debugPrint(
          '[OneSignal] ✅ Notification sent! ID: $id, Recipients: $recipients',
        );
        if (recipients == 0) {
          debugPrint(
            '[OneSignal] ⚠️ WARNING: 0 recipients! The external ID is not subscribed or not found.',
          );
        }
      } else {
        final errors = responseJson['errors'] ?? responseJson;
        debugPrint(
          '[OneSignal] ❌ Failed to send notification. Errors: $errors',
        );
      }
    } catch (e) {
      debugPrint('[OneSignal] ❌ HTTP Exception: $e');
    }
  }
}
