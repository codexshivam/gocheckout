import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../../data/config/auth_rollout_config.dart';
import '../../data/models/app_error_envelope.dart';
import '../../data/models/schema/appwrite_user_doc.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/auth_observability_service.dart';

enum AuthViewState {
  checking,
  authenticated,
  unauthenticated,
}

class AuthStateController extends ChangeNotifier {
  AuthStateController({
    AuthServiceContract? authService,
    AuthRolloutConfig? rolloutConfig,
    AuthObservabilityContract? observability,
  })  : _authService = authService ?? AuthService(),
        _rolloutConfig = rolloutConfig ?? AuthRolloutConfig.fromEnvironment(),
        _observability = observability ??
            AuthObservabilityService(
              oauthFailureThreshold: (rolloutConfig ?? AuthRolloutConfig.fromEnvironment())
                  .oauthFailureAlertThreshold,
              oauthFailureWindow:
                  (rolloutConfig ?? AuthRolloutConfig.fromEnvironment()).oauthFailureAlertWindow,
            );

  final AuthServiceContract _authService;
  final AuthRolloutConfig _rolloutConfig;
  final AuthObservabilityContract _observability;

  AuthViewState _state = AuthViewState.checking;
  bool _isLoading = false;
  bool _showRegister = false;
  String? _errorMessage;
  AppErrorEnvelope? _lastError;
  User? _currentUser;
  AppwriteUserDoc? _userProfile;
  bool _isProfileLoading = false;
  bool _isBootstrapping = false;
  Future<void>? _bootstrapInFlight;
  int _bootstrapGeneration = 0;

  AuthViewState get state => _state;
  bool get isLoading => _isLoading;
  bool get showRegister => _showRegister;
  String? get errorMessage => _errorMessage;
  AppErrorEnvelope? get lastError => _lastError;
  User? get currentUser => _currentUser;
  AppwriteUserDoc? get userProfile => _userProfile;
  bool get isProfileLoading => _isProfileLoading;
  bool get hasCompletedProfile => _userProfile?.hasCompletedProfile ?? false;
  String? get activeStoreId => _userProfile?.activeStoreId;
  bool get isBootstrapping => _isBootstrapping;
  bool get canRetryStartup => _bootstrapInFlight == null;

  bool get _isTransitionLocked => _isLoading || _isBootstrapping;

  void _recordEvent(String name, {Map<String, String> metadata = const <String, String>{}}) {
    if (!_rolloutConfig.enableAuthTelemetry) {
      return;
    }
    _observability.record(
      name,
      samplePercent: _rolloutConfig.telemetrySamplePercent,
      subject: _currentUser?.$id ?? 'anonymous',
      metadata: metadata,
    );
  }

  void _setError(
    Object error, {
    required String source,
    required String fallbackMessage,
  }) {
    _lastError = AppErrorEnvelope.from(
      error,
      source: source,
      fallbackMessage: fallbackMessage,
    );
    _errorMessage = _lastError!.message;
  }

  String _oauthFallbackMessage(AppwriteException error, {required bool signUp}) {
    final String message = (error.message ?? '').toLowerCase();
    if (message.contains('popup') && message.contains('block')) {
      return 'Browser blocked the Google popup. Allow popups for this site and retry.';
    }
    if (message.contains('redirect') || message.contains('callback') || message.contains('origin')) {
      return 'OAuth callback validation failed. Refresh and try again.';
    }
    return signUp ? 'Google sign up failed.' : 'Google login failed.';
  }

  void _setOAuthError(
    AppwriteException error, {
    required String source,
    required bool signUp,
  }) {
    final AppErrorEnvelope base = AppErrorEnvelope.from(
      error,
      source: source,
      fallbackMessage: signUp ? 'Google sign up failed.' : 'Google login failed.',
    );
    final String message = _oauthFallbackMessage(error, signUp: signUp);
    _lastError = AppErrorEnvelope(
      code: base.code,
      message: message,
      retryable: base.retryable,
      source: base.source,
      debugDetails: base.debugDetails,
    );
    _errorMessage = message;
  }

  Future<void> bootstrapSession() async {
    _recordEvent('auth.bootstrap.start');
    if (_bootstrapInFlight != null) {
      return _bootstrapInFlight;
    }

    final Future<void> run = _bootstrapSessionInternal();
    _bootstrapInFlight = run;
    try {
      await run;
    } finally {
      if (identical(_bootstrapInFlight, run)) {
        _bootstrapInFlight = null;
      }
    }
  }

  Future<void> _bootstrapSessionInternal() async {
    final int runId = ++_bootstrapGeneration;
    _isBootstrapping = true;
    _state = AuthViewState.checking;
    _errorMessage = null;
    _lastError = null;
    notifyListeners();
    try {
      final User? user = await _checkSessionWithRetry();
      if (runId != _bootstrapGeneration) {
        return;
      }

      if (user == null) {
        _currentUser = null;
        _userProfile = null;
        _state = AuthViewState.unauthenticated;
        _recordEvent('auth.bootstrap.no_session');
        notifyListeners();
        return;
      }

      _currentUser = user;
      try {
        await _authService.resolvePendingStoreAccess(uid: user.$id, email: user.email);
      } catch (error) {
        debugPrint('Error resolving pending store access during bootstrap: $error');
        _setError(
          error,
          source: 'auth.bootstrap.resolvePendingStoreAccess',
          fallbackMessage: 'Could not sync store access. Pull to refresh after login.',
        );
      }

      if (runId != _bootstrapGeneration) {
        return;
      }

      await refreshUserProfile();
      if (runId != _bootstrapGeneration) {
        return;
      }

      _state = AuthViewState.authenticated;
      _recordEvent('auth.bootstrap.success');
      notifyListeners();
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> retryStartupSessionCheck() async {
    if (_bootstrapInFlight != null) {
      return;
    }
    _errorMessage = null;
    _lastError = null;
    notifyListeners();
    await bootstrapSession();
  }

  Future<User?> _checkSessionWithRetry() async {
    const int maxAttempts = 3;
    const Duration timeout = Duration(seconds: 8);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final User? user = await _authService.checkSession().timeout(timeout);
        return user;
      } on AppwriteException catch (error) {
        final bool retryable = (error.code ?? 0) >= 500 || error.code == null;
        if (!retryable || attempt == maxAttempts) {
          _setError(
            error,
            source: 'auth.bootstrap.checkSession',
            fallbackMessage: 'Unable to validate session right now. Please retry.',
          );
          _recordEvent(
            'auth.bootstrap.failure',
            metadata: <String, String>{'kind': 'appwrite', 'code': '${error.code ?? -1}'},
          );
          return null;
        }
      } on TimeoutException {
        if (attempt == maxAttempts) {
          _setError(
            TimeoutException('Session check timed out'),
            source: 'auth.bootstrap.checkSession',
            fallbackMessage: 'Session check timed out. Check your network and try again.',
          );
          _recordEvent('auth.bootstrap.failure', metadata: const <String, String>{'kind': 'timeout'});
          return null;
        }
      } catch (error) {
        if (attempt == maxAttempts) {
          _setError(
            error,
            source: 'auth.bootstrap.checkSession',
            fallbackMessage: 'Unable to validate session right now. Please retry.',
          );
          debugPrint('Unexpected bootstrap session error: $error');
          _recordEvent('auth.bootstrap.failure', metadata: const <String, String>{'kind': 'unexpected'});
          return null;
        }
      }

      _recordEvent('auth.bootstrap.retry', metadata: <String, String>{'attempt': '$attempt'});
      await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
    }

    return null;
  }

  void navigateToRegister() {
    _showRegister = true;
    _errorMessage = null;
    _lastError = null;
    notifyListeners();
  }

  void navigateToLogin() {
    _showRegister = false;
    _errorMessage = null;
    _lastError = null;
    notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    if (_isTransitionLocked) {
      return;
    }
    _recordEvent('auth.login.attempt');
    _isLoading = true;
    _errorMessage = null;
    _lastError = null;
    notifyListeners();

    try {
      await _authService.loginWithGoogle();
      // On web this returns after redirect completion; refresh session either way.
      final User? user = await _authService.checkSession();
      if (user != null) {
        _currentUser = user;
        await _authService.resolvePendingStoreAccess(uid: user.$id, email: user.email);
        await refreshUserProfile();
        _state = AuthViewState.authenticated;
        _recordEvent('auth.login.success');
      }
    } on AppwriteException catch (error) {
      if (_rolloutConfig.enableOAuthHardening) {
        _setOAuthError(
          error,
          source: 'auth.loginWithGoogle',
          signUp: false,
        );
      } else {
        _setError(
          error,
          source: 'auth.loginWithGoogle',
          fallbackMessage: 'Google login failed.',
        );
      }
      _recordEvent(
        'auth.login.oauth_failure',
        metadata: <String, String>{'code': '${error.code ?? -1}'},
      );
      debugPrint('AppwriteException in AuthStateController.loginWithGoogle: ${error.message}');
    } catch (error) {
      _setError(
        error,
        source: 'auth.loginWithGoogle',
        fallbackMessage: 'Google login failed.',
      );
      _recordEvent('auth.login.failure', metadata: const <String, String>{'kind': 'unexpected'});
      debugPrint('Unexpected error in AuthStateController.loginWithGoogle: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signupWithGoogle() async {
    if (_isTransitionLocked) {
      return;
    }
    _recordEvent('auth.signup.attempt');
    _isLoading = true;
    _errorMessage = null;
    _lastError = null;
    notifyListeners();

    try {
      await _authService.signupWithGoogle();
      final User? user = await _authService.checkSession();
      if (user != null) {
        _currentUser = user;
        _showRegister = false;
        await _authService.resolvePendingStoreAccess(uid: user.$id, email: user.email);
        await refreshUserProfile();
        _state = AuthViewState.authenticated;
        _recordEvent('auth.signup.success');
      }
    } on AppwriteException catch (error) {
      if (_rolloutConfig.enableOAuthHardening) {
        _setOAuthError(
          error,
          source: 'auth.signupWithGoogle',
          signUp: true,
        );
      } else {
        _setError(
          error,
          source: 'auth.signupWithGoogle',
          fallbackMessage: 'Google sign up failed.',
        );
      }
      _recordEvent(
        'auth.signup.oauth_failure',
        metadata: <String, String>{'code': '${error.code ?? -1}'},
      );
      debugPrint('AppwriteException in AuthStateController.signupWithGoogle: ${error.message}');
    } catch (error) {
      _setError(
        error,
        source: 'auth.signupWithGoogle',
        fallbackMessage: 'Google sign up failed.',
      );
      _recordEvent('auth.signup.failure', metadata: const <String, String>{'kind': 'unexpected'});
      debugPrint('Unexpected error in AuthStateController.signupWithGoogle: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_isTransitionLocked) {
      return;
    }
    _recordEvent('auth.logout.attempt');

    // Invalidate any in-flight startup checks so stale completions cannot
    // overwrite post-logout state.
    _bootstrapGeneration += 1;

    _isLoading = true;
    _errorMessage = null;
    _lastError = null;
    notifyListeners();

    bool remoteLogoutFailed = false;
    try {
      await _authService.logoutCurrentSession();
      _recordEvent('auth.logout.success');
    } on AppwriteException catch (error) {
      remoteLogoutFailed = true;
      _setError(
        error,
        source: 'auth.logout',
        fallbackMessage: 'Signed out locally, but remote session cleanup failed.',
      );
      _recordEvent(
        'auth.logout.failure',
        metadata: <String, String>{'kind': 'appwrite', 'code': '${error.code ?? -1}'},
      );
      debugPrint('AppwriteException in AuthStateController.logout: ${error.message}');
    } catch (error) {
      remoteLogoutFailed = true;
      _setError(
        error,
        source: 'auth.logout',
        fallbackMessage: 'Signed out locally, but remote session cleanup failed.',
      );
      _recordEvent('auth.logout.failure', metadata: const <String, String>{'kind': 'unexpected'});
      debugPrint('Unexpected error in AuthStateController.logout: $error');
    } finally {
      _currentUser = null;
      _userProfile = null;
      _isProfileLoading = false;
      _showRegister = false;
      _state = AuthViewState.unauthenticated;
      _isLoading = false;
      if (!remoteLogoutFailed) {
        _errorMessage = null;
        _lastError = null;
      }
      notifyListeners();
    }
  }

  Future<void> refreshUserProfile() async {
    final User? user = _currentUser;
    if (user == null) {
      _userProfile = null;
      return;
    }

    _isProfileLoading = true;
    notifyListeners();

    try {
      _userProfile = await _authService.getUserProfile(user.$id);
    } on AppwriteException catch (error) {
      _setError(
        error,
        source: 'auth.refreshUserProfile',
        fallbackMessage: 'Failed to load user profile.',
      );
      debugPrint('AppwriteException in refreshUserProfile: ${error.message}');
    } catch (error) {
      _setError(
        error,
        source: 'auth.refreshUserProfile',
        fallbackMessage: 'Failed to load user profile.',
      );
      debugPrint('Unexpected error in refreshUserProfile: $error');
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeProfile({
    required String phone,
    required String address,
  }) async {
    if (_isTransitionLocked) {
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    _lastError = null;
    notifyListeners();

    try {
      await _authService.completeUserProfile(phone: phone, address: address);
      if (_currentUser != null) {
        await _authService.resolvePendingStoreAccess(
          uid: _currentUser!.$id,
          email: _currentUser!.email,
        );
      }
      await refreshUserProfile();
      return true;
    } on AppwriteException catch (error) {
      _setError(
        error,
        source: 'auth.completeProfile',
        fallbackMessage: 'Profile completion failed.',
      );
      debugPrint('AppwriteException in completeProfile: ${error.message}');
      return false;
    } catch (error) {
      _setError(
        error,
        source: 'auth.completeProfile',
        fallbackMessage: 'Profile completion failed.',
      );
      debugPrint('Unexpected error in completeProfile: $error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
