import 'package:flutter_test/flutter_test.dart';

import 'package:merchantportal/data/models/schema/coupon_models.dart';
import 'package:merchantportal/data/services/coupon_validation_service.dart';

void main() {
  group('CouponValidationService', () {
    CouponValidationInput makeInput({
      String code = 'SAVE20',
      CouponDiscountType type = CouponDiscountType.percentage,
      num? discountValue = 20,
      int? maxUsageLimit = 100,
      DateTime? startsAt,
      DateTime? endsAt,
      String? allowedPhone,
    }) {
      return CouponValidationInput(
        code: code,
        discountType: type,
        discountValue: discountValue,
        maxUsageLimit: maxUsageLimit,
        startsAt: startsAt,
        endsAt: endsAt,
        allowedCustomerPhone: allowedPhone,
      );
    }

    test('returns no errors for a valid percentage coupon', () {
      final errors = CouponValidationService.validate(makeInput());
      expect(errors, isEmpty);
    });

    test('returns no errors for a valid flat coupon', () {
      final errors = CouponValidationService.validate(
        makeInput(type: CouponDiscountType.flat, discountValue: 500),
      );
      expect(errors, isEmpty);
    });

    test('requires a non-empty code', () {
      final errors = CouponValidationService.validate(makeInput(code: ''));
      expect(errors.any((e) => e.toLowerCase().contains('code')), isTrue);
    });

    test('code must match A-Z0-9_- pattern, 4-24 chars', () {
      final errors = CouponValidationService.validate(makeInput(code: 'ab'));
      expect(errors, isNotEmpty);
    });

    test('requires discount value to be provided', () {
      final errors = CouponValidationService.validate(makeInput(discountValue: null));
      expect(errors, isNotEmpty);
    });

    test('requires discount value > 0', () {
      final errors = CouponValidationService.validate(makeInput(discountValue: 0));
      expect(errors, isNotEmpty);
    });

    test('requires maxUsageLimit > 0', () {
      final errors = CouponValidationService.validate(makeInput(maxUsageLimit: 0));
      expect(errors, isNotEmpty);
    });

    test('percentage discount cannot exceed 100', () {
      final errors = CouponValidationService.validate(
        makeInput(type: CouponDiscountType.percentage, discountValue: 101),
      );
      expect(errors, isNotEmpty);
    });

    test('validates date range: endsAt before startsAt is invalid', () {
      final now = DateTime.now().toUtc();
      final errors = CouponValidationService.validate(
        makeInput(
          code: 'EXPIREDX',
          startsAt: now.add(const Duration(hours: 2)),
          endsAt: now.add(const Duration(hours: 1)),
        ),
      );
      expect(errors.any((e) => e.toLowerCase().contains('end')), isTrue);
    });

    test('allows endsAt after startsAt', () {
      final now = DateTime.now().toUtc();
      final errors = CouponValidationService.validate(
        makeInput(
          code: 'VALIDDTE',
          startsAt: now,
          endsAt: now.add(const Duration(days: 30)),
        ),
      );
      expect(errors, isEmpty);
    });

    test('invalid phone format returns error', () {
      final errors = CouponValidationService.validate(
        makeInput(allowedPhone: 'not-a-phone'),
      );
      expect(errors.any((e) => e.toLowerCase().contains('phone')), isTrue);
    });

    test('valid 10-digit phone is accepted', () {
      final errors = CouponValidationService.validate(
        makeInput(allowedPhone: '9800000000'),
      );
      expect(errors, isEmpty);
    });
  });
}
