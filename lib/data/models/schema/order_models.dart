class OrderCustomerInfo {
  const OrderCustomerInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.district,
  });

  final String name;
  final String phone;
  final String address;
  final String district;

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'address': address,
    'district': district,
  };

  factory OrderCustomerInfo.fromMap(Map<String, dynamic> map) {
    return OrderCustomerInfo(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      district: map['district'] as String? ?? '',
    );
  }
}

enum PaymentMethod { cod, esewa, khalti, bankTransfer }

enum PaymentStatus { pending, completed, failed }

class OrderPayment {
  const OrderPayment({
    required this.method,
    required this.status,
    required this.proofUrl,
  });

  final PaymentMethod method;
  final PaymentStatus status;
  final String proofUrl;

  Map<String, dynamic> toMap() => {
    'method': _methodName(method),
    'status': status.name,
    'proofUrl': proofUrl,
  };

  factory OrderPayment.fromMap(Map<String, dynamic> map) {
    return OrderPayment(
      method: _parseMethod(map['method'] as String?),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
      proofUrl: map['proofUrl'] as String? ?? '',
    );
  }

  static PaymentMethod _parseMethod(String? value) {
    switch (value) {
      case 'esewa':
        return PaymentMethod.esewa;
      case 'khalti':
        return PaymentMethod.khalti;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.cod;
    }
  }

  static String _methodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.esewa:
        return 'esewa';
      case PaymentMethod.khalti:
        return 'khalti';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.cod:
        return 'cod';
    }
  }
}

enum ShippingStatus { created, shipped, delivered, rto }

class ShippingTimeline {
  const ShippingTimeline({
    required this.createdAt,
    this.shippedAt,
    this.deliveredAt,
    this.rtoAt,
  });

  final DateTime createdAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? rtoAt;

  Map<String, dynamic> toMap() => {
    'createdAt': createdAt,
    'shippedAt': shippedAt,
    'deliveredAt': deliveredAt,
    'rtoAt': rtoAt,
  };

  factory ShippingTimeline.fromMap(Map<String, dynamic> map) {
    DateTime? asDate(dynamic value) {
      return value is DateTime ? value : null;
    }

    return ShippingTimeline(
      createdAt: asDate(map['createdAt']) ?? DateTime.now(),
      shippedAt: asDate(map['shippedAt']),
      deliveredAt: asDate(map['deliveredAt']),
      rtoAt: asDate(map['rtoAt']),
    );
  }
}

class OrderShipping {
  const OrderShipping({required this.status, required this.timeline});

  final ShippingStatus status;
  final ShippingTimeline timeline;

  Map<String, dynamic> toMap() => {
    'status': status.name,
    'timeline': timeline.toMap(),
  };

  factory OrderShipping.fromMap(Map<String, dynamic> map) {
    return OrderShipping(
      status: ShippingStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'created'),
        orElse: () => ShippingStatus.created,
      ),
      timeline: ShippingTimeline.fromMap(
        (map['timeline'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

enum OrderOrigin { checkoutLink, manual }

enum OrderPaymentCollectionStatus { unpaid, partiallyPaid, fullyPaid }

enum OrderLedgerPaymentMethod { bankTransfer, codCash, esewa, khalti }

enum OrderLedgerPaymentStatus { pending, verified, failed }

class OrderPaymentSummary {
  const OrderPaymentSummary({
    required this.totalPaid,
    required this.balanceDue,
    required this.paymentStatus,
  });

  final num totalPaid;
  final num balanceDue;
  final OrderPaymentCollectionStatus paymentStatus;

  Map<String, dynamic> toMap() => {
    'totalPaid': totalPaid,
    'balanceDue': balanceDue,
    'paymentStatus': paymentStatus.name,
  };

  factory OrderPaymentSummary.fromMap(Map<String, dynamic> map) {
    return OrderPaymentSummary(
      totalPaid: map['totalPaid'] as num? ?? 0,
      balanceDue: map['balanceDue'] as num? ?? 0,
      paymentStatus: OrderPaymentCollectionStatus.values.firstWhere(
        (s) => s.name == (map['paymentStatus'] as String? ?? 'unpaid'),
        orElse: () => OrderPaymentCollectionStatus.unpaid,
      ),
    );
  }
}

class OrderPaymentLedgerEntry {
  const OrderPaymentLedgerEntry({
    required this.method,
    required this.amount,
    required this.status,
    this.proofUrl,
    this.recordedAt,
  });

  final OrderLedgerPaymentMethod method;
  final num amount;
  final OrderLedgerPaymentStatus status;
  final String? proofUrl;
  final DateTime? recordedAt;

  Map<String, dynamic> toMap() => {
    'method': method.name,
    'amount': amount,
    'status': status.name,
    'proofUrl': proofUrl,
    'recordedAt': recordedAt,
  };

  factory OrderPaymentLedgerEntry.fromMap(Map<String, dynamic> map) {
    return OrderPaymentLedgerEntry(
      method: OrderLedgerPaymentMethod.values.firstWhere(
        (m) => m.name == (map['method'] as String? ?? 'bankTransfer'),
        orElse: () => OrderLedgerPaymentMethod.bankTransfer,
      ),
      amount: map['amount'] as num? ?? 0,
      status: OrderLedgerPaymentStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'pending'),
        orElse: () => OrderLedgerPaymentStatus.pending,
      ),
      proofUrl: map['proofUrl'] as String?,
      recordedAt: map['recordedAt'] is DateTime
          ? map['recordedAt'] as DateTime
          : null,
    );
  }
}

class OrderDocument {
  const OrderDocument({
    required this.id,
    required this.merchantId,
    required this.checkoutLinkId,
    required this.items,
    required this.financials,
    required this.customerInfo,
    required this.payment,
    required this.shipping,
    this.origin = OrderOrigin.manual,
    this.sourceLinkId = '',
    this.paymentSummary = const OrderPaymentSummary(
      totalPaid: 0,
      balanceDue: 0,
      paymentStatus: OrderPaymentCollectionStatus.unpaid,
    ),
    this.paymentLedger = const <OrderPaymentLedgerEntry>[],
  });

  final String id;
  final String merchantId;
  String get storeId => merchantId;
  final String checkoutLinkId;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> financials;
  final OrderCustomerInfo customerInfo;
  final OrderPayment payment;
  final OrderShipping shipping;
  final OrderOrigin origin;
  final String sourceLinkId;
  final OrderPaymentSummary paymentSummary;
  final List<OrderPaymentLedgerEntry> paymentLedger;

  Map<String, dynamic> toMap() => {
    'storeId': merchantId,
    'merchantId': merchantId,
    'checkoutLinkId': checkoutLinkId,
    'items': items,
    'financials': financials,
    'customerInfo': customerInfo.toMap(),
    'payment': payment.toMap(),
    'shipping': shipping.toMap(),
    'origin': origin.name,
    'sourceLinkId': sourceLinkId,
    'paymentSummary': paymentSummary.toMap(),
    'paymentLedger': paymentLedger.map((e) => e.toMap()).toList(),
    'shippingTimeline': shipping.timeline.toMap(),
  };

  factory OrderDocument.fromMap(String id, Map<String, dynamic> map) {
    final String resolvedStoreId =
        map['storeId'] as String? ?? map['merchantId'] as String? ?? '';
    final String resolvedSourceLinkId =
        map['sourceLinkId'] as String? ?? map['checkoutLinkId'] as String? ?? '';
    final List<OrderPaymentLedgerEntry> resolvedPaymentLedger =
        ((map['paymentLedger'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(OrderPaymentLedgerEntry.fromMap)
            .toList();
    final num totalAmount = ((map['financials'] as Map<String, dynamic>?) ?? const {})['totalAmount'] as num? ?? 0;
    final OrderPaymentSummary resolvedPaymentSummary =
        map['paymentSummary'] is Map<String, dynamic>
        ? OrderPaymentSummary.fromMap(map['paymentSummary'] as Map<String, dynamic>)
        : OrderPaymentSummary(
            totalPaid: 0,
            balanceDue: totalAmount,
            paymentStatus: totalAmount <= 0
                ? OrderPaymentCollectionStatus.fullyPaid
                : OrderPaymentCollectionStatus.unpaid,
          );

    return OrderDocument(
      id: id,
      merchantId: resolvedStoreId,
      checkoutLinkId: map['checkoutLinkId'] as String? ?? '',
      items: ((map['items'] as List<dynamic>?) ?? const [])
          .map((e) => (e as Map<String, dynamic>))
          .toList(),
      financials: (map['financials'] as Map<String, dynamic>?) ?? const {},
      customerInfo: OrderCustomerInfo.fromMap(
        (map['customerInfo'] as Map<String, dynamic>?) ?? const {},
      ),
      payment: OrderPayment.fromMap(
        (map['payment'] as Map<String, dynamic>?) ?? const {},
      ),
      shipping: OrderShipping.fromMap(
        (map['shipping'] as Map<String, dynamic>?) ?? const {},
      ),
      origin: OrderOrigin.values.firstWhere(
        (o) => o.name == (map['origin'] as String? ?? 'manual'),
        orElse: () => OrderOrigin.manual,
      ),
      sourceLinkId: resolvedSourceLinkId,
      paymentSummary: resolvedPaymentSummary,
      paymentLedger: resolvedPaymentLedger,
    );
  }
}
