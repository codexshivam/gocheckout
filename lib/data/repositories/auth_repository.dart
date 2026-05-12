import '../models/schema/auth_models.dart';

/// Abstract auth repository interface.
abstract class AuthRepository {
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> registerWithGoogle();
  Future<void> signOut();
  AuthUser? getCurrentUser();
  bool get isAuthenticated;
}

/// Mock/Fake implementation for testing without Google Sign In.
class GoogleAuthRepository implements AuthRepository {
  AuthUser? _currentUser;

  @override
  Future<AuthResult> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Fake successful login
    final AuthUser user = AuthUser(
      id: 'user_123',
      email: 'merchant@example.com',
      displayName: 'Yuva Merchant',
      photoUrl: null,
    );

    _currentUser = user;

    return AuthResult(
      success: true,
      user: user,
    );
  }

  @override
  Future<AuthResult> registerWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Fake successful registration
    final AuthUser user = AuthUser(
      id: 'user_456',
      email: 'newmerchant@example.com',
      displayName: 'New Store Owner',
      photoUrl: null,
    );

    _currentUser = user;

    return AuthResult(
      success: true,
      user: user,
    );
  }

  @override
  Future<void> signOut() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  AuthUser? getCurrentUser() => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;
}
