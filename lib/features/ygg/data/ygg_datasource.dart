import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:easy_film/features/settings/data/settings_repository.dart';
import 'package:easy_film/features/ygg/domain/ygg_search_result.dart';
import 'package:easy_film/shared/models/app_error.dart';
import 'package:easy_film/shared/network/c411_client.dart';
import 'package:easy_film/shared/network/http_client_factory.dart';

/// Datasource that queries c411 torrent API.
class YggDatasource {
  YggDatasource({
    SettingsRepository? settingsRepository,
    C411Client? c411Client,
  })  : _settingsRepository = settingsRepository ?? SettingsRepository(),
        _c411Client = c411Client;

  final SettingsRepository _settingsRepository;
  C411Client? _c411Client;
  String? _currentBaseUrl;
  CancelToken? _activeCancelToken;

  /// Search for torrents matching [searchTerm].
  Future<List<YggSearchResult>> search(String searchTerm) async {
    cancelSearch();

    final settings = await _settingsRepository.load();
    final apiKey = settings.c411ApiKey.trim();
    final baseUrl = _resolveBaseUrl(settings.c411ApiBaseUrl);

    if (apiKey.isEmpty) {
      throw const AppError(
        AppErrorType.validation,
        'Configurez la cle API c411 dans les reglages.',
      );
    }

    final client = _clientFor(baseUrl);
    _activeCancelToken = CancelToken();

    try {
      final payload = await client.searchTorrents(
        term: searchTerm,
        bearerToken: apiKey,
        cancelToken: _activeCancelToken,
      );
      final data = payload['data'];
      if (data is! List) {
        return const <YggSearchResult>[];
      }

      final results = <YggSearchResult>[];
      for (final item in data) {
        if (item is! Map) continue;
        try {
          results.add(
              YggSearchResult.fromC411Json(Map<String, dynamic>.from(item)));
        } catch (e) {
          developer.log('Failed to parse c411 item: $e', name: 'YggDatasource');
        }
      }
      return results;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return const <YggSearchResult>[];
      }

      final status = e.response?.statusCode ?? 0;
      if (status == 401 || status == 403) {
        throw AppError(
          AppErrorType.auth,
          'Authentification c411 echouee. Verifiez la cle API.',
          cause: e,
        );
      }
      if (status >= 500) {
        throw AppError(
          AppErrorType.server,
          'Le serveur c411 a renvoye une erreur.',
          cause: e,
        );
      }
      throw AppError(
        AppErrorType.network,
        'Impossible d\'interroger c411.',
        cause: e,
      );
    } finally {
      _activeCancelToken = null;
    }
  }

  C411Client _clientFor(String baseUrl) {
    if (_c411Client != null && _currentBaseUrl == baseUrl) {
      return _c411Client!;
    }

    _c411Client = C411Client(HttpClientFactory.c411(baseUrl));
    _currentBaseUrl = baseUrl;
    return _c411Client!;
  }

  String _resolveBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'https://c411.org';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'https://c411.org';
    }

    return uri.origin;
  }

  /// Cancel the current HTTP search request.
  void cancelSearch() {
    _activeCancelToken?.cancel('Cancelled by user action.');
    _activeCancelToken = null;
  }

  /// No persistent connection to close for HTTP mode.
  Future<void> disconnect() async {
    cancelSearch();
  }
}
