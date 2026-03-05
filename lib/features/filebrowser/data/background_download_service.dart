import 'package:background_downloader/background_downloader.dart';

class BackgroundDownloadService {
  Future<String> enqueue({required String url, required String filename}) async {
    final task = DownloadTask(url: url, filename: filename);
    await FileDownloader().enqueue(task);
    return task.taskId;
  }
}
