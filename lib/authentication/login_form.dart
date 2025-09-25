import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snapalyze/components/custom_elevetedbutton.dart';
import 'package:snapalyze/components/custom_textfeild.dart';

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
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool rememberMe = false;

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
                if (value!.isEmpty) {
                  return 'Enter e-mail';
                } else if (!value.contains('@gmail.com')) {
                  return 'Enter valid e-mail';
                }
                return null;
              },
            ),

            SizedBox(height: 20),

            // Password Field
            CustomTextField(
              iconPathName: 'password',
              hintText: 'Enter your password',
              isPassword: true,
              isEmail: false,
              controller: passwordController,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Enter password';
                } else if (value.length < 9) {
                  return 'Password must be at least 9 characters';
                }
                return null;
              },
            ),

            SizedBox(height: 24),

            // Login Button
            CustomElevatedButton(
              isLoading: isLoading,
              text: 'Login',
              onPressed: _handleLogin,
            ),

            SizedBox(height: 32),

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

            SizedBox(height: 32),

            // Create Account Button
            CustomElevatedButton(
              text: 'Create a new Account',
              onPressed: () {
                widget.move?.call(false);
              },
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _handleLogin() {
    if (globalKey.currentState!.validate()) {
      setState(() => isLoading = true);

      HapticFeedback.lightImpact();
      Fluttertoast.showToast(msg: 'Logging in...');

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => isLoading = false);
        }
        widget.onLoginPressed?.call();
      });
    }
  }
}
