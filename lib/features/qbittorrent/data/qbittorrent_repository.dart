import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:easy_film/features/qbittorrent/data/qbittorrent_auth_datasource.dart';
import 'package:easy_film/features/qbittorrent/data/qbittorrent_torrents_datasource.dart';
import 'package:easy_film/features/qbittorrent/domain/torrent_item.dart';
import 'package:easy_film/features/settings/data/settings_repository.dart';
import 'package:easy_film/shared/models/app_error.dart';
import 'package:easy_film/shared/network/http_client_factory.dart';
import 'package:easy_film/shared/network/qbittorrent_client.dart';
import 'package:flutter/foundation.dart';

class QbittorrentRepository {
  QbittorrentRepository({SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository ?? SettingsRepository();

  final SettingsRepository _settingsRepository;
  QbittorrentClient? _client;
  QbittorrentAuthDatasource? _authDatasource;
  QbittorrentTorrentsDatasource? _torrentsDatasource;

  Future<void> _ensureClient() async {
    final settings = await _settingsRepository.load();
    final baseUrl = _resolveQbittorrentBaseUrl(settings.qbittorrentUrl);
    if (baseUrl.isEmpty) {
      throw const AppError(AppErrorType.validation, 'Configurez qBittorrent dans Settings.');
    }
    _client ??= QbittorrentClient(HttpClientFactory.qbittorrent(baseUrl));
    _authDatasource ??= QbittorrentAuthDatasource(_client!);
    _torrentsDatasource ??= QbittorrentTorrentsDatasource(_client!);
  }

  Future<void> _authenticate() async {
    await _ensureClient();
    if (_client!.isAuthenticated) {
      return;
    }
    final settings = await _settingsRepository.load();
    final ok = await _authDatasource!.login(
      username: settings.qbittorrentUsername,
      password: settings.qbittorrentPassword,
    );
    if (!ok) {
      throw const AppError(AppErrorType.auth, 'Authentification qBittorrent impossible.');
    }
  }

  Future<void> addTorrent(MultipartFile file) async {
    return addTorrents(<MultipartFile>[file]);
  }

  /// Send a magnet link to qBittorrent for download.
  Future<void> addTorrentByMagnet(String magnetUrl) async {
    if (magnetUrl.isEmpty) {
      throw const AppError(AppErrorType.validation, 'Lien magnet vide.');
    }
    final response = await _runAuthenticatedAction(
      () => _torrentsDatasource!.addTorrentByMagnetUrl(magnetUrl),
    );
    _ensureSuccess(response, 'Échec d\'envoi du lien magnet');
  }

  Future<List<String>> addTorrentsAndDetectNewHashes(
    List<MultipartFile> files, {
    Duration detectTimeout = const Duration(seconds: 20),
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    developer.log(
      'Détection hash: début pour ${files.length} fichier(s), timeout=${detectTimeout.inSeconds}s, interval=${pollInterval.inSeconds}s.',
      name: 'QbittorrentRepository',
    );
    final beforeHashes = (await listTorrents())
        .map((torrent) => torrent.hash)
        .where((hash) => hash.isNotEmpty)
        .toSet();
    developer.log(
      'Détection hash: ${beforeHashes.length} hash(es) déjà présents avant upload.',
      name: 'QbittorrentRepository',
    );

    await addTorrents(files);

    final detectedHashes = <String>{};
    final deadline = DateTime.now().add(detectTimeout);
    var pollCount = 0;
    while (DateTime.now().isBefore(deadline)) {
      pollCount++;
      final current = await listTorrents();
      for (final torrent in current) {
        if (torrent.hash.isNotEmpty && !beforeHashes.contains(torrent.hash)) {
          detectedHashes.add(torrent.hash);
        }
      }
      developer.log(
        'Détection hash: poll#$pollCount détectés=${detectedHashes.length}/${files.length}.',
        name: 'QbittorrentRepository',
      );
      if (detectedHashes.length >= files.length) {
        break;
      }
      await Future<void>.delayed(pollInterval);
    }

    if (detectedHashes.isEmpty) {
      developer.log(
        'Détection hash: aucun nouveau hash détecté avant timeout.',
        name: 'QbittorrentRepository',
        level: 900,
      );
    } else {
      developer.log(
        'Détection hash: fin avec ${detectedHashes.length} hash(es) détectés.',
        name: 'QbittorrentRepository',
      );
    }

    return detectedHashes.toList(growable: false);
  }

  Future<void> addTorrents(List<MultipartFile> files) async {
    if (files.isEmpty) {
      throw const AppError(AppErrorType.validation, 'Aucun fichier .torrent sélectionné.');
    }
    final response = await _runAuthenticatedAction(() => _torrentsDatasource!.addTorrents(files));
    _ensureSuccess(response, 'Échec d\'envoi torrent');
  }

  Future<List<TorrentItem>> listTorrents() async {
    final response = await _runAuthenticatedAction(() => _torrentsDatasource!.listTorrents());
    _ensureSuccess(response, 'Échec de lecture torrents');

    final rawData = response.data;
    final List<dynamic> items;
    if (rawData is List) {
      items = rawData;
    } else if (rawData is String && rawData.trim().isNotEmpty) {
      final decoded = jsonDecode(rawData);
      items = decoded is List ? decoded : const <dynamic>[];
    } else {
      items = const <dynamic>[];
    }

    return items
        .whereType<Map>()
        .map((item) => TorrentItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<void> resumeTorrent(String hash) async {
    final response = await _runAuthenticatedAction(() => _torrentsDatasource!.resumeTorrent(hash));
    _ensureSuccess(response, 'Échec de reprise torrent');
  }

  Future<void> pauseTorrent(String hash) async {
    final response = await _runAuthenticatedAction(() => _torrentsDatasource!.pauseTorrent(hash));
    _ensureSuccess(response, 'Échec de pause torrent');
  }

  Future<void> deleteTorrent(String hash, {bool deleteFiles = false}) async {
    final response = await _runAuthenticatedAction(
      () => _torrentsDatasource!.deleteTorrent(hash, deleteFiles: deleteFiles),
    );
    _ensureSuccess(response, 'Échec de suppression torrent');
  }

  Future<void> removeAllTrackers(String hash) async {
    developer.log(
      'removeAllTrackers démarré pour hash=$hash.',
      name: 'QbittorrentRepository',
    );
    final trackersResponse = await _runAuthenticatedAction(
      () => _torrentsDatasource!.listTrackers(hash),
    );
    developer.log(
      'listTrackers status=${trackersResponse.statusCode} pour hash=$hash.',
      name: 'QbittorrentRepository',
    );
    _ensureSuccess(trackersResponse, 'Échec de lecture trackers');

    final rawData = trackersResponse.data;
    final List<dynamic> trackers = rawData is List ? rawData : const <dynamic>[];
    developer.log(
      'Trackers reçus: ${trackers.length} (type=${rawData.runtimeType}) pour hash=$hash.',
      name: 'QbittorrentRepository',
    );
    final urls = trackers
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map((item) => item['url']?.toString() ?? '')
        .where(_isRemovableTrackerUrl)
        .toList(growable: false);

    developer.log(
      'Trackers supprimables trouvés: ${urls.length} pour hash=$hash.',
      name: 'QbittorrentRepository',
    );

    if (urls.isEmpty) {
      developer.log(
        'Aucun tracker supprimable pour hash=$hash.',
        name: 'QbittorrentRepository',
        level: 900,
      );
      return;
    }

    final removeResponse = await _runAuthenticatedAction(
      () => _torrentsDatasource!.removeTrackers(hash, urls),
    );
    developer.log(
      'removeTrackers status=${removeResponse.statusCode} pour hash=$hash urls=${urls.join('|')}.',
      name: 'QbittorrentRepository',
    );
    _ensureSuccess(removeResponse, 'Échec de suppression trackers');
    developer.log(
      'removeAllTrackers terminé pour hash=$hash.',
      name: 'QbittorrentRepository',
    );
  }

  bool _isRemovableTrackerUrl(String url) {
    if (url.isEmpty) {
      return false;
    }
    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme) {
      return false;
    }
    return parsed.scheme == 'http' ||
        parsed.scheme == 'https' ||
        parsed.scheme == 'udp' ||
        parsed.scheme == 'ws' ||
        parsed.scheme == 'wss';
  }

  Future<Response<dynamic>> _runAuthenticatedAction(
    Future<Response<dynamic>> Function() action,
  ) async {
    await _authenticate();
    var response = await action();
    if (_isAuthError(response)) {
      _client?.clearSession();
      await _authenticate();
      response = await action();
    }
    return response;
  }

  bool _isAuthError(Response<dynamic> response) {
    return response.statusCode == 401 || response.statusCode == 403;
  }

  void _ensureSuccess(Response<dynamic> response, String context) {
    if ((response.statusCode ?? 500) >= 400) {
      throw AppError(AppErrorType.server, '$context (${response.statusCode}).');
    }
  }

  String _resolveQbittorrentBaseUrl(String inputUrl) {
    if (!kIsWeb) {
      return inputUrl;
    }

    final uri = Uri.tryParse(inputUrl);
    if (uri == null) {
      return inputUrl;
    }

    final isLocalHost = uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1';
    final isHttp = uri.scheme == 'http';
    if (!isLocalHost || !isHttp) {
      return inputUrl;
    }

    if (uri.port == 8788) {
      return inputUrl;
    }

    return uri.replace(port: 8788).toString();
  }
}
