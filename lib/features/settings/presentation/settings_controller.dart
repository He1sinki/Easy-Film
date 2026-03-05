import 'package:dio/dio.dart';
import 'package:easy_film/features/settings/data/settings_repository.dart';
import 'package:easy_film/features/settings/domain/settings_form_model.dart';
import 'package:easy_film/features/settings/domain/settings_validator.dart';
import 'package:easy_film/shared/errors/user_message_mapper.dart';
import 'package:easy_film/shared/network/filebrowser_client.dart';
import 'package:easy_film/shared/network/http_client_factory.dart';
import 'package:easy_film/shared/network/qbittorrent_client.dart';
import 'package:flutter/foundation.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

  final SettingsRepository _repository;

  SettingsFormModel model = const SettingsFormModel();
  bool isLoading = false;
  bool isTestingQb = false;
  bool isTestingFb = false;
  String? error;
  String? success;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    model = await _repository.load();
    isLoading = false;
    notifyListeners();
  }

  void update(SettingsFormModel value) {
    model = value;
    error = null;
    success = null;
    notifyListeners();
  }

  Future<bool> save() async {
    final validation = SettingsValidator.validate(model);
    if (validation != null) {
      error = validation;
      success = null;
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();
    try {
      await _repository.save(model);
      success = 'Configuration sauvegardée.';
      error = null;
      return true;
    } catch (e) {
      success = null;
      error = UserMessageMapper.fromError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Tests connection to qBittorrent with current form values.
  Future<bool> testQbConnection() async {
    if (model.qbittorrentUrl.isEmpty) {
      error = 'URL qBittorrent vide.';
      notifyListeners();
      return false;
    }
    isTestingQb = true;
    error = null;
    success = null;
    notifyListeners();
    try {
      final dio = HttpClientFactory.qbittorrent(model.qbittorrentUrl);
      final client = QbittorrentClient(dio);
      final ok = await client.login(
        username: model.qbittorrentUsername,
        password: model.qbittorrentPassword,
      );
      isTestingQb = false;
      if (ok) {
        success = 'qBittorrent : connexion réussie !';
      } else {
        error = 'qBittorrent : identifiants incorrects.';
      }
      notifyListeners();
      return ok;
    } on DioException catch (e) {
      isTestingQb = false;
      error = 'qBittorrent : ${e.message ?? 'serveur injoignable.'}';
      notifyListeners();
      return false;
    } catch (_) {
      isTestingQb = false;
      error = 'qBittorrent : erreur inattendue.';
      notifyListeners();
      return false;
    }
  }

  /// Tests connection to FileBrowser with current form values.
  Future<bool> testFbConnection() async {
    if (model.filebrowserUrl.isEmpty) {
      error = 'URL FileBrowser vide.';
      notifyListeners();
      return false;
    }
    isTestingFb = true;
    error = null;
    success = null;
    notifyListeners();
    try {
      final dio = HttpClientFactory.filebrowser(model.filebrowserUrl);
      final client = FilebrowserClient(dio);
      final token = await client.login(
        username: model.filebrowserUsername,
        password: model.filebrowserPassword,
      );
      isTestingFb = false;
      if (token != null && token.isNotEmpty) {
        success = 'FileBrowser : connexion réussie !';
      } else {
        error = 'FileBrowser : identifiants incorrects.';
      }
      notifyListeners();
      return token != null && token.isNotEmpty;
    } on DioException catch (e) {
      isTestingFb = false;
      error = 'FileBrowser : ${e.message ?? 'serveur injoignable.'}';
      notifyListeners();
      return false;
    } catch (_) {
      isTestingFb = false;
      error = 'FileBrowser : erreur inattendue.';
      notifyListeners();
      return false;
    }
  }
}
