import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  bool hidePassword = true;

  bool validateNameNow = false;
  bool validateEmailNow = false;
  bool validatePasswordNow = false;

  @override
  void initState() {
    super.initState();

    nameFocus.addListener(() {
      if (!nameFocus.hasFocus) {
        setState(() => validateNameNow = true);
        _formKey.currentState?.validate();
      }
    });

    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        setState(() => validateEmailNow = true);
        _formKey.currentState?.validate();
      }
    });

    passwordFocus.addListener(() {
      if (!passwordFocus.hasFocus) {
        setState(() => validatePasswordNow = true);
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  // Validators (delegated to the shared Validators utility so every
  // screen enforces the same trim / email / strong-password rules).
  String? validateName(String? value) => Validators.validateName(value ?? '');

  String? validateEmail(String? value) => Validators.validateEmail(value ?? '');

  String? validatePassword(String? value) =>
      Validators.validateStrongPassword(value ?? '');

  void register() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(authControllerProvider.notifier)
        .register(name.text.trim(), email.text.trim(), password.text.trim());
  }

  // Shared decoration: cyanDim border on focus, red border + red error
  // text when a field fails validation. Only the email/password (and
  // name) fields are touched here — nothing else on this screen changes.
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyanDim, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      errorStyle: const TextStyle(
        color: AppColors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      errorMaxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.error == null && !next.isLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Registration Success")));
        Navigator.pop(context);
      }

      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: name,
                focusNode: nameFocus,
                textInputAction: TextInputAction.next,
                autovalidateMode: validateNameNow
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                validator: validateName,
                decoration: _inputDecoration("Name"),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: email,
                focusNode: emailFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: validateEmailNow
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                validator: validateEmail,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(passwordFocus),
                decoration: _inputDecoration("Email"),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: password,
                focusNode: passwordFocus,
                obscureText: hidePassword,
                autovalidateMode: validatePasswordNow
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                validator: validatePassword,
                decoration: _inputDecoration("Password").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => hidePassword = !hidePassword),
                  ),
                ),
                onFieldSubmitted: (_) => register(),
              ),

              const SizedBox(height: 20),

              authState.isLoading
                  ? const CircularProgressIndicator()
                  : CustomButton(text: "Register", onPressed: register),
            ],
          ),
        ),
      ),
    );
  }
}
