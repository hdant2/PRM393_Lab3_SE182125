/// User đăng nhập qua Firebase Authentication (Google).
class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
  });
}
