import 'package:dio/dio.dart';

class C411Client {
  C411Client(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> searchTorrents({
    required String term,
    required String bearerToken,
    int page = 1,
    int perPage = 25,
    String sortBy = 'relevance',
    String sortOrder = 'desc',
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      '/api/torrents',
      queryParameters: {
        'page': page,
        'perPage': perPage,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'name': term,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
        },
      ),
      cancelToken: cancelToken,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{'data': const <dynamic>[]};
  }
}
