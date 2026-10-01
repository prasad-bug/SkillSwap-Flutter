import '../models/app_user.dart';

/// Abstract interface for user data operations.
abstract class UserRepository {
  /// Stream of the currently signed-in user (null if signed out).
  Stream<AppUser?> get currentUserStream;

  /// Get the current user once.
  Future<AppUser?> getCurrentUser();

  /// Sign in with email and password.
  Future<AppUser> signInWithEmail(String email, String password);

  /// Register with email and password.
  Future<AppUser> registerWithEmail(
      String name, String email, String password);

  /// Sign out.
  Future<void> signOut();

  /// Get a user by id.
  Future<AppUser?> getUserById(String userId);

  /// Update user profile.
  Future<AppUser> updateUser(AppUser user);
}
