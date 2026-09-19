// lib/features/settings/service_management/presentation/screens/providers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/utils/validators.dart';
import '../../data/models/service_provider_model.dart';
import '../providers/service_provider_provider.dart';
import 'add_provider_screen.dart';

/// SCREEN 1 — "Recharge providers"
///
/// Balance + health per provider, inline "Reload balance" for low ones,
/// and "+ Add provider" in the header.
class ProvidersListScreen extends ConsumerWidget {
  final int? categoryId;
  final String? categoryName;

  const ProvidersListScreen({super.key, this.categoryId, this.categoryName});

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String money(double value) {
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

  Color _accentFor(int index) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFFEA580C),
      Color(0xFF16A34A),
      Color(0xFF9333EA),
      Color(0xFF0D9488),
      Color(0xFFEAB308),
    ];

    return colors[index % colors.length];
  }

  Future<void> _reloadBalance(
    BuildContext context,
    WidgetRef ref,
    ServiceProviderModel provider,
  ) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
        ),
        title: Text(
          'Reload balance',
          style: TextStyle(
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_capitalizeFirstLetter(provider.name)} · current ${money(provider.balance)}',
              style: TextStyle(
                fontSize: R.fs(context, 13),
                color: const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: R.sp(context, 12)),
            TextFormField(
              controller: controller,
              autofocus: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: TextStyle(
                fontSize: R.fs(context, 16),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Amount to add',
                prefixText: '₹ ',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: R.sp(context, 12),
                  vertical: R.sp(context, 12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(
                    color: AppColors.cyanDim,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(R.radius(context, 10)),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.5,
                  ),
                ),
                errorStyle: TextStyle(fontSize: R.fs(context, 11)),
              ),
              validator: (v) => Validators.validateReloadAmount(
                v ?? '',
                fieldName: 'Reload amount',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Reload',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final amountError = Validators.validateReloadAmount(
      controller.text,
      fieldName: 'Reload amount',
    );

    if (amountError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              amountError,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }

      return;
    }

    final amount = double.parse(controller.text.trim());

    final updated = await ref
        .read(providerOperationsProvider.notifier)
        .reloadBalance(provider.id!, amount);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: updated == null
            ? Colors.red.shade700
            : const Color(0xFF16A34A),
        content: Text(
          updated == null
              ? 'Could not reload balance.'
              : 'Balance is now ${money(updated.balance)}.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ServiceProviderModel provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.radius(context, 16)),
        ),
        title: Text(
          'Delete provider?',
          style: TextStyle(
            fontSize: R.fs(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${provider.name}"?',
          style: TextStyle(
            fontSize: R.fs(context, 13),
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && provider.id != null) {
      await ref
          .read(providerOperationsProvider.notifier)
          .removeProvider(provider.id!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = categoryId == null
        ? ref.watch(allProvidersProvider)
        : ref.watch(providersByCategoryProvider(categoryId));

    final hPad = R.hPad(context, base: 16);
    final cardRadius = R.radius(context, 14);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPad.left,
                vertical: R.sp(context, 10),
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
                      'Recharge providers',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        fontSize: R.fs(context, 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── List ───
            Expanded(
              child: providersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad.left),
                    child: Text(
                      'Failed to load providers: $e',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: R.fs(context, 14),
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                data: (providers) {
                  if (providers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No providers yet',
                            style: TextStyle(
                              fontSize: R.fs(context, 16),
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      ref.invalidate(allProvidersProvider);
                      ref.invalidate(providersByCategoryProvider);
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad.left,
                        vertical: R.sp(context, 6),
                      ),
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        final provider = providers[index];
                        final accent = _accentFor(index);
                        final low = provider.isLowBalance;

                        return Container(
                          margin: EdgeInsets.only(bottom: R.sp(context, 12)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(cardRadius),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(cardRadius),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddProviderScreen(
                                      existingProviderId: provider.id,
                                    ),
                                  ),
                                );

                                ref.invalidate(allProvidersProvider);
                                ref.invalidate(providersByCategoryProvider);
                              },
                              onLongPress: () =>
                                  _confirmDelete(context, ref, provider),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(R.sp(context, 14)),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: R.sp(context, 42),
                                          height: R.sp(context, 42),
                                          decoration: BoxDecoration(
                                            color: accent,
                                            borderRadius: BorderRadius.circular(
                                              R.radius(context, 10),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.bolt_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _capitalizeFirstLetter(
                                                  provider.name,
                                                ),
                                                style: TextStyle(
                                                  fontSize: R.fs(context, 15),
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                provider.categoryName.isEmpty
                                                    ? 'Provider'
                                                    : _capitalizeFirstLetter(
                                                        provider.categoryName,
                                                      ),
                                                style: TextStyle(
                                                  fontSize: R.fs(context, 12),
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              money(provider.balance),
                                              style: TextStyle(
                                                fontSize: R.fs(context, 15),
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Balance',
                                              style: TextStyle(
                                                fontSize: R.fs(context, 11),
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              provider.healthLabel,
                                              style: TextStyle(
                                                fontSize: R.fs(context, 11.5),
                                                fontWeight: FontWeight.w700,
                                                color: low
                                                    ? const Color(0xFFDC2626)
                                                    : const Color(0xFF16A34A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        _reloadBalance(context, ref, provider),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: R.sp(context, 12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Reload balance',
                                          style: TextStyle(
                                            fontSize: R.fs(context, 13.5),
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
