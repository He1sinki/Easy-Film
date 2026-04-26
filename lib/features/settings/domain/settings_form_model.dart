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
    this.c411ApiBaseUrl = 'https://c411.org',
    this.c411ApiKey = '',
  });

  final String qbittorrentUrl;
  final String qbittorrentUsername;
  final String qbittorrentPassword;
  final String filebrowserUrl;
  final String filebrowserUsername;
  final String filebrowserPassword;
  final String targetFolder;
  final String c411ApiBaseUrl;
  final String c411ApiKey;

  SettingsFormModel copyWith({
    String? qbittorrentUrl,
    String? qbittorrentUsername,
    String? qbittorrentPassword,
    String? filebrowserUrl,
    String? filebrowserUsername,
    String? filebrowserPassword,
    String? targetFolder,
    String? c411ApiBaseUrl,
    String? c411ApiKey,
  }) {
    return SettingsFormModel(
      qbittorrentUrl: qbittorrentUrl ?? this.qbittorrentUrl,
      qbittorrentUsername: qbittorrentUsername ?? this.qbittorrentUsername,
      qbittorrentPassword: qbittorrentPassword ?? this.qbittorrentPassword,
      filebrowserUrl: filebrowserUrl ?? this.filebrowserUrl,
      filebrowserUsername: filebrowserUsername ?? this.filebrowserUsername,
      filebrowserPassword: filebrowserPassword ?? this.filebrowserPassword,
      targetFolder: targetFolder ?? this.targetFolder,
      c411ApiBaseUrl: c411ApiBaseUrl ?? this.c411ApiBaseUrl,
      c411ApiKey: c411ApiKey ?? this.c411ApiKey,
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
        c411ApiBaseUrl,
        c411ApiKey,
      ];
}
