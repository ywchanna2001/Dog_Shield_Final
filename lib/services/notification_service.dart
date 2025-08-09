import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:dogshield_ai/data/models/reminder_model.dart';
import 'package:dogshield_ai/data/services/reminder_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Timer? _reminderCheckTimer;
  List<Function(Reminder)> _notificationCallbacks = [];
  List<Reminder> _scheduledReminders = [];
  Set<String> _sentNotifications = {}; // Track sent notifications to prevent duplicates

  Future<void> initialize() async {
    try {
      print('NotificationService: Initializing...');

      // Initialize timezone data
      tz.initializeTimeZones();

      // Android notification settings
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS notification settings
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final initialized = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('NotificationService: Initialized successfully: $initialized');

      // Create notification channel for Android
      await _createNotificationChannel();

      // Request permissions for Android 13+
      await _requestPermissions();

      // Start background monitoring for reminders - check every 30 seconds for more accuracy
      _reminderCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkDueReminders();
      });

      print('NotificationService: Background monitoring started (30-second intervals)');
    } catch (e) {
      print('NotificationService: Error during initialization: $e');
      rethrow;
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pet_reminders',
      'Pet Reminders',
      description: 'Notifications for pet care reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      print('NotificationService: Notification channel created');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      print('NotificationService: Requesting permissions...');

      // Request notification permissions for Android 13+
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        print('NotificationService: Permission granted: $granted');
      }
    } catch (e) {
      print('NotificationService: Error requesting permissions: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('Notification tapped: ${notificationResponse.payload}');
    // You can add navigation logic here if needed
  }

  void addNotificationCallback(Function(Reminder) callback) {
    _notificationCallbacks.add(callback);
  }

  void removeNotificationCallback(Function(Reminder) callback) {
    _notificationCallbacks.remove(callback);
  }

  Future<void> _checkDueReminders() async {
    try {
      final now = DateTime.now();
      print('NotificationService: Checking for due reminders at ${now.toString().substring(11, 19)}');

      // Get all reminders from database to ensure we have the latest
      final reminderService = ReminderService();
      final allReminders = await reminderService.getAllReminders();

      print('NotificationService: Found ${allReminders.length} total reminders to check');

      for (final reminder in allReminders) {
        if (!reminder.isCompleted) {
          final timeDifference = now.difference(reminder.date);

          // Check if reminder is due now (within 30 seconds window for immediate triggering)
          if (timeDifference.inSeconds >= 0 && timeDifference.inSeconds <= 30) {
            final notificationKey = '${reminder.id}_due_${reminder.date.millisecondsSinceEpoch}';

            // Only send notification if we haven't already sent it for this exact time
            if (!_sentNotifications.contains(notificationKey)) {
              print('NotificationService: *** TRIGGERING DUE NOTIFICATION *** for: ${reminder.title}');

              // Show immediate notification (same mechanism as test notification)
              await _showImmediateDueNotification(reminder);

              // Mark this notification as sent
              _sentNotifications.add(notificationKey);

              // Trigger in-app notification callbacks
              for (final callback in _notificationCallbacks) {
                callback(reminder);
              }
            }
          }
          // Check if reminder is overdue (past due time by more than 30 seconds)
          else if (timeDifference.inSeconds > 30 && timeDifference.inHours <= 24) {
            final notificationKey = '${reminder.id}_overdue_${reminder.date.millisecondsSinceEpoch}';

            if (!_sentNotifications.contains(notificationKey)) {
              print('NotificationService: *** TRIGGERING OVERDUE NOTIFICATION *** for: ${reminder.title}');

              // Show immediate notification for overdue reminder
              await _showImmediateOverdueNotification(reminder);

              // Mark this notification as sent
              _sentNotifications.add(notificationKey);

              // Trigger in-app notification callbacks
              for (final callback in _notificationCallbacks) {
                callback(reminder);
              }
            }
          }
        }
      }

      // Clean up old notification keys (keep only last 100 to prevent memory bloat)
      if (_sentNotifications.length > 100) {
        final sortedKeys = _sentNotifications.toList()..sort();
        _sentNotifications.clear();
        _sentNotifications.addAll(sortedKeys.skip(sortedKeys.length - 50));
      }

      print('NotificationService: Completed reminder check, tracking ${_sentNotifications.length} sent notifications');
    } catch (e) {
      print('NotificationService: Error checking due reminders: $e');
    }
  }

  Future<void> _showImmediateDueNotification(Reminder reminder) async {
    try {
      print('NotificationService: Showing immediate due notification for ${reminder.title}');

      await _flutterLocalNotificationsPlugin.show(
        reminder.id.hashCode,
        '🔔 ${reminder.title}',
        'Time for ${reminder.title}! Don\'t forget your pet\'s care.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pet_reminders',
            'Pet Reminders',
            channelDescription: 'Notifications for pet care reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            showWhen: true,
            enableVibration: true,
            playSound: true,
            autoCancel: true,
            ongoing: false,
            color: Color(0xFF4CAF50), // Green for due reminders
          ),
          iOS: DarwinNotificationDetails(sound: 'default', presentAlert: true, presentBadge: true, presentSound: true),
        ),
      );

      print('NotificationService: Immediate due notification sent successfully for ${reminder.title}');
    } catch (e) {
      print('NotificationService: Error showing immediate due notification: $e');
    }
  }

  Future<void> _showImmediateOverdueNotification(Reminder reminder) async {
    try {
      print('NotificationService: Showing immediate overdue notification for ${reminder.title}');

      final overdueDays = DateTime.now().difference(reminder.date).inDays;
      final overdueText =
          overdueDays > 0
              ? 'Overdue by $overdueDays day${overdueDays > 1 ? 's' : ''}!'
              : 'Overdue! Please check on your pet.';

      await _flutterLocalNotificationsPlugin.show(
        reminder.id.hashCode + 10000, // Different ID for overdue notifications
        '⚠️ ${reminder.title} - OVERDUE',
        overdueText,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pet_reminders',
            'Pet Reminders',
            channelDescription: 'Notifications for pet care reminders',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            showWhen: true,
            enableVibration: true,
            playSound: true,
            autoCancel: true,
            ongoing: false,
            color: Color(0xFFFF5722), // Red/orange for overdue reminders
          ),
          iOS: DarwinNotificationDetails(sound: 'default', presentAlert: true, presentBadge: true, presentSound: true),
        ),
      );

      print('NotificationService: Immediate overdue notification sent successfully for ${reminder.title}');
    } catch (e) {
      print('NotificationService: Error showing immediate overdue notification: $e');
    }
  }

  Future<void> _showDueNotification(Reminder reminder) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        reminder.id.hashCode,
        '🔔 ${reminder.title}',
        'Time for ${reminder.title}! Don\'t forget your pet\'s care.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pet_reminders',
            'Pet Reminders',
            channelDescription: 'Notifications for pet care reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF4CAF50), // Green for due reminders
          ),
          iOS: DarwinNotificationDetails(sound: 'default', presentAlert: true, presentBadge: true, presentSound: true),
        ),
        payload: reminder.id,
      );
      print('NotificationService: Showed due notification for ${reminder.title}');
    } catch (e) {
      print('Error showing due notification: $e');
    }
  }

  Future<void> _showOverdueNotification(Reminder reminder) async {
    try {
      final overdueDays = DateTime.now().difference(reminder.date).inDays;
      final overdueText =
          overdueDays > 0
              ? 'Overdue by $overdueDays day${overdueDays > 1 ? 's' : ''}!'
              : 'Overdue! Please check on your pet.';

      await _flutterLocalNotificationsPlugin.show(
        reminder.id.hashCode + 10000, // Different ID for overdue notifications
        '⚠️ ${reminder.title} - OVERDUE',
        overdueText,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pet_reminders',
            'Pet Reminders',
            channelDescription: 'Notifications for pet care reminders',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFFF5722), // Red/orange for overdue reminders
          ),
          iOS: DarwinNotificationDetails(sound: 'default', presentAlert: true, presentBadge: true, presentSound: true),
        ),
        payload: reminder.id,
      );
      print('NotificationService: Showed overdue notification for ${reminder.title}');
    } catch (e) {
      print('Error showing overdue notification: $e');
    }
  }

  Future<void> scheduleReminderNotification(Reminder reminder) async {
    try {
      // Add to our local list for checking
      _scheduledReminders.add(reminder);

      // Calculate notification ID (use hashCode for consistency)
      final int notificationId = reminder.id.hashCode;

      // Schedule the actual mobile notification
      final scheduledDate = tz.TZDateTime.from(reminder.date, tz.local);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '🐕 ${reminder.title}',
        'Time for ${reminder.title} for your pet!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pet_reminders',
            'Pet Reminders',
            channelDescription: 'Notifications for pet care reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(sound: 'default', presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id,
      );

      print('Scheduled mobile notification for reminder: ${reminder.title} at ${reminder.date}');
    } catch (e) {
      print('Error scheduling notification: $e');
      // Fallback to in-app only
      _scheduledReminders.add(reminder);
    }
  }

  Future<void> cancelNotification(String reminderId) async {
    try {
      // Remove from our local list
      _scheduledReminders.removeWhere((reminder) => reminder.id == reminderId);

      // Cancel the mobile notification
      final int notificationId = reminderId.hashCode;
      await _flutterLocalNotificationsPlugin.cancel(notificationId);

      print('Canceled mobile notification for reminder: $reminderId');
    } catch (e) {
      print('Error canceling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      // Clear our local list
      _scheduledReminders.clear();

      // Cancel all mobile notifications
      await _flutterLocalNotificationsPlugin.cancelAll();

      print('Canceled all mobile notifications');
    } catch (e) {
      print('Error canceling all notifications: $e');
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }
      return true; // Assume enabled for iOS
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  Future<void> requestPermissions() async {
    await _requestPermissions();
  }

  void dispose() {
    _reminderCheckTimer?.cancel();
    _notificationCallbacks.clear();
    _scheduledReminders.clear();
  }

  // Method to check for overdue reminders immediately (called when app starts)
  Future<void> checkForOverdueReminders() async {
    try {
      final now = DateTime.now();
      print('NotificationService: Checking for overdue reminders...');

      // Load all existing reminders from the database
      final reminderService = ReminderService();
      final allReminders = await reminderService.getAllReminders();

      print('NotificationService: Found ${allReminders.length} total reminders');

      // Check each reminder for being overdue or due
      for (final reminder in allReminders) {
        if (!reminder.isCompleted) {
          // Check if reminder is overdue
          if (reminder.date.isBefore(now)) {
            print('NotificationService: Found overdue reminder: ${reminder.title}');
            await _showOverdueNotification(reminder);

            // Add to scheduled list if not already there
            if (!_scheduledReminders.any((r) => r.id == reminder.id)) {
              _scheduledReminders.add(reminder);
            }
          }
          // Check if reminder is due today (within next 24 hours)
          else if (reminder.date.isBefore(now.add(const Duration(hours: 24)))) {
            // Add to scheduled list for periodic checking
            if (!_scheduledReminders.any((r) => r.id == reminder.id)) {
              _scheduledReminders.add(reminder);
              print('NotificationService: Added upcoming reminder to monitoring: ${reminder.title}');

              // Reschedule the mobile notification to ensure it's properly set
              await _rescheduleNotification(reminder);
            }
          }
        }
      }

      print('NotificationService: Now monitoring ${_scheduledReminders.length} active reminders');
    } catch (e) {
      print('Error checking for overdue reminders: $e');
    }
  }

  // Helper method to reschedule a notification
  Future<void> _rescheduleNotification(Reminder reminder) async {
    try {
      final now = DateTime.now();

      // Only reschedule if the reminder is in the future
      if (reminder.date.isAfter(now)) {
        // Cancel any existing notification first
        final int notificationId = reminder.id.hashCode;
        await _flutterLocalNotificationsPlugin.cancel(notificationId);

        // Schedule the notification
        final scheduledDate = tz.TZDateTime.from(reminder.date, tz.local);

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          '🐕 ${reminder.title}',
          'Time for ${reminder.title} for your pet!',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'pet_reminders',
              'Pet Reminders',
              channelDescription: 'Notifications for pet care reminders',
              importance: Importance.high,
              priority: Priority.high,
              showWhen: true,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: reminder.id,
        );

        print('NotificationService: Rescheduled notification for ${reminder.title} at ${reminder.date}');
      }
    } catch (e) {
      print('Error rescheduling notification: $e');
    }
  }

  Future<void> showTestNotification() async {
    try {
      print('NotificationService: Attempting to show test notification...');

      // Check if notifications are enabled first
      final enabled = await areNotificationsEnabled();
      print('NotificationService: Notifications enabled: $enabled');

      if (!enabled) {
        print('NotificationService: Requesting permissions...');
        await requestPermissions();

        // Check again after requesting
        final enabledAfter = await areNotificationsEnabled();
        print('NotificationService: Notifications enabled after request: $enabledAfter');
      }

      await _flutterLocalNotificationsPlugin.show(
        999,
        '🐕 DogShield Test',
        'Mobile notifications are working! Time: ${DateTime.now().toString().substring(11, 19)}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pet_reminders',
            'Pet Reminders',
            channelDescription: 'Notifications for pet care reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            showWhen: true,
            enableVibration: true,
            playSound: true,
            autoCancel: true,
            ongoing: false,
          ),
          iOS: DarwinNotificationDetails(sound: 'default', presentAlert: true, presentBadge: true, presentSound: true),
        ),
      );

      print('NotificationService: Test notification sent successfully');
    } catch (e) {
      print('NotificationService: Error showing test notification: $e');
      rethrow;
    }
  }

  // Debug method to check scheduled notifications
  Future<void> debugScheduledNotifications() async {
    try {
      print('=== NOTIFICATION DEBUG INFO ===');
      print('Current time: ${DateTime.now()}');
      print('Monitored reminders: ${_scheduledReminders.length}');

      for (final reminder in _scheduledReminders) {
        final now = DateTime.now();
        final timeDiff = reminder.date.difference(now);
        print('Reminder: ${reminder.title}');
        print('  Scheduled for: ${reminder.date}');
        print('  Time until due: ${timeDiff.inMinutes} minutes');
        print('  Is completed: ${reminder.isCompleted}');
        print('  Is overdue: ${reminder.date.isBefore(now)}');
        print('  Is due soon: ${reminder.date.isBefore(now.add(const Duration(minutes: 5)))}');
        print('---');
      }

      // Check all reminders from database
      final reminderService = ReminderService();
      final allReminders = await reminderService.getAllReminders();
      print('Total reminders in database: ${allReminders.length}');

      for (final reminder in allReminders) {
        if (!reminder.isCompleted) {
          final now = DateTime.now();
          final timeDiff = reminder.date.difference(now);
          print('DB Reminder: ${reminder.title}');
          print('  Scheduled for: ${reminder.date}');
          print('  Time until due: ${timeDiff.inMinutes} minutes');
          print('  Is overdue: ${reminder.date.isBefore(now)}');
          print('---');
        }
      }
      print('=== END DEBUG INFO ===');
    } catch (e) {
      print('Error in debug: $e');
    }
  }

  // Get notification settings for debugging
  Future<Map<String, dynamic>> getNotificationStatus() async {
    try {
      final enabled = await areNotificationsEnabled();

      return {
        'enabled': enabled,
        'platform': 'android', // or get actual platform
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'enabled': false, 'error': e.toString(), 'timestamp': DateTime.now().toIso8601String()};
    }
  }

  // Method to check if background monitoring is active
  bool isBackgroundMonitoringActive() {
    final isActive = _reminderCheckTimer?.isActive ?? false;
    print('NotificationService: Background monitoring active: $isActive');
    print('NotificationService: Tracking ${_sentNotifications.length} sent notifications');
    return isActive;
  }
}
