import 'package:easy_film/app/theme/app_theme.dart';
import 'package:easy_film/features/ygg/domain/ygg_search_query.dart';
import 'package:easy_film/features/ygg/domain/ygg_search_result.dart';
import 'package:easy_film/features/ygg/presentation/ygg_controller.dart';
import 'package:easy_film/shared/utils/format_utils.dart';
import 'package:easy_film/shared/widgets/empty_state.dart';
import 'package:easy_film/shared/widgets/metric_tile.dart';
import 'package:easy_film/shared/widgets/shimmer_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class YggSearchScreen extends StatefulWidget {
  const YggSearchScreen({super.key, this.controller});

  /// Optional controller injection for testing.
  final YggController? controller;

  @override
  State<YggSearchScreen> createState() => _YggSearchScreenState();
}

class _YggSearchScreenState extends State<YggSearchScreen> {
  late final YggController _controller;
  late final TextEditingController _searchController;
  bool _searchEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? YggController();
    _controller.addListener(_refreshUi);
    _searchController = TextEditingController()
      ..addListener(() {
        final enabled = _searchController.text.trim().isNotEmpty;
        if (enabled != _searchEnabled) {
          setState(() => _searchEnabled = enabled);
        }
      });
  }

  void _refreshUi() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_refreshUi);
    if (widget.controller == null) _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    if (!_searchEnabled) return;
    FocusScope.of(context).unfocus();
    _controller.search(_searchController.text);
  }

  void _onSendTorrent(YggSearchResult result) async {
    final sendStatus = _controller.sendStatusFor(result.infoHash);
    if (sendStatus == SendTorrentStatus.sending) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Envoyer vers qBittorrent ?'),
        content: Text(
          result.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final needsConfig = await _controller.sendTorrent(result);

    if (needsConfig && mounted) {
      // FR-012: Redirect to Settings when qBittorrent is not configured
      context.push('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
        actions: [
          IconButton(
            tooltip: 'Réglages',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _onSearch(),
                decoration: InputDecoration(
                  hintText: 'Rechercher un torrent…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Search button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: FilledButton.icon(
                onPressed:
                    _searchEnabled && !_controller.isLoading ? _onSearch : null,
                icon: _controller.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search_rounded, size: 18),
                label: const Text('Rechercher'),
              ),
            ),
          ),

          // Filter & Sort bar (visible when results available)
          if (_controller.allResults.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: _FilterSortBar(controller: _controller),
              ),
            ),
          ],

          // Metrics row
          if (_controller.hasResults)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(children: [
                  MetricTile(
                    label: 'Résultats',
                    value: '${_controller.results.length}',
                    icon: Icons.search_rounded,
                    iconColor: const Color(0xFF6C63FF),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  MetricTile(
                    label: 'Taille totale',
                    value: FormatUtils.formatBytes(
                      _controller.results
                          .fold<int>(0, (sum, r) => sum + r.totalSize),
                    ),
                    icon: Icons.storage_rounded,
                    iconColor: const Color(0xFF4DD0E1),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  MetricTile(
                    label: 'Seeders',
                    value:
                        '${_controller.results.fold<int>(0, (sum, r) => sum + r.seeders)}',
                    icon: Icons.upload_rounded,
                    iconColor: const Color(0xFF81C784),
                  ),
                ]),
              ),
            ),

          // Error message
          if (_controller.errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.errorContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline_rounded,
                        size: 16, color: colors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _controller.errorMessage!,
                        style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurface.withValues(alpha: 0.8)),
                      ),
                    ),
                    TextButton(
                      onPressed: _onSearch,
                      child: const Text('Réessayer'),
                    ),
                  ]),
                ),
              ),
            ),

          // Loading shimmer
          if (_controller.isLoading)
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: SizedBox(height: 400, child: const ShimmerList()),
              ),
            )
          // Empty state (search returned no results)
          else if (_controller.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Aucun résultat',
                subtitle: 'Essayez avec d\'autres mots-clés.',
              ),
            )
          // Initial empty state
          else if (_controller.isInitial)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.search_rounded,
                title: 'Recherche de torrents',
                subtitle:
                    'Saisissez un terme de recherche pour trouver des torrents sur c411.',
              ),
            )
          // Filter produced empty results
          else if (_controller.isFilteredEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.filter_list_off_rounded,
                title: 'Aucun résultat dans cette catégorie',
                subtitle:
                    'Désélectionnez le filtre pour voir tous les résultats.',
                actionLabel: 'Tout afficher',
                onAction: () => _controller.setCategoryFilter(null),
              ),
            )
          // Results list
          else if (_controller.hasResults)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100),
              sliver: SliverList.separated(
                itemCount: _controller.results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final result = _controller.results[index];
                  final sendStatus = _controller.sendStatusFor(result.infoHash);
                  final sendMessage =
                      _controller.sendMessageFor(result.infoHash);
                  return _TorrentResultCard(
                    result: result,
                    sendStatus: sendStatus,
                    sendMessage: sendMessage,
                    onTap: () => _onSendTorrent(result),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Filter & Sort Bar ────────────────────────────────────────

class _FilterSortBar extends StatelessWidget {
  const _FilterSortBar({required this.controller});
  final YggController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categories = controller.availableCategories;
    final activeFilter = controller.query.categoryFilter;
    final activeSortCriteria = controller.query.sortCriteria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category filter chips
        if (categories.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Tout (${controller.allResults.length})',
                  selected: activeFilter == null,
                  onTap: () => controller.setCategoryFilter(null),
                ),
                ...categories.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _FilterChip(
                        label: '${entry.key} (${entry.value})',
                        selected: activeFilter == entry.key,
                        onTap: () {
                          if (activeFilter == entry.key) {
                            controller.setCategoryFilter(null);
                          } else {
                            controller.setCategoryFilter(entry.key);
                          }
                        },
                      ),
                    )),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Sort controls
        Row(
          children: [
            Text('Trier par : ',
                style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.5))),
            _SortChip(
                label: 'Date',
                selected: activeSortCriteria == SortCriteria.date,
                onTap: () => controller.setSortCriteria(SortCriteria.date)),
            const SizedBox(width: 4),
            _SortChip(
                label: 'Taille',
                selected: activeSortCriteria == SortCriteria.size,
                onTap: () => controller.setSortCriteria(SortCriteria.size)),
            const SizedBox(width: 4),
            _SortChip(
                label: 'Seeders',
                selected: activeSortCriteria == SortCriteria.seeders,
                onTap: () => controller.setSortCriteria(SortCriteria.seeders)),
            const Spacer(),
            GestureDetector(
              onTap: controller.toggleSortDirection,
              child: Icon(
                controller.query.sortDescending
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 18,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.15)
              : const Color(0xFF1A1B26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? colors.primary
                : colors.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// ─── Torrent Result Card ──────────────────────────────────────

class _TorrentResultCard extends StatelessWidget {
  const _TorrentResultCard({
    required this.result,
    required this.sendStatus,
    this.sendMessage,
    required this.onTap,
  });

  final YggSearchResult result;
  final SendTorrentStatus sendStatus;
  final String? sendMessage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSending = sendStatus == SendTorrentStatus.sending;
    final isSent = sendStatus == SendTorrentStatus.success;
    final isError = sendStatus == SendTorrentStatus.error;
    final noSeeders = result.seeders == 0;

    return GestureDetector(
      onTap: isSending ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSent
                ? const Color(0xFF81C784).withValues(alpha: 0.4)
                : isError
                    ? colors.error.withValues(alpha: 0.4)
                    : colors.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + send indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSending)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isSent)
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: Color(0xFF81C784))
                else if (isError)
                  Icon(Icons.error_rounded, size: 16, color: colors.error),
              ],
            ),

            const SizedBox(height: 6),

            // Category + age
            Row(
              children: [
                if (result.categoryLabel != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      result.categoryLabel!,
                      style: TextStyle(
                          fontSize: 11,
                          color: colors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.access_time_rounded,
                    size: 12, color: colors.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 3),
                Text(
                  FormatUtils.formatRelativeAge(result.createdAt),
                  style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Metadata row: size, files, seeders, leechers
            Row(
              children: [
                _MetaChip(
                    icon: Icons.storage_rounded,
                    label: FormatUtils.formatBytes(result.totalSize)),
                const SizedBox(width: 10),
                _MetaChip(
                    icon: Icons.insert_drive_file_rounded,
                    label: '${result.fileCount}'),
                const Spacer(),
                _MetaChip(
                  icon: Icons.arrow_upward_rounded,
                  label: '${result.seeders}',
                  color: noSeeders ? colors.error : const Color(0xFF81C784),
                ),
                const SizedBox(width: 10),
                _MetaChip(
                  icon: Icons.arrow_downward_rounded,
                  label: '${result.leechers}',
                  color: const Color(0xFFE57373),
                ),
              ],
            ),

            // Send feedback message
            if (sendMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                sendMessage!,
                style: TextStyle(
                  fontSize: 11,
                  color: isSent ? const Color(0xFF81C784) : colors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final defaultColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? defaultColor),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 11, color: color ?? defaultColor)),
      ],
    );
  }
}
