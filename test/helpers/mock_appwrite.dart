// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

import 'package:merchantportal/data/services/active_store_resolver.dart';
import 'package:merchantportal/data/services/auth_service.dart';
import 'package:merchantportal/data/models/schema/appwrite_user_doc.dart';

// ---------------------------------------------------------------------------
// Mock Databases
// ---------------------------------------------------------------------------

/// Minimal Databases mock for unit tests. Override per-method as needed.
class MockDatabases implements Databases {
  MockDatabases(this.client);

  @override
  final Client client;

  Future<Document> Function(String, String, String)? onGetDocument;
  Future<DocumentList> Function(String, String, List<String>)? onListDocuments;
  Future<Document> Function(String, String, String, Map<String, dynamic>)? onCreateDocument;
  Future<Document> Function(String, String, String, Map<String, dynamic>)? onUpdateDocument;
  Future<dynamic> Function(String, String, String)? onDeleteDocument;

  @override
  Future<Document> getDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    List<String>? queries,
    String? transactionId,
  }) async {
    if (onGetDocument != null) {
      return onGetDocument!(databaseId, collectionId, documentId);
    }
    throw UnimplementedError('MockDatabases.getDocument not configured');
  }

  @override
  Future<DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
    bool? total,
    String? transactionId,
    int? ttl,
  }) async {
    if (onListDocuments != null) {
      return onListDocuments!(databaseId, collectionId, queries ?? []);
    }
    throw UnimplementedError('MockDatabases.listDocuments not configured');
  }

  @override
  Future<Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<dynamic, dynamic> data,
    List<String>? permissions,
    String? transactionId,
  }) async {
    if (onCreateDocument != null) {
      return onCreateDocument!(databaseId, collectionId, documentId, Map<String, dynamic>.from(data));
    }
    throw UnimplementedError('MockDatabases.createDocument not configured');
  }

  @override
  Future<Document> updateDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    Map<dynamic, dynamic>? data,
    List<String>? permissions,
    String? transactionId,
  }) async {
    if (onUpdateDocument != null) {
      return onUpdateDocument!(databaseId, collectionId, documentId, data != null ? Map<String, dynamic>.from(data) : {});
    }
    throw UnimplementedError('MockDatabases.updateDocument not configured');
  }

  @override
  Future<dynamic> deleteDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    String? transactionId,
  }) async {
    if (onDeleteDocument != null) {
      return onDeleteDocument!(databaseId, collectionId, documentId);
    }
    throw UnimplementedError('MockDatabases.deleteDocument not configured');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not implemented in MockDatabases');
}

// ---------------------------------------------------------------------------
// Mock AuthService
// ---------------------------------------------------------------------------

class MockAuthService implements AuthServiceContract {
  MockAuthService({
    this.mockUser,
    this.mockUserDoc,
    this.mockStoreId,
  });

  final User? mockUser;
  final AppwriteUserDoc? mockUserDoc;
  final String? mockStoreId;

  @override
  Future<User?> checkSession() async => mockUser;

  @override
  Future<void> loginWithGoogle() async {}

  @override
  Future<void> signupWithGoogle() async {}

  @override
  Future<void> completeUserProfile({
    required String phone,
    required String address,
  }) async {}

  @override
  Future<void> logoutCurrentSession() async {}

  @override
  Future<AppwriteUserDoc?> getUserProfile(String uid) async => mockUserDoc;

  @override
  Future<void> setActiveStoreForUser({
    required String uid,
    required String storeId,
  }) async {}

  @override
  Future<String?> resolvePendingStoreAccess({
    required String uid,
    required String email,
  }) async => mockStoreId;
}

// ---------------------------------------------------------------------------
// Mock ActiveStoreResolver
// ---------------------------------------------------------------------------

class MockActiveStoreResolver implements ActiveStoreResolver {
  MockActiveStoreResolver({
    required this.storeId,
    this.userId = 'test_user_id',
    this.userEmail = 'test@example.com',
  });

  final String storeId;
  final String userId;
  final String userEmail;

  @override
  Future<String> resolve() async => storeId;

  @override
  Future<String?> resolveUserId() async => userId;

  @override
  Future<String?> resolveUserEmail() async => userEmail;

  @override
  void clearCache() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not implemented in MockActiveStoreResolver');
}

// ---------------------------------------------------------------------------
// Test Document helpers
// ---------------------------------------------------------------------------

/// Creates a minimal Appwrite-like Document for use in tests.
Document makeDocument({
  required String id,
  required Map<String, dynamic> data,
  String collectionId = 'test_collection',
  String databaseId = 'test_db',
}) {
  return Document(
    $id: id,
    $collectionId: collectionId,
    $databaseId: databaseId,
    $createdAt: DateTime.now().toIso8601String(),
    $updatedAt: DateTime.now().toIso8601String(),
    $permissions: [],
    $sequence: '',
    data: data,
  );
}

/// Creates a DocumentList wrapping the given documents.
DocumentList makeDocumentList(List<Document> documents) {
  return DocumentList(total: documents.length, documents: documents);
}
