import 'dart:developer' as developer;

import 'package:easy_film/features/qbittorrent/data/qbittorrent_repository.dart';
import 'package:easy_film/features/settings/data/settings_repository.dart';
import 'package:easy_film/features/ygg/domain/magnet_uri_builder.dart';
import 'package:easy_film/features/ygg/domain/ygg_search_result.dart';
import 'package:easy_film/shared/models/app_error.dart';

/// Result of a send-torrent operation.
sealed class SendResult {
  const SendResult();
}

class SendSuccess extends SendResult {
  const SendSuccess();
}

class SendNeedsConfig extends SendResult {
  const SendNeedsConfig();
}

class SendFailure extends SendResult {
  const SendFailure(this.message);
  final String message;
}

/// Use case: send a Ygg search result to qBittorrent via its magnet link.
///
/// Checks that qBittorrent is configured (FR-012: redirects to Settings if not),
/// builds the magnet URI, and sends it.
class SendTorrentUseCase {
  SendTorrentUseCase({
    QbittorrentRepository? qbittorrentRepository,
    SettingsRepository? settingsRepository,
  })  : _qbittorrentRepository = qbittorrentRepository ?? QbittorrentRepository(),
        _settingsRepository = settingsRepository ?? SettingsRepository();

  final QbittorrentRepository _qbittorrentRepository;
  final SettingsRepository _settingsRepository;

  /// Execute the send operation for [result].
  ///
  /// Returns [SendNeedsConfig] if qBittorrent URL is not configured.
  /// Returns [SendSuccess] on success.
  /// Returns [SendFailure] with a user-facing message on error.
  Future<SendResult> execute(YggSearchResult result) async {
    // FR-012: Check qBittorrent configuration
    try {
      final settings = await _settingsRepository.load();
      if (settings.qbittorrentUrl.trim().isEmpty) {
        developer.log(
          'qBittorrent non configuré → redirection Settings.',
          name: 'SendTorrentUseCase',
        );
        return const SendNeedsConfig();
      }
    } catch (e) {
      developer.log('Erreur lecture settings: $e', name: 'SendTorrentUseCase');
      return const SendFailure('Impossible de vérifier la configuration.');
    }

    // Build the magnet URI
    final magnetUrl = MagnetUriBuilder.build(
      infoHash: result.infoHash,
      title: result.title,
      eventTrackers: result.trackers,
    );

    developer.log(
      'Envoi magnet vers qBittorrent: ${result.title} (${result.infoHash})',
      name: 'SendTorrentUseCase',
    );

    // Send to qBittorrent
    try {
      await _qbittorrentRepository.addTorrentByMagnet(magnetUrl);
      developer.log('Envoi réussi: ${result.infoHash}', name: 'SendTorrentUseCase');
      return const SendSuccess();
    } on AppError catch (e) {
      developer.log('Erreur envoi: $e', name: 'SendTorrentUseCase');
      return SendFailure(e.message);
    } catch (e) {
      developer.log('Erreur inattendue envoi: $e', name: 'SendTorrentUseCase');
      return const SendFailure('Échec de l\'envoi vers qBittorrent.');
    }
  }
}
