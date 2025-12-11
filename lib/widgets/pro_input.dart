import 'package:flutter/material.dart';

class ProInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? hint;
  final String? prefixText;
  final String? suffixText;
  final bool decimal;
  final bool formatWithSeparator;
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
    this.formatWithSeparator = false,
    required this.focusNode,
    this.nextFocus,
    this.onChanged,
  });

  String _formatNumber(String raw) {
    // remove existing commas
    raw = raw.replaceAll(',', '');
    if (raw.isEmpty) return '';

    // split integer/decimal part
    String integerPart = raw;
    String decimalPart = '';
    if (raw.contains('.')) {
      final parts = raw.split('.');
      integerPart = parts[0];
      decimalPart = parts.length > 1 ? parts[1] : '';
    }

    final isNegative = integerPart.startsWith('-');
    if (isNegative) {
      integerPart = integerPart.substring(1);
    }

    // add thousand separators to integer part
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      final positionFromEnd = integerPart.length - i;
      buffer.write(integerPart[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    String result = buffer.toString();
    if (decimal && decimalPart.isNotEmpty) {
      result = '$result.$decimalPart';
    }
    if (isNegative) {
      result = '-$result';
    }
    return result;
  }

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
          onChanged: (value) {
            if (formatWithSeparator) {
              final withoutCommas = value.replaceAll(',', '');
              if (withoutCommas.isEmpty) {
                onChanged?.call('');
                return;
              }

              final parsed = double.tryParse(withoutCommas);
              if (parsed == null) {
                onChanged?.call(value);
                return;
              }

              final formatted = _formatNumber(withoutCommas);
              if (formatted != value) {
                controller.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }

              onChanged?.call(formatted);
            } else {
              onChanged?.call(value);
            }
          },
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
