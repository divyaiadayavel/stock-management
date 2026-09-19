// lib/features/settings/service_management/presentation/screens/provider_preview_screen.dart

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../data/models/provider_question_model.dart';
import '../../data/models/service_provider_model.dart';
import '../../domain/enums/provider_field_type.dart';

/// SCREEN 4 — "Preview"
///
/// Read-only — exactly what the customer will see. Saving happens on
/// the Add/Edit provider screen underneath; "Edit" here just returns
/// to it, the same way the services preview screen works.
class ProviderPreviewScreen extends StatelessWidget {
  final ServiceProviderModel provider;
  final bool isEditing;

  const ProviderPreviewScreen({
    super.key,
    required this.provider,
    this.isEditing = false,
  });

  String _money(double value) {
    final whole = value.toStringAsFixed(2).split('.').first;
    final buffer = StringBuffer();

    for (var i = 0; i < whole.length; i++) {
      buffer.write(whole[i]);

      final remaining = whole.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return '₹${buffer.toString()}';
  }

  // ─────────────────────────────────────────────
  // READ-ONLY FIELD PREVIEWS
  // ─────────────────────────────────────────────
  Widget _label(BuildContext context, ProviderQuestionModel q) {
    return Padding(
      padding: EdgeInsets.only(bottom: R.sp(context, 6)),
      child: Text(
        q.required ? q.label : '${q.label} (optional)',
        style: TextStyle(
          fontSize: R.fs(context, 13),
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _inputPlaceholder(BuildContext context, String hint) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: R.sp(context, 14),
        vertical: R.sp(context, 14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.radius(context, 10)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        hint,
        style: TextStyle(
          fontSize: R.fs(context, 14),
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _choicePreview(BuildContext context, ProviderQuestionModel q) {
    return Wrap(
      spacing: R.sp(context, 8),
      runSpacing: R.sp(context, 8),
      children: q.options.map((option) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: R.sp(context, 14),
            vertical: R.sp(context, 8),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(R.radius(context, 20)),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            option,
            style: TextStyle(
              fontSize: R.fs(context, 13),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _questionPreview(BuildContext context, ProviderQuestionModel q) {
    Widget field;

    switch (q.type) {
      case ProviderFieldType.choice:
        field = _choicePreview(context, q);
        break;
      case ProviderFieldType.amount:
        field = _inputPlaceholder(context, '₹ amount');
        break;
      case ProviderFieldType.number:
        field = _inputPlaceholder(context, 'Enter number');
        break;
      case ProviderFieldType.date:
        field = _inputPlaceholder(context, 'dd/mm/yyyy');
        break;
      case ProviderFieldType.paragraph:
        field = _inputPlaceholder(context, 'Enter details');
        break;
      case ProviderFieldType.shortText:
        field = _inputPlaceholder(context, 'Enter ${q.label.toLowerCase()}');
        break;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: R.sp(context, 18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context, q),
          field,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = R.hPad(context, base: 20);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPad.left,
                vertical: R.sp(context, 12),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        fontSize: R.fs(context, 20),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: R.sp(context, 12),
                        vertical: R.sp(context, 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          R.radius(context, 20),
                        ),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: R.icon(context, 14),
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: R.fs(context, 12),
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Body ───
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  hPad.left,
                  0,
                  hPad.left,
                  R.sp(context, 20),
                ),
                children: [
                  // Available balance strip
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 14),
                      vertical: R.sp(context, 12),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius:
                          BorderRadius.circular(R.radius(context, 10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Current balance' : 'Opening balance',
                          style: TextStyle(
                            fontSize: R.fs(context, 13),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          _money(provider.balance),
                          style: TextStyle(
                            fontSize: R.fs(context, 15),
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: R.sp(context, 20)),

                  ...provider.questionModels.map(
                    (q) => _questionPreview(context, q),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
