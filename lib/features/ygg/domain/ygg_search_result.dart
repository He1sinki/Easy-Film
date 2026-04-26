import 'package:easy_film/features/ygg/domain/magnet_uri_builder.dart';
import 'package:easy_film/features/ygg/domain/ygg_category_map.dart';
import 'package:equatable/equatable.dart';

/// A single file inside a torrent (NIP-35 `file` tag).
class TorrentFile extends Equatable {
  const TorrentFile({required this.name, required this.size});

  final String name;
  final int size;

  @override
  List<Object?> get props => [name, size];
}

/// A torrent search result parsed from a torrent search provider payload.
class YggSearchResult extends Equatable {
  const YggSearchResult({
    required this.id,
    required this.infoHash,
    required this.title,
    this.categoryId,
    this.categoryLabel,
    required this.totalSize,
    required this.createdAt,
    required this.fileCount,
    required this.seeders,
    required this.leechers,
    required this.completed,
    required this.magnetUri,
    required this.trackers,
    required this.files,
  });

  final String id;
  final String infoHash;
  final String title;
  final String? categoryId;
  final String? categoryLabel;
  final int totalSize;
  final int createdAt;
  final int fileCount;
  final int seeders;
  final int leechers;
  final int completed;
  final String magnetUri;
  final List<String> trackers;
  final List<TorrentFile> files;

  /// Parse a c411 API item (single object from `data[]`) into a [YggSearchResult].
  factory YggSearchResult.fromC411Json(Map<String, dynamic> item) {
    final category = _asMap(item['category']);
    final subcategory = _asMap(item['subcategory']);

    final title = item['name']?.toString().trim();
    final infoHash = item['infoHash']?.toString().trim() ?? '';
    final size = _toInt(item['size']);
    final createdAt = _parseCreatedAt(item['createdAt']);
    final categoryId = (subcategory['id'] ?? category['id'])?.toString();
    final categoryLabel = (subcategory['name'] ?? category['name'])?.toString();

    final resolvedTitle =
        (title == null || title.isEmpty) ? 'Sans titre' : title;

    return YggSearchResult(
      id: item['id']?.toString() ?? '',
      infoHash: infoHash,
      title: resolvedTitle,
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      totalSize: size,
      createdAt: createdAt,
      fileCount: 0,
      seeders: _toInt(item['seeders']),
      leechers: _toInt(item['leechers']),
      completed: _toInt(item['completions']),
      magnetUri: MagnetUriBuilder.build(
        infoHash: infoHash,
        title: resolvedTitle,
      ),
      trackers: const [],
      files: const [],
    );
  }

  /// Legacy parser for older Nostr event payloads.
  factory YggSearchResult.fromNostrEvent(Map<String, dynamic> event) {
    final tags = (event['tags'] as List<dynamic>?)?.cast<List<dynamic>>() ?? [];

    String? infoHash;
    String? title;
    String? categoryId;
    int totalSize = 0;
    int createdAt = event['created_at'] as int? ?? 0;
    int seeders = 0;
    int leechers = 0;
    int completed = 0;
    final trackers = <String>[];
    final files = <TorrentFile>[];

    for (final tag in tags) {
      if (tag.isEmpty) continue;
      final tagName = tag[0].toString();

      switch (tagName) {
        case 'x':
          if (tag.length >= 2) infoHash = tag[1].toString();
        case 'title':
          if (tag.length >= 2) title = tag[1].toString();
        case 'size':
          if (tag.length >= 2) {
            totalSize = int.tryParse(tag[1].toString()) ?? 0;
          }
        case 'file':
          if (tag.length >= 2) {
            final file = _parseFileTag(tag);
            if (file != null) files.add(file);
          }
        case 'tracker':
          if (tag.length >= 2) trackers.add(tag[1].toString());
        case 'l':
          if (tag.length >= 2)
            _parseLabelTag(tag[1].toString(), (cat) => categoryId = cat,
                (s) => seeders = s, (l) => leechers = l, (c) => completed = c);
        case 'published_at':
          if (tag.length >= 2) {
            createdAt = int.tryParse(tag[1].toString()) ?? createdAt;
          }
      }
    }

    // Title fallback to content
    title ??= event['content']?.toString() ?? '';

    // If totalSize not available from `size` tag, compute from files
    if (totalSize == 0 && files.isNotEmpty) {
      totalSize = files.fold<int>(0, (sum, f) => sum + f.size);
    }

    final resolvedInfoHash = infoHash ?? '';
    final resolvedTitle = title.isEmpty ? 'Sans titre' : title;

    final magnetUri = MagnetUriBuilder.build(
      infoHash: resolvedInfoHash,
      title: resolvedTitle,
      eventTrackers: trackers,
    );

    return YggSearchResult(
      id: event['id']?.toString() ?? '',
      infoHash: resolvedInfoHash,
      title: resolvedTitle,
      categoryId: categoryId,
      categoryLabel: resolveCategoryLabel(categoryId),
      totalSize: totalSize,
      createdAt: createdAt,
      fileCount: files.length,
      seeders: seeders,
      leechers: leechers,
      completed: completed,
      magnetUri: magnetUri,
      trackers: trackers,
      files: files,
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _parseCreatedAt(Object? value) {
    if (value is int) return value;
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 0;
    return date.millisecondsSinceEpoch ~/ 1000;
  }

  static TorrentFile? _parseFileTag(List<dynamic> tag) {
    final value = tag[1].toString();

    // Format 2: ["file", "name", "size"]
    if (tag.length >= 3) {
      final name = value;
      final size = int.tryParse(tag[2].toString()) ?? 0;
      return TorrentFile(name: name, size: size);
    }

    // Format 1: ["file", "name;size"]
    final semicolonIndex = value.lastIndexOf(';');
    if (semicolonIndex > 0) {
      final name = value.substring(0, semicolonIndex);
      final size = int.tryParse(value.substring(semicolonIndex + 1)) ?? 0;
      return TorrentFile(name: name, size: size);
    }

    // Filename only, no size
    return TorrentFile(name: value, size: 0);
  }

  static void _parseLabelTag(
    String value,
    void Function(String) onCategory,
    void Function(int) onSeeders,
    void Function(int) onLeechers,
    void Function(int) onCompleted,
  ) {
    if (value.startsWith('u2p.cat:')) {
      onCategory(value.substring(8));
    } else if (value.startsWith('u2p.seed:')) {
      onSeeders(int.tryParse(value.substring(9)) ?? 0);
    } else if (value.startsWith('u2p.leech:')) {
      onLeechers(int.tryParse(value.substring(10)) ?? 0);
    } else if (value.startsWith('u2p.completed:')) {
      onCompleted(int.tryParse(value.substring(14)) ?? 0);
    }
  }

  @override
  List<Object?> get props => [
        id,
        infoHash,
        title,
        categoryId,
        totalSize,
        createdAt,
        seeders,
        leechers
      ];
}
