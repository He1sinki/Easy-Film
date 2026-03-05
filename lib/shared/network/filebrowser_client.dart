import 'package:dio/dio.dart';

class FilebrowserClient {
  FilebrowserClient(this._dio);

  final Dio _dio;
  String? _token;

  Future<String?> login({required String username, required String password}) async {
    final response = await _dio.post<String>(
      '/api/login',
      data: {'username': username, 'password': password},
    );
    if (response.statusCode == 200) {
      _token = response.data?.trim();
      return _token;
    }
    return null;
  }

  Future<Response<dynamic>> listResources(String folderPath) {
    final normalized = folderPath.startsWith('/') ? folderPath.substring(1) : folderPath;
    return _dio.get('/api/resources/$normalized/', options: _withToken());
  }

  String? get token => _token;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  void setToken(String? token) {
    _token = token;
  }

  void clearSession() {
    _token = null;
  }

  Options _withToken() {
    return Options(headers: _token == null ? null : {'X-Auth': _token});
  }
}
