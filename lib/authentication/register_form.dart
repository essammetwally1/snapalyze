import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/components/custom_elevetedbutton.dart';
import 'package:snapalyze/components/custom_textfeild.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onForgotPasswordPressed;
  final VoidCallback? onCreateAccountPressed;
  final Function(bool)? move;

  const RegisterForm({
    super.key,
    this.onLoginPressed,
    this.onForgotPasswordPressed,
    this.onCreateAccountPressed,
    this.move,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(height: size.height * .1),
        Text('Register', style: textTheme.labelSmall),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: globalKey,
              child: Column(
                // void register() {
                //   if (globalKey.currentState!.validate()) {
                //     if (passwordController.text != confirmPasswordController.text) {
                //       Utilis.showErrorMessage('Passwords do not match');
                //       return;
                //     }
                //     registerUser();
                //   }
                // }
                children: [
                  SizedBox(height: size.height * .1),
                  CustomTextField(
                    iconPathName: 'profile',
                    hintText: 'Enter your user name',
                    isPassword: false,
                    isEmail: false,
                    controller: nameController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter Your Name';
                      } else {
                        return null;
                      }
                    },
                  ),

                  SizedBox(height: 24),

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
                    controller: passwordController,
                    hintText: 'Password',
                    iconPathName: 'password',
                    isPassword: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter password';
                      } else if (value.length < 9) {
                        return 'Password must be at least 9 characters';
                      } else if (!RegExp(r'^(?=.*[a-z])').hasMatch(value)) {
                        return 'Password must contain lowercase letter';
                      } else if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
                        return 'Password must contain uppercase letter';
                      } else if (!RegExp(r'^(?=.*[0-9])').hasMatch(value)) {
                        return 'Password must contain number';
                      } else if (!RegExp(
                        r'^(?=.*[!@#$%^&*(),.?":{}|<>])',
                      ).hasMatch(value)) {
                        return 'Password must contain special character';
                      } else {
                        return null;
                      }
                    },
                  ),

                  SizedBox(height: 24),

                  // confirm password Field
                  CustomTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    iconPathName: 'password',
                    isPassword: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter confirm password';
                      } else if (value != passwordController.text) {
                        return 'Passwords do not match';
                      } else {
                        return null;
                      }
                    },
                  ),

                  SizedBox(height: 24),

                  // phone number Field
                  CustomTextField(
                    controller: phoneController,
                    hintText: 'Phone Number',
                    iconPathName: 'phone',
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter phone number';
                      } else if (!value.startsWith('+2')) {
                        return 'Phone number must start with +2';
                      } else if (!RegExp(r'^\+2[0-9]{11}$').hasMatch(value)) {
                        return 'Enter valid phone number (+2 followed by 11 digits)';
                      } else {
                        return null;
                      }
                    },
                  ),

                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already Have Account ?',
                        style: textTheme.titleSmall,
                      ),
                      TextButton(
                        onPressed: () {
                          widget.move!(true);
                        },
                        child: Text(
                          'Login',
                          style: textTheme.titleMedium!.copyWith(
                            color: AppTheme.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Create Account Button
                  CustomElevatedButton(
                    isLoading: isLoading,
                    text: 'Create Account',
                    onPressed: () {
                      if (globalKey.currentState!.validate()) {
                        log('Register button pressed');
                        widget.onCreateAccountPressed?.call();
                      }
                    },
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
