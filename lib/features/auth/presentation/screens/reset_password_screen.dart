import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import 'login_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();

  bool validatePasswordNow = false;
  bool validateConfirmPasswordNow = false;

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    passwordFocus.addListener(() {
      if (!passwordFocus.hasFocus) {
        setState(() => validatePasswordNow = true);
        _formKey.currentState?.validate();
      }
    });

    confirmPasswordFocus.addListener(() {
      if (!confirmPasswordFocus.hasFocus) {
        setState(() => validateConfirmPasswordNow = true);
        _formKey.currentState?.validate();
      }
    });
  }

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(widget.email, passwordController.text.trim());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      final error =
          ref.read(authControllerProvider).error ?? "Password reset failed";

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.cyanDim),
      filled: true,
      fillColor: AppColors.card,

      // Normal / default border
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),

      // Normal enabled field
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),

      // ⭐ When user clicks / focuses the field
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cyanDim, width: 1.8),
      ),

      // Validation error
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),

      // Focused + validation error
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.red, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        title: const Text(
          "Reset Password",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                const Text(
                  "Create a new password for your account.",
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.textPrimaryDark,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // ─────────────────────────────
                // EMAIL LABEL
                // ─────────────────────────────
                const Text(
                  "Email",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryDark,
                  ),
                ),

                const SizedBox(height: 8),

                // ─────────────────────────────
                // EMAIL FIELD
                // ─────────────────────────────
                TextFormField(
                  initialValue: widget.email,
                  readOnly: true,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimaryDark,
                  ),
                  decoration: InputDecoration(
                    // No labelText here.
                    // This removes the "Email" text
                    // appearing inside/floating on the box.
                    hintText: null,

                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.cyanDim,
                    ),

                    filled: true,
                    fillColor: AppColors.card,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.cyanDim,
                        width: 1.5,
                      ),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.cyanDim,
                        width: 1.8,
                      ),
                    ),

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  "New Password",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryDark,
                  ),
                ),

                const SizedBox(height: 8),

                // ─────────────────────────────
                // NEW PASSWORD FIELD
                // ─────────────────────────────
                TextFormField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  obscureText: hidePassword,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimaryDark,
                  ),
                  autovalidateMode: validatePasswordNow
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  decoration: InputDecoration(
                    hintText: "New Password",

                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.cyanDim,
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => hidePassword = !hidePassword),
                    ),

                    filled: true,
                    fillColor: AppColors.card,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.cyanDim,
                        width: 1.8,
                      ),
                    ),

                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.red,
                        width: 1.5,
                      ),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.red,
                        width: 1.8,
                      ),
                    ),

                    errorStyle: const TextStyle(
                      color: AppColors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    errorMaxLines: 2,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                  ),
                  validator: (value) =>
                      Validators.validateStrongPassword(value ?? ''),
                ),

                const SizedBox(height: 24),

                // ─────────────────────────────
                // CONFIRM PASSWORD LABEL
                // ─────────────────────────────
                const Text(
                  "Confirm Password",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryDark,
                  ),
                ),

                const SizedBox(height: 8),

                // ─────────────────────────────
                // CONFIRM PASSWORD FIELD
                // ─────────────────────────────
                TextFormField(
                  controller: confirmPasswordController,
                  focusNode: confirmPasswordFocus,
                  obscureText: hideConfirmPassword,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimaryDark,
                  ),
                  autovalidateMode: validateConfirmPasswordNow
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  decoration: InputDecoration(
                    hintText: "Confirm Password",

                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),

                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.cyanDim,
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        hideConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(
                        () => hideConfirmPassword = !hideConfirmPassword,
                      ),
                    ),

                    filled: true,
                    fillColor: AppColors.card,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.cyanDim,
                        width: 1.8,
                      ),
                    ),

                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.red,
                        width: 1.5,
                      ),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.red,
                        width: 1.8,
                      ),
                    ),

                    errorStyle: const TextStyle(
                      color: AppColors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    errorMaxLines: 2,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                  ),
                  validator: (value) => Validators.validateConfirmPassword(
                    passwordController.text,
                    value ?? '',
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.textWhite,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: AppColors.textWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Update Password",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
