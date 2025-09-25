import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/authentication/auth_screen.dart';
import 'package:snapalyze/onboarding/onboarding_screen.dart';
import 'package:snapalyze/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(Snapalyze());
}

class Snapalyze extends StatelessWidget {
  const Snapalyze({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        HomeScreen.routeName: (context) => HomeScreen(),
        OnboardingScreen.routeName: (context) => OnboardingScreen(),
        AuthScreen.routeName: (context) => AuthScreen(),
      },
      initialRoute: AuthScreen.routeName,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
    );
  }
}
