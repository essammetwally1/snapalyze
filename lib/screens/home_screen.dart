import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/components/home_drawer.dart';
import 'package:snapalyze/providers/user_provider.dart';

class HomeScreen extends StatelessWidget {
  static const String routeName = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser!;

    return Scaffold(
      // Drawer
      drawer: HomeDrawer(),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // remove hamburger
        title: Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.black,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.white,
                      backgroundImage: AssetImage(
                        'assets/avatar/${user.gender}.png',
                      ),
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Text(
                        'snapalyze',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'FjallaOne',
                          decorationColor: AppTheme.primary,
                          shadows: [
                            Shadow(
                              color: AppTheme.primary.withValues(alpha: .5),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      body: Column(
        children: [
          // Image Section (60% height)
          Expanded(
            flex: 6, // 60%
            child: Image.asset(
              'assets/image.jpg',
              fit: BoxFit.cover, // fill width nicely
              width: double.infinity,
            ),
          ),

          // Remaining Section (40% height)
          Expanded(
            flex: 4, // 40%
            child: Center(
              child: Text(
                'Welcome, ${user.name} 👋',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
