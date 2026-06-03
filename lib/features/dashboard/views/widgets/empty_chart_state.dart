import 'package:flutter/material.dart';
import 'package:personal_fin/core/providers/language_provider.dart';
import 'package:personal_fin/core/shared_widgets/animated_empty_state.dart';
import 'package:provider/provider.dart';

class EmptyChartState extends StatelessWidget {
  final String textMessage;

  const EmptyChartState({super.key, required this.textMessage});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedEmptyState(
          message: lang.translate('No data recorded').toUpperCase(),
          imagePath: 'assets/images/empty_wallet_light.svg',
          darkImagePath: 'assets/images/empty_wallet_dark1.svg',
        ),
        const SizedBox(height: 16),
        Text(
          textMessage,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}