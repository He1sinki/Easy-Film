import 'package:easy_film/features/filebrowser/domain/media_file_entry.dart';
import 'package:easy_film/shared/models/app_error.dart';

class FilebrowserDownloadUrlBuilder {
  static String build({
    required String baseUrl,
    required String token,
    required MediaFileEntry entry,
  }) {
    if (!entry.isVideo) {
      throw const AppError(AppErrorType.validation, 'Seuls les fichiers .mkv/.mp4 sont autorisés.');
    }

    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final safePath = entry.path.startsWith('/') ? entry.path.substring(1) : entry.path;
    final encodedSegments = safePath.split('/').map(Uri.encodeComponent).join('/');
    final encodedToken = Uri.encodeQueryComponent(token);
    return '$normalizedBase/api/raw/$encodedSegments?auth=$encodedToken';
  }
}
