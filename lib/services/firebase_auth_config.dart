/// Firebase project KoroKoro — korokoro-b6a76
class FirebaseAuthConfig {
  static const String projectId = 'korokoro-b6a76';

  /// Web client ID — có sau khi bật Authentication → Google rồi tải lại google-services.json.
  /// Tìm trong JSON: oauth_client có "client_type": 3
  static const String webClientId =
      '843211294647-nkdig5n435sc77bp5b71m4pfu59lp5ka.apps.googleusercontent.com';

  /// Package Android mới — đăng ký trên Firebase KoroKoro (không trùng com.example.lab2).
  static const String androidPackage = 'com.korokoro.journalai';

  static const String debugSha1 =
      '41:96:D7:28:EE:34:B4:C7:EF:8C:3D:3E:E1:D2:EF:1B:F2:EE:DB:F9';

  static bool get hasWebClientId => webClientId.isNotEmpty;
}
