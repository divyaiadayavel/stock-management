import 'package:flutter/material.dart';

import '../../../../../../core/constants/app_colors.dart';

/// A standalone button that triggers a test print and shows an inline
/// result indicator (success / failure) without navigating away.
///
/// [onPressed] should return `true` on success, `false` on failure.
class TestPrintButton extends StatefulWidget {
  const TestPrintButton({super.key, required this.onPressed});

  final Future<bool> Function() onPressed;

  @override
  State<TestPrintButton> createState() => _TestPrintButtonState();
}

class _TestPrintButtonState extends State<TestPrintButton> {
  _Stage _stage = _Stage.idle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _bgColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _stage == _Stage.printing ? null : _run,
        icon: _icon,
        label: Text(
          _label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  Future<void> _run() async {
    setState(() => _stage = _Stage.printing);
    final ok = await widget.onPressed();
    setState(() => _stage = ok ? _Stage.success : _Stage.failure);

    // Reset back to idle after a short delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _stage = _Stage.idle);
  }

  String get _label {
    switch (_stage) {
      case _Stage.idle:
        return 'Print Test Receipt';
      case _Stage.printing:
        return 'Printing…';
      case _Stage.success:
        return 'Print Successful';
      case _Stage.failure:
        return 'Print Failed';
    }
  }

  Widget get _icon {
    switch (_stage) {
      case _Stage.idle:
        return const Icon(Icons.print_outlined, size: 18);
      case _Stage.printing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
        );
      case _Stage.success:
        return const Icon(Icons.check_circle_outline, size: 18);
      case _Stage.failure:
        return const Icon(Icons.error_outline, size: 18);
    }
  }

  Color get _bgColor {
    switch (_stage) {
      case _Stage.idle:
      case _Stage.printing:
        return AppColors.primary;
      case _Stage.success:
        return AppColors.green;
      case _Stage.failure:
        return AppColors.red;
    }
  }
}

enum _Stage { idle, printing, success, failure }
