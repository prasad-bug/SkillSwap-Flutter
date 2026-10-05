import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';

/// Real Firebase implementation of [UserRepository] using
/// Firebase Authentication and Cloud Firestore ('users' collection).
class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  @override
  Stream<AppUser?> get currentUserStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final doc = await _usersCol.doc(firebaseUser.uid).get();
        if (doc.exists && doc.data() != null) {
          return AppUser.fromFirestore(doc.data()!, doc.id);
        }
        // If user document doesn't exist yet, create default record
        final newUser = AppUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User',
          email: firebaseUser.email ?? '',
          avatarUrl: firebaseUser.photoURL,
        );
        await _usersCol.doc(firebaseUser.uid).set(newUser.toFirestore());
        return newUser;
      } catch (e) {
        // Fallback representation if Firestore is temporarily unreachable
        return AppUser(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User',
          email: firebaseUser.email ?? '',
          avatarUrl: firebaseUser.photoURL,
        );
      }
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserById(user.uid);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Failed to sign in: User is null');

      final profile = await getUserById(user.uid);
      if (profile != null) return profile;

      // Create profile document if first time
      final newProfile = AppUser(
        id: user.uid,
        name: user.displayName ?? email.split('@').first,
        email: email.trim(),
      );
      await _usersCol.doc(user.uid).set(newProfile.toFirestore());
      return newProfile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<AppUser> registerWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Registration failed: User is null');

      await user.updateDisplayName(name);

      final newProfile = AppUser(
        id: user.uid,
        name: name,
        email: email.trim(),
      );

      await _usersCol.doc(user.uid).set(newProfile.toFirestore());
      return newProfile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _usersCol.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    try {
      await _usersCol.doc(user.id).set(
            user.toFirestore(),
            SetOptions(merge: true),
          );
      return user;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak (minimum 6 characters).';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication failed. Please check your credentials.';
    }
  }
}
