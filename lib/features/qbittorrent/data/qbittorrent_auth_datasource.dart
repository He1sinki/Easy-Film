import 'package:easy_film/shared/network/qbittorrent_client.dart';

class QbittorrentAuthDatasource {
  QbittorrentAuthDatasource(this._client);

  final QbittorrentClient _client;

  Future<bool> login({required String username, required String password}) {
    return _client.login(username: username, password: password);
  }
}
