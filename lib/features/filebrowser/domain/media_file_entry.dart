import 'package:equatable/equatable.dart';

class MediaFileEntry extends Equatable {
  const MediaFileEntry({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.isDirectory,
  });

  final String path;
  final String name;
  final String extension;
  final int sizeBytes;
  final bool isDirectory;

  bool get isVideo => !isDirectory && (extension == 'mkv' || extension == 'mp4');

  factory MediaFileEntry.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final extension = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return MediaFileEntry(
      path: json['path']?.toString() ?? name,
      name: name,
      extension: extension,
      sizeBytes: (json['size'] as num?)?.toInt() ?? 0,
      isDirectory: json['isDir'] == true || json['type'] == 'dir',
    );
  }

  @override
  List<Object?> get props => [path, name, extension, sizeBytes, isDirectory];
}
