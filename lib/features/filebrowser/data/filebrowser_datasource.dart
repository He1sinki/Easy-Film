import 'package:easy_film/features/filebrowser/domain/media_file_entry.dart';
import 'package:easy_film/shared/network/filebrowser_client.dart';

class FilebrowserDatasource {
  FilebrowserDatasource(this._client);

  final FilebrowserClient _client;

  Future<String?> login({required String username, required String password}) {
    return _client.login(username: username, password: password);
  }

  Future<List<MediaFileEntry>> listResources(String folderPath) async {
    final response = await _client.listResources(folderPath);
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => MediaFileEntry.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }
    if (data is Map) {
      final mapData = Map<String, dynamic>.from(data);
      final items = (mapData['items'] as List<dynamic>? ?? const []);
      return items
          .whereType<Map>()
          .map((item) => MediaFileEntry.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }
    return const [];
  }
}
