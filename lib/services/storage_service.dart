import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Upload PDF lên Firebase Storage — path theo uid user đã login.
class StorageService {
  static Future<String> uploadPdf(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Cần đăng nhập Firebase trước khi upload PDF.');
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
    final ref = FirebaseStorage.instance.ref().child(
          'reports/${user.uid}/$fileName',
        );

    try {
      await ref.putFile(
        file,
        SettableMetadata(contentType: 'application/pdf'),
      );
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StateError(_friendlyStorageError(e));
    }
  }

  static String _friendlyStorageError(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        return 'Firebase Storage chưa bật hoặc bucket chưa tồn tại. '
            'Vào Console → Storage → Get started, publish rules trong firebase/storage.rules.';
      case 'unauthorized':
      case 'permission-denied':
        return 'Storage từ chối quyền. Đăng nhập lại và publish rules cho reports/{uid}/.';
      case 'unauthenticated':
        return 'Chưa xác thực Firebase. Đăng nhập Google trước khi upload.';
      default:
        final message = e.message ?? '';
        if (message.contains('billing') || message.contains('Blaze')) {
          return 'Firebase Storage cần gói Blaze (pay-as-you-go). '
              'Nâng cấp project korokoro-b6a76 trong Console → Upgrade.';
        }
        return 'Upload thất bại (${e.code}): ${e.message ?? 'unknown'}';
    }
  }
}
