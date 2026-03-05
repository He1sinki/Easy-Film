import 'dart:async';
import 'dart:developer' as developer;

import 'package:easy_film/features/qbittorrent/data/qbittorrent_repository.dart';
import 'package:easy_film/features/qbittorrent/domain/torrent_item.dart';
import 'package:easy_film/features/qbittorrent/domain/upload_torrent_use_case.dart';
import 'package:easy_film/shared/errors/user_message_mapper.dart';
import 'package:flutter/foundation.dart';

class QbittorrentController extends ChangeNotifier {
  QbittorrentController({
    QbittorrentRepository? repository,
    UploadTorrentUseCase? uploadUseCase,
    Duration trackerCleanupDelay = const Duration(seconds: 10),
  })  : _repository = repository ?? QbittorrentRepository(),
        _uploadUseCase = uploadUseCase ?? UploadTorrentUseCase(),
        _trackerCleanupDelay = trackerCleanupDelay;

  final QbittorrentRepository _repository;
  final UploadTorrentUseCase _uploadUseCase;
  final Duration _trackerCleanupDelay;

  List<TorrentItem> torrents = const [];
  bool isLoading = false;
  String? message;
  Timer? _pollTimer;
  final Map<String, Timer> _trackerCleanupTimers = <String, Timer>{};

  Future<void> refreshNow({bool clearMessageOnSuccess = true}) async {
    isLoading = true;
    notifyListeners();
    try {
      torrents = await _repository.listTorrents();
      if (clearMessageOnSuccess) {
        message = null;
      }
    } catch (error) {
      message = UserMessageMapper.fromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void startPolling() {
    _pollTimer?.cancel();
    refreshNow();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => refreshNow());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    developer.log('Polling arrêté.', name: 'QbittorrentController');
  }

  Future<void> uploadTorrent() async {
    try {
      final result = await _uploadUseCase.pickAndUpload();
      final uploadedCount = result.uploadedCount;
      developer.log(
        'Résultat upload: uploadedCount=$uploadedCount, hashesDetectés=${result.torrentHashes.length}.',
        name: 'QbittorrentController',
      );
      if (uploadedCount == 0) {
        developer.log(
          'Aucun fichier uploadé, cleanup trackers non planifié.',
          name: 'QbittorrentController',
          level: 900,
        );
        return;
      }

      message = uploadedCount == 1
          ? 'Torrent envoyé avec succès.'
          : '$uploadedCount torrents envoyés avec succès.';
      await refreshNow(clearMessageOnSuccess: false);
    } catch (error) {
      message = UserMessageMapper.fromError(error);
      notifyListeners();
    }
  }

  void _scheduleTrackerCleanup(List<String> hashes) {
    developer.log(
      'Planification suppression trackers: ${hashes.length} hash(es), délai=${_trackerCleanupDelay.inSeconds}s.',
      name: 'QbittorrentController',
    );
    for (final hash in hashes) {
      if (hash.isEmpty) {
        developer.log(
          'Hash torrent vide ignoré pour suppression trackers.',
          name: 'QbittorrentController',
          level: 900,
        );
        continue;
      }
      _trackerCleanupTimers[hash]?.cancel();
      developer.log(
        'Timer suppression trackers programmé pour hash=$hash.',
        name: 'QbittorrentController',
      );
      _trackerCleanupTimers[hash] = Timer(_trackerCleanupDelay, () async {
        try {
          developer.log(
            'Début suppression trackers pour hash=$hash.',
            name: 'QbittorrentController',
          );
          await _repository.removeAllTrackers(hash);
          developer.log(
            'Suppression trackers terminée pour hash=$hash.',
            name: 'QbittorrentController',
          );
        } catch (error) {
          developer.log(
            'Erreur suppression trackers pour hash=$hash: $error',
            name: 'QbittorrentController',
            level: 1000,
            error: error,
          );
          message = UserMessageMapper.fromError(error);
          notifyListeners();
        } finally {
          _trackerCleanupTimers.remove(hash);
          developer.log(
            'Timer suppression trackers nettoyé pour hash=$hash.',
            name: 'QbittorrentController',
          );
        }
      });
    }
  }

  Future<void> startTorrent(String hash) async {
    try {
      developer.log(
        'Demande de reprise torrent pour hash=$hash.',
        name: 'QbittorrentController',
      );
      await _repository.resumeTorrent(hash);
      _scheduleTrackerCleanup(<String>[hash]);
      developer.log(
        'Reprise torrent réussie, cleanup trackers planifié pour hash=$hash.',
        name: 'QbittorrentController',
      );
      message = 'Torrent démarré.';
      await refreshNow(clearMessageOnSuccess: false);
    } catch (error) {
      message = UserMessageMapper.fromError(error);
      notifyListeners();
    }
  }

  Future<void> pauseTorrent(String hash) async {
    try {
      await _repository.pauseTorrent(hash);
      message = 'Torrent en pause.';
      await refreshNow(clearMessageOnSuccess: false);
    } catch (error) {
      message = UserMessageMapper.fromError(error);
      notifyListeners();
    }
  }

  Future<void> removeTorrent(String hash) async {
    try {
      await _repository.deleteTorrent(hash);
      message = 'Torrent supprimé.';
      await refreshNow(clearMessageOnSuccess: false);
    } catch (error) {
      message = UserMessageMapper.fromError(error);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    developer.log(
      'Dispose controller: annulation ${_trackerCleanupTimers.length} timer(s) de suppression trackers.',
      name: 'QbittorrentController',
      level: 900,
    );
    stopPolling();
    for (final timer in _trackerCleanupTimers.values) {
      timer.cancel();
    }
    _trackerCleanupTimers.clear();
    super.dispose();
  }
}
