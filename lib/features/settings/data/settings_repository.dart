import 'package:easy_film/features/settings/domain/settings_form_model.dart';
import 'package:easy_film/shared/storage/secure_storage_service.dart';

class SettingsRepository {
  SettingsRepository({SecureStorageService? storage})
      : _storage = storage ?? FlutterSecureStorageService();

  final SecureStorageService _storage;

  static const _qbUrl = 'qb_url';
  static const _qbUser = 'qb_user';
  static const _qbPass = 'qb_pass';
  static const _fbUrl = 'fb_url';
  static const _fbUser = 'fb_user';
  static const _fbPass = 'fb_pass';
  static const _targetFolder = 'target_folder';
  static const _c411ApiBaseUrl = 'c411_api_base_url';
  static const _c411ApiKey = 'c411_api_key';

  Future<void> save(SettingsFormModel model) async {
    await _storage.write(_qbUrl, model.qbittorrentUrl);
    await _storage.write(_qbUser, model.qbittorrentUsername);
    await _storage.write(_qbPass, model.qbittorrentPassword);
    await _storage.write(_fbUrl, model.filebrowserUrl);
    await _storage.write(_fbUser, model.filebrowserUsername);
    await _storage.write(_fbPass, model.filebrowserPassword);
    await _storage.write(_targetFolder, model.targetFolder);
    await _storage.write(_c411ApiBaseUrl, model.c411ApiBaseUrl);
    await _storage.write(_c411ApiKey, model.c411ApiKey);
  }

  Future<SettingsFormModel> load() async {
    final qbUrl = await _storage.read(_qbUrl) ?? '';
    final qbUser = await _storage.read(_qbUser) ?? '';
    final qbPass = await _storage.read(_qbPass) ?? '';
    final fbUrl = await _storage.read(_fbUrl) ?? '';
    final fbUser = await _storage.read(_fbUser) ?? '';
    final fbPass = await _storage.read(_fbPass) ?? '';
    final targetFolder = await _storage.read(_targetFolder) ?? '';
    final c411ApiBaseUrl =
        await _storage.read(_c411ApiBaseUrl) ?? 'https://c411.org';
    final c411ApiKey = await _storage.read(_c411ApiKey) ?? '';

    return SettingsFormModel(
      qbittorrentUrl: qbUrl,
      qbittorrentUsername: qbUser,
      qbittorrentPassword: qbPass,
      filebrowserUrl: fbUrl,
      filebrowserUsername: fbUser,
      filebrowserPassword: fbPass,
      targetFolder: targetFolder,
      c411ApiBaseUrl: c411ApiBaseUrl,
      c411ApiKey: c411ApiKey,
    );
  }
}
