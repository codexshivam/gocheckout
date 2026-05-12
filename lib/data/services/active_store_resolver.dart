// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../services/auth_service.dart';

/// Resolves the active store ID for the currently authenticated user.
///
/// This logic was previously duplicated in every [Appwrite*Repository].
/// Centralised here so all repositories share one tested implementation.
///
/// Throws [StateError] if there is no active session or no active store.
class ActiveStoreResolver {
  ActiveStoreResolver({
    required AuthServiceContract authService,
    AppwriteConfig? config,
    Databases? databases,
  })  : _authService = authService,
        _config = config ?? AppwriteConfig.instance,
        _databasesOverride = databases;

  final AuthServiceContract _authService;
  final AppwriteConfig _config;
  final Databases? _databasesOverride;

  Databases get _databases => _databasesOverride ?? _config.databases;

  // Cache the resolved storeId for the lifetime of this resolver so repos
  // within the same request don't issue duplicate Appwrite document fetches.
  String? _cachedStoreId;

  /// Returns the active store ID for the current user.
  ///
  /// Caches the result per-instance. Call [clearCache] after logout.
  Future<String> resolve() async {
    if (_cachedStoreId != null && _cachedStoreId!.isNotEmpty) {
      return _cachedStoreId!;
    }

    try {
      final User? user = await _authService.checkSession();
      if (user == null) {
        throw StateError('No active user session.');
      }

      final Document userDoc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colUsers,
        documentId: user.$id,
      );

      final String? storeId = userDoc.data['activeStoreId'] as String?;
      if (storeId == null || storeId.trim().isEmpty) {
        throw StateError(
          'No active store is set for user ${user.$id}. '
          'Complete onboarding before performing store operations.',
        );
      }

      _cachedStoreId = storeId.trim();
      return _cachedStoreId!;
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in ActiveStoreResolver.resolve: ${error.message}');
      rethrow;
    } on StateError {
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in ActiveStoreResolver.resolve: $error');
      rethrow;
    }
  }

  /// Returns the current user's Appwrite UID, or null if not logged in.
  Future<String?> resolveUserId() async {
    try {
      final User? user = await _authService.checkSession();
      return user?.$id;
    } catch (_) {
      return null;
    }
  }

  /// Returns the current user's email, or null if not logged in.
  Future<String?> resolveUserEmail() async {
    try {
      final User? user = await _authService.checkSession();
      return user?.email;
    } catch (_) {
      return null;
    }
  }

  /// Clears the cached store ID. Should be called after logout so the next
  /// resolve() fetches fresh data.
  void clearCache() {
    _cachedStoreId = null;
  }
}
