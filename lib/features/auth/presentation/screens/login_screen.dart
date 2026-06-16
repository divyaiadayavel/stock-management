import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/db_helper.dart';
import '../../../../core/utils/responsive_helper.dart'; // Ensure this path matches your directory structure
import 'package:stock_management/features/dashboard/presentation/screens/main_navigation.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  bool hidePassword = true;
  bool rememberMe = false;

  bool validateEmailNow = false;
  bool validatePasswordNow = false;

  // ✅ DYNAMIC BRANDING
  String storeName = "Catalystack";
  String tagline = "Smart Billing for Modern Stores";
  String? logoPath;

  @override
  void initState() {
    super.initState();

    // ✅ LOAD SAVED DATA
    loadBranding();

    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        setState(() {
          validateEmailNow = true;
        });
        formKey.currentState?.validate();
      }
    });

    passwordFocus.addListener(() {
      if (!passwordFocus.hasFocus) {
        setState(() {
          validatePasswordNow = true;
        });
        formKey.currentState?.validate();
      }
    });
  }

  // =========================
  // 🔹 LOAD BRANDING
  // =========================
  Future<void> loadBranding() async {
    try {
      final data = await DBHelper.getProfile();

      if (data != null && mounted) {
        setState(() {
          storeName = data['storeName'] ?? "Catalystack";

          tagline = data['tagline'] ?? "Smart Billing for Modern Stores";

          logoPath = data['logoPath'];
        });
      }
    } catch (_) {
      return;
    }
  }

  // ==========================
  // 🔐 LOGIN USER
  // ==========================
  Future<void> loginUser() async {
    setState(() {
      validateEmailNow = true;
      validatePasswordNow = true;
    });

    if (!formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(emailController.text.trim(), passwordController.text.trim());

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      final error =
          ref.read(authControllerProvider).error ?? "Invalid email or password";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    emailFocus.dispose();
    passwordFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.06,
              vertical: R.sp(context, 20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: EdgeInsets.all(R.sp(context, 24)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(R.radius(context, 28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: R.radius(context, 50),
                              backgroundColor: Colors.blue.shade50,
                              backgroundImage:
                                  logoPath != null && logoPath!.isNotEmpty
                                  ? FileImage(File(logoPath!))
                                  : null,
                              child: (logoPath == null || logoPath!.isEmpty)
                                  ? Icon(
                                      Icons.store,
                                      size: R.icon(context, 45),
                                      color: Colors.blue,
                                    )
                                  : null,
                            ),

                            SizedBox(height: R.sp(context, 18)),

                            Text(
                              storeName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: R.fs(context, 28),
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),

                            SizedBox(height: R.sp(context, 8)),

                            Text(
                              tagline,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: R.fs(context, 14),
                                color: Colors.black54,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: R.sp(context, 35)),

                      /// EMAIL
                      Text(
                        "Email Address",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: R.fs(context, 15),
                        ),
                      ),

                      SizedBox(height: R.sp(context, 10)),

                      TextFormField(
                        controller: emailController,
                        focusNode: emailFocus,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: R.fs(context, 14)),
                        autovalidateMode: validateEmailNow
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Email is required";
                          }

                          final emailRegex = RegExp(
                            r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$',
                          );

                          if (!emailRegex.hasMatch(value.trim())) {
                            return "Enter valid email (example@gmail.com)";
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(passwordFocus);
                        },
                        decoration: inputDecoration(
                          "Enter your email",
                          Icons.email_outlined,
                        ),
                      ),

                      SizedBox(height: R.sp(context, 22)),

                      /// PASSWORD
                      Text(
                        "Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: R.fs(context, 15),
                        ),
                      ),

                      SizedBox(height: R.sp(context, 10)),

                      TextFormField(
                        controller: passwordController,
                        focusNode: passwordFocus,
                        obscureText: hidePassword,
                        style: TextStyle(fontSize: R.fs(context, 14)),
                        autovalidateMode: validatePasswordNow
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required";
                          }

                          if (value.length < 6) {
                            return "Minimum 6 characters required";
                          }

                          return null;
                        },
                        decoration: inputDecoration(
                          "Enter your password",
                          Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: R.icon(context, 22),
                            ),
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                          ),
                        ),
                        onFieldSubmitted: (_) => loginUser(),
                      ),

                      SizedBox(height: R.sp(context, 14)),

                      /// REMEMBER + FORGOT
                      Row(
                        children: [
                          SizedBox(
                            height: R.fluid(context, 22, 26),
                            width: R.fluid(context, 22, 26),
                            child: Checkbox(
                              value: rememberMe,
                              activeColor: AppColors.primary,
                              onChanged: (v) {
                                setState(() {
                                  rememberMe = v ?? false;
                                });
                              },
                            ),
                          ),

                          SizedBox(width: R.sp(context, 10)),

                          Expanded(
                            child: Text(
                              "Remember me",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: R.fs(context, 13)),
                            ),
                          ),

                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.symmetric(
                                horizontal: R.fluid(context, 8, 12),
                                vertical: R.fluid(context, 8, 12),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: R.fs(context, 13),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: R.sp(context, 22)),

                      /// LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: R.btnH(context),
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                R.radius(context, 16),
                              ),
                            ),
                          ),
                          child: authState.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontSize: R.fs(context, 17),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================
  // 🔹 INPUT DESIGN
  // ==========================
  InputDecoration inputDecoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black45),
      prefixIcon: Icon(icon, color: Colors.black54, size: R.icon(context, 22)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xfff7f8fa),
      contentPadding: EdgeInsets.symmetric(
        horizontal: R.fluid(context, 16, 20),
        vertical: R.fluid(context, 18, 22),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 16)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 16)),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 16)),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.radius(context, 16)),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
