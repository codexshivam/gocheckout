import 'schema_adapter.dart';

class AppwriteInviteDoc {
  const AppwriteInviteDoc({
    required this.documentId,
    required this.email,
    required this.role,
    required this.targetStoreId,
  });

  final String documentId;
  final String email;
  final String role;
  final String targetStoreId;

  static AppwriteInviteDoc fromMap({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return AppwriteInviteDoc(
      documentId: documentId,
      email: SchemaAdapter.asString(data['email']),
      role: SchemaAdapter.asString(data['role'], fallback: 'staff'),
      targetStoreId: SchemaAdapter.asString(data['targetStoreId']),
    );
  }
}
