import 'package:equatable/equatable.dart';

class TorrentItem extends Equatable {
  const TorrentItem({
    required this.hash,
    required this.name,
    required this.progress,
    required this.state,
    required this.downloadSpeed,
    required this.downloadedBytes,
    required this.totalSizeBytes,
    required this.updatedAt,
  });

  final String hash;
  final String name;
  final double progress;
  final String state;
  final int downloadSpeed;
  final int downloadedBytes;
  final int totalSizeBytes;
  final DateTime updatedAt;

  factory TorrentItem.fromJson(Map<String, dynamic> json) {
    return TorrentItem(
      hash: json['hash']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      state: json['state']?.toString() ?? 'unknown',
      downloadSpeed: (json['dlspeed'] as num?)?.toInt() ?? 0,
      totalSizeBytes: ((json['total_size'] ?? json['size']) as num?)?.toInt() ?? 0,
      downloadedBytes: (json['downloaded'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [hash, name, progress, state, downloadSpeed, downloadedBytes, totalSizeBytes, updatedAt];
}
