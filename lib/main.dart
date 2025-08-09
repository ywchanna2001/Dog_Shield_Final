import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';
import 'package:dogshield_ai/core/constants/app_theme.dart';
import 'package:dogshield_ai/core/utils/router.dart';
import 'package:dogshield_ai/core/auth/auth_wrapper.dart';
import 'package:dogshield_ai/services/notification_service.dart';
import 'package:dogshield_ai/data/services/reminder_service.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('is_dark_mode') ?? false;

  // Initialize Firebase
  bool firebaseInitialized = false;
  try {
    // Check if Firebase is already initialized
    try {
      Firebase.app();
      firebaseInitialized = true;
      print('Firebase already initialized');
    } catch (e) {
      // Firebase not initialized, so initialize it
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.appAttest,
      );

      firebaseInitialized = true;
      print('Firebase initialized successfully');
    }
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    print('App will run with limited functionality');
  }

  // ALWAYS Initialize notification service regardless of Firebase status
  try {
    print('*** DogShield: Starting notification service initialization ***');
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('*** DogShield: Notification service initialized with 30-second background monitoring ***');

    // Initialize reminder service and set up the connection
    final reminderService = ReminderService();
    reminderService.setNotificationService(notificationService);
    print('*** DogShield: Services connected successfully ***');

    // Check for overdue reminders when app starts
    await notificationService.checkForOverdueReminders();
    print('*** DogShield: Completed initial overdue reminder check ***');
  } catch (e) {
    print('*** DogShield: CRITICAL ERROR - Failed to initialize notification service: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(isDarkMode),
      child: DogShieldApp(firebaseInitialized: firebaseInitialized),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;

  ThemeProvider(this._isDarkMode);

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;

    // Save theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);

    notifyListeners();
  }
}

class DogShieldApp extends StatelessWidget {
  final bool firebaseInitialized;

  const DogShieldApp({super.key, this.firebaseInitialized = false});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          theme: themeProvider.themeData,
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRouter.generateRoute,
          home: const AuthWrapper(), // Use AuthWrapper instead of initialRoute
          builder: (context, child) {
            if (!firebaseInitialized) {
              return _buildFirebaseWarningBanner(context, child);
            }
            return child!;
          },
        );
      },
    );
  }

  Widget _buildFirebaseWarningBanner(BuildContext context, Widget? child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Column(
          children: [
            Container(
              color: Colors.amber,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Running with limited functionality. Firebase is not initialized. See SETUP_GUIDE.md for instructions.',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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
