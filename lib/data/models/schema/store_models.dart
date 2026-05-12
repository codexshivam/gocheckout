enum StoreVerificationStatus { pending, verified, rejected }

enum StoreTeamRole { owner, chatAgent }

enum StorePlan { trial, pro }

enum StoreSubscriptionStatus { active, pastDue }

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.activeStoreId,
  });

  final String uid;
  final String name;
  final String phone;
  final String email;
  final String activeStoreId;

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'email': email,
    'activeStoreId': activeStoreId,
  };

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      activeStoreId: map['activeStoreId'] as String? ?? '',
    );
  }
}

class StoreTeamMember {
  const StoreTeamMember({required this.userId, required this.role});

  final String userId;
  final StoreTeamRole role;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'role': role.name,
  };

  factory StoreTeamMember.fromMap(Map<String, dynamic> map) {
    final String rawRole = map['role'] as String? ?? 'chat_agent';
    return StoreTeamMember(
      userId: map['userId'] as String? ?? '',
      role: _parseRole(rawRole),
    );
  }

  static StoreTeamRole _parseRole(String value) {
    switch (value) {
      case 'owner':
        return StoreTeamRole.owner;
      case 'chat_agent':
      case 'chatAgent':
        return StoreTeamRole.chatAgent;
      default:
        return StoreTeamRole.chatAgent;
    }
  }
}

class StoreSubscription {
  const StoreSubscription({
    required this.plan,
    required this.status,
    required this.expiresAt,
  });

  final StorePlan plan;
  final StoreSubscriptionStatus status;
  final DateTime expiresAt;

  Map<String, dynamic> toMap() => {
    'plan': plan.name,
    'status': status.name,
    'expiresAt': expiresAt,
  };

  factory StoreSubscription.fromMap(Map<String, dynamic> map) {
    final String rawPlan = map['plan'] as String? ?? 'trial';
    final String rawStatus = map['status'] as String? ?? 'active';
    return StoreSubscription(
      plan: StorePlan.values.firstWhere(
        (p) => p.name == rawPlan,
        orElse: () => StorePlan.trial,
      ),
      status: StoreSubscriptionStatus.values.firstWhere(
        (s) => s.name == rawStatus,
        orElse: () => StoreSubscriptionStatus.active,
      ),
      expiresAt: map['expiresAt'] is DateTime
          ? map['expiresAt'] as DateTime
          : DateTime.now(),
    );
  }
}

class StoreContactInfo {
  const StoreContactInfo({required this.email, required this.phone});

  final String email;
  final String phone;

  Map<String, dynamic> toMap() => {
    'email': email,
    'phone': phone,
  };

  factory StoreContactInfo.fromMap(Map<String, dynamic> map) {
    return StoreContactInfo(
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }
}

class Store {
  const Store({
    required this.storeId,
    required this.businessName,
    required this.businessAddress,
    required this.contactInfo,
    required this.storeLogoUrl,
    required this.verificationStatus,
    required this.team,
    required this.subscription,
  });

  final String storeId;
  final String businessName;
  final String businessAddress;
  final StoreContactInfo contactInfo;
  final String storeLogoUrl;
  final StoreVerificationStatus verificationStatus;
  final List<StoreTeamMember> team;
  final StoreSubscription subscription;

  Map<String, dynamic> toMap() => {
    'businessName': businessName,
    'businessAddress': businessAddress,
    'contactInfo': contactInfo.toMap(),
    'storeLogoUrl': storeLogoUrl,
    'verificationStatus': verificationStatus.name,
    'team': team.map((e) => e.toMap()).toList(),
    'subscription': subscription.toMap(),
  };

  factory Store.fromMap(String storeId, Map<String, dynamic> map) {
    final String statusRaw = map['verificationStatus'] as String? ?? 'pending';
    return Store(
      storeId: storeId,
      businessName: map['businessName'] as String? ?? '',
      businessAddress: map['businessAddress'] as String? ?? '',
      contactInfo: StoreContactInfo.fromMap(
        (map['contactInfo'] as Map<String, dynamic>?) ?? const {},
      ),
      storeLogoUrl: map['storeLogoUrl'] as String? ?? '',
      verificationStatus: StoreVerificationStatus.values.firstWhere(
        (s) => s.name == statusRaw,
        orElse: () => StoreVerificationStatus.pending,
      ),
      team: ((map['team'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(StoreTeamMember.fromMap)
          .toList(),
      subscription: StoreSubscription.fromMap(
        (map['subscription'] as Map<String, dynamic>?) ??
            const <String, dynamic>{
              'plan': 'trial',
              'status': 'active',
            },
      ),
    );
  }
}
