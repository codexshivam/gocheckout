enum MerchantVerificationStatus { pending, verified, rejected }

class MerchantContactInfo {
  const MerchantContactInfo({
    required this.email,
    required this.phone,
    required this.whatsapp,
  });

  final String email;
  final String phone;
  final String whatsapp;

  Map<String, dynamic> toMap() => {
    'email': email,
    'phone': phone,
    'whatsapp': whatsapp,
  };

  factory MerchantContactInfo.fromMap(Map<String, dynamic> map) {
    return MerchantContactInfo(
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      whatsapp: map['whatsapp'] as String? ?? '',
    );
  }
}

class MerchantStats {
  const MerchantStats({
    required this.totalSales,
    required this.totalOrders,
    required this.rtoCount,
  });

  final num totalSales;
  final int totalOrders;
  final int rtoCount;

  Map<String, dynamic> toMap() => {
    'totalSales': totalSales,
    'totalOrders': totalOrders,
    'rtoCount': rtoCount,
  };

  factory MerchantStats.fromMap(Map<String, dynamic> map) {
    return MerchantStats(
      totalSales: map['totalSales'] as num? ?? 0,
      totalOrders: map['totalOrders'] as int? ?? 0,
      rtoCount: map['rtoCount'] as int? ?? 0,
    );
  }
}

class Merchant {
  const Merchant({
    required this.merchantId,
    required this.businessName,
    required this.businessAddress,
    required this.contactInfo,
    required this.storeLogoUrl,
    required this.verificationStatus,
    required this.stats,
  });

  final String merchantId;
  final String businessName;
  final String businessAddress;
  final MerchantContactInfo contactInfo;
  final String storeLogoUrl;
  final MerchantVerificationStatus verificationStatus;
  final MerchantStats stats;

  Map<String, dynamic> toMap() => {
    'businessName': businessName,
    'businessAddress': businessAddress,
    'contactInfo': contactInfo.toMap(),
    'storeLogoUrl': storeLogoUrl,
    'verificationStatus': verificationStatus.name,
    'stats': stats.toMap(),
  };

  factory Merchant.fromMap(String merchantId, Map<String, dynamic> map) {
    final String statusRaw = map['verificationStatus'] as String? ?? 'pending';
    return Merchant(
      merchantId: merchantId,
      businessName: map['businessName'] as String? ?? '',
      businessAddress: map['businessAddress'] as String? ?? '',
      contactInfo: MerchantContactInfo.fromMap(
        (map['contactInfo'] as Map<String, dynamic>?) ?? const {},
      ),
      storeLogoUrl: map['storeLogoUrl'] as String? ?? '',
      verificationStatus: MerchantVerificationStatus.values.firstWhere(
        (s) => s.name == statusRaw,
        orElse: () => MerchantVerificationStatus.pending,
      ),
      stats: MerchantStats.fromMap(
        (map['stats'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}
