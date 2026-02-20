import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/currency_provider.dart';
import 'package:provider/provider.dart';


class CurrencyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool autofocus;
  final bool enabled;

  const CurrencyInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currencyProvider = context.watch<CurrencyProvider>();
    final currency = currencyProvider.currency;
    final symbol = currency.symbol;

    return TextFormField(
      controller: controller,
      style: textTheme.bodyLarge,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autofocus: autofocus,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        prefixText: symbol.isNotEmpty ? '$symbol ' : null,
        prefixStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colors.primary,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.7),
        ),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        filled: true,
        fillColor: colors.surfaceContainerHigh.withValues(alpha: 0.5),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}