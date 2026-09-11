// lib/features/services/presentation/widgets/service_category_card.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../settings/service_management/data/models/service_category_model.dart';

class ServiceCategoryCard extends StatelessWidget {
  final ServiceCategoryModel category;
  final VoidCallback onTap;

  const ServiceCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardRadius = R.radius(context, 10);
    final cardPad = R.sp(context, 12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(cardRadius),
      child: Container(
        padding: EdgeInsets.all(cardPad),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: R.imgSize(context, 0.12),
              height: R.imgSize(context, 0.12),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(R.radius(context, 8)),
              ),
              child: Icon(
                Icons.category_outlined,
                color: AppColors.primary,
                size: R.icon(context, 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: R.fs(context, 14),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.servicesCount} Services Available',
                    style: TextStyle(
                      fontSize: R.fs(context, 12),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: R.icon(context, 20),
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
