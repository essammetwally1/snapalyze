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
  Color genderColor = AppTheme.white;
  bool isLoading = false;
  String? selectedGender;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: globalKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: size.height * 0.05),
            Text('Register', style: textTheme.labelSmall),

            // Gender Selection Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Male Avatar
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedGender = 'male';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedGender == 'male'
                                ? AppTheme.blue.withOpacity(
                                    0.1,
                                  ) // Fixed: use withOpacity instead of withValues
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedGender == 'male'
                                  ? AppTheme.blue
                                  : Colors.grey.shade300,
                              width: selectedGender == 'male' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/avatar/male.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Icon(Icons.person, size: 30),
                                  );
                                },
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Male',
                                style: textTheme.titleSmall!.copyWith(
                                  color: selectedGender == 'male'
                                      ? AppTheme.blue
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 40),

                      // Female Avatar
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedGender = 'female';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedGender == 'female'
                                ? AppTheme.blue.withOpacity(
                                    0.1,
                                  ) // Fixed: use withOpacity
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedGender == 'female'
                                  ? AppTheme.blue
                                  : Colors.grey.shade300,
                              width: selectedGender == 'female' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/avatar/female.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Icon(Icons.person_outline, size: 30),
                                  );
                                },
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Female',
                                style: textTheme.titleSmall!.copyWith(
                                  color: selectedGender == 'female'
                                      ? AppTheme.blue
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (selectedGender == null)
                    Text(
                      'select your gender',
                      style: textTheme.titleSmall!.copyWith(color: genderColor),
                    ),
                ],
              ),
            ),

            // Form Fields
            CustomTextField(
              iconPathName: 'profile',
              hintText: 'Enter your user name',
              isPassword: false,
              isEmail: false,
              controller: nameController,
              validator: (value) {
                if (value!.isEmpty) return 'Enter Your Name';
                return null;
              },
            ),

            SizedBox(height: 16),

            CustomTextField(
              iconPathName: 'mail',
              hintText: 'Enter your email',
              isPassword: false,
              isEmail: true,
              controller: emailController,
              validator: (value) {
                if (value!.isEmpty) return 'Enter e-mail';
                if (!value.contains('@gmail.com')) return 'Enter valid e-mail';
                return null;
              },
            ),

            SizedBox(height: 16),

            CustomTextField(
              controller: passwordController,
              hintText: 'Password',
              iconPathName: 'password',
              isPassword: true,
              validator: (value) {
                if (value!.isEmpty) return 'Enter password';
                if (value.length < 9) {
                  return 'Password must be at least 9 characters';
                }
                if (!RegExp(r'^(?=.*[a-z])').hasMatch(value)) {
                  return 'Password must contain lowercase letter';
                }
                if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
                  return 'Password must contain uppercase letter';
                }
                if (!RegExp(r'^(?=.*[0-9])').hasMatch(value)) {
                  return 'Password must contain number';
                }
                if (!RegExp(r'^(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
                  return 'Password must contain special character';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            CustomTextField(
              controller: confirmPasswordController,
              hintText: 'Confirm Password',
              iconPathName: 'password',
              isPassword: true,
              validator: (value) {
                if (value!.isEmpty) return 'Enter confirm password';
                if (value != passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            CustomTextField(
              controller: phoneController,
              hintText: 'Phone Number',
              iconPathName: 'phone',
              validator: (value) {
                if (value!.isEmpty) return 'Enter phone number';
                if (!value.startsWith('+2')) {
                  return 'Phone number must start with +2';
                }
                if (!RegExp(r'^\+2[0-9]{11}$').hasMatch(value)) {
                  return 'Enter valid phone number (+2 followed by 11 digits)';
                }
                return null;
              },
            ),

            SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already Have Account ?', style: textTheme.titleSmall),
                TextButton(
                  onPressed: () => widget.move!(true),
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

            CustomElevatedButton(
              isLoading: isLoading,
              text: 'Create Account',
              onPressed: () {
                if (selectedGender == null) {
                  setState(() {
                    genderColor = AppTheme.red;
                  });
                }

                if (globalKey.currentState!.validate()) {
                  log('Register button pressed - Gender: $selectedGender');
                  widget.onCreateAccountPressed?.call();
                }
              },
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
