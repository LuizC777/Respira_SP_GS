import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/severity_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/zone_snapshot.dart';
import '../../providers/territory_providers.dart';

/// Mostra de onde vêm os dados (ao vivo, offline ou exemplo) e quando
/// foram atualizados. Fundamental para a transparência.
class DataStatusBar extends ConsumerWidget {
  const DataStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final territory = ref.watch(territoryProvider);
    final data = territory.valueOrNull;
    if (data == null) return const SizedBox.shrink();

    final colors = context.severityColors;
    final scheme = Theme.of(context).colorScheme;
    final origin = data.origin;
    final (icon, color) = switch (origin) {
      DataOrigin.api => (Icons.wifi, colors.good),
      DataOrigin.cache => (Icons.wifi_off, colors.moderate),
      DataOrigin.sample => (Icons.science_outlined, colors.critical),
    };
    final when = data.oldestFetch ?? data.loadedAt;
    final label = origin == DataOrigin.api
        ? '${origin.label} · atualizado ${Fmt.relative(when)}'
        : '${origin.label} · ${Fmt.dateTime(when)}';

    return Semantics(
      liveRegion: true,
      label: 'Origem dos dados: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            if (territory.isRefreshing) ...[
              const SizedBox(width: AppSpacing.sm),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
