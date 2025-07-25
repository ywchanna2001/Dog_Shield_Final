// filepath: d:\Desktop\dogshield_ai\Pet_Care_App_FE\lib\presentation\widgets\bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:dogshield_ai/core/constants/app_constants.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;

  const BottomNavigation({super.key, this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        if (currentIndex == index) return; // Don't navigate if already on this tab

        // Navigate to respective screens
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
            break;
          case 1:
            Navigator.pushReplacementNamed(context, AppConstants.petsRoute);
            break;
          case 2:
            Navigator.pushReplacementNamed(context, AppConstants.reminderRoute);
            break;
          case 3:
            Navigator.pushReplacementNamed(context, AppConstants.aiDetectionRoute);
            break;
          case 4:
            Navigator.pushReplacementNamed(context, AppConstants.profileRoute);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Reminders'),
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'AI Detection'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
