import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import 'reset_password_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final formKey = GlobalKey<FormState>();
  final otpController = TextEditingController();

  // ============================================================
  // RESEND COOLDOWN (WhatsApp-style escalating wait time)
  //
  // Wait time required BEFORE each resend attempt is allowed:
  //   1st resend -> 60s
  //   2nd resend -> 120s (2 min)
  //   3rd resend -> 300s (5 min)
  //   4th resend -> 900s (15 min), and also flags a backup/fallback
  //                 verification notice
  //   5th resend -> soft-locked for 1 hour (blocks further requests)
  // ============================================================
  static const List<int> _cooldownSchedule = [60, 120, 300, 900];
  static const int _softLockSeconds = 60 * 60; // 1 hour soft lock

  int _resendCount = 0;
  int _secondsLeft = _cooldownSchedule.first; // cooldown before 1st resend
  bool _isLocked = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown(_secondsLeft);
  }

  @override
  void dispose() {
    otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          if (_isLocked) {
            // Soft lock finished — reset the escalation and start fresh.
            _isLocked = false;
            _resendCount = 0;
          }
        });
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _startSoftLock() {
    _isLocked = true;
    _startCountdown(_softLockSeconds);
  }

  String _formatCountdown(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleResend() async {
    if (_isLocked || _secondsLeft > 0) return;

    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(widget.email);

    if (!mounted) return;

    if (!ok) {
      showMessage("Failed to resend OTP");
      return;
    }

    _resendCount++;

    if (_resendCount >= 4) {
      // 4th resend reached — flag the fallback notice, then soft-lock
      // the 5th attempt for the longer cooldown.
      showMessage(
        "OTP resent. Too many requests will pause further attempts for a while.",
      );
      _startSoftLock();
    } else {
      showMessage("OTP resent successfully");
      _startCountdown(_cooldownSchedule[_resendCount]);
    }
  }

  Future<void> verifyOtp() async {
    if (!formKey.currentState!.validate()) return;

    final otp = otpController.text.trim();
    final auth = ref.read(authControllerProvider.notifier);

    // ✅ AWAIT the Future
    final success = await auth.verifyOtp(widget.email, otp);

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: widget.email),
        ),
      );
    } else {
      showMessage("Invalid OTP");
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        title: const Text(
          "OTP Verification",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                const Text(
                  "Verify Code",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Enter the verification code sent to\n${widget.email}",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  "OTP Code",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) => Validators.validateOtp(value ?? ''),
                  decoration: InputDecoration(
                    hintText: "Enter 6 digit OTP",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
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
                        color: AppColors.cyanDim,
                        width: 1.5,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.cyanDim,
                        width: 1.5,
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
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: state.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Verify OTP",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: _secondsLeft > 0
                      ? Text(
                          _isLocked
                              ? "Too many attempts. Try again in ${_formatCountdown(_secondsLeft)}"
                              : "Resend code in ${_formatCountdown(_secondsLeft)}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : TextButton(
                          onPressed: _handleResend,
                          child: const Text(
                            "Resend Code",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
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
