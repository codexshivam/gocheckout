import 'schema_adapter.dart';

class AppwriteUserDoc {
  const AppwriteUserDoc({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.activeStoreId,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? activeStoreId;

  bool get hasCompletedProfile => phone.trim().isNotEmpty && address.trim().isNotEmpty;

  AppwriteUserDoc copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? activeStoreId,
  }) {
    return AppwriteUserDoc(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      activeStoreId: activeStoreId ?? this.activeStoreId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'activeStoreId': activeStoreId,
    };
  }

  static AppwriteUserDoc fromMap({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return AppwriteUserDoc(
      uid: uid,
      name: SchemaAdapter.asString(data['name']),
      email: SchemaAdapter.asString(data['email']),
      phone: SchemaAdapter.asString(data['phone']),
      address: SchemaAdapter.asString(data['address']),
      activeStoreId: SchemaAdapter.asNullableString(data['activeStoreId']),
    );
  }
}
