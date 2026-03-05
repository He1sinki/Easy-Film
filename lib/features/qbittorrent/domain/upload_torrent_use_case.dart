import 'package:dio/dio.dart';
import 'package:easy_film/features/qbittorrent/data/qbittorrent_repository.dart';
import 'package:easy_film/shared/models/app_error.dart';
import 'package:file_picker/file_picker.dart';

typedef PickTorrentFiles = Future<FilePickerResult?> Function();

class UploadTorrentResult {
  const UploadTorrentResult({
    required this.uploadedCount,
    required this.torrentHashes,
  });

  final int uploadedCount;
  final List<String> torrentHashes;
}

class UploadTorrentUseCase {
  UploadTorrentUseCase({
    QbittorrentRepository? repository,
    PickTorrentFiles? pickTorrentFiles,
  })  : _repository = repository ?? QbittorrentRepository(),
        _pickTorrentFiles = pickTorrentFiles ?? _defaultPicker;

  final QbittorrentRepository _repository;
  final PickTorrentFiles _pickTorrentFiles;

  static Future<FilePickerResult?> _defaultPicker() {
    return FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['torrent'],
      withData: true,
      allowMultiple: true,
    );
  }

  Future<UploadTorrentResult> pickAndUpload() async {
    final picked = await _pickTorrentFiles();
    final files = picked?.files;
    if (files == null || files.isEmpty) {
      return const UploadTorrentResult(uploadedCount: 0, torrentHashes: <String>[]);
    }

    final selectedTorrentFiles =
        files.where((file) => file.name.toLowerCase().endsWith('.torrent')).toList(growable: false);
    if (selectedTorrentFiles.isEmpty) {
      throw const AppError(AppErrorType.validation, 'Sélectionnez au moins un fichier .torrent');
    }

    final multipartFiles = <MultipartFile>[];
    for (final file in selectedTorrentFiles) {
      if (file.bytes != null) {
        multipartFiles.add(MultipartFile.fromBytes(file.bytes!, filename: file.name));
        continue;
      }
      if (file.path != null) {
        multipartFiles.add(await MultipartFile.fromFile(file.path!, filename: file.name));
        continue;
      }
      throw AppError(
        AppErrorType.validation,
        'Impossible de lire le fichier sélectionné: ${file.name}',
      );
    }

    final hashes = await _repository.addTorrentsAndDetectNewHashes(multipartFiles);
    return UploadTorrentResult(
      uploadedCount: multipartFiles.length,
      torrentHashes: hashes,
    );
  }
}
