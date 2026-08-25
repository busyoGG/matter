import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DateSeparator extends StatelessWidget {
  final String dateLabel;

  const DateSeparator({super.key, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Container(height: 0.5, color: colors.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Container(height: 0.5, color: colors.outlineVariant)),
        ],
      ),
    );
  }
}
