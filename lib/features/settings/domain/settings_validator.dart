import 'package:easy_film/features/settings/domain/settings_form_model.dart';

class SettingsValidator {
  static String? validate(SettingsFormModel model) {
    if (model.qbittorrentUrl.isEmpty ||
        model.qbittorrentUsername.isEmpty ||
        model.qbittorrentPassword.isEmpty ||
        model.filebrowserUrl.isEmpty ||
        model.filebrowserUsername.isEmpty ||
        model.filebrowserPassword.isEmpty ||
        model.c411ApiBaseUrl.isEmpty ||
        model.c411ApiKey.isEmpty) {
      return 'Tous les champs sont obligatoires.';
    }

    final qbUri = Uri.tryParse(model.qbittorrentUrl);
    if (qbUri == null || !qbUri.hasScheme || !qbUri.hasAuthority) {
      return 'URL qBittorrent invalide.';
    }

    final fbUri = Uri.tryParse(model.filebrowserUrl);
    if (fbUri == null || !fbUri.hasScheme || !fbUri.hasAuthority) {
      return 'URL FileBrowser invalide.';
    }
    final isHttps = fbUri.scheme == 'https';
    final isLocalHttp = fbUri.scheme == 'http' && _isLocalDevHost(fbUri.host);
    if (!isHttps && !isLocalHttp) {
      return 'FileBrowser doit utiliser HTTPS (sauf hôte local/IP privée en développement).';
    }

    final c411Uri = Uri.tryParse(model.c411ApiBaseUrl);
    if (c411Uri == null || !c411Uri.hasScheme || !c411Uri.hasAuthority) {
      return 'URL c411 invalide.';
    }
    final c411IsHttps = c411Uri.scheme == 'https';
    final c411IsLocalHttp =
        c411Uri.scheme == 'http' && _isLocalDevHost(c411Uri.host);
    if (!c411IsHttps && !c411IsLocalHttp) {
      return 'c411 doit utiliser HTTPS (sauf hote local/IP privee en developpement).';
    }

    if (model.targetFolder.trim().isEmpty) {
      return 'Le dossier cible est obligatoire.';
    }
    return null;
  }

  static bool _isLocalDevHost(String host) {
    final normalized = host.toLowerCase();
    if (normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1') {
      return true;
    }

    if (normalized.endsWith('.local')) {
      return true;
    }

    final parts = normalized.split('.');
    if (parts.length != 4) {
      return false;
    }

    final octets = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) {
        return false;
      }
      octets.add(value);
    }

    final a = octets[0];
    final b = octets[1];

    final isPrivate10 = a == 10;
    final isPrivate172 = a == 172 && b >= 16 && b <= 31;
    final isPrivate192 = a == 192 && b == 168;
    final isCarrierGradeNat = a == 100 && b >= 64 && b <= 127;
    final isLinkLocal = a == 169 && b == 254;

    return isPrivate10 ||
        isPrivate172 ||
        isPrivate192 ||
        isCarrierGradeNat ||
        isLinkLocal;
  }
}
