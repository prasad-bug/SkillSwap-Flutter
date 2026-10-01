import 'dart:async';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import '../mock_data/mock_data.dart';

/// In-memory mock implementation of [UserRepository].
class MockUserRepository implements UserRepository {
  MockUserRepository() {
    // Start with the demo user logged in
    _currentUser = MockData.users.firstWhere((u) => u.id == 'current_user');
    _userController.add(_currentUser);
  }

  AppUser? _currentUser;
  final _userController = StreamController<AppUser?>.broadcast();
  final List<AppUser> _users = List.from(MockData.users);

  @override
  Stream<AppUser?> get currentUserStream async* {
    yield _currentUser;
    yield* _userController.stream;
  }

  @override
  Future<AppUser?> getCurrentUser() async => _currentUser;

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final user = _users.where((u) => u.email == email).firstOrNull;
    if (user == null) throw Exception('User not found');
    _currentUser = user;
    _userController.add(_currentUser);
    return user;
  }

  @override
  Future<AppUser> registerWithEmail(
      String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final existing = _users.where((u) => u.email == email).firstOrNull;
    if (existing != null) throw Exception('Email already in use');
    final newUser = AppUser(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
    );
    _users.add(newUser);
    _currentUser = newUser;
    _userController.add(_currentUser);
    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _userController.add(null);
  }

  @override
  Future<AppUser?> getUserById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _users.where((u) => u.id == userId).firstOrNull;
  }

  @override
  Future<AppUser> updateUser(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx == -1) throw Exception('User not found');
    _users[idx] = user;
    if (_currentUser?.id == user.id) {
      _currentUser = user;
      _userController.add(_currentUser);
    }
    return user;
  }

  void dispose() {
    _userController.close();
  }
}
