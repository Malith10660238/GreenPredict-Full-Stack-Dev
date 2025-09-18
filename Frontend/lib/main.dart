import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/crop_provider.dart';
import 'providers/listing_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'utils/app_theme.dart';
import 'screens/ui/animated_buttons_demo.dart';
import 'screens/marketplace/my_listings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase removed temporarily - uncomment when needed:
  // await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
      ],
      child: MaterialApp(
        title: 'Green Predict',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const MainNavigation(),
          '/ui-demo': (context) => const AnimatedButtonsDemo(),
          '/my-listings': (context) => const MyListingsScreen(),
        },
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.lightGradient,
            ),
            child: child,
          );
        },
      ),
    );
  }
}