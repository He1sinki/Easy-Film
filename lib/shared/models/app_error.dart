import 'package:equatable/equatable.dart';

enum AppErrorType { auth, network, server, validation, storage, nostrConnection, nostrTimeout, magnetSendFailed, unknown }

class AppError extends Equatable implements Exception {
  const AppError(this.type, this.message, {this.cause});

  final AppErrorType type;
  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [type, message, cause];
}
