import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapalyze/shared/app_theme.dart';
import 'package:snapalyze/components/custom_elevetedbutton.dart';
import 'package:snapalyze/components/custom_textfeild.dart';
import 'package:snapalyze/models/user_model.dart';
import 'package:snapalyze/providers/user_provider.dart';
import 'package:snapalyze/screens/home_screen.dart';
import 'package:snapalyze/services/firebase_service.dart';
import 'package:snapalyze/shared/utilis.dart';

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
  Color genderColor = AppTheme.white;
  bool isLoading = false;
  String? selectedGender;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
            Text('Register', style: textTheme.labelSmall),
            SizedBox(height: size.height * 0.05),

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
                                ? AppTheme.blue.withValues(
                                    alpha: 0.1,
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
                                ? AppTheme.blue.withValues(
                                    alpha: 0.1,
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
                } else if (globalKey.currentState!.validate() &&
                    selectedGender != null) {
                  register();
                }
              },
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> register() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    try {
      final UserModel user = await FirebaseService.register(
        name: nameController.text.trim(),
        password: passwordController.text.trim(),
        email: emailController.text.trim(),
        gender: selectedGender!,
      );
      Provider.of<UserProvider>(context, listen: false).setUser(user);

      Utilis.showSuccessMessage('Register Success');
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (error) {
      Utilis.showErrorMessage(error.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
