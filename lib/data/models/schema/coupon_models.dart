import 'schema_adapter.dart';

enum CouponDiscountType { flat, percentage }

enum CouponLifecycleStatus { active, paused, archived }

class CouponUsageTracker {
  const CouponUsageTracker({
    required this.currentUsageCount,
    required this.maxUsageLimit,
  });

  final int currentUsageCount;
  final int maxUsageLimit;

  Map<String, dynamic> toMap() => {
    'currentUsageCount': currentUsageCount,
    'maxUsageLimit': maxUsageLimit,
  };

  factory CouponUsageTracker.fromMap(Map<String, dynamic> map) {
    return CouponUsageTracker(
      currentUsageCount: map['currentUsageCount'] as int? ?? 0,
      maxUsageLimit: map['maxUsageLimit'] as int? ?? 0,
    );
  }
}

class Coupon {
  const Coupon({
    required this.id,
    required this.merchantId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.usageTracker,
    this.lifecycleStatus = CouponLifecycleStatus.active,
    this.startsAt,
    this.endsAt,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.perCustomerLimit,
    this.allowedCustomerPhone,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  final String id;
  final String merchantId;
  final String code;
  final CouponDiscountType discountType;
  final num discountValue;
  final CouponUsageTracker usageTracker;
  final CouponLifecycleStatus lifecycleStatus;
  final String? startsAt;
  final String? endsAt;
  final num? minOrderAmount;
  final num? maxDiscountAmount;
  final int? perCustomerLimit;
  final String? allowedCustomerPhone;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final bool isDeleted;

  Map<String, dynamic> toMap() => {
    'merchantId': merchantId,
    'code': code,
    'discountType': discountType.name,
    'discountValue': discountValue,
    'usageTracker': usageTracker.toMap(),
    'lifecycleStatus': lifecycleStatus.name,
    'startsAt': startsAt,
    'endsAt': endsAt,
    'minOrderAmount': minOrderAmount,
    'maxDiscountAmount': maxDiscountAmount,
    'perCustomerLimit': perCustomerLimit,
    'allowedCustomerPhone': allowedCustomerPhone,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'isDeleted': isDeleted,
  };

  factory Coupon.fromMap(String id, Map<String, dynamic> map) {
    final String typeRaw = SchemaAdapter.asString(map['discountType'], fallback: 'flat');
    final String statusRaw = SchemaAdapter.asString(
      map['lifecycleStatus'],
      fallback: 'active',
    );
    final num discountValue =
        (map['discountValue'] is num) ? map['discountValue'] as num : num.tryParse(
          SchemaAdapter.asString(map['discountValue']),
        ) ??
        0;
    final num? minOrderAmount =
        (map['minOrderAmount'] is num)
            ? map['minOrderAmount'] as num
            : num.tryParse(SchemaAdapter.asString(map['minOrderAmount']));
    final num? maxDiscountAmount =
        (map['maxDiscountAmount'] is num)
            ? map['maxDiscountAmount'] as num
            : num.tryParse(SchemaAdapter.asString(map['maxDiscountAmount']));
    final int? perCustomerLimit =
        (map['perCustomerLimit'] is int)
            ? map['perCustomerLimit'] as int
            : int.tryParse(SchemaAdapter.asString(map['perCustomerLimit']));

    return Coupon(
      id: id,
      merchantId: SchemaAdapter.asString(map['merchantId']),
      code: SchemaAdapter.asString(map['code']),
      discountType: CouponDiscountType.values.firstWhere(
        (t) => t.name == typeRaw,
        orElse: () => CouponDiscountType.flat,
      ),
      discountValue: discountValue,
      usageTracker: CouponUsageTracker.fromMap(
        SchemaAdapter.asMap(map['usageTracker']),
      ),
      lifecycleStatus: CouponLifecycleStatus.values.firstWhere(
        (status) => status.name == statusRaw,
        orElse: () => CouponLifecycleStatus.active,
      ),
      startsAt: SchemaAdapter.asNullableString(map['startsAt']),
      endsAt: SchemaAdapter.asNullableString(map['endsAt']),
      minOrderAmount: minOrderAmount,
      maxDiscountAmount: maxDiscountAmount,
      perCustomerLimit: perCustomerLimit,
      allowedCustomerPhone: SchemaAdapter.asNullableString(map['allowedCustomerPhone']),
      createdBy: SchemaAdapter.asNullableString(map['createdBy']),
      createdAt: SchemaAdapter.asNullableString(map['createdAt']),
      updatedAt: SchemaAdapter.asNullableString(map['updatedAt']),
      isDeleted: SchemaAdapter.asBool(map['isDeleted'], fallback: false),
    );
  }
}
