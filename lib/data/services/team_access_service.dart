// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';

import '../config/appwrite_config.dart';
import '../models/schema/team_access_models.dart';

DateTime? _parseDateTime(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

class TeamAccessService {
  TeamAccessService({
    AppwriteConfig? config,
    Databases? databases,
  })  : _config = config ?? AppwriteConfig.instance,
        _databasesOverride = databases;

  final AppwriteConfig _config;
  final Databases? _databasesOverride;

  Databases get _databases => _databasesOverride ?? _config.databases;

  Future<List<TeamMemberRecord>> listTeamMembers(String storeId) async {
    try {
      final Document storeDoc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
      );

      final List<dynamic> team = storeDoc.data['team'] as List<dynamic>? ?? <dynamic>[];
      final List<TeamMemberRecord> results = <TeamMemberRecord>[];

      for (final dynamic entry in team) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }
        final String uid = entry['uid'] as String? ?? '';
        final String roleRaw = entry['role'] as String? ?? 'staff';
        if (uid.isEmpty) {
          continue;
        }

        String label = uid;
        try {
          final Document userDoc = await _databases.getDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.colUsers,
            documentId: uid,
          );
          final String name = userDoc.data['name'] as String? ?? '';
          final String email = userDoc.data['email'] as String? ?? '';
          label = name.isNotEmpty && email.isNotEmpty ? '$name • $email' : (email.isNotEmpty ? email : uid);
        } on AppwriteException catch (error) {
          debugPrint('AppwriteException in listTeamMembers user lookup: ${error.message}');
        }

        final TeamRole role = roleRaw == 'owner' || roleRaw == 'admin'
            ? TeamRole.admin
            : TeamRole.staff;

        results.add(
          TeamMemberRecord(
            id: uid,
            nameOrEmail: label,
            role: role,
            status: TeamMemberStatus.active,
            isPrimaryOwner: roleRaw == 'owner',
          ),
        );
      }

      final DocumentList inviteList = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colInvites,
        queries: <String>[Query.equal('targetStoreId', storeId)],
      );

      for (final Document invite in inviteList.documents) {
        final String email = invite.data['email'] as String? ?? '';
        final String roleRaw = invite.data['role'] as String? ?? 'staff';
        if (email.isEmpty) {
          continue;
        }

        results.add(
          TeamMemberRecord(
            id: invite.$id,
            nameOrEmail: email,
            role: roleRaw == 'admin' ? TeamRole.admin : TeamRole.staff,
            status: TeamMemberStatus.pending,
            isPrimaryOwner: false,
            pendingExpiresAt: _parseDateTime(invite.data['inviteExpiresAt']),
            pendingLastSentAt: _parseDateTime(invite.data['lastInviteSentAt']),
          ),
        );
      }

      return results;
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in listTeamMembers: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in listTeamMembers: $error');
      rethrow;
    }
  }

  Future<void> sendInvite({
    required String storeId,
    required String email,
    required TeamRole role,
  }) async {
    try {
      final String normalizedEmail = email.toLowerCase().trim();
      final DocumentList existing = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colInvites,
        queries: <String>[
          Query.equal('targetStoreId', storeId),
          Query.equal('emailLower', normalizedEmail),
          Query.limit(1),
        ],
      );

      final Map<String, dynamic> payload = <String, dynamic>{
        'email': normalizedEmail,
        'emailLower': normalizedEmail,
        'targetStoreId': storeId,
        'role': role == TeamRole.admin ? 'admin' : 'staff',
        'status': 'pending',
        'lastInviteSentAt': DateTime.now().toUtc().toIso8601String(),
        'inviteExpiresAt': DateTime.now()
            .toUtc()
            .add(const Duration(days: 7))
            .toIso8601String(),
      };

      if (existing.documents.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.colInvites,
          documentId: existing.documents.first.$id,
          data: payload,
        );
        return;
      }

      await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colInvites,
        documentId: ID.unique(),
        data: payload,
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in sendInvite: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in sendInvite: $error');
      rethrow;
    }
  }

  Future<void> removeMember({
    required String storeId,
    required TeamMemberRecord record,
  }) async {
    try {
      if (record.status == TeamMemberStatus.pending) {
        await _databases.deleteDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.colInvites,
          documentId: record.id,
        );
        return;
      }

      final Document storeDoc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
      );

      final List<dynamic> team = (storeDoc.data['team'] as List<dynamic>? ?? <dynamic>[])
          .where((entry) => entry is Map<String, dynamic> && entry['uid'] != record.id)
          .toList();

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colStores,
        documentId: storeId,
        data: <String, dynamic>{'team': team},
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in removeMember: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in removeMember: $error');
      rethrow;
    }
  }

  Future<void> resendPendingAccess({
    required TeamMemberRecord record,
  }) async {
    if (record.status != TeamMemberStatus.pending) {
      return;
    }

    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.colInvites,
        documentId: record.id,
        data: <String, dynamic>{
          'status': 'pending',
          'lastInviteSentAt': DateTime.now().toUtc().toIso8601String(),
          'inviteExpiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(days: 7))
              .toIso8601String(),
        },
      );
    } on AppwriteException catch (error) {
      debugPrint('AppwriteException in resendPendingAccess: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('Unexpected error in resendPendingAccess: $error');
      rethrow;
    }
  }
}
