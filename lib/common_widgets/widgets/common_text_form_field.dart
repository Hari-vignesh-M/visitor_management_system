import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/components/color/app_colors.dart';
import 'common_required_label.dart';


class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.isRequired = false,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.showCounter = false,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool isRequired;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final bool showCounter;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequiredLabel(label: label, isRequired: isRequired),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: isMultiline ? 3 : 1,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null
                ? null
                : Padding(
                    padding: EdgeInsets.only(bottom: isMultiline ? 44 : 0),
                    child: Icon(icon, size: 20),
                  ),
            counterText: showCounter ? null : '',
          ),
        ),
      ],
    );
  }
}
