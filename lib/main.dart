import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/core/utils/router.dart';
import 'package:dogshield_ai/core/auth/auth_wrapper.dart';
import 'package:dogshield_ai/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Catch any errors during initialization
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]);

    // Initialize shared preferences
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('is_dark_mode') ?? false;

    // Initialize Firebase
    bool firebaseInitialized = false;
    try {
      try {
        Firebase.app();
        firebaseInitialized = true;
        print('Firebase already initialized');
      } catch (e) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform
        );

        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.appAttest,
        );

        firebaseInitialized = true;
        print('Firebase initialized successfully');
      }
    } catch (e) {
      print('Firebase initialization failed: $e');
      print('App will continue with limited functionality');
    }

    // Initialize notification service - WITH BETTER ERROR HANDLING
    bool notificationInitialized = false;
    try {
      print('Initializing notification service...');
      final notificationService = NotificationService();

      await notificationService.initialize();
      print('Notification service initialized');

      await notificationService.requestPermissions();
      print('Notification permissions requested');

      // Request Android 12+ exact alarm permission
      try {
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      } catch (e) {
        print('Exact alarm permission error (non-critical): $e');
      }

      // Request Android 13+ notification permission
      try {
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }
      } catch (e) {
        print('Notification permission error (non-critical): $e');
      }

      notificationInitialized = true;
      print('Notification service fully initialized');
    } catch (e, stackTrace) {
      print('Notification initialization failed: $e');
      print('Stack trace: $stackTrace');
      print('App will continue without notifications');
    }

    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(isDarkMode),
        child: DogShieldApp(
          firebaseInitialized: firebaseInitialized,
          notificationInitialized: notificationInitialized,
        ),
      ),
    );
  }, (error, stack) {
    print('FATAL ERROR: $error');
    print('Stack trace: $stack');
  });
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;

  ThemeProvider(this._isDarkMode);

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }
}

class DogShieldApp extends StatelessWidget {
  final bool firebaseInitialized;
  final bool notificationInitialized;

  const DogShieldApp({
    super.key,
    this.firebaseInitialized = false,
    this.notificationInitialized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: AppConstants.appName,
          theme: themeProvider.themeData,
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRouter.generateRoute,
          home: const AuthWrapper(),
          builder: (context, child) {
            // Only show warning for critical Firebase failure
            if (!firebaseInitialized) {
              return _buildWarningBanner(context, child);
            }
            // Notification failure is non-critical, just log it
            if (!notificationInitialized) {
              print('Running without notifications');
            }
            return child!;
          },
        );
      },
    );
  }

  Widget _buildWarningBanner(BuildContext context, Widget? child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Column(
          children: [
            Container(
              color: Colors.amber,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Warning: Firebase not initialized. Limited functionality.',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(child: child ?? Container()),
          ],
        ),
      ),
    );
  }
}