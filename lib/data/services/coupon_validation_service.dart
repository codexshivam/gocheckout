import '../models/schema/coupon_models.dart';

class CouponValidationInput {
  const CouponValidationInput({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.maxUsageLimit,
    this.allowedCustomerPhone,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.startsAt,
    this.endsAt,
    this.perCustomerLimit,
  });

  final String code;
  final CouponDiscountType discountType;
  final num? discountValue;
  final int? maxUsageLimit;
  final String? allowedCustomerPhone;
  final num? minOrderAmount;
  final num? maxDiscountAmount;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? perCustomerLimit;
}

class CouponValidationService {
  static final RegExp _codePattern = RegExp(r'^[A-Z0-9_-]{4,24}$');
  static final RegExp _phonePattern = RegExp(r'^\d{10,14}$');

  const CouponValidationService._();

  static List<String> validate(CouponValidationInput input) {
    final List<String> errors = <String>[];

    final String normalizedCode = input.code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      errors.add('Coupon code is required.');
    } else if (!_codePattern.hasMatch(normalizedCode)) {
      errors.add('Coupon code must be 4-24 chars with only A-Z, 0-9, _ or -.');
    }

    final num? discountValue = input.discountValue;
    if (discountValue == null) {
      errors.add('Discount value is required.');
    } else if (input.discountType == CouponDiscountType.percentage) {
      if (discountValue <= 0 || discountValue > 100) {
        errors.add('Percentage discount must be between 1 and 100.');
      }
    } else if (discountValue <= 0) {
      errors.add('Flat discount must be greater than zero.');
    }

    final int? maxUsageLimit = input.maxUsageLimit;
    if (maxUsageLimit == null || maxUsageLimit <= 0) {
      errors.add('Max usage limit must be greater than zero.');
    }

    final String phone = (input.allowedCustomerPhone ?? '').trim();
    if (phone.isNotEmpty && !_phonePattern.hasMatch(phone)) {
      errors.add('Allowed phone must be 10 to 14 digits.');
    }

    final num? minOrderAmount = input.minOrderAmount;
    if (minOrderAmount != null && minOrderAmount < 0) {
      errors.add('Minimum order amount cannot be negative.');
    }

    final num? maxDiscountAmount = input.maxDiscountAmount;
    if (maxDiscountAmount != null && maxDiscountAmount <= 0) {
      errors.add('Maximum discount amount must be greater than zero.');
    }

    if (input.discountType == CouponDiscountType.flat &&
        maxDiscountAmount != null &&
        discountValue != null &&
        discountValue > maxDiscountAmount) {
      errors.add('Flat discount cannot be greater than maximum discount cap.');
    }

    final DateTime? startsAt = input.startsAt;
    final DateTime? endsAt = input.endsAt;
    if (startsAt != null && endsAt != null && endsAt.isBefore(startsAt)) {
      errors.add('End date cannot be before start date.');
    }

    final int? perCustomerLimit = input.perCustomerLimit;
    if (perCustomerLimit != null && perCustomerLimit <= 0) {
      errors.add('Per-customer limit must be greater than zero.');
    }

    return errors;
  }
}
