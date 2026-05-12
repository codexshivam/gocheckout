// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/schema_adapter.dart';
import '../models/schema/appwrite_user_doc.dart';

typedef OAuthSessionLauncher = Future<void> Function({
  required OAuthProvider provider,
  required String success,
  required String failure,
});

typedef UriProvider = Uri Function();

abstract class AuthServiceContract {
  Future<void> loginWithGoogle();
  Future<void> signupWithGoogle();
  Future<User?> checkSession();
  Future<void> completeUserProfile({
    required String phone,
    required String address,
  });
  Future<void> logoutCurrentSession();
  Future<AppwriteUserDoc?> getUserProfile(String uid);
  Future<void> setActiveStoreForUser({
    required String uid,
    required String storeId,
  });
  Future<String?> resolvePendingStoreAccess({
    required String uid,
    required String email,
  });
}

class AuthService implements AuthServiceContract {
  AuthService({
    AppwriteConfig? config,
    Account? account,
    Databases? databases,
    Future<User> Function()? sessionUserFetcher,
    OAuthSessionLauncher? oauthSessionLauncher,
    UriProvider? webBaseUriProvider,
  })  : _config = config ?? AppwriteConfig.instance,
        _accountOverride = account,
        _databasesOverride = databases,
        _sessionUserFetcherOverride = sessionUserFetcher,
        _oauthSessionLauncherOverride = oauthSessionLauncher,
        _webBaseUriProvider = webBaseUriProvider;

  final AppwriteConfig _config;
  final Account? _accountOverride;
  final Databases? _databasesOverride;
  final Future<User> Function()? _sessionUserFetcherOverride;
  final OAuthSessionLauncher? _oauthSessionLauncherOverride;
  final UriProvider? _webBaseUriProvider;

  Future<User?>? _checkSessionInFlight;
  User? _cachedSessionUser;
  DateTime? _cachedSessionAt;

  static const Duration _sessionCacheTtl = Duration(seconds: 5);
  static const Duration _clockSkewTolerance = Duration(minutes: 5);

  Account get _account => _accountOverride ?? _config.account;
  Databases get _databases => _databasesOverride ?? _config.databases;

  Uri get _webBaseUri => (_webBaseUriProvider ?? () => Uri.base)();

  OAuthSessionLauncher get _launchOAuthSession =>
      _oauthSessionLauncherOverride ?? _account.createOAuth2Session;

  bool _isCachedSessionFresh() {
    final DateTime? at = _cachedSessionAt;
    if (at == null || _cachedSessionUser == null) {
      return false;
    }
    return DateTime.now().difference(at) <= _sessionCacheTtl;
  }

  bool _isSessionUserValid(User user) {
    if (user.$id.trim().isEmpty || user.email.trim().isEmpty) {
      return false;
    }

    final DateTime? registration = DateTime.tryParse(user.registration);
    final DateTime? accessedAt = DateTime.tryParse(user.accessedAt);
    if (registration == null || accessedAt == null) {
      return false;
    }

    final DateTime now = DateTime.now().toUtc();
    if (accessedAt.isAfter(now.add(_clockSkewTolerance))) {
      return false;
    }

    return true;
  }

  Future<User?> _checkSessionInternal() async {
    try {
      final Future<User> Function() getSessionUser =
          _sessionUserFetcherOverride ?? _account.get;
      final User user = await getSessionUser();
      if (!_isSessionUserValid(user)) {
        debugPrint('Invalid session payload received from Appwrite account.get().');
        return null;
      }
      _cachedSessionUser = user;
      _cachedSessionAt = DateTime.now();
      return user;
    } on AppwriteException catch (error) {
      // 401 means there is no active session; other errors should bubble up
      // so startup/login can show retryable failures instead of silent logout.
      if (error.code == 401) {
        _cachedSessionUser = null;
        _cachedSessionAt = null;
        return null;
      }
      debugPrint('AppwriteException in checkSession: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in checkSession: $error');
      rethrow;
    }
  }

  @override
  Future<void> loginWithGoogle() async {
    await _launchGoogleOAuth(source: 'loginWithGoogle');
  }

  @override
  Future<void> signupWithGoogle() async {
    await _launchGoogleOAuth(source: 'signupWithGoogle');
  }

  Future<void> _launchGoogleOAuth({required String source}) async {
    try {
      final String successUrl = _buildRedirectUrl();
      final String failureUrl = _buildRedirectUrl();

      await _launchOAuthSession(
        provider: OAuthProvider.google,
        success: successUrl,
        failure: failureUrl,
      );
    } on AppwriteException catch (error) {
      if (_isPopupBlockedError(error)) {
        throw AppwriteException(
          'Browser blocked the OAuth popup. Allow popups for this site and retry.',
          error.code,
          error.response,
        );
      }
      if (_isRedirectValidationError(error)) {
        throw AppwriteException(
          'OAuth callback was rejected. Verify redirect origin/callback settings and retry.',
          error.code,
          error.response,
        );
      }
      debugPrint('AppwriteException in $source: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in $source: $error');
      rethrow;
    }
  }

  @override
  Future<User?> checkSession() async {
    if (_isCachedSessionFresh()) {
      return _cachedSessionUser;
    }

    final Future<User?>? inFlight = _checkSessionInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final Future<User?> run = _checkSessionInternal();
    _checkSessionInFlight = run;
    try {
      return await run;
    } finally {
      if (identical(_checkSessionInFlight, run)) {
        _checkSessionInFlight = null;
      }
    }
  }

  @override
  Future<void> completeUserProfile({
    required String phone,
    required String address,
  }) async {
    try {
      final User user = await _account.get();
      final AppwriteUserDoc userDoc = AppwriteUserDoc(
        uid: user.$id,
        name: user.name,
        email: user.email,
        phone: phone,
        address: address,
        activeStoreId: null,
      );

      await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colUsers,
        documentId: user.$id,
        data: userDoc.toMap(),
      );
    } on AppwriteException catch (error) {
      if (error.code == 409) {
        try {
          final User user = await _account.get();
          final AppwriteUserDoc userDoc = AppwriteUserDoc(
            uid: user.$id,
            name: user.name,
            email: user.email,
            phone: phone,
            address: address,
            activeStoreId: null,
          );
          await _databases.updateDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.colUsers,
            documentId: user.$id,
            data: userDoc.toMap(),
          );
          return;
        } on AppwriteException catch (nestedError) {
          debugPrint(
            'AppwriteException in completeUserProfile update path: ${nestedError.message}',
          );
          rethrow;
        }
      }
      debugPrint('AppwriteException in completeUserProfile: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in completeUserProfile: $error');
      rethrow;
    }
  }

  @override
  Future<void> logoutCurrentSession() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      _cachedSessionUser = null;
      _cachedSessionAt = null;
    } on AppwriteException catch (error) {
      if (error.code == 401 || error.code == 404) {
        _cachedSessionUser = null;
        _cachedSessionAt = null;
        return;
      }
      debugPrint('AppwriteException in logoutCurrentSession: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in logoutCurrentSession: $error');
      rethrow;
    }
  }

  @override
  Future<AppwriteUserDoc?> getUserProfile(String uid) async {
    try {
      final Document document = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colUsers,
        documentId: uid,
      );
      return AppwriteUserDoc.fromMap(uid: document.$id, data: document.data);
    } on AppwriteException catch (error) {
      if (error.code == 404) {
        return null;
      }
      debugPrint('AppwriteException in getUserProfile: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in getUserProfile: $error');
      rethrow;
    }
  }

  @override
  Future<void> setActiveStoreForUser({
    required String uid,
    required String storeId,
  }) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colUsers,
        documentId: uid,
        data: <String, dynamic>{'activeStoreId': storeId},
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in setActiveStoreForUser: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in setActiveStoreForUser: $error');
      rethrow;
    }
  }

  @override
  Future<String?> resolvePendingStoreAccess({
    required String uid,
    required String email,
  }) async {
    try {
      final String normalizedEmail = email.toLowerCase().trim();
      final DocumentList lowerInviteList = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colInvites,
        queries: <String>[
          Query.equal('emailLower', normalizedEmail),
        ],
      );

      final DocumentList inviteList;
      if (lowerInviteList.documents.isEmpty) {
        final DocumentList exactInviteList = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.colInvites,
          queries: <String>[Query.equal('email', email)],
        );
        if (exactInviteList.documents.isNotEmpty) {
          inviteList = exactInviteList;
        } else {
          inviteList = await _databases.listDocuments(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.colInvites,
            queries: <String>[Query.equal('email', normalizedEmail)],
          );
        }
      } else {
        inviteList = lowerInviteList;
      }

      if (inviteList.documents.isEmpty) {
        return null;
      }

      String? assignedStoreId;
      for (final Document invite in inviteList.documents) {
        final String targetStoreId = SchemaAdapter.asString(
          invite.data['targetStoreId'],
        );
        final String roleRaw = SchemaAdapter.asString(
          invite.data['role'],
          fallback: 'staff',
        );
        if (targetStoreId.isEmpty) {
          continue;
        }

        await _addUserToStoreTeam(
          targetStoreId: targetStoreId,
          uid: uid,
          role: roleRaw,
        );

        assignedStoreId ??= targetStoreId;

        await _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.colInvites,
          documentId: invite.$id,
        );
      }

      if (assignedStoreId != null) {
        try {
          await setActiveStoreForUser(uid: uid, storeId: assignedStoreId);
        } on AppwriteException catch (error) {
          if (error.code != 404) {
            rethrow;
          }
        }
      }

      return assignedStoreId;
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in resolvePendingStoreAccess: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in resolvePendingStoreAccess: $error');
      rethrow;
    }
  }

  Future<void> _addUserToStoreTeam({
    required String targetStoreId,
    required String uid,
    required String role,
  }) async {
    final Document storeDoc = await _databases.getDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.colStores,
      documentId: targetStoreId,
    );

    final List<Map<String, dynamic>> existingTeam = SchemaAdapter.asListOfMaps(
      storeDoc.data['team'],
    );
    final List<dynamic> team = List<dynamic>.from(existingTeam);

    final bool exists = team.any(
      (dynamic entry) =>
          entry is Map<String, dynamic> &&
          SchemaAdapter.asString(entry['uid']) == uid,
    );

    if (exists) {
      return;
    }

    team.add(<String, dynamic>{
      'uid': uid,
      'role': role == 'admin' || role == 'owner' ? 'admin' : 'staff',
    });

    await _databases.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.colStores,
      documentId: targetStoreId,
      data: <String, dynamic>{'team': team},
    );
  }

  String _buildRedirectUrl() {
    if (kIsWeb) {
      final Uri webUri = _sanitizeWebRedirectUri(_webBaseUri);
      return webUri.toString();
    }

    return 'https://localhost/auth-callback';
  }

  static Uri sanitizeWebRedirectUri(Uri raw) {
    final String scheme = raw.scheme.toLowerCase();
    final String host = raw.host.toLowerCase();
    final bool localhostHost = host == 'localhost' || host == '127.0.0.1';
    final bool schemeAllowed = scheme == 'https' || (scheme == 'http' && localhostHost);
    if (!schemeAllowed || host.isEmpty) {
      throw AppwriteException(
        'Unsafe OAuth redirect origin. Use HTTPS, or HTTP only on localhost.',
        400,
        raw.toString(),
      );
    }

    final String safePath = raw.path.isEmpty ? '/' : raw.path;
    return Uri(
      scheme: raw.scheme,
      host: raw.host,
      port: raw.hasPort ? raw.port : null,
      path: safePath,
    );
  }

  bool _isPopupBlockedError(AppwriteException error) {
    final String msg = (error.message ?? '').toLowerCase();
    return msg.contains('popup') && msg.contains('block');
  }

  bool _isRedirectValidationError(AppwriteException error) {
    final String msg = (error.message ?? '').toLowerCase();
    return msg.contains('redirect') || msg.contains('callback') || msg.contains('origin');
  }

  Uri _sanitizeWebRedirectUri(Uri raw) => sanitizeWebRedirectUri(raw);
}
