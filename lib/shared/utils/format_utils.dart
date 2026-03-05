/// Utility helpers for formatting values in the UI.
class FormatUtils {
  FormatUtils._();

  /// Formats bytes into human-readable size (KB, MB, GB, TB).
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Formats bytes/s into human-readable speed.
  static String formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    return '${formatBytes(bytesPerSecond)}/s';
  }

  /// Formats a UNIX timestamp as a relative age string in French.
  ///
  /// Examples: "2 mois", "3 jours", "1 heure", "< 1 min".
  static String formatRelativeAge(int unixTimestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
    final diff = now.difference(date);

    if (diff.isNegative) return 'dans le futur';
    if (diff.inDays >= 365) {
      final years = diff.inDays ~/ 365;
      return years == 1 ? '1 an' : '$years ans';
    }
    if (diff.inDays >= 30) {
      final months = diff.inDays ~/ 30;
      return '$months mois';
    }
    if (diff.inDays >= 1) {
      return diff.inDays == 1 ? '1 jour' : '${diff.inDays} jours';
    }
    if (diff.inHours >= 1) {
      return diff.inHours == 1 ? '1 heure' : '${diff.inHours} heures';
    }
    if (diff.inMinutes >= 1) {
      return diff.inMinutes == 1 ? '1 min' : '${diff.inMinutes} min';
    }
    return '< 1 min';
  }

  /// Normalizes a file path (deduplicates slashes, ensures leading slash).
  static String normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    var normalized = trimmed.replaceAll(RegExp(r'/+'), '/');
    if (!normalized.startsWith('/')) normalized = '/$normalized';
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// Returns the parent folder path.
  static String parentPath(String path) {
    final normalized = normalizePath(path);
    if (normalized.isEmpty || normalized == '/') return '';
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash <= 0) return '/';
    return normalized.substring(0, lastSlash);
  }

  /// Translates qBittorrent state strings to French labels.
  static String translateTorrentState(String state) {
    return switch (state.toLowerCase()) {
      'downloading' || 'forceddl' => 'Téléchargement',
      'stalledDL' || 'stalleddl' => 'En attente (DL)',
      'uploading' || 'forcedup' => 'Envoi en cours',
      'stalledUP' || 'stalledup' => 'En partage',
      'pausedDL' || 'pauseddl' => 'En pause',
      'pausedUP' || 'pausedup' => 'Terminé (pause)',
      'queueddl' || 'queuedup' => 'En file d\'attente',
      'checkingdl' || 'checkingup' || 'checkingresumedata' => 'Vérification…',
      'moving' => 'Déplacement…',
      'error' || 'missingfiles' => 'Erreur',
      'unknown' => 'Inconnu',
      _ => state,
    };
  }

  /// Returns a semantic color for a torrent state.
  static TorrentStateInfo torrentStateInfo(String state) {
    return switch (state.toLowerCase()) {
      'downloading' || 'forceddl' => TorrentStateInfo.downloading,
      'stalleddl' => TorrentStateInfo.waiting,
      'uploading' || 'forcedup' || 'stalledup' => TorrentStateInfo.seeding,
      'pauseddl' => TorrentStateInfo.paused,
      'pausedup' => TorrentStateInfo.completed,
      'error' || 'missingfiles' => TorrentStateInfo.error,
      'checkingdl' || 'checkingup' || 'checkingresumedata' || 'moving' => TorrentStateInfo.checking,
      _ => TorrentStateInfo.unknown,
    };
  }
}

enum TorrentStateInfo {
  downloading,
  waiting,
  seeding,
  paused,
  completed,
  error,
  checking,
  unknown,
}
