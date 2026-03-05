import 'package:easy_film/features/ygg/data/ygg_datasource.dart';
import 'package:easy_film/features/ygg/domain/ygg_search_result.dart';

/// Repository orchestrating Ygg torrent search.
///
/// Handles deduplication by infoHash and delegates to [YggDatasource].
class YggRepository {
  YggRepository({YggDatasource? datasource})
      : _datasource = datasource ?? YggDatasource();

  final YggDatasource _datasource;

  /// Search for torrents matching [searchTerm].
  ///
  /// Returns deduplicated results (by infoHash).
  Future<List<YggSearchResult>> search(String searchTerm) async {
    final rawResults = await _datasource.search(searchTerm);
    return _deduplicateByInfoHash(rawResults);
  }

  /// Cancel the current search.
  void cancelSearch() {
    _datasource.cancelSearch();
  }

  /// Disconnect from the relay.
  Future<void> disconnect() async {
    await _datasource.disconnect();
  }

  List<YggSearchResult> _deduplicateByInfoHash(List<YggSearchResult> results) {
    final seen = <String>{};
    return results.where((r) {
      if (r.infoHash.isEmpty) return true;
      return seen.add(r.infoHash);
    }).toList(growable: false);
  }
}
