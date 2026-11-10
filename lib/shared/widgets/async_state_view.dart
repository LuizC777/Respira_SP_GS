import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';

/// Trata os 3 estados obrigatórios de qualquer tela com dados:
/// carregando, erro e vazio. Telas só implementam o caso de sucesso.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.value,
    required this.builder,
    this.isEmpty,
    this.emptyTitle = 'Nada por aqui',
    this.emptyMessage = 'Não há dados para mostrar.',
    this.emptyIcon = Icons.inbox_outlined,
    this.onRetry,
    this.loadingMessage = 'Carregando dados do território…',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final VoidCallback? onRetry;
  final String loadingMessage;

  @override
  Widget build(BuildContext context) {
    // Durante um "atualizar", mantém os dados anteriores na tela.
    if (value.hasValue && !value.hasError) {
      final data = value.requireValue;
      if (isEmpty?.call(data) ?? false) {
        return EmptyStateView(
          icon: emptyIcon,
          title: emptyTitle,
          message: emptyMessage,
        );
      }
      return builder(data);
    }
    if (value.hasError) {
      return ErrorStateView(
        message: 'Não foi possível carregar os dados.',
        details: value.error.toString(),
        onRetry: onRetry,
      );
    }
    return LoadingStateView(message: loadingMessage);
  }
}

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.message = 'Carregando…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Center(
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              AppSpacing.gapMd,
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
  });

  final String message;
  final String? details;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: scheme.error),
            AppSpacing.gapMd,
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (details != null) ...[
              AppSpacing.gapSm,
              Text(
                details!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (onRetry != null) ...[
              AppSpacing.gapMd,
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.primary),
            AppSpacing.gapMd,
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.gapXs,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (action != null) ...[AppSpacing.gapMd, action!],
          ],
        ),
      ),
    );
  }
}
