abstract class DownloadService {
  Future<String> enqueue({required String url, required String filename});
}
