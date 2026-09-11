import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../providers/settings_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_config.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  Map<String, dynamic> profileData = {};
  bool isLoading = true;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bundle = await ref.read(settingsControllerProvider.future);

    if (!mounted) return;

    setState(() {
      profileData = bundle.profile.toMap();
      isLoading = false;
    });
  }

  Future<void> _pickBusinessLogo() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .uploadBusinessLogo(File(image.path));

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Business logo updated successfully."),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  // ── Simple, clean edit dialog — plain AlertDialog so Flutter
  //    handles keyboard avoidance automatically (no manual padding hacks) ──
  void _openEditDialog(
    String title,
    String dbKey,
    String currentValue, {
    bool required = true,
  }) {
    final TextEditingController ctrl = TextEditingController(
      text: currentValue,
    );
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleSave() async {
              final newValue = ctrl.text.trim();

              if (required && newValue.isEmpty) {
                setDialogState(() => errorText = "$title cannot be empty");
                return;
              }

              setDialogState(() {
                isSaving = true;
                errorText = null;
              });

              try {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .updateProfileField(dbKey, newValue);

                if (!mounted) return;
                Navigator.pop(dialogContext);
                await _loadData();

                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text("$title updated")),
                );
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                  errorText = "Failed to save. Try again.";
                });
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              title: Text(
                title,
                style: AppTextStyles.cardValue.copyWith(
                  fontSize: 17,
                  fontFamily: AppTextStyles.fontDisplay,
                ),
              ),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
                onSubmitted: (_) => handleSave(),
                style: AppTextStyles.cardValue.copyWith(
                  fontFamily: AppTextStyles.fontBody,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  errorText: errorText,
                  filled: true,
                  fillColor: AppColors.surface2,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: const BorderSide(color: AppColors.red),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isSaving ? null : handleSave,
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          "Save",
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
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

  @override
  Widget build(BuildContext context) {
    final storeName =
        (profileData["storeName"]?.toString().isEmpty ?? true)
            ? "Business Name"
            : profileData["storeName"].toString();

    final tagline =
        (profileData["tagline"]?.toString().isEmpty ?? true)
            ? "Add your business tagline"
            : profileData["tagline"].toString();

    final logoPath = profileData["logoPath"]?.toString() ?? "";

    final logoUrl = logoPath.isEmpty
        ? null
        : logoPath.startsWith("http")
            ? logoPath
            : "${ApiConfig.baseUrl}/$logoPath";

    final businessAddress =
        (profileData['businessAddress']?.toString().isEmpty ?? true)
            ? "Not set"
            : profileData['businessAddress'].toString();

    final phoneNumber =
        (profileData['phoneNumber']?.toString().isEmpty ?? true)
            ? "Not set"
            : profileData['phoneNumber'].toString();

    final emailAddress =
        (profileData['emailAddress']?.toString().isEmpty ?? true)
            ? "Not set"
            : profileData['emailAddress'].toString();

    final gstNumber =
        (profileData['gstNumber']?.toString().isEmpty ?? true)
            ? "Not set"
            : profileData['gstNumber'].toString();

    final taxRegistrationType =
        (profileData['taxRegistrationType']?.toString().isEmpty ?? true)
            ? "Regular"
            : profileData['taxRegistrationType'].toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleSpacing: 0,
        title: Text(
          "Business Profile",
          style: AppTextStyles.cardValue.copyWith(
            fontSize: 22,
            fontFamily: AppTextStyles.fontDisplay,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _logoSection(logoUrl)),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Identity group ───────────────────────────
                  _group([
                    _tile(
                      icon: Icons.store_mall_directory_outlined,
                      iconBg: AppColors.primary,
                      title: "Business Name",
                      value: storeName,
                      dbKey: "storeName",
                    ),
                    _tile(
                      icon: Icons.campaign_outlined,
                      iconBg: AppColors.cyan,
                      title: "Business Tagline",
                      value: tagline,
                      dbKey: "tagline",
                      required: false,
                    ),
                  ]),

                  // ── Contact group ────────────────────────────
                  _group([
                    _tile(
                      icon: Icons.location_on_outlined,
                      iconBg: AppColors.cyan,
                      title: "Business Address",
                      value: businessAddress,
                      dbKey: "businessAddress",
                      required: false,
                    ),
                    _tile(
                      icon: Icons.phone_outlined,
                      iconBg: AppColors.green,
                      title: "Phone Number",
                      value: phoneNumber,
                      dbKey: "phoneNumber",
                      required: false,
                    ),
                    _tile(
                      icon: Icons.email_outlined,
                      iconBg: AppColors.orange,
                      title: "Email Address",
                      value: emailAddress,
                      dbKey: "emailAddress",
                      required: false,
                    ),
                  ]),

                  // ── Tax group ────────────────────────────────
                  _group([
                    _tile(
                      icon: Icons.receipt_long_outlined,
                      iconBg: AppColors.primaryHover,
                      title: "GST Number",
                      value: gstNumber,
                      dbKey: "gstNumber",
                      required: false,
                    ),
                    _tile(
                      icon: Icons.account_balance_wallet_outlined,
                      iconBg: AppColors.cyanDim,
                      title: "Tax Registration Type",
                      value: taxRegistrationType,
                      dbKey: "taxRegistrationType",
                      required: false,
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  // ── Logo only — no name/tagline text underneath ──
  Widget _logoSection(String? logoUrl) {
    return GestureDetector(
      onTap: _pickBusinessLogo,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surface2,
                backgroundImage:
                    logoUrl != null ? NetworkImage(logoUrl) : null,
                child: logoUrl == null
                    ? const Icon(
                        Icons.store,
                        size: 46,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Tap to change logo",
            style: AppTextStyles.small.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Samsung-style bordered card wrapper — matches Settings screen ──
  Widget _groupCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  // ── Group of tiles with a divider inset evenly on both sides ──
  Widget _group(List<Widget> tiles) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i != tiles.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
            ),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
          ),
        );
      }
    }
    return _groupCard(child: Column(children: children));
  }

  // ── Samsung-style tile: solid colored circle + white icon, flat row ──
  Widget _tile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String value,
    required String dbKey,
    bool required = true,
  }) {
    return InkWell(
      onTap: () => _openEditDialog(
        title,
        dbKey,
        (value == "Not set" || value == "Regular") ? "" : value,
        required: required,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(
                icon,
                color: AppColors.textWhite,
                size: AppSizes.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardValue.copyWith(
                      fontSize: 15,
                      fontFamily: AppTextStyles.fontBody,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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