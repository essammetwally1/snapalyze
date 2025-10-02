import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/authentication/auth_screen.dart';
import 'package:snapalyze/components/root_decider.dart';
import 'package:snapalyze/onboarding/onboarding_screen.dart';
import 'package:snapalyze/providers/user_provider.dart';
import 'package:snapalyze/screens/analysis_screen.dart';
import 'package:snapalyze/screens/home_screen.dart';
import 'package:snapalyze/screens/resize_screen.dart';
import 'package:snapalyze/screens/search_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const Snapalyze(),
    ),
  );
}

class Snapalyze extends StatelessWidget {
  const Snapalyze({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        AnalysisScreen.routeName: (context) => const AnalysisScreen(),
        ResizeScreen.routeName: (context) => const ResizeScreen(),
        SearchScreen.routeName: (context) => const SearchScreen(),
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        AuthScreen.routeName: (context) => const AuthScreen(),
      },
      home: const RootDecider(),
    );
  }
}
