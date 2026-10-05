import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage service for uploading and fetching profile media.
class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads profile image bytes to `profile_images/{userId}/profile.jpg`
  /// and returns the public download URL.
  Future<String> uploadProfileImage(String userId, Uint8List imageBytes) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId/profile.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );
      final uploadTask = await ref.putData(imageBytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Retrieves the download URL for a user's profile image if it exists.
  Future<String?> getProfileImageUrl(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId/profile.jpg');
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
