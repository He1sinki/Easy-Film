import 'package:easy_film/app/theme/app_theme.dart';
import 'package:easy_film/features/qbittorrent/domain/torrent_item.dart';
import 'package:easy_film/features/qbittorrent/presentation/qbittorrent_controller.dart';
import 'package:easy_film/shared/utils/format_utils.dart';
import 'package:easy_film/shared/widgets/empty_state.dart';
import 'package:easy_film/shared/widgets/metric_tile.dart';
import 'package:easy_film/shared/widgets/shimmer_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QbittorrentScreen extends StatefulWidget {
  const QbittorrentScreen({super.key});

  @override
  State<QbittorrentScreen> createState() => _QbittorrentScreenState();
}

class _QbittorrentScreenState extends State<QbittorrentScreen>
    with WidgetsBindingObserver {
  late final QbittorrentController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = QbittorrentController()..addListener(_refreshUi);
    _controller.startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.startPolling();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _controller.stopPolling();
    }
  }

  void _refreshUi() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_refreshUi);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final torrents = _controller.torrents;
    final activeCount = torrents.where((t) => t.downloadSpeed > 0).length;
    final totalSpeed = torrents.fold<int>(0, (acc, t) => acc + t.downloadSpeed);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Torrents'),
        actions: [
          IconButton(
            tooltip: 'Réglages',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.isLoading ? null : _controller.uploadTorrent,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: _controller.isLoading
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: _controller.refreshNow,
        color: colors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Metrics ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0,
                ),
                child: Row(
                  children: [
                    MetricTile(
                      label: 'Total',
                      value: '${torrents.length}',
                      icon: Icons.downloading_rounded,
                      iconColor: const Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    MetricTile(
                      label: 'Actifs',
                      value: '$activeCount',
                      icon: Icons.speed_rounded,
                      iconColor: const Color(0xFF4DD0E1),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    MetricTile(
                      label: 'Débit',
                      value: FormatUtils.formatSpeed(totalSpeed),
                      icon: Icons.arrow_downward_rounded,
                      iconColor: const Color(0xFF81C784),
                    ),
                  ],
                ),
              ),
            ),

            // ── Message ──
            if (_controller.message != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _controller.message!.contains('succès') || _controller.message!.contains('démarré')
                          ? const Color(0xFF81C784).withValues(alpha: 0.12)
                          : colors.errorContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _controller.message!.contains('succès') || _controller.message!.contains('démarré')
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          size: 16,
                          color: _controller.message!.contains('succès') || _controller.message!.contains('démarré')
                              ? const Color(0xFF81C784)
                              : colors.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _controller.message!,
                            style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Torrent list ──
            if (_controller.isLoading && torrents.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverToBoxAdapter(child: SizedBox(height: 400, child: const ShimmerList())),
              )
            else if (torrents.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.cloud_download_outlined,
                  title: 'Aucun torrent',
                  subtitle: 'Ajoute un fichier .torrent pour commencer le téléchargement.',
                  actionLabel: 'Ajouter .torrent',
                  onAction: _controller.uploadTorrent,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100,
                ),
                sliver: SliverList.separated(
                  itemCount: torrents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final torrent = torrents[index];
                    return _TorrentCard(
                      torrent: torrent,
                      onStart: () => _controller.startTorrent(torrent.hash),
                      onPause: () => _controller.pauseTorrent(torrent.hash),
                      onRemove: () => _confirmRemove(context, torrent),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, TorrentItem torrent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le torrent ?'),
        content: Text(
          torrent.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.removeTorrent(torrent.hash);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ── Torrent card ─────────────────────────────────────────────────────

class _TorrentCard extends StatelessWidget {
  const _TorrentCard({
    required this.torrent,
    required this.onStart,
    required this.onPause,
    required this.onRemove,
  });

  final TorrentItem torrent;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stateInfo = FormatUtils.torrentStateInfo(torrent.state);
    final stateLabel = FormatUtils.translateTorrentState(torrent.state);
    final stateColor = _stateColor(stateInfo);
    final progress = torrent.progress.clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    final isPaused = torrent.state.toLowerCase().contains('paused');
    final isDownloading = torrent.state.toLowerCase().contains('downloading') ||
        torrent.state.toLowerCase().contains('forceddl');

    return Dismissible(
      key: ValueKey(torrent.hash),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline_rounded, color: colors.error),
      ),
      confirmDismiss: (_) async {
        onRemove();
        return false; // We handle through the dialog
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            // ── Progress circle ──
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: stateColor,
                    backgroundColor: stateColor.withValues(alpha: 0.15),
                  ),
                  Text(
                    '$percent',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: stateColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // ── Name + details ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    torrent.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: stateColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          stateLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: stateColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${FormatUtils.formatBytes(torrent.downloadedBytes)} / ${FormatUtils.formatBytes(torrent.totalSizeBytes)}',
                        style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.4)),
                      ),
                      if (torrent.downloadSpeed > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_downward_rounded, size: 11, color: const Color(0xFF4DD0E1)),
                        const SizedBox(width: 2),
                        Text(
                          FormatUtils.formatSpeed(torrent.downloadSpeed),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF4DD0E1)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // ── Actions ──
            if (isPaused || stateInfo == TorrentStateInfo.waiting || stateInfo == TorrentStateInfo.paused)
              _ActionButton(
                icon: Icons.play_arrow_rounded,
                tooltip: 'Démarrer',
                color: const Color(0xFF81C784),
                onPressed: onStart,
              ),
            if (isDownloading || stateInfo == TorrentStateInfo.seeding)
              _ActionButton(
                icon: Icons.pause_rounded,
                tooltip: 'Pause',
                color: const Color(0xFFFFA726),
                onPressed: onPause,
              ),
            _ActionButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Supprimer',
              color: colors.error,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Color _stateColor(TorrentStateInfo info) {
    return switch (info) {
      TorrentStateInfo.downloading => const Color(0xFF4DD0E1),
      TorrentStateInfo.waiting => const Color(0xFFFFA726),
      TorrentStateInfo.seeding => const Color(0xFF81C784),
      TorrentStateInfo.paused => const Color(0xFF9E9E9E),
      TorrentStateInfo.completed => const Color(0xFF81C784),
      TorrentStateInfo.error => const Color(0xFFEF5350),
      TorrentStateInfo.checking => const Color(0xFFFFD54F),
      TorrentStateInfo.unknown => const Color(0xFF9E9E9E),
    };
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(36, 36),
        ),
      ),
    );
  }
}
