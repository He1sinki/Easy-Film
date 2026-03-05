import 'package:easy_film/features/filebrowser/data/download_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebDownloadService implements DownloadService {
  int _counter = 0;

  @override
  Future<String> enqueue({required String url, required String filename}) async {
    // Use window.open as primary method – works on both desktop and mobile
    // browsers. The anchor-click approach is blocked by some mobile browsers.
    html.window.open(url, '_blank');
    _counter++;
    return 'web-download-$_counter';
  }
}
