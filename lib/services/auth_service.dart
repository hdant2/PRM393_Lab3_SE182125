import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import 'firebase_auth_config.dart';

/// Firebase Authentication + Google Sign-In (đúng đề Lab 3).
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _mapFirebaseUser(user);
  }

  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map((user) {
        if (user == null) return null;
        return _mapFirebaseUser(user);
      });

  Future<void> initialize() async {
    if (_initialized) return;
    if (FirebaseAuthConfig.hasWebClientId) {
      await _googleSignIn.initialize(
        serverClientId: FirebaseAuthConfig.webClientId,
      );
    } else {
      await _googleSignIn.initialize();
    }
    _initialized = true;
  }

  Future<AppUser> signInWithGoogle() async {
    await initialize();

    final GoogleSignInAccount account;
    if (_googleSignIn.supportsAuthenticate()) {
      account = await _googleSignIn.authenticate();
    } else {
      throw StateError(
        'Google Sign-In authenticate() không hỗ trợ trên nền tảng này.',
      );
    }

    final googleAuth = account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw StateError('Firebase Auth không trả về user sau khi đăng nhập.');
    }

    return _mapFirebaseUser(user);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  AppUser _mapFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
