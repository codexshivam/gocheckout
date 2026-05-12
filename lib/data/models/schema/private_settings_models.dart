class MerchantVerificationPrivateSettings {
  const MerchantVerificationPrivateSettings({
    required this.citizenshipUrl,
    required this.businessRegUrl,
    required this.panUrl,
  });

  final String citizenshipUrl;
  final String businessRegUrl;
  final String panUrl;

  Map<String, dynamic> toMap() => {
    'citizenshipUrl': citizenshipUrl,
    'businessRegUrl': businessRegUrl,
    'panUrl': panUrl,
  };

  factory MerchantVerificationPrivateSettings.fromMap(
    Map<String, dynamic> map,
  ) {
    return MerchantVerificationPrivateSettings(
      citizenshipUrl: map['citizenshipUrl'] as String? ?? '',
      businessRegUrl: map['businessRegUrl'] as String? ?? '',
      panUrl: map['panUrl'] as String? ?? '',
    );
  }
}

class PaymentMethodSecrets {
  const PaymentMethodSecrets({
    required this.isActive,
    required this.credentials,
  });

  final bool isActive;
  final Map<String, String> credentials;

  Map<String, dynamic> toMap() => {'isActive': isActive, ...credentials};

  factory PaymentMethodSecrets.fromMap(Map<String, dynamic> map) {
    final Map<String, String> creds = {};
    map.forEach((key, value) {
      if (key != 'isActive') {
        creds[key] = value.toString();
      }
    });
    return PaymentMethodSecrets(
      isActive: map['isActive'] as bool? ?? false,
      credentials: creds,
    );
  }
}

class MerchantPaymentsPrivateSettings {
  const MerchantPaymentsPrivateSettings({
    required this.esewa,
    required this.khalti,
    required this.bankTransfer,
    required this.cod,
    this.lastModifiedAt,
    this.lastModifiedBy,
  });

  final PaymentMethodSecrets esewa;
  final PaymentMethodSecrets khalti;
  final PaymentMethodSecrets bankTransfer;
  final PaymentMethodSecrets cod;
  final String? lastModifiedAt;
  final String? lastModifiedBy;

  Map<String, dynamic> toMap() => {
    'esewa': esewa.toMap(),
    'khalti': khalti.toMap(),
    'bankTransfer': bankTransfer.toMap(),
    'cod': cod.toMap(),
    'lastModifiedAt': lastModifiedAt,
    'lastModifiedBy': lastModifiedBy,
  };

  factory MerchantPaymentsPrivateSettings.fromMap(Map<String, dynamic> map) {
    return MerchantPaymentsPrivateSettings(
      esewa: PaymentMethodSecrets.fromMap(
        (map['esewa'] as Map<String, dynamic>?) ?? const {},
      ),
      khalti: PaymentMethodSecrets.fromMap(
        (map['khalti'] as Map<String, dynamic>?) ?? const {},
      ),
      bankTransfer: PaymentMethodSecrets.fromMap(
        (map['bankTransfer'] as Map<String, dynamic>?) ?? const {},
      ),
      cod: PaymentMethodSecrets.fromMap(
        (map['cod'] as Map<String, dynamic>?) ?? const {},
      ),
      lastModifiedAt: map['lastModifiedAt'] as String?,
      lastModifiedBy: map['lastModifiedBy'] as String?,
    );
  }
}
