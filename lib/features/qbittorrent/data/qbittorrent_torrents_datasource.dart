import 'package:dio/dio.dart';
import 'package:easy_film/shared/network/qbittorrent_client.dart';

class QbittorrentTorrentsDatasource {
  QbittorrentTorrentsDatasource(this._client);

  final QbittorrentClient _client;

  Future<Response<dynamic>> addTorrent(MultipartFile file) {
    return addTorrents(<MultipartFile>[file]);
  }

  Future<Response<dynamic>> addTorrents(List<MultipartFile> files) {
    return _client.addTorrents(files);
  }

  Future<Response<dynamic>> addTorrentByMagnetUrl(String magnetUrl) {
    return _client.addTorrentByMagnetUrl(magnetUrl);
  }

  Future<Response<dynamic>> listTorrents() {
    return _client.listTorrents();
  }

  Future<Response<dynamic>> resumeTorrent(String hash) {
    return _client.resumeTorrent(hash);
  }

  Future<Response<dynamic>> pauseTorrent(String hash) {
    return _client.pauseTorrent(hash);
  }

  Future<Response<dynamic>> deleteTorrent(String hash, {bool deleteFiles = false}) {
    return _client.deleteTorrent(hash, deleteFiles: deleteFiles);
  }

  Future<Response<dynamic>> listTrackers(String hash) {
    return _client.listTrackers(hash);
  }

  Future<Response<dynamic>> removeTrackers(String hash, List<String> trackerUrls) {
    return _client.removeTrackers(hash, trackerUrls);
  }
}
