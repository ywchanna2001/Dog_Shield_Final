import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/main.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String reminderPayload = 'reminder_notification';
  static const String channelId = 'dogshield_reminders_channel';
  static const String channelName = 'DogShield Reminders';

  Future<void> initialize() async {
    debugPrint('*** NotificationService: Starting initialization ***');

    // Initialize timezone database FIRST
    tz.initializeTimeZones();

    // IMPORTANT: Set to YOUR timezone
    // Common timezones: 'America/New_York', 'America/Los_Angeles', 'Europe/London', 'Asia/Colombo'
    final String timeZoneName = 'Asia/Colombo';
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint('*** NotificationService: Timezone set to $timeZoneName ***');

    // Android notification channel configuration
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Channel for DogShield pet care reminders',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    // Create the notification channel on Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('*** NotificationService: Notification channel created ***');

    // Initialization settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialization settings for iOS
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    debugPrint('*** NotificationService: Initialization complete ***');
  }

  // Handler for when notification is tapped
  static void onNotificationTap(NotificationResponse response) {
    debugPrint('*** NotificationService: Notification tapped ***');
    debugPrint('    Payload: ${response.payload}');

    // Navigate to reminders screen
    if (navigatorKey.currentState != null) {
      debugPrint('*** NotificationService: Navigating to reminders screen ***');
      navigatorKey.currentState?.pushNamed(AppConstants.remindersRoute);
    } else {
      debugPrint('*** WARNING: Navigator key is null! ***');
    }
  }

  Future<void> requestPermissions() async {
    debugPrint('*** NotificationService: Requesting permissions ***');

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      debugPrint('*** Notification permission: $granted ***');

      final exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
      debugPrint('*** Exact alarm permission: $exactAlarmGranted ***');
    }

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    debugPrint('*** NotificationService: Permissions requested ***');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      debugPrint('*** NotificationService: Scheduling notification ***');
      debugPrint('    ID: $id');
      debugPrint('    Title: $title');
      debugPrint('    Scheduled for: $scheduledDate');
      debugPrint('    Current time: ${DateTime.now()}');

      final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);
      debugPrint('    TZ Scheduled time: $scheduledTZDate');

      final now = tz.TZDateTime.now(tz.local);
      if (scheduledTZDate.isBefore(now)) {
        debugPrint('*** WARNING: Scheduled time is in the past! ***');
        debugPrint('    Difference: ${now.difference(scheduledTZDate)}');
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Channel for DogShield pet care reminders.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            // showBadge: true,
            ticker: 'DogShield Reminder',
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default.wav',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminderPayload,
      );

      debugPrint('*** Notification scheduled successfully ***');

      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint('*** Total pending notifications: ${pendingNotifications.length} ***');

      final scheduled = pendingNotifications.where((n) => n.id == id).toList();
      if (scheduled.isNotEmpty) {
        debugPrint('*** Confirmed: Notification $id is pending ***');
      } else {
        debugPrint('*** WARNING: Notification $id NOT found in pending list ***');
      }
    } catch (e, stackTrace) {
      debugPrint('*** ERROR scheduling notification: $e ***');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> showTestNotification() async {
    debugPrint('*** Showing test notification ***');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Test notification',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      '🐕 DogShield Test',
      'Notifications are working! Tap to test navigation.',
      platformDetails,
      payload: reminderPayload,
    );
  }

  Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      bool? enabled = false;
      bool? exactAlarmEnabled = false;

      if (androidImplementation != null) {
        enabled = await androidImplementation.areNotificationsEnabled();
        try {
          exactAlarmEnabled = await androidImplementation.canScheduleExactNotifications();
        } catch (e) {
          exactAlarmEnabled = null;
        }
      }

      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();

      return {
        'enabled': enabled ?? false,
        'exactAlarmEnabled': exactAlarmEnabled,
        'platform': 'Android',
        'timestamp': DateTime.now().toIso8601String(),
        'pendingNotifications': pendingNotifications.length,
        'pendingIds': pendingNotifications.map((n) => n.id).toList(),
        'error': null,
      };
    } catch (e) {
      return {
        'enabled': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> cancelNotification(int id) async {
    debugPrint('*** Cancelling notification $id ***');
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('*** Notification $id cancelled ***');
    } catch (e) {
      debugPrint('*** ERROR cancelling notification: $e ***');
    }
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('*** Cancelling all notifications ***');
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}