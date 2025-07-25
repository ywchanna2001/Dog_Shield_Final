class AppConstants {
  // App information
  static const String appName = 'DogShield AI';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-driven mobile app for pet health management and rabies detection in dogs';
    // Navigation routes
  static const String splashRoute = '/splash';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String petsRoute = '/pets';
  static const String petProfileRoute = '/pet-profile';
  static const String addPetRoute = '/add-pet';
  static const String editPetRoute = '/edit-pet';
  static const String aiDetectionRoute = '/ai-detection';
  static const String cameraRoute = '/camera';
  static const String detectionResultRoute = '/detection-result';
  static const String detectionHistoryRoute = '/detection-history';
  static const String reminderRoute = '/reminders';
  static const String addReminderRoute = '/add-reminder';
  static const String editReminderRoute = '/edit-reminder';
  static const String settingsRoute = '/settings';
  
  // Shared preferences keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String isFirstTimeKey = 'is_first_time';
  static const String themeKey = 'app_theme';
  static const String selectedPetKey = 'selected_pet';
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String petsCollection = 'pets';
  static const String remindersCollection = 'reminders';
  static const String vaccinesCollection = 'vaccines';
  static const String medicationsCollection = 'medications';
  static const String feedingsCollection = 'feedings';
  static const String detectionHistoryCollection = 'detection_history';
  
  // Reminder types
  static const String typeVaccination = 'vaccination';
  static const String typeMedication = 'medication';
  static const String typeFeeding = 'feeding';
  static const String typeDeworming = 'deworming';
  static const String typeCheckup = 'checkup';
  static const String typeGrooming = 'grooming';
  static const String typeOther = 'other';
  
  // Validation constants
  static const int passwordMinLength = 8;
  static const int petNameMinLength = 2;
  static const int petNameMaxLength = 30;
  
  // Assets paths
  static const String imagePath = 'assets/images/';
  static const String animationPath = 'assets/animations/';
  static const String mlModelPath = 'assets/ml_models/';
  
  // AI Detection
  static const double rabiesDetectionThreshold = 0.75; // Confidence threshold
  static const int videoMaxDuration = 30; // seconds
  static const int maxDetectionHistory = 100; // Number of detection records to keep
} 