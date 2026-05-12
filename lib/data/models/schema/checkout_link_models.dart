class CheckoutLinkItem {
  const CheckoutLinkItem({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String variantId;
  final String productName;
  final String variantName;
  final int quantity;
  final num unitPrice;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'variantId': variantId,
    'productName': productName,
    'variantName': variantName,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  factory CheckoutLinkItem.fromMap(Map<String, dynamic> map) {
    return CheckoutLinkItem(
      productId: map['productId'] as String? ?? '',
      variantId: map['variantId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      variantName: map['variantName'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 0,
      unitPrice: map['unitPrice'] as num? ?? 0,
    );
  }
}

class CheckoutFinancials {
  const CheckoutFinancials({
    required this.subtotal,
    required this.shippingFee,
    required this.discountAmount,
    required this.totalAmount,
    this.extraCharges = const <CheckoutExtraCharge>[],
    this.discount,
  });

  final num subtotal;
  final num shippingFee;
  final num discountAmount;
  final num totalAmount;
  final List<CheckoutExtraCharge> extraCharges;
  final CheckoutDiscount? discount;

  Map<String, dynamic> toMap() => {
    'subtotal': subtotal,
    'shippingFee': shippingFee,
    'discountAmount': discountAmount,
    'totalAmount': totalAmount,
    'extraCharges': extraCharges.map((e) => e.toMap()).toList(),
    'discount': discount?.toMap(),
  };

  factory CheckoutFinancials.fromMap(Map<String, dynamic> map) {
    final List<CheckoutExtraCharge> parsedCharges =
        ((map['extraCharges'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(CheckoutExtraCharge.fromMap)
            .toList();
    final CheckoutDiscount? parsedDiscount = map['discount'] is Map<String, dynamic>
        ? CheckoutDiscount.fromMap(map['discount'] as Map<String, dynamic>)
        : null;

    return CheckoutFinancials(
      subtotal: map['subtotal'] as num? ?? 0,
      shippingFee: map['shippingFee'] as num? ?? 0,
      discountAmount: map['discountAmount'] as num? ?? 0,
      totalAmount: map['totalAmount'] as num? ?? 0,
      extraCharges: parsedCharges,
      discount: parsedDiscount,
    );
  }
}

class CheckoutExtraCharge {
  const CheckoutExtraCharge({required this.name, required this.amount});

  final String name;
  final num amount;

  Map<String, dynamic> toMap() => {'name': name, 'amount': amount};

  factory CheckoutExtraCharge.fromMap(Map<String, dynamic> map) {
    return CheckoutExtraCharge(
      name: map['name'] as String? ?? '',
      amount: map['amount'] as num? ?? 0,
    );
  }
}

enum CheckoutDiscountType { fixed, percentage }

class CheckoutDiscount {
  const CheckoutDiscount({required this.type, required this.amountDeducted});

  final CheckoutDiscountType type;
  final num amountDeducted;

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'amountDeducted': amountDeducted,
  };

  factory CheckoutDiscount.fromMap(Map<String, dynamic> map) {
    final String rawType = map['type'] as String? ?? 'fixed';
    return CheckoutDiscount(
      type: CheckoutDiscountType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => CheckoutDiscountType.fixed,
      ),
      amountDeducted: map['amountDeducted'] as num? ?? 0,
    );
  }
}

enum CheckoutLinkStatus { active, completed, converted, expired }

class CheckoutLink {
  const CheckoutLink({
    required this.linkId,
    required this.merchantId,
    required this.items,
    required this.financials,
    required this.status,
    required this.createdAt,
    this.convertedToOrderId,
  });

  final String linkId;
  final String merchantId;
  String get storeId => merchantId;
  final List<CheckoutLinkItem> items;
  final CheckoutFinancials financials;
  final CheckoutLinkStatus status;
  final DateTime createdAt;
  final String? convertedToOrderId;

  Map<String, dynamic> toMap() => {
    'storeId': merchantId,
    'merchantId': merchantId,
    'items': items.map((e) => e.toMap()).toList(),
    'financials': financials.toMap(),
    'status': status.name,
    'createdAt': createdAt,
    'convertedToOrderId': convertedToOrderId,
  };

  factory CheckoutLink.fromMap(String linkId, Map<String, dynamic> map) {
    final String statusRaw = map['status'] as String? ?? 'active';
    final String resolvedStoreId =
        map['storeId'] as String? ?? map['merchantId'] as String? ?? '';
    return CheckoutLink(
      linkId: linkId,
      merchantId: resolvedStoreId,
      items: ((map['items'] as List<dynamic>?) ?? const [])
          .map((e) => CheckoutLinkItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      financials: CheckoutFinancials.fromMap(
        (map['financials'] as Map<String, dynamic>?) ?? const {},
      ),
      status: CheckoutLinkStatus.values.firstWhere(
        (s) => s.name == statusRaw,
        orElse: () => CheckoutLinkStatus.active,
      ),
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
      convertedToOrderId: map['convertedToOrderId'] as String?,
    );
  }
}
