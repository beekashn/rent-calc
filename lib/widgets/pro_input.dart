import 'package:flutter/material.dart';

class ProInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? hint;
  final String? prefixText;
  final String? suffixText;
  final bool decimal;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final ValueChanged<String>? onChanged;

  const ProInput({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.hint,
    this.prefixText,
    this.suffixText,
    this.decimal = false,
    required this.focusNode,
    this.nextFocus,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: theme.inputDecorationTheme.labelStyle?.copyWith(
              fontSize: 12,
            ),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          textInputAction: nextFocus != null
              ? TextInputAction.next
              : TextInputAction.done,
          onChanged: onChanged,
          onSubmitted: (_) => nextFocus != null
              ? FocusScope.of(context).requestFocus(nextFocus)
              : FocusScope.of(context).unfocus(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: theme.hintColor)
                : null,
            prefixText: prefixText,
            suffixText: suffixText,
          ),
        ),
      ],
    );
  }
}
