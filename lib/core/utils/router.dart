import 'package:flutter/material.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';

// Screens
import 'package:dogshield_ai/presentation/screens/auth/login_screen.dart';
import 'package:dogshield_ai/presentation/screens/auth/register_screen.dart';
import 'package:dogshield_ai/presentation/screens/dashboard/home_screen.dart';
import 'package:dogshield_ai/presentation/screens/pet_profile/add_pet_screen.dart';
import 'package:dogshield_ai/presentation/screens/pet_profile/pet_profile_screen.dart';
import 'package:dogshield_ai/presentation/screens/pet_profile/pets_screen.dart';
import 'package:dogshield_ai/presentation/screens/reminders/reminders_screen.dart';
import 'package:dogshield_ai/presentation/screens/reminders/add_reminder_screen.dart';
import 'package:dogshield_ai/presentation/screens/profile/profile_screen.dart';
import 'package:dogshield_ai/presentation/screens/ai_detection/ai_detection_screen.dart';
import 'package:dogshield_ai/presentation/screens/notifications/notifications_screen.dart';
import 'package:dogshield_ai/data/models/pet_model.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppConstants.registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case AppConstants.homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppConstants.addPetRoute:
        return MaterialPageRoute(builder: (_) => const AddPetScreen());

      case AppConstants.aiDetectionRoute:
        return MaterialPageRoute(builder: (_) => const AIDetectionScreen());

      case AppConstants.petProfileRoute:
        final pet = settings.arguments as Pet;
        return MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet));

      case AppConstants.editPetRoute:
        final pet = settings.arguments as Pet;
        return MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet));

      case AppConstants.petsRoute:
        return MaterialPageRoute(builder: (_) => const PetsScreen());

      case AppConstants.profileRoute:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case AppConstants.reminderRoute:
        return MaterialPageRoute(builder: (_) => const RemindersScreen());

      case AppConstants.addReminderRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => AddReminderScreen(args: args));

      case AppConstants.notificationsRoute:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case AppConstants.detectionHistoryRoute:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                appBar: AppBar(title: const Text('Detection History')),
                body: const Center(child: Text('Detection History Screen - To be implemented')),
              ),
        );

      case AppConstants.settingsRoute:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: const Center(child: Text('Settings Screen - To be implemented')),
              ),
        );

      case AppConstants.forgotPasswordRoute:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                appBar: AppBar(title: const Text('Forgot Password')),
                body: const Center(child: Text('Forgot Password Screen - To be implemented')),
              ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Center(child: Text('No route defined for ${settings.name}'))),
        );
    }
  }
}
