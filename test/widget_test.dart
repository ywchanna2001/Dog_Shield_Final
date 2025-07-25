// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dogshield_ai/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(false),
        child: const DogShieldApp(firebaseInitialized: false),
      ),
    );

    // Verify that the app starts and shows some initial content
    await tester.pumpAndSettle();

    // The app should show some content (login screen or similar)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
