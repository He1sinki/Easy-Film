import 'package:equatable/equatable.dart';

class SettingsFormModel extends Equatable {
  const SettingsFormModel({
    this.qbittorrentUrl = '',
    this.qbittorrentUsername = '',
    this.qbittorrentPassword = '',
    this.filebrowserUrl = '',
    this.filebrowserUsername = '',
    this.filebrowserPassword = '',
    this.targetFolder = '',
  });

  final String qbittorrentUrl;
  final String qbittorrentUsername;
  final String qbittorrentPassword;
  final String filebrowserUrl;
  final String filebrowserUsername;
  final String filebrowserPassword;
  final String targetFolder;

  SettingsFormModel copyWith({
    String? qbittorrentUrl,
    String? qbittorrentUsername,
    String? qbittorrentPassword,
    String? filebrowserUrl,
    String? filebrowserUsername,
    String? filebrowserPassword,
    String? targetFolder,
  }) {
    return SettingsFormModel(
      qbittorrentUrl: qbittorrentUrl ?? this.qbittorrentUrl,
      qbittorrentUsername: qbittorrentUsername ?? this.qbittorrentUsername,
      qbittorrentPassword: qbittorrentPassword ?? this.qbittorrentPassword,
      filebrowserUrl: filebrowserUrl ?? this.filebrowserUrl,
      filebrowserUsername: filebrowserUsername ?? this.filebrowserUsername,
      filebrowserPassword: filebrowserPassword ?? this.filebrowserPassword,
      targetFolder: targetFolder ?? this.targetFolder,
    );
  }

  @override
  List<Object?> get props => [
        qbittorrentUrl,
        qbittorrentUsername,
        qbittorrentPassword,
        filebrowserUrl,
        filebrowserUsername,
        filebrowserPassword,
        targetFolder,
      ];
}
