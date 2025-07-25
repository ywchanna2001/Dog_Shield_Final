# DogShield AI

AI-driven mobile app for pet health management and rabies detection in dogs.

## Features

- **User Authentication**: Secure login and registration system
- **Pet Profiles**: Add and manage your pets' information
- **AI Rabies Detection**: Use ML to detect potential rabies symptoms from images and videos
- **Reminders**: Set reminders for vaccinations, medications, and other pet care activities
- **Detection History**: Keep track of previous detection results

## Setup Instructions

### Prerequisites

- Flutter SDK (3.7.2 or higher)
- Android Studio / VS Code with Flutter plugins
- Android SDK (API level 26 or higher)
- Firebase account

### Environment Setup

1. Clone the repository
   ```
   git clone https://github.com/ywchanna2001/Pet_Care_App_FE.git
   cd Pet_Care_App_FE
   ```

2. Install dependencies
   ```
   flutter pub get
   ```

3. Firebase Configuration

   The app requires Firebase for authentication, database, and storage features.

   a. Create a new Firebase project at https://console.firebase.google.com/

   b. Install the FlutterFire CLI:
      ```
      dart pub global activate flutterfire_cli
      ```
   c. Configure Firebase for your Flutter app:
      ```
      flutterfire configure --project=your-firebase-project-id
      ```
   d. This will generate a `firebase_options.dart` file with your Firebase configuration.

   e. Deploy Firebase security rules:
      ```
      firebase deploy --only firestore:rules,storage:rules
      ```
      See [FIREBASE_RULES_DEPLOYMENT.md](FIREBASE_RULES_DEPLOYMENT.md) for detailed instructions.

### Running the App

```
flutter run
```

## Required Assets

The app needs the following assets in the specified directories:

### Images
- `assets/images/`: Place app images, icons, and logos here

### Animations
- `assets/animations/analyzing.json`: Lottie animation for AI analysis state

## Firebase Configuration

The app requires the following Firebase services:

1. **Authentication**: For user login and registration
   - Enable Email/Password authentication in Firebase Console

2. **Firestore Database**: For storing user and pet data
   - Create the following collections:
     - `users`
     - `pets`
     - `reminders`
     - `detection_history`
   - Deploy the security rules in `firestore.rules` to ensure proper data access control

3. **Storage**: For storing pet images and detection media
   - Set up the security rules from `storage.rules` for appropriate access control
   - Create the following folders:
     - `pet_images/`
     - `detection_media/`
     - `vaccine_records/`

4. **App Check (Required)**: For securing your backend resources
   - Enable App Check in Firebase Console
   - Configure with the debug provider for development (included in the app)
   - Use reCAPTCHA for web deployments

5. **Cloud Messaging (Optional)**: For push notifications
   - Configure FCM if reminder notifications are needed

## Technical Details

- **State Management**: Provider pattern with ChangeNotifier
- **Navigation**: Named routes with AppRouter
- **Theme**: Customizable light and dark themes
- **Security**: Firebase App Check and custom security rules

## Troubleshooting

- **Firebase Connection Issues**: Verify your `google-services.json` and Firebase options
- **Permission Denied Errors**: Check Firebase security rules deployment
- **TFLite Model Errors**: Ensure model format is compatible with TFLite Flutter
- **Build Errors**: Check Android SDK version and NDK compatibility
- **OpenGL Errors**: May appear in emulators but should not affect functionality

## License

MIT
