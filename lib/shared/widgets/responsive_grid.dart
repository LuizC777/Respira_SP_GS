import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Grade responsiva: calcula quantas colunas cabem pela largura mínima
/// de cada item (1 coluna no celular, 2+ em telas largas).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 160,
    this.maxColumns = 4,
    this.spacing = AppSpacing.sm,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = ((width + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, maxColumns)
            .toInt();
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
