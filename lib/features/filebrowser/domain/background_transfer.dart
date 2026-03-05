import 'package:equatable/equatable.dart';

enum TransferStatus { queued, running, paused, completed, failed, canceled }

class BackgroundTransfer extends Equatable {
  const BackgroundTransfer({
    required this.taskId,
    required this.remoteUrl,
    required this.localPath,
    required this.progress,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String taskId;
  final String remoteUrl;
  final String localPath;
  final double progress;
  final TransferStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  BackgroundTransfer copyWith({
    double? progress,
    TransferStatus? status,
    String? errorMessage,
    DateTime? updatedAt,
  }) {
    return BackgroundTransfer(
      taskId: taskId,
      remoteUrl: remoteUrl,
      localPath: localPath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [taskId, remoteUrl, localPath, progress, status, errorMessage, createdAt, updatedAt];
}
