import 'package:easy_film/app/theme/app_theme.dart';
import 'package:easy_film/features/filebrowser/domain/media_file_entry.dart';
import 'package:easy_film/features/filebrowser/presentation/filebrowser_controller.dart';
import 'package:easy_film/shared/utils/format_utils.dart';
import 'package:easy_film/shared/widgets/empty_state.dart';
import 'package:easy_film/shared/widgets/metric_tile.dart';
import 'package:easy_film/shared/widgets/shimmer_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FilebrowserScreen extends StatefulWidget {
  const FilebrowserScreen({super.key});

  @override
  State<FilebrowserScreen> createState() => _FilebrowserScreenState();
}

class _FilebrowserScreenState extends State<FilebrowserScreen> {
  late final FilebrowserController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentFolder = '';

  @override
  void initState() {
    super.initState();
    _controller = FilebrowserController()..addListener(_refreshUi);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _controller.loadFolder();
  }

  void _refreshUi() {
    if (_currentFolder.isEmpty && _controller.rootFolder.isNotEmpty) {
      _currentFolder = _controller.rootFolder;
    }

    final availableDirectoryPaths = _controller.files
        .where((e) => e.isDirectory)
        .map((e) => FormatUtils.normalizePath(e.path))
        .toSet()
      ..add(_controller.rootFolder);

    if (_currentFolder.isNotEmpty && !availableDirectoryPaths.contains(_currentFolder)) {
      _currentFolder = _controller.rootFolder;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_refreshUi);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final entries = _buildVisibleEntries();
    final foldersCount = entries.where((e) => e.isDirectory).length;
    final videosCount = entries.where((e) => !e.isDirectory && e.isVideo).length;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Films'),
        actions: [
          IconButton(
            tooltip: 'Réglages',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _controller.loadFolder,
        color: colors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Metrics row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0,
                ),
                child: Row(
                  children: [
                    MetricTile(
                      label: 'Dossiers',
                      value: '$foldersCount',
                      icon: Icons.folder_rounded,
                      iconColor: const Color(0xFFFFA726),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    MetricTile(
                      label: 'Vidéos',
                      value: '$videosCount',
                      icon: Icons.movie_rounded,
                      iconColor: const Color(0xFF4DD0E1),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.onSurface.withValues(alpha: 0.4),
                    ),
                    hintText: 'Rechercher un film ou dossier…',
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // ── Breadcrumb ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs,
                ),
                child: _searchQuery.isEmpty
                    ? _buildBreadcrumb(context)
                    : _buildSearchResultsHeader(entries.length, context),
              ),
            ),

            // ── Message ──
            if (_controller.message != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: Builder(builder: (context) {
                    final isError = _controller.isMessageError;
                    final msgColor = isError ? colors.error : const Color(0xFF81C784);
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: msgColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: msgColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isError ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                            size: 16,
                            color: msgColor,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _controller.message!,
                              style: TextStyle(color: msgColor, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

            // ── File list ──
            if (_controller.isLoading && _controller.files.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverToBoxAdapter(child: SizedBox(height: 400, child: const ShimmerList())),
              )
            else if (entries.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.folder_off_rounded,
                  title: 'Aucun élément',
                  subtitle: 'Ce dossier est vide ou aucun résultat ne correspond à ta recherche.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
                ),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _FileEntryCard(
                      entry: entry,
                      onDownload: () => _controller.download(entry),
                      onTap: entry.isDirectory && _searchQuery.isEmpty
                          ? () => _openDirectory(entry)
                          : null,
                    );
                  },
                ),
              ),

          ],
        ),
      ),
    );
  }

  // ── Breadcrumb ─────────────────────────────────────────────────────

  Widget _buildBreadcrumb(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final root = _controller.rootFolder;
    final path = _currentFolder.isEmpty ? root : _currentFolder;
    if (path.isEmpty) return const SizedBox.shrink();

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final rootSegments = root.split('/').where((s) => s.isNotEmpty).toList();

    return Row(
      children: [
        if (_canGoUp())
          GestureDetector(
            onTap: _goUp,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back_rounded, size: 16, color: colors.onSurface.withValues(alpha: 0.6)),
            ),
          ),
        if (_canGoUp()) const SizedBox(width: AppSpacing.sm),
        if (_controller.isLoading)
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
        if (_controller.isLoading) const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < segments.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.chevron_right_rounded, size: 16,
                          color: colors.onSurface.withValues(alpha: 0.3)),
                    ),
                  GestureDetector(
                    onTap: i < segments.length - 1
                        ? () {
                            final targetPath = '/${segments.sublist(0, i + 1).join('/')}';
                            setState(() => _currentFolder = targetPath);
                          }
                        : null,
                    child: Text(
                      i < rootSegments.length ? segments[i] : segments[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: i == segments.length - 1 ? FontWeight.w600 : FontWeight.w400,
                        color: i == segments.length - 1
                            ? colors.onSurface
                            : colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsHeader(int count, BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.filter_list_rounded, size: 16, color: colors.primary),
        const SizedBox(width: 6),
        Text(
          '$count résultat${count != 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // ── Data logic ─────────────────────────────────────────────────────

  List<MediaFileEntry> _buildVisibleEntries() {
    if (_searchQuery.isNotEmpty) {
      return _controller.files
          .where((e) => !e.isDirectory && e.isVideo)
          .where(_matchesSearch)
          .toList(growable: false)
        ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    }

    final root = _controller.rootFolder;
    if (_currentFolder.isEmpty && root.isNotEmpty) _currentFolder = root;

    return _controller.files
        .where((e) => FormatUtils.parentPath(e.path) == _currentFolder)
        .where((e) => e.isDirectory || e.isVideo)
        .where(_matchesSearch)
        .toList(growable: false)
      ..sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  bool _matchesSearch(MediaFileEntry entry) {
    if (_searchQuery.isEmpty) return true;
    return '${entry.name} ${entry.path}'.toLowerCase().contains(_searchQuery);
  }

  void _openDirectory(MediaFileEntry entry) {
    final target = FormatUtils.normalizePath(entry.path);
    if (target.isEmpty) return;
    setState(() => _currentFolder = target);
  }

  void _goUp() {
    final parent = FormatUtils.parentPath(_currentFolder);
    setState(() => _currentFolder = parent.isEmpty ? _controller.rootFolder : parent);
  }

  bool _canGoUp() {
    final root = _controller.rootFolder;
    if (root.isEmpty || _currentFolder.isEmpty) return false;
    return FormatUtils.normalizePath(_currentFolder) != FormatUtils.normalizePath(root);
  }
}

// ── File entry card ────────────────────────────────────────────────────

class _FileEntryCard extends StatelessWidget {
  const _FileEntryCard({
    required this.entry,
    required this.onDownload,
    this.onTap,
  });

  final MediaFileEntry entry;
  final VoidCallback onDownload;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDir = entry.isDirectory;
    final isVideo = entry.isVideo;

    return Material(
      color: const Color(0xFF1A1B26),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isDir ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDir
                      ? const Color(0xFFFFA726).withValues(alpha: 0.12)
                      : isVideo
                          ? const Color(0xFF4DD0E1).withValues(alpha: 0.12)
                          : colors.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDir
                      ? Icons.folder_rounded
                      : isVideo
                          ? Icons.movie_rounded
                          : Icons.insert_drive_file_rounded,
                  size: 20,
                  color: isDir
                      ? const Color(0xFFFFA726)
                      : isVideo
                          ? const Color(0xFF4DD0E1)
                          : colors.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                    if (!isDir) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${entry.extension.toUpperCase()} · ${FormatUtils.formatBytes(entry.sizeBytes)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing
              if (isDir)
                Icon(Icons.chevron_right_rounded, size: 20,
                    color: colors.onSurface.withValues(alpha: 0.3))
              else if (isVideo)
                IconButton(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                    foregroundColor: colors.primary,
                  ),
                  iconSize: 20,
                  tooltip: 'Télécharger',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
