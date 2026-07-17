/// Firebase project prm392-lab3
class FirebaseAuthConfig {
  static const String projectId = 'prm392-lab3';

  /// Web client ID — oauth_client có "client_type": 3
  static const String webClientId =
      '243614851294-hul6tpej1spedpj1o4d6h4qclndkonh1.apps.googleusercontent.com';

  static const String androidPackage = 'com.example.lab2';

  static const String debugSha1 =
      'A6:70:FC:52:C1:DC:5F:5F:7D:C0:32:43:D1:F7:69:1C:12:2D:E3:C7';

  static bool get hasWebClientId => webClientId.isNotEmpty;
}
