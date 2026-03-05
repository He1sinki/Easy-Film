import 'package:easy_film/features/filebrowser/data/create_download_service.dart';
import 'package:easy_film/features/filebrowser/data/download_service.dart';
import 'package:easy_film/features/filebrowser/data/filebrowser_datasource.dart';
import 'package:easy_film/features/filebrowser/domain/background_transfer.dart';
import 'package:easy_film/features/filebrowser/domain/filebrowser_download_url_builder.dart';
import 'package:easy_film/features/filebrowser/domain/media_file_entry.dart';
import 'package:easy_film/features/settings/domain/settings_form_model.dart';
import 'package:easy_film/features/settings/data/settings_repository.dart';
import 'package:easy_film/shared/errors/user_message_mapper.dart';
import 'package:easy_film/shared/models/app_error.dart';
import 'package:easy_film/shared/network/filebrowser_client.dart';
import 'package:easy_film/shared/network/http_client_factory.dart';
import 'package:easy_film/shared/utils/format_utils.dart';
import 'package:flutter/foundation.dart';

class FilebrowserController extends ChangeNotifier {
  FilebrowserController({
    SettingsRepository? settingsRepository,
    DownloadService? downloadService,
    Future<List<MediaFileEntry>> Function(SettingsFormModel settings)? listResources,
    Future<String?> Function(SettingsFormModel settings)? login,
  })  : _settingsRepository = settingsRepository ?? SettingsRepository(),
        _downloadService = downloadService ?? createDownloadService(),
        _listResourcesOverride = listResources,
        _loginOverride = login;

  final SettingsRepository _settingsRepository;
  final DownloadService _downloadService;
  final Future<List<MediaFileEntry>> Function(SettingsFormModel settings)? _listResourcesOverride;
  final Future<String?> Function(SettingsFormModel settings)? _loginOverride;

  List<MediaFileEntry> files = const [];
  final List<BackgroundTransfer> transfers = [];
  String rootFolder = '';
  String? message;
  bool isMessageError = true;
  bool isLoading = false;
  bool _isDisposed = false;

  Future<void> loadFolder() async {
    isLoading = true;
    _notifySafely();
    try {
      final settings = await _settingsRepository.load();
      rootFolder = FormatUtils.normalizePath(settings.targetFolder);
      final token = await _requireToken(settings);
      files = await _listResources(settings, existingToken: token);
      message = null;
    } catch (error) {
      message = UserMessageMapper.fromError(error);
      isMessageError = true;
    } finally {
      isLoading = false;
      _notifySafely();
    }
  }

  Future<void> download(MediaFileEntry entry) async {
    try {
      final settings = await _settingsRepository.load();
      final token = await _requireToken(settings);

      final url = FilebrowserDownloadUrlBuilder.build(
        baseUrl: settings.filebrowserUrl,
        token: token,
        entry: entry,
      );
      final taskId = await _downloadService.enqueue(url: url, filename: entry.name);
      transfers.add(
        BackgroundTransfer(
          taskId: taskId,
          remoteUrl: url,
          localPath: entry.name,
          progress: 0,
          status: TransferStatus.queued,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      message = 'Téléchargement démarré.';
      isMessageError = false;
    } catch (error) {
      message = UserMessageMapper.fromError(error);
      isMessageError = true;
    }
    _notifySafely();
  }

  Future<String> _requireToken(SettingsFormModel settings) async {
    final token = await _login(settings);
    if (token == null || token.isEmpty) {
      throw const AppError(AppErrorType.auth, 'Authentification FileBrowser impossible.');
    }
    return token;
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<String?> _login(SettingsFormModel settings) async {
    if (_loginOverride != null) {
      return _loginOverride(settings);
    }
    final client = FilebrowserClient(HttpClientFactory.filebrowser(settings.filebrowserUrl));
    final datasource = FilebrowserDatasource(client);
    return datasource.login(
      username: settings.filebrowserUsername,
      password: settings.filebrowserPassword,
    );
  }

  Future<List<MediaFileEntry>> _listResources(
    SettingsFormModel settings, {
    String? existingToken,
  }) async {
    if (_listResourcesOverride != null) {
      return _listResourcesOverride(settings);
    }
    final client = FilebrowserClient(HttpClientFactory.filebrowser(settings.filebrowserUrl));
    if (existingToken != null && existingToken.isNotEmpty) {
      client.setToken(existingToken);
    }
    final datasource = FilebrowserDatasource(client);
    return _listResourcesRecursively(
      datasource: datasource,
      rootFolder: settings.targetFolder,
    );
  }

  Future<List<MediaFileEntry>> _listResourcesRecursively({
    required FilebrowserDatasource datasource,
    required String rootFolder,
  }) async {
    final foldersToScan = <String>[rootFolder];
    final scannedFolders = <String>{};
    final collected = <MediaFileEntry>[];
    final collectedKeys = <String>{};

    while (foldersToScan.isNotEmpty) {
      final currentFolder = foldersToScan.removeAt(0);
      final normalizedFolder = FormatUtils.normalizePath(currentFolder);
      if (scannedFolders.contains(normalizedFolder)) {
        continue;
      }
      scannedFolders.add(normalizedFolder);

      final items = await datasource.listResources(currentFolder);
      for (final item in items) {
        final normalizedItemPath = FormatUtils.normalizePath(item.path);
        final key = '${item.isDirectory ? 'd' : 'f'}:$normalizedItemPath';
        if (!collectedKeys.contains(key)) {
          collectedKeys.add(key);
          collected.add(item);
        }

        if (item.isDirectory) {
          final subFolderPath = normalizedItemPath.isEmpty
              ? FormatUtils.normalizePath('$normalizedFolder/${item.name}')
              : normalizedItemPath;
          if (subFolderPath.isNotEmpty && !scannedFolders.contains(subFolderPath)) {
            foldersToScan.add(subFolderPath);
          }
        }
      }
    }

    collected.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });

    return collected;
  }

}
