import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapalyze/providers/user_provider.dart';
import 'package:snapalyze/screens/home_screen.dart';
import 'package:snapalyze/authentication/auth_screen.dart';

class RootDecider extends StatefulWidget {
  const RootDecider({super.key});

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    // Load saved session (if any) once
    _initFuture = context.read<UserProvider>().loadFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final userProv = context.watch<UserProvider>();
        // If remembered and we have a user → Home; else → Auth
        if (userProv.rememberMe && userProv.isLoggedIn) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
