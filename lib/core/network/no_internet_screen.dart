import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
class NoInternetScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? title;
  final String? subtitle;

  const NoInternetScreen({
    super.key,
    this.onRetry,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: const Icon(
                    Icons.wifi_off_outlined,
                    size: 42,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  title ?? "No Internet Connection",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    decoration: TextDecoration.none,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  subtitle ??
                      "Please check your internet connection and try again.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black54,
                    decoration: TextDecoration.none,
                  ),
                ),

                const SizedBox(height: 40),

SizedBox(
  width: 180,
  height: 46,
  child: DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1B3A8C),
          Color(0xFF00C8F8),
        ],
      ),
      borderRadius: BorderRadius.circular(100),
    ),
    child: ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(
        Icons.refresh_rounded,
        size: 20,
      ),
      label: const Text(
        "Try Again",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ).copyWith(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
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