// lib/features/settings/service_management/presentation/widgets/add_category_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/utils/validators.dart';
import '../providers/service_management_provider.dart';

/// Mirrors "Add Category (Popup)" — screen 2 in the reference design.
Future<void> showAddCategoryDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  bool isSaving = false;
  String? nameError;

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(R.radius(context, 10)),
    borderSide: BorderSide(color: Colors.grey.shade300),
  );

  return showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(R.radius(context, 16)),
            ),
            titlePadding: EdgeInsets.fromLTRB(
              R.sp(context, 20),
              R.sp(context, 20),
              R.sp(context, 20),
              R.sp(context, 8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: R.sp(context, 20),
              vertical: R.sp(context, 8),
            ),
            actionsPadding: EdgeInsets.fromLTRB(
              R.sp(context, 16),
              R.sp(context, 8),
              R.sp(context, 16),
              R.sp(context, 16),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(R.sp(context, 8)),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(R.radius(context, 8)),
                  ),
                  child: Icon(
                    Icons.create_new_folder_outlined,
                    color: AppColors.primary,
                    size: R.icon(context, 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Category',
                    style: TextStyle(
                      fontSize: R.fs(context, 18),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Category Name',
                  style: TextStyle(
                    fontSize: R.fs(context, 13),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    fontSize: R.fs(context, 14),
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter category name',
                    hintStyle: TextStyle(
                      fontSize: R.fs(context, 14),
                      color: Colors.grey.shade400,
                    ),
                    errorText: nameError,
                    errorStyle: TextStyle(fontSize: R.fs(context, 11.5)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: R.sp(context, 14),
                      vertical: R.sp(context, 12),
                    ),
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorder.copyWith(
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: inputBorder.copyWith(
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: inputBorder.copyWith(
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (nameError == null) return;

                    setState(() {
                      nameError = Validators.validateCategoryName(value);
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: R.fs(context, 13),
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: isSaving
                    ? null
                    : () async {
                        final error = Validators.validateCategoryName(
                          controller.text,
                        );

                        if (error != null) {
                          setState(() => nameError = error);
                          return;
                        }

                        final name = Validators.normalizeText(
                          controller.text,
                        );
                        setState(() => isSaving = true);
                        final ok = await ref
                            .read(serviceCategoriesProvider.notifier)
                            .addCategory(name);
                        if (context.mounted) {
                          Navigator.pop(dialogContext);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Unable to save category. Please try again.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: R.sp(context, 16),
                    vertical: R.sp(context, 10),
                  ),
                  decoration: BoxDecoration(
                    gradient: isSaving ? null : AppColors.brandGradient,
                    color: isSaving ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(R.radius(context, 20)),
                  ),
                  child: isSaving
                      ? SizedBox(
                          width: R.sp(context, 16),
                          height: R.sp(context, 16),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Category',
                          style: TextStyle(
                            fontSize: R.fs(context, 13),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
