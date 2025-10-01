import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/models/user_model.dart';
import 'package:snapalyze/providers/user_provider.dart';
import 'package:snapalyze/authentication/auth_screen.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final UserModel userModel = Provider.of<UserProvider>(context).currentUser!;
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      backgroundColor: AppTheme.primary.withValues(alpha: .3),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // top + bottom
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: AppTheme.white,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primary,
                      backgroundImage: AssetImage(
                        'assets/avatar/${userModel.gender}.png',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(userModel.name, style: textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Text(
                    userModel.email,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // 🔻 Logout button at bottom
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.red, // red or your choice
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    // clear provider + prefs
                    await userProvider.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AuthScreen.routeName,
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: Text("Logout", style: textTheme.titleMedium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
