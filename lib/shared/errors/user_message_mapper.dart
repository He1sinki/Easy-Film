import 'package:dio/dio.dart';
import 'package:easy_film/shared/models/app_error.dart';

class UserMessageMapper {
  static String fromError(Object error) {
    if (error is DioException) {
      final payload =
          '${error.message ?? ''} ${error.error ?? ''}'.toLowerCase();
      final looksLikeCors =
          payload.contains('xmlhttprequest') || payload.contains('cors');
      if (looksLikeCors) {
        return 'Requête bloquée par CORS sur le navigateur. En local: qBittorrent via `http://localhost:8788`, FileBrowser via `http://localhost:8787`, c411 via `http://localhost:8789`.';
      }
      return 'Réseau indisponible. Vérifiez votre connexion et réessayez.';
    }

    if (error is AppError) {
      switch (error.type) {
        case AppErrorType.auth:
          return 'Authentification échouée. Vérifiez vos identifiants.';
        case AppErrorType.network:
          return 'Réseau indisponible. Vérifiez votre connexion et réessayez.';
        case AppErrorType.server:
          return 'Le serveur a répondu avec une erreur. Réessayez plus tard.';
        case AppErrorType.validation:
          return error.message;
        case AppErrorType.storage:
          return 'Impossible d\'accéder au stockage local sécurisé.';
        case AppErrorType.nostrConnection:
          return 'Impossible de se connecter au relais Nostr. Vérifiez votre connexion internet.';
        case AppErrorType.nostrTimeout:
          return 'Le relais Nostr n\'a pas répondu dans le délai imparti. Réessayez.';
        case AppErrorType.magnetSendFailed:
          return 'Échec de l\'envoi du lien magnet vers qBittorrent. Vérifiez la configuration du serveur.';
        case AppErrorType.unknown:
          return 'Une erreur inattendue est survenue.';
      }
    }
    return 'Une erreur inattendue est survenue.';
  }
}
