import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class QbittorrentClient {
  QbittorrentClient(this._dio);

  final Dio _dio;
  String? _sidCookie;
  bool _proxyManagedSession = false;

  Future<bool> login({required String username, required String password}) async {
    final response = await _dio.post<String>(
      '/api/v2/auth/login',
      data: {'username': username, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      for (final value in setCookie) {
        final match = RegExp(r'SID=([^;]+)').firstMatch(value);
        if (match != null) {
          _sidCookie = 'SID=${match.group(1)}';
          break;
        }
      }
    }

    final proxySessionHeader = response.headers.value('x-qb-proxy-session');
    final loginOk = (response.statusCode == 200) && (response.data?.trim().toLowerCase() == 'ok.');
    final canUseProxySession = kIsWeb && loginOk && (proxySessionHeader == 'active' || _sidCookie == null);

    _proxyManagedSession = canUseProxySession;
    return loginOk && (_sidCookie != null || _proxyManagedSession);
  }

  Future<Response<dynamic>> addTorrent(MultipartFile torrentFile) {
    return addTorrents(<MultipartFile>[torrentFile]);
  }

  Future<Response<dynamic>> addTorrentByMagnetUrl(String magnetUrl) {
    return _dio.post(
      '/api/v2/torrents/add',
      data: {'urls': magnetUrl},
      options: Options(
        headers: _withSid().headers,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
  }

  Future<Response<dynamic>> addTorrents(List<MultipartFile> torrentFiles) {
    return _dio.post(
      '/api/v2/torrents/add',
      data: FormData.fromMap({'torrents': torrentFiles}),
      options: _withSid(),
    );
  }

  Future<Response<dynamic>> listTorrents() {
    return _dio.get<dynamic>('/api/v2/torrents/info', options: _withSid());
  }

  Future<Response<dynamic>> resumeTorrent(String hash) {
    return _dio.post<dynamic>(
      '/api/v2/torrents/resume',
      data: {'hashes': hash},
      options: Options(
        headers: _withSid().headers,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
  }

  Future<Response<dynamic>> pauseTorrent(String hash) {
    return _dio.post<dynamic>(
      '/api/v2/torrents/pause',
      data: {'hashes': hash},
      options: Options(
        headers: _withSid().headers,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
  }

  Future<Response<dynamic>> deleteTorrent(String hash, {bool deleteFiles = false}) {
    return _dio.post<dynamic>(
      '/api/v2/torrents/delete',
      data: {
        'hashes': hash,
        'deleteFiles': deleteFiles.toString(),
      },
      options: Options(
        headers: _withSid().headers,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
  }

  Future<Response<dynamic>> listTrackers(String hash) {
    return _dio.get<dynamic>(
      '/api/v2/torrents/trackers',
      queryParameters: {'hash': hash},
      options: _withSid(),
    );
  }

  Future<Response<dynamic>> removeTrackers(String hash, List<String> trackerUrls) {
    return _dio.post<dynamic>(
      '/api/v2/torrents/removeTrackers',
      data: {
        'hash': hash,
        'urls': trackerUrls.join('|'),
      },
      options: Options(
        headers: _withSid().headers,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
  }

  bool get isAuthenticated => _sidCookie != null || _proxyManagedSession;

  void clearSession() {
    _sidCookie = null;
    _proxyManagedSession = false;
  }

  Options _withSid() {
    if (_proxyManagedSession || _sidCookie == null) {
      return Options();
    }
    return Options(headers: {'Cookie': _sidCookie});
  }
}
