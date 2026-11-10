import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';

/// Aviso fixo: os alertas apoiam, mas não substituem, a decisão humana.
class HumanDecisionBanner extends StatelessWidget {
  const HumanDecisionBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Aviso: ${AppConstants.humanDecisionNotice}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? AppSpacing.sm + 2 : AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person_pin_outlined, color: scheme.onPrimaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                compact
                    ? 'Os alertas apoiam, mas não substituem, a decisão humana.'
                    : AppConstants.humanDecisionNotice,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
