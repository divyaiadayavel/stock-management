// lib/features/settings/service_management/presentation/screens/preview_service_screen.dart

import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/widgets/dynamic_question_field.dart';
import '../../data/models/service_model.dart';

class PreviewServiceScreen extends StatelessWidget {
  final ServiceModel service;

  const PreviewServiceScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final hPad = R.hPad(context, base: 16);
    final cardRadius = R.radius(context, 10);
    final cardPad = R.sp(context, 14);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top App Bar ─────────────────────────────────────────
            Padding(
              padding: hPad,
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Preview Service',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
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
            const SizedBox(height: 12),

            // ─── Content ─────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: hPad.left),
                children: [
                  // Service Info Card
                  Container(
                    padding: EdgeInsets.all(cardPad),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: R.imgSize(context, 0.1),
                              height: R.imgSize(context, 0.1),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  R.radius(context, 8),
                                ),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Icon(
                                Icons.design_services_outlined,
                                color: AppColors.primary,
                                size: R.icon(context, 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name.isEmpty
                                        ? 'Untitled Service'
                                        : service.name,
                                    style: TextStyle(
                                      fontSize: R.fs(context, 15),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: R.sp(context, 8),
                                      vertical: R.sp(context, 2),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      service.categoryName.isEmpty
                                          ? 'No Category'
                                          : service.categoryName,
                                      style: TextStyle(
                                        fontSize: R.fs(context, 11),
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Form Preview',
                        style: TextStyle(
                          fontSize: R.fs(context, 14),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${service.questions.length} Fields',
                        style: TextStyle(
                          fontSize: R.fs(context, 12),
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (service.questions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: R.sp(context, 32),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(cardRadius),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: R.icon(context, 36),
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No questions configured',
                            style: TextStyle(
                              fontSize: R.fs(context, 14),
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This service does not require custom inputs.',
                            style: TextStyle(
                              fontSize: R.fs(context, 12),
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...service.questions.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: R.sp(context, 10)),
                        child: Container(
                          padding: EdgeInsets.all(cardPad),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(cardRadius),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DynamicQuestionField(
                            index: entry.key + 1,
                            question: entry.value,
                            enabled: false,
                            onChanged: (_) {},
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
