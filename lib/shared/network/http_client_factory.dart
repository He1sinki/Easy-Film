import 'package:dio/dio.dart';

class HttpClientFactory {
  static Dio qbittorrent(String baseUrl) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        responseType: ResponseType.json,
        validateStatus: (status) => (status ?? 500) < 500,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  static Dio filebrowser(String baseUrl) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        responseType: ResponseType.json,
        validateStatus: (status) => (status ?? 500) < 500,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }
}
