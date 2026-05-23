/// Configuration d'environnement injectée au build via --dart-define=ENV=prod.
///
/// Phase de test pré-lancement : dev ET prod pointent tous les deux vers le
/// serveur de production (https://www.groupebilogistics.com) pour valider le
/// fonctionnement end-to-end avant l'ouverture officielle.
///
/// Une fois en exploitation, repasser `dev` sur une API locale en passant
/// --dart-define=API_URL=http://10.0.2.2:8000 au `flutter run`.
class Env {
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String _prodUrl = 'https://www.groupebilogistics.com';

  /// URL racine de l'API Laravel (sans slash final).
  static String get apiBaseUrl {
    switch (_env) {
      case 'prod':
        return const String.fromEnvironment('API_URL', defaultValue: _prodUrl);
      case 'staging':
        return const String.fromEnvironment('API_URL', defaultValue: _prodUrl);
      case 'dev':
      default:
        // Par défaut : serveur de prod (phase de test).
        // Pour pointer sur une API locale : --dart-define=API_URL=http://10.0.2.2:8000
        return const String.fromEnvironment('API_URL', defaultValue: _prodUrl);
    }
  }

  static bool get isProd => _env == 'prod';
  static bool get isDev => _env == 'dev';

  /// Clés stockage local
  static const String storageAuthToken = 'auth_token';
  static const String storageOnboardingSeen = 'onboarding_seen';
  static const String storageLocale = 'locale';
}
