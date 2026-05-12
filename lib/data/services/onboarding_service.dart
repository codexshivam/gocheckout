// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/appwrite_invite_doc.dart';
import '../models/schema/appwrite_store_doc.dart';
import '../models/schema/appwrite_user_doc.dart';

enum OnboardingRouteState {
  redirectToDashboard,
  redirectToCreateStore,
}

class OnboardingService {
  OnboardingService({
    AppwriteConfig? config,
    Databases? databases,
  })  : _config = config ?? AppwriteConfig.instance,
        _databasesOverride = databases;

  final AppwriteConfig _config;
  final Databases? _databasesOverride;

  Databases get _databases => _databasesOverride ?? _config.databases;

  Future<String?> _getUserActiveStoreId(String uid) async {
    try {
      final Document userDoc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colUsers,
        documentId: uid,
      );
      return AppwriteUserDoc.fromMap(uid: userDoc.$id, data: userDoc.data)
          .activeStoreId;
    } on AppwriteException catch (error) {
      if (error.code == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> _setUserActiveStoreIfNeeded({
    required String uid,
    required String targetStoreId,
  }) async {
    final String? existing = await _getUserActiveStoreId(uid);
    if ((existing ?? '').trim() == targetStoreId) {
      return;
    }
    await _databases.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.colUsers,
      documentId: uid,
      data: <String, dynamic>{'activeStoreId': targetStoreId},
    );
  }

  Future<void> _deleteInviteIfPresent(String inviteId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colInvites,
        documentId: inviteId,
      );
    } on AppwriteException catch (error) {
      if (error.code == 404) {
        return;
      }
      rethrow;
    }
  }

  Future<AppwriteInviteDoc?> _findInviteByEmail(String email) async {
    final String normalizedEmail = email.toLowerCase().trim();
    final DocumentList inviteList = await _databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.colInvites,
      queries: <String>[
        Query.equal('emailLower', normalizedEmail),
        Query.limit(1),
      ],
    );

    DocumentList effectiveInviteList = inviteList;
    if (effectiveInviteList.documents.isEmpty) {
      final DocumentList exactInviteList = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colInvites,
        queries: <String>[Query.equal('email', email), Query.limit(1)],
      );
      if (exactInviteList.documents.isNotEmpty) {
        effectiveInviteList = exactInviteList;
      } else {
        effectiveInviteList = await _databases.listDocuments(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.colInvites,
          queries: <String>[
            Query.equal('email', normalizedEmail),
            Query.limit(1),
          ],
        );
      }
    }

    if (effectiveInviteList.documents.isEmpty) {
      return null;
    }

    final Document inviteDoc = effectiveInviteList.documents.first;
    return AppwriteInviteDoc.fromMap(
      documentId: inviteDoc.$id,
      data: inviteDoc.data,
    );
  }

  Future<OnboardingRouteState> evaluateUserPath(String uid, String email) async {
    try {
      final String? activeStoreId = await _getUserActiveStoreId(uid);
      final AppwriteInviteDoc? inviteDoc = await _findInviteByEmail(email);

      if (inviteDoc == null) {
        if ((activeStoreId ?? '').trim().isNotEmpty) {
          return OnboardingRouteState.redirectToDashboard;
        }
        return OnboardingRouteState.redirectToCreateStore;
      }

      final String targetStoreId = inviteDoc.targetStoreId.trim();

      if (targetStoreId.isEmpty) {
        if ((activeStoreId ?? '').trim().isNotEmpty) {
          return OnboardingRouteState.redirectToDashboard;
        }
        return OnboardingRouteState.redirectToCreateStore;
      }

      await _setUserActiveStoreIfNeeded(
        uid: uid,
        targetStoreId: targetStoreId,
      );

      await _addUserToStoreTeam(
        targetStoreId: targetStoreId,
        uid: uid,
        role: inviteDoc.role,
      );

      await _deleteInviteIfPresent(inviteDoc.documentId);

      return OnboardingRouteState.redirectToDashboard;
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in evaluateUserPath: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in evaluateUserPath: $error');
      rethrow;
    }
  }

  Future<void> _addUserToStoreTeam({
    required String targetStoreId,
    required String uid,
    required String role,
  }) async {
    try {
      final Document storeDoc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: targetStoreId,
      );

      final AppwriteStoreDoc parsedStore = AppwriteStoreDoc.fromMap(
        documentId: storeDoc.$id,
        data: storeDoc.data,
      );

      if (!parsedStore.hasUser(uid)) {
        final AppwriteStoreDoc updatedStore = parsedStore.addUser(
          uid: uid,
          role: role == 'admin' || role == 'owner' ? 'admin' : 'staff',
        );
        await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.colStores,
          documentId: targetStoreId,
          data: <String, dynamic>{'team': updatedStore.team.map((m) => m.toMap()).toList()},
        );
      }
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in _addUserToStoreTeam: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in _addUserToStoreTeam: $error');
      rethrow;
    }
  }
}
