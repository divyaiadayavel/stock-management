// lib/features/settings/service_management/presentation/widgets/provider_question_type_sheet.dart

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../domain/enums/provider_field_type.dart';

/// Bottom sheet used by the provider builder to pick a field type.
///
/// Mirrors the "Choose question type" sheet used by the services builder
/// (see question_type_picker_sheet.dart) — same header, same expandable
/// card-with-example pattern — just backed by [ProviderFieldType] instead
/// of the service-only `QuestionType`.
Future<ProviderFieldType?> showProviderFieldTypePicker(
  BuildContext context,
) async {
  return showModalBottomSheet<ProviderFieldType>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return const ProviderFieldTypeSheet();
    },
  );
}

class ProviderFieldTypeSheet extends StatefulWidget {
  const ProviderFieldTypeSheet({super.key});

  @override
  State<ProviderFieldTypeSheet> createState() =>
      _ProviderFieldTypeSheetState();
}

class _ProviderFieldTypeSheetState extends State<ProviderFieldTypeSheet> {
  int? _expandedIndex;

  List<_ProviderFieldTypeInfo> get _fieldTypes => [
    _ProviderFieldTypeInfo(
      key: ProviderFieldType.shortText,
      title: 'Short text',
      bestFor: 'Single line of text',
      icon: Icons.short_text_rounded,
      example: const _ShortTextExample(),
    ),
    _ProviderFieldTypeInfo(
      key: ProviderFieldType.paragraph,
      title: 'Paragraph',
      bestFor: 'Multi-line notes',
      icon: Icons.notes_rounded,
      example: const _ParagraphExample(),
    ),
    _ProviderFieldTypeInfo(
      key: ProviderFieldType.number,
      title: 'Number',
      bestFor: 'Digits only — phone, account no.',
      icon: Icons.pin_rounded,
      example: const _NumberExample(),
    ),
    _ProviderFieldTypeInfo(
      key: ProviderFieldType.amount,
      title: 'Amount',
      bestFor: 'Money value — deducted from balance',
      icon: Icons.currency_rupee_rounded,
      example: const _AmountExample(),
    ),
    _ProviderFieldTypeInfo(
      key: ProviderFieldType.choice,
      title: 'Choice',
      bestFor: 'Pick one from a list',
      icon: Icons.radio_button_checked_rounded,
      example: const _ChoiceExample(),
    ),
    _ProviderFieldTypeInfo(
      key: ProviderFieldType.date,
      title: 'Date',
      bestFor: 'Calendar date',
      icon: Icons.calendar_today_rounded,
      example: const _DateExample(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final types = _fieldTypes;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Top handle
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose question type',
                          style: TextStyle(
                            fontSize: R.fs(context, 19),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Select the type of answer you want from the user.',
                          style: TextStyle(
                            fontSize: R.fs(context, 12),
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Field type list
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: types.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = types[index];
                  final isExpanded = _expandedIndex == index;

                  return _ProviderFieldTypeCard(
                    item: item,
                    isExpanded: isExpanded,
                    onExpand: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    onSelect: () {
                      Navigator.pop(context, item.key);
                    },
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

class _ProviderFieldTypeInfo {
  final ProviderFieldType key;
  final String title;
  final String bestFor;
  final IconData icon;
  final Widget example;

  const _ProviderFieldTypeInfo({
    required this.key,
    required this.title,
    required this.bestFor,
    required this.icon,
    required this.example,
  });
}

class _ProviderFieldTypeCard extends StatelessWidget {
  final _ProviderFieldTypeInfo item;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onSelect;

  const _ProviderFieldTypeCard({
    required this.item,
    required this.isExpanded,
    required this.onExpand,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isExpanded ? 0.045 : 0.025),
            blurRadius: isExpanded ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      item.icon,
                      color: const Color(0xFF475569),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: R.fs(context, 15),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Best for: ',
                                  style: TextStyle(
                                    fontSize: R.fs(context, 10.5),
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                TextSpan(
                                  text: item.bestFor,
                                  style: TextStyle(
                                    fontSize: R.fs(context, 10.5),
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onExpand,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 24,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Example',
                    style: TextStyle(
                      fontSize: R.fs(context, 11),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  item.example,
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXAMPLES
// ═══════════════════════════════════════════════════════════════

class _ShortTextExample extends StatelessWidget {
  const _ShortTextExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(
            Icons.person_outline_rounded,
            size: 19,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 9),
          Text(
            'Enter customer name',
            style: TextStyle(
              fontSize: R.fs(context, 12),
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParagraphExample extends StatelessWidget {
  const _ParagraphExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      alignment: Alignment.topLeft,
      child: Text(
        'Enter notes or extra details',
        style: TextStyle(
          fontSize: R.fs(context, 12),
          height: 1.35,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _NumberExample extends StatelessWidget {
  const _NumberExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(
            Icons.pin_rounded,
            size: 19,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 9),
          Text(
            'Enter account number',
            style: TextStyle(
              fontSize: R.fs(context, 12),
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountExample extends StatelessWidget {
  const _AmountExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(
            Icons.currency_rupee_rounded,
            size: 19,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 9),
          Text(
            'Amount to deduct',
            style: TextStyle(
              fontSize: R.fs(context, 12),
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceExample extends StatelessWidget {
  const _ChoiceExample();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _radioRow('Prepaid', true, context),
        const SizedBox(height: 7),
        _radioRow('Postpaid', false, context),
      ],
    );
  }

  Widget _radioRow(String text, bool selected, BuildContext context) {
    return Row(
      children: [
        Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: selected ? AppColors.primary : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 9),
        Text(
          text,
          style: TextStyle(
            fontSize: R.fs(context, 12),
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _DateExample extends StatelessWidget {
  const _DateExample();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'DD/MM/YYYY',
              style: TextStyle(
                fontSize: R.fs(context, 12),
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }
}
