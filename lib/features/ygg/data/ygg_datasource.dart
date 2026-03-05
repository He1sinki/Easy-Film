import 'dart:async';
import 'dart:developer' as developer;

import 'package:easy_film/features/ygg/domain/ygg_search_result.dart';
import 'package:easy_film/shared/models/app_error.dart';
import 'package:easy_film/shared/network/nostr_client.dart';

/// Datasource that queries the Nostr relay for NIP-35 torrent events.
class YggDatasource {
  YggDatasource({NostrClient? nostrClient})
      : _nostrClient = nostrClient ?? NostrClient();

  final NostrClient _nostrClient;
  NostrSubscription? _activeSubscription;

  /// Search for torrents matching [searchTerm].
  ///
  /// Connects to the relay if not yet connected, sends a NIP-50 REQ
  /// for Kind 2003 events, collects all EVENT messages until EOSE or timeout,
  /// then returns parsed results.
  ///
  /// Automatically cancels any previous subscription (FR-009).
  Future<List<YggSearchResult>> search(String searchTerm) async {
    // Cancel previous subscription
    cancelSearch();

    try {
      if (!_nostrClient.isConnected) {
        await _nostrClient.connect();
      }
    } catch (e) {
      throw AppError(
        AppErrorType.nostrConnection,
        'Impossible de se connecter au relais Nostr.',
        cause: e,
      );
    }

    final results = <YggSearchResult>[];
    final completer = Completer<List<YggSearchResult>>();

    try {
      _activeSubscription = _nostrClient.subscribe(searchTerm: searchTerm);

      _activeSubscription!.events.listen(
        (event) {
          try {
            final result = YggSearchResult.fromNostrEvent(event);
            results.add(result);
          } catch (e) {
            developer.log('Failed to parse event: $e', name: 'YggDatasource');
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(results);
          }
        },
        onError: (Object error) {
          if (!completer.isCompleted) {
            completer.completeError(AppError(
              AppErrorType.nostrTimeout,
              'Erreur de communication avec le relais Nostr.',
              cause: error,
            ));
          }
        },
      );
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(AppError(
          AppErrorType.nostrConnection,
          'Erreur lors de la souscription au relais Nostr.',
          cause: e,
        ));
      }
    }

    return completer.future;
  }

  /// Cancel the current search subscription.
  void cancelSearch() {
    _activeSubscription?.close();
    _activeSubscription = null;
  }

  /// Disconnect from the relay.
  Future<void> disconnect() async {
    cancelSearch();
    await _nostrClient.disconnect();
  }
}
