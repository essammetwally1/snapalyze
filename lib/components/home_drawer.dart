import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/providers/user_provider.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser!;

    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      backgroundColor: AppTheme.primary.withValues(alpha: .3),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: AppTheme.white,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: AssetImage(
                    'assets/avatar/${user.gender}.png',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
