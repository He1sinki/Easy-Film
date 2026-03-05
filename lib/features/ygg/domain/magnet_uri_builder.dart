/// Builds magnet URIs from torrent metadata.
///
/// Combines the infohash, display name, default trackers, and
/// event-specific trackers into a valid magnet link.
class MagnetUriBuilder {
  MagnetUriBuilder._();

  /// Default tracker list from U2P Client source (most reliable subset).
  static const List<String> magnetTrackers = [
    'https://tracker.yggleak.top/announce',
    'udp://tracker.opentrackr.org:1337/announce',
    'udp://open.demonii.com:1337/announce',
    'udp://open.stealth.si:80/announce',
    'udp://exodus.desync.com:6969/announce',
    'udp://tracker.torrent.eu.org:451/announce',
    'udp://tracker.srv00.com:6969/announce',
    'udp://tracker.dler.org:6969/announce',
    'udp://explodie.org:6969/announce',
  ];

  /// Build a magnet URI from an infohash, title, and optional event trackers.
  ///
  /// The trackers list merges event-specific trackers with the default
  /// [magnetTrackers], de-duplicating entries.
  static String build({
    required String infoHash,
    required String title,
    List<String> eventTrackers = const [],
  }) {
    final buffer = StringBuffer('magnet:?xt=urn:btih:$infoHash');
    buffer.write('&dn=${Uri.encodeComponent(title)}');

    // Merge event trackers + default trackers, de-duplicate
    final seen = <String>{};
    final allTrackers = [...eventTrackers, ...magnetTrackers];
    for (final tracker in allTrackers) {
      if (tracker.isNotEmpty && seen.add(tracker)) {
        buffer.write('&tr=${Uri.encodeComponent(tracker)}');
      }
    }

    return buffer.toString();
  }
}
