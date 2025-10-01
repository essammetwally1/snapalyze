import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/components/custom_elevetedbutton.dart';
import 'package:snapalyze/components/custom_textfeild.dart';
import 'package:snapalyze/consts.dart';
import 'package:snapalyze/models/user_model.dart';
import 'package:snapalyze/providers/user_provider.dart';
import 'package:snapalyze/screens/home_screen.dart';
import 'package:snapalyze/services/firebase_service.dart';
import 'package:snapalyze/utilis.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onForgotPasswordPressed;
  final VoidCallback? onCreateAccountPressed;
  final Function(bool)? move;

  const LoginForm({
    super.key,
    this.onLoginPressed,
    this.onForgotPasswordPressed,
    this.onCreateAccountPressed,
    this.move,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late UserModel user;

  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: globalKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Login', style: textTheme.labelSmall),

            SizedBox(height: size.height * 0.05),

            // Email Field
            CustomTextField(
              iconPathName: 'mail',
              hintText: 'Enter your email',
              isPassword: false,
              isEmail: true,
              controller: emailController,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Enter e-mail';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                  return 'Enter valid e-mail';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Password Field
            CustomTextField(
              iconPathName: 'password',
              hintText: 'Enter your password',
              isPassword: true,
              isEmail: false,
              controller: passwordController,
              validator: (value) {
                final v = value ?? '';
                if (v.isEmpty) return 'Enter password';
                if (v.length < 9) {
                  return 'Password must be at least 9 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 10),

            // Remember me + (optional) Forgot password
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: (val) {
                    setState(() => rememberMe = val ?? false);
                  },
                  // fill color of the box (white when unchecked, still white when checked)
                  fillColor: WidgetStateProperty.resolveWith<Color>(
                    (states) => AppTheme.white,
                  ),
                  // the tick/check color
                  checkColor: AppTheme.primary,
                  // rounded corners
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6), // adjust roundness
                  ),
                  side: const BorderSide(
                    color: Colors.grey, // outline color when unchecked
                    width: 1.5,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(
                  "Remember me",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Login Button
            CustomElevatedButton(
              isLoading: isLoading,
              text: 'Login',
              onPressed: () {
                FocusScope.of(context).unfocus();
                if (globalKey.currentState!.validate()) {
                  login();
                }
              },
            ),

            const SizedBox(height: 32),

            // OR Divider
            Row(
              children: [
                Expanded(
                  child: Divider(thickness: 1, color: Colors.grey.shade400),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: textTheme.titleMedium),
                ),
                Expanded(
                  child: Divider(thickness: 1, color: Colors.grey.shade400),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Create Account Button
            CustomElevatedButton(
              text: 'Create a new Account',
              onPressed: () => widget.move?.call(false),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> login() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      user = await FirebaseService.logIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Persist remember-me choice + email (if checked)
      await Provider.of<UserProvider>(
        context,
        listen: false,
      ).setUser(user, remember: rememberMe);
      // Update provider with the logged-in user@

      Utilis.showSuccessMessage('Login Success');

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (error) {
      Utilis.showErrorMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
