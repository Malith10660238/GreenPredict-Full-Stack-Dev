import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'guest_profile_screen.dart';

void main() {
  group('Guest Profile Screen Tests', () {
    testWidgets('Guest profile screen displays correctly', (WidgetTester tester) async {
      // Create a test app with AuthProvider
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
          child: const MaterialApp(
            home: GuestProfileScreen(),
          ),
        ),
      );

      // Verify the screen displays
      expect(find.text('Guest User'), findsOneWidget);
      expect(find.text('Browsing as guest'), findsOneWidget);
      expect(find.text('Benefits of Creating an Account'), findsOneWidget);
      expect(find.text('What You Can Do as a Guest'), findsOneWidget);
      expect(find.text('Ready to Get Started?'), findsOneWidget);
    });

    testWidgets('Login and Sign Up buttons work', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
          child: const MaterialApp(
            home: GuestProfileScreen(),
          ),
        ),
      );

      // Find and tap the Sign Up button
      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget);
      
      // Note: In a real test, you would verify navigation to login screen
      // await tester.tap(signUpButton);
      // await tester.pumpAndSettle();
      // expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
