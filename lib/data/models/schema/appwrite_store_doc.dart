import 'schema_adapter.dart';

class StoreTeamMember {
  const StoreTeamMember({required this.uid, required this.role});

  final String uid;
  final String role;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'uid': uid, 'role': role};
  }

  static StoreTeamMember fromMap(Map<String, dynamic> data) {
    return StoreTeamMember(
      uid: SchemaAdapter.asString(data['uid']),
      role: SchemaAdapter.asString(data['role'], fallback: 'staff'),
    );
  }
}

class StoreSubscription {
  const StoreSubscription({required this.status});

  final String status;

  bool get isActive => status == 'active';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'status': status};
  }

  static StoreSubscription fromMap(Map<String, dynamic> data) {
    return StoreSubscription(
      status: SchemaAdapter.asString(data['status'], fallback: 'pending_payment'),
    );
  }
}

class AppwriteStoreDoc {
  const AppwriteStoreDoc({
    required this.documentId,
    required this.businessName,
    required this.team,
    required this.subscription,
  });

  final String documentId;
  final String businessName;
  final List<StoreTeamMember> team;
  final StoreSubscription subscription;

  bool hasUser(String uid) {
    return team.any((member) => member.uid == uid);
  }

  AppwriteStoreDoc addUser({required String uid, required String role}) {
    if (hasUser(uid)) {
      return this;
    }

    return AppwriteStoreDoc(
      documentId: documentId,
      businessName: businessName,
      team: <StoreTeamMember>[...team, StoreTeamMember(uid: uid, role: role)],
      subscription: subscription,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'businessName': businessName,
      'team': team.map((member) => member.toMap()).toList(),
      'subscription': subscription.toMap(),
    };
  }

  static AppwriteStoreDoc fromMap({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final List<Map<String, dynamic>> rawTeam = SchemaAdapter.asListOfMaps(
      data['team'],
    );
    return AppwriteStoreDoc(
      documentId: documentId,
      businessName: SchemaAdapter.asString(data['businessName']),
      team: rawTeam.map(StoreTeamMember.fromMap).toList(),
      subscription: StoreSubscription.fromMap(
        SchemaAdapter.asMap(data['subscription']),
      ),
    );
  }

  static AppwriteStoreDoc pendingPayment({
    required String documentId,
    required String businessName,
    required String ownerUid,
  }) {
    return AppwriteStoreDoc(
      documentId: documentId,
      businessName: businessName,
      team: <StoreTeamMember>[StoreTeamMember(uid: ownerUid, role: 'owner')],
      subscription: const StoreSubscription(status: 'pending_payment'),
    );
  }
}
