import 'package:flutter/material.dart';

import '../../utils/components/color/app_colors.dart';
import 'common_required_label.dart';


class CustomDropdownField extends StatelessWidget {
  const CustomDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.icon,
    this.validator,
  });

  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? hint;
  final IconData? icon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequiredLabel(label: label, isRequired: true),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : null,
          isExpanded: true,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: AppColors.surface,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          hint: Text(
            hint ?? 'Select ${label.toLowerCase()}',
            style: const TextStyle(color: AppColors.textHint, fontSize: 15),
          ),
          decoration: InputDecoration(
            prefixIcon: icon == null ? null : Icon(icon, size: 20),
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
