import 'package:easy_film/features/filebrowser/data/download_service.dart';
import 'package:easy_film/features/filebrowser/data/native_download_service.dart';

DownloadService createDownloadService() => NativeDownloadService();
