import 'dart:developer' as developer;

import 'package:easy_film/features/ygg/data/ygg_repository.dart';
import 'package:easy_film/features/ygg/domain/send_torrent_use_case.dart';
import 'package:easy_film/features/ygg/domain/ygg_search_query.dart';
import 'package:easy_film/features/ygg/domain/ygg_search_result.dart';
import 'package:easy_film/shared/errors/user_message_mapper.dart';
import 'package:flutter/foundation.dart';

/// Status of the send-to-qBittorrent operation for a single result.
enum SendTorrentStatus { idle, sending, success, error }

/// Controller for the Ygg torrent search screen.
///
/// Manages search state, filtering, sorting, and send-to-qBittorrent status.
class YggController extends ChangeNotifier {
  YggController({YggRepository? repository, SendTorrentUseCase? sendTorrentUseCase})
      : _repository = repository ?? YggRepository(),
        _sendTorrentUseCase = sendTorrentUseCase ?? SendTorrentUseCase();

  final YggRepository _repository;
  final SendTorrentUseCase _sendTorrentUseCase;

  // ─── Search state ───────────────────────────────────────────
  List<YggSearchResult> _allResults = [];
  List<YggSearchResult> _filteredResults = [];
  bool isLoading = false;
  bool _hasSearched = false;
  String? errorMessage;
  YggSearchQuery _query = const YggSearchQuery(term: '');

  /// Results after applying filter and sort.
  List<YggSearchResult> get results => _filteredResults;

  /// All unfiltered results from the last search.
  List<YggSearchResult> get allResults => _allResults;

  /// Current query (includes active filter and sort).
  YggSearchQuery get query => _query;

  /// Whether there are results to display.
  bool get hasResults => _filteredResults.isNotEmpty;

  /// Whether the search returned empty (no results at all).
  bool get isEmpty => !isLoading && _hasSearched && _allResults.isEmpty && errorMessage == null;

  /// Whether filtered results are empty but unfiltered are not.
  bool get isFilteredEmpty => !isLoading && _allResults.isNotEmpty && _filteredResults.isEmpty;

  /// Whether no search has been performed yet.
  bool get isInitial => !isLoading && !_hasSearched && errorMessage == null;

  // ─── Category filter state ──────────────────────────────────
  /// Dynamic categories extracted from current results with counts.
  Map<String, int> get availableCategories {
    final counts = <String, int>{};
    for (final result in _allResults) {
      final label = result.categoryLabel ?? 'Inconnu';
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts;
  }

  // ─── Send state (per result infoHash) ───────────────────────
  final Map<String, SendTorrentStatus> _sendStatuses = {};
  final Map<String, String> _sendMessages = {};

  /// Get send status for a specific result.
  SendTorrentStatus sendStatusFor(String infoHash) =>
      _sendStatuses[infoHash] ?? SendTorrentStatus.idle;

  /// Get send message for a specific result.
  String? sendMessageFor(String infoHash) => _sendMessages[infoHash];

  // ─── Search ─────────────────────────────────────────────────

  /// Execute a search with the given [term].
  ///
  /// Cancels any in-progress search (FR-009).
  /// Ignores empty terms (FR-010 — button should be disabled).
  Future<void> search(String term) async {
    if (term.trim().isEmpty) return;

    // Cancel previous search
    _repository.cancelSearch();

    _query = YggSearchQuery(term: term.trim());
    isLoading = true;
    _hasSearched = true;
    errorMessage = null;
    _allResults = [];
    _filteredResults = [];
    _sendStatuses.clear();
    _sendMessages.clear();
    notifyListeners();

    try {
      _allResults = await _repository.search(term.trim());
      _applyFilterAndSort();
      developer.log('Search "${term.trim()}" → ${_allResults.length} results', name: 'YggController');
    } catch (error) {
      errorMessage = UserMessageMapper.fromError(error);
      developer.log('Search error: $error', name: 'YggController');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─── Filter ─────────────────────────────────────────────────

  /// Set category filter. Pass null to clear.
  void setCategoryFilter(String? categoryLabel) {
    if (categoryLabel == null) {
      _query = _query.copyWith(categoryFilter: () => null);
    } else {
      _query = _query.copyWith(categoryFilter: () => categoryLabel);
    }
    _applyFilterAndSort();
    notifyListeners();
  }

  // ─── Sort ───────────────────────────────────────────────────

  /// Set sort criteria.
  void setSortCriteria(SortCriteria criteria) {
    _query = _query.copyWith(sortCriteria: criteria);
    _applyFilterAndSort();
    notifyListeners();
  }

  /// Toggle sort direction.
  void toggleSortDirection() {
    _query = _query.copyWith(sortDescending: !_query.sortDescending);
    _applyFilterAndSort();
    notifyListeners();
  }

  // ─── Send to qBittorrent ────────────────────────────────────

  /// Update the send status for a result. Called from use case / screen.
  void setSendStatus(String infoHash, SendTorrentStatus status, {String? message}) {
    _sendStatuses[infoHash] = status;
    if (message != null) {
      _sendMessages[infoHash] = message;
    } else {
      _sendMessages.remove(infoHash);
    }
    notifyListeners();
  }

  /// Send the given [result] to qBittorrent.
  ///
  /// Returns `true` if qBittorrent needs configuration (redirect to Settings).
  Future<bool> sendTorrent(YggSearchResult result) async {
    setSendStatus(result.infoHash, SendTorrentStatus.sending);

    final sendResult = await _sendTorrentUseCase.execute(result);

    return switch (sendResult) {
      SendNeedsConfig() => () {
          setSendStatus(result.infoHash, SendTorrentStatus.idle);
          return true;
        }(),
      SendSuccess() => () {
          setSendStatus(result.infoHash, SendTorrentStatus.success,
              message: 'Torrent envoyé à qBittorrent');
          return false;
        }(),
      SendFailure(message: final msg) => () {
          setSendStatus(result.infoHash, SendTorrentStatus.error, message: msg);
          return false;
        }(),
    };
  }

  // ─── Internal ───────────────────────────────────────────────

  void _applyFilterAndSort() {
    var list = List<YggSearchResult>.from(_allResults);

    // Filter by category
    final filter = _query.categoryFilter;
    if (filter != null && filter.isNotEmpty) {
      list = list.where((r) => r.categoryLabel == filter).toList();
    }

    // Sort
    list.sort((a, b) {
      final cmp = switch (_query.sortCriteria) {
        SortCriteria.date => a.createdAt.compareTo(b.createdAt),
        SortCriteria.size => a.totalSize.compareTo(b.totalSize),
        SortCriteria.seeders => a.seeders.compareTo(b.seeders),
      };
      return _query.sortDescending ? -cmp : cmp;
    });

    _filteredResults = list;
  }

  @override
  void dispose() {
    _repository.cancelSearch();
    super.dispose();
  }
}
