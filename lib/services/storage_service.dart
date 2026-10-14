import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Handles file uploads to Firebase Storage. Currently just profile
/// photos, but structured so other upload types can be added later.
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads [bytes] as the student's profile photo and returns the
  /// public download URL. Always the same storage path per user
  /// (`profile_photos/{uid}`, no extension — content type carries that
  /// info instead), so re-uploading simply replaces the old photo
  /// rather than accumulating orphaned files.
  Future<String> uploadProfilePhoto(String uid, Uint8List bytes, {String contentType = 'image/jpeg'}) async {
    final ref = _storage.ref('profile_photos/$uid');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
