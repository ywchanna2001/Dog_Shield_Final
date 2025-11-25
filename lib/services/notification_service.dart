import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/main.dart'; // We will create this navigatorKey in main.dart
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // A constant payload to identify our notifications
  static const String reminderPayload = 'reminder_notification';

  Future<void> initialize() async {
    // Initialization settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Make sure you have this app icon

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

    // Initialize timezone database
    tz.initializeTimeZones();

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // This function is called when a notification is tapped
      onDidReceiveNotificationResponse: onNotificationTap,
    );
  }

  // This is the handler for when a user taps on a notification
  static void onNotificationTap(NotificationResponse response) {
    if (response.payload != null && response.payload == reminderPayload) {
      // Use the global navigator key to navigate to the reminders screen
      // The key is defined in main.dart
      navigatorKey.currentState?.pushNamed(AppConstants.remindersRoute);
    }
  }
  
  // Request permissions (essential for iOS and newer Android)
  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission(); 
        
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // The new, powerful scheduling method
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dogshield_reminders_channel', // Channel ID
          'DogShield Reminders',         // Channel Name
          channelDescription: 'Channel for DogShield pet care reminders.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
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
      payload: reminderPayload, // Set the payload for navigation
    );
  }

  // Add missing methods 
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dogshield_test_channel',
      'DogShield Test',
      channelDescription: 'Channel for testing notifications.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      999, // A static ID for the test notification
      'Test Notification',
      'If you can see this, notifications are working!',
      platformDetails,
    );
  }

  Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final bool? enabled = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      
      return {
        'enabled': enabled ?? false,
        'platform': 'Android', // Or check for iOS
        'timestamp': DateTime.now().toIso8601String(),
        'error': null,
      };
    } catch (e) {
      return {
        'enabled': false,
        'error': e.toString(),
      };
    }
  }


  // Method to cancel a notification if a reminder is deleted or completed
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}