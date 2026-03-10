import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';
import 'loading_shimmer.dart';

/// ============================================================
/// ASSET CARD SKELETON - Loading placeholder para cards de ativos
/// Design System: OwanyTheme
/// Usado em listagens com paginação/busca server-side
/// ============================================================

/// Skeleton de um card de ativo individual
class AssetCardSkeleton extends StatelessWidget {
  final bool isDark;

  const AssetCardSkeleton({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final dark = isDark || OwanyTheme.isDark(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OwanyTheme.borderColor(context).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: OwanyTheme.textPrimary(context).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon placeholder
          LoadingShimmer.circle(size: 48, isDark: dark),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome
                LoadingShimmer.text(width: 180, height: 18, isDark: dark),
                const SizedBox(height: 8),
                // Código
                LoadingShimmer.text(width: 140, height: 14, isDark: dark),
                const SizedBox(height: 12),
                // Badges row
                Row(
                  children: [
                    LoadingShimmer.rectangle(
                      width: 70,
                      height: 24,
                      borderRadius: 12,
                      isDark: dark,
                    ),
                    const SizedBox(width: 8),
                    LoadingShimmer.rectangle(
                      width: 90,
                      height: 24,
                      borderRadius: 12,
                      isDark: dark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action button
          LoadingShimmer.circle(size: 32, isDark: dark),
        ],
      ),
    );
  }
}

/// Lista de skeletons para loading de ativos
class AssetListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool isDark;

  const AssetListSkeleton({
    super.key, 
    this.itemCount = 5,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverList.builder(
        itemCount: itemCount,
        itemBuilder: (_, __) => AssetCardSkeleton(isDark: isDark),
      ),
    );
  }
}

/// Skeleton para header de stats da tela de ativos
class AssetStatsRowSkeleton extends StatelessWidget {
  const AssetStatsRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = OwanyTheme.isDark(context);
    
    return Row(
      children: [
        Expanded(child: _StatCardSkeleton(isDark: dark)),
        const SizedBox(width: 12),
        Expanded(child: _StatCardSkeleton(isDark: dark)),
        const SizedBox(width: 12),
        Expanded(child: _StatCardSkeleton(isDark: dark)),
        const SizedBox(width: 12),
        Expanded(child: _StatCardSkeleton(isDark: dark)),
      ],
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  final bool isDark;
  
  const _StatCardSkeleton({this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OwanyTheme.borderColor(context).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          LoadingShimmer.text(width: 40, height: 24, isDark: isDark),
          const SizedBox(height: 6),
          LoadingShimmer.text(width: 60, height: 12, isDark: isDark),
        ],
      ),
    );
  }
}

/// Widget de indicador de busca em andamento
class SearchLoadingIndicator extends StatelessWidget {
  final String? message;

  const SearchLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: OwanyTheme.primaryOrange,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: OwanyTheme.mutedStyle(context, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget de estado vazio para busca sem resultados
class SearchEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onClear;
  final String clearButtonText;

  const SearchEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.onClear,
    this.clearButtonText = 'Limpar busca',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: OwanyTheme.textMutedColor(context).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: OwanyTheme.titleStyle(context, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: OwanyTheme.mutedStyle(context, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
            if (onClear != null) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: Text(clearButtonText),
                style: TextButton.styleFrom(
                  foregroundColor: OwanyTheme.primaryOrange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget de paginação para listagens
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final bool isLoading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    this.isLoading = false,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: OwanyTheme.cardColor(context),
        border: Border(
          top: BorderSide(color: OwanyTheme.borderColor(context).withOpacity(0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton.filled(
            onPressed: currentPage > 1 && !isLoading ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded),
            style: IconButton.styleFrom(
              backgroundColor: currentPage > 1 
                  ? OwanyTheme.primaryOrange.withOpacity(0.1)
                  : OwanyTheme.surface,
              foregroundColor: currentPage > 1 
                  ? OwanyTheme.primaryOrange 
                  : OwanyTheme.textMutedColor(context),
            ),
          ),
          const SizedBox(width: 16),
          // Page info
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Página $currentPage de $totalPages',
                style: OwanyTheme.titleStyle(context, fontSize: 14),
              ),
              Text(
                '$total itens no total',
                style: OwanyTheme.mutedStyle(context, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Next button
          IconButton.filled(
            onPressed: currentPage < totalPages && !isLoading ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            style: IconButton.styleFrom(
              backgroundColor: currentPage < totalPages 
                  ? OwanyTheme.primaryOrange.withOpacity(0.1)
                  : OwanyTheme.surface,
              foregroundColor: currentPage < totalPages 
                  ? OwanyTheme.primaryOrange 
                  : OwanyTheme.textMutedColor(context),
            ),
          ),
          // Loading indicator
          if (isLoading) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}
