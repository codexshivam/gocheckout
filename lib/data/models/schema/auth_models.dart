/// Authentication user model representing a merchant.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  /// Create a copy with optional field overrides.
  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  String toString() => 'AuthUser(id: $id, email: $email, displayName: $displayName)';
}

/// Authentication result with status and optional user/error.
class AuthResult {
  const AuthResult({
    required this.success,
    this.user,
    this.error,
  });

  final bool success;
  final AuthUser? user;
  final String? error;

  @override
  String toString() => 'AuthResult(success: $success, error: $error)';
}
