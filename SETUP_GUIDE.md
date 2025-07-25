# DogShield AI - Full Features Setup Guide

This guide will walk you through the steps required to enable all features of the DogShield AI application.

## 1. Firebase Setup

### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Enter a project name (e.g., "DogShield AI")
4. Enable Google Analytics if desired
5. Accept terms and create the project

### Configure Flutter App with Firebase

1. Install the FlutterFire CLI:
   ```
   dart pub global activate flutterfire_cli
   ```

2. Configure your Flutter app with Firebase:
   ```
   flutterfire configure --project=your-firebase-project-id
   ```

3. Select the platforms you want to support (Android, iOS, web, etc.)

4. The CLI will generate a `firebase_options.dart` file in your project.

5. Update `main.dart` to use the generated options file:
   ```dart
   import 'firebase_options.dart';
   
   // In the main() function:
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

### Enable Authentication

1. In the Firebase Console, go to "Authentication" > "Sign-in method"
2. Enable "Email/Password" authentication
3. Optionally enable other auth methods like Google, Facebook, etc.

### Set Up Firestore Database

1. Go to "Firestore Database" in Firebase Console
2. Click "Create database"
3. Start in production mode or test mode as needed
4. Choose a location close to your target users
5. Create the following collections:
   - `users`
   - `pets`
   - `reminders`
   - `detection_history`

### Configure Storage

1. Go to "Storage" in Firebase Console
2. Click "Get started"
3. Set up security rules (initially can use test mode)
4. Create the following folders:
   - `pet_images`
   - `detection_media`

## 2. TensorFlow Lite Model Setup

For the AI Detection feature to work properly, you need a TensorFlow Lite model for rabies detection. You have two options:

### Option 1: Use a Pre-trained Model

1. Download a pre-trained image classification model from [TensorFlow Hub](https://tfhub.dev/)
2. Convert it to TFLite format using the [TensorFlow Lite Converter](https://www.tensorflow.org/lite/convert)
3. Place the `.tflite` file in the `assets/ml_models/` directory as `rabies_detection.tflite`
4. Update the labels file if necessary (`assets/ml_models/rabies_labels.txt`)

### Option 2: Train a Custom Model

1. Collect a dataset of dog images with and without rabies symptoms
2. Train a model using TensorFlow (using transfer learning is recommended)
3. Convert the trained model to TFLite format
4. Place the resulting `.tflite` file in the `assets/ml_models/` directory
5. Create a `rabies_labels.txt` file with your model's classes

## 3. Animations and Images

### Lottie Animations

Ensure you have the required Lottie animation files:

1. We've created a placeholder `analyzing.json` file in `assets/animations/`
2. For better visuals, you can replace it with a more professional animation from:
   - [LottieFiles](https://lottiefiles.com/) (many free options available)
   - Search for "scanning", "analyzing", or "processing" animations

### App Images and Icons

1. Create or obtain the following images:
   - App icon (multiple sizes for different platforms)
   - Placeholder pet images
   - UI elements and icons

2. Place them in the `assets/images/` directory

## 4. Configure Notifications

For reminder notifications to work:

### Android Configuration

1. Update `android/app/src/main/AndroidManifest.xml` to include required permissions:
   ```xml
   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
   <uses-permission android:name="android.permission.VIBRATE" />
   <uses-permission android:name="android.permission.WAKE_LOCK" />
   <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
   ```

2. Add the receiver to the application section:
   ```xml
   <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
       <intent-filter>
           <action android:name="android.intent.action.BOOT_COMPLETED" />
           <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
       </intent-filter>
   </receiver>
   ```

### iOS Configuration

1. Update `ios/Runner/Info.plist` to include:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>fetch</string>
       <string>remote-notification</string>
   </array>
   ```

## 5. Troubleshooting Common Issues

### Firebase Connection Issues

If you encounter issues connecting to Firebase:

1. Verify that `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in the correct locations
2. Check your Firebase project settings and make sure the package name matches your app
3. Ensure you've correctly initialized Firebase in `main.dart`

### TFLite Model Issues

If the AI detection doesn't work:

1. Check that your model file is in the correct format and location
2. Verify that the labels file matches your model's output classes
3. Ensure you've properly included the model in `pubspec.yaml` under assets

### Build Issues on Android

If you encounter build issues on Android:

1. Make sure your `compileSdk`, `minSdk`, and `targetSdk` values in `android/app/build.gradle.kts` are appropriate
2. Check that the NDK version is set to `27.0.12077973` or later
3. Enable core library desugaring as shown in your build file

## 6. Testing Full Features

To verify all features are working:

1. Test user registration and login
2. Add a pet profile with image upload
3. Set up a reminder
4. Test the AI detection feature with sample images
5. Verify that pet data is being saved to Firestore

## Next Steps

After completing this setup, you can:

1. Customize the app's theme and branding
2. Improve the ML model for better detection accuracy
3. Add analytics to track app usage
4. Implement more advanced features using Firebase services

For any questions or issues, refer to the Flutter and Firebase documentation or contact the development team. 