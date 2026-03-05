import 'package:background_downloader/background_downloader.dart';
import 'package:easy_film/features/filebrowser/data/download_service.dart';

class NativeDownloadService implements DownloadService {
  @override
  Future<String> enqueue({required String url, required String filename}) async {
    final task = DownloadTask(url: url, filename: filename);
    await FileDownloader().enqueue(task);
    return task.taskId;
  }
}
