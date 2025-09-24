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
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(height: size.height * .1),
        Text('Login', style: textTheme.labelSmall),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),

            child: Form(
              key: globalKey,
              child: Column(
                children: [
                  SizedBox(height: size.height * .1),

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
                      } else {
                        return null;
                      }
                    },
                  ),

                  SizedBox(height: 24),

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
                        return 'Enter valid password -more than 9 letters-';
                      } else {
                        return null;
                      }
                    },
                  ),

                  SizedBox(height: 24),

                  // Login & Forgot Password Buttons Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: CustomElevatedButton(
                      isLoading: isLoading,

                      text: 'Login',
                      onPressed: () {
                        if (globalKey.currentState!.validate()) {
                          HapticFeedback.lightImpact();
                          Fluttertoast.showToast(msg: 'Login button pressed');
                          widget.onLoginPressed?.call();
                        }
                      },
                    ),
                  ),

                  SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: Divider(thickness: 2, indent: 50)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text('OR', style: textTheme.titleMedium),
                      ),

                      Expanded(child: Divider(thickness: 2, endIndent: 50)),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Create Account Button
                  CustomElevatedButton(
                    text: 'Create a new Account',
                    onPressed: () {
                      widget.move!(false);
                      if (globalKey.currentState!.validate()) {
                        HapticFeedback.lightImpact();
                        Fluttertoast.showToast(msg: 'Login button pressed');
                        widget.onLoginPressed?.call();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
