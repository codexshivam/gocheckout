import 'package:flutter_test/flutter_test.dart';

import 'package:merchantportal/data/models/schema/coupon_models.dart';
import 'package:merchantportal/data/repositories/coupons_repository.dart';

void main() {
  group('SampleCouponsRepository', () {
    late SampleCouponsRepository repo;

    Coupon makeCoupon({
      String id = 'cp_test',
      String code = 'TEST10',
      String merchantId = 'store_01',
      num discountValue = 10,
      CouponDiscountType type = CouponDiscountType.percentage,
    }) {
      return Coupon(
        id: id,
        merchantId: merchantId,
        code: code,
        discountType: type,
        discountValue: discountValue,
        usageTracker: const CouponUsageTracker(
          currentUsageCount: 0,
          maxUsageLimit: 100,
        ),
        lifecycleStatus: CouponLifecycleStatus.active,
        isDeleted: false,
      );
    }

    setUp(() {
      repo = SampleCouponsRepository();
    });

    test('fetchCoupons returns non-empty list from sample data', () async {
      final coupons = await repo.fetchCoupons();
      expect(coupons, isNotEmpty);
    });

    test('saveCoupon creates a new coupon', () async {
      final initial = await repo.fetchCoupons();
      final initialCount = initial.length;

      await repo.saveCoupon(makeCoupon(id: 'cp_brand_new'));

      final updated = await repo.fetchCoupons();
      expect(updated.length, initialCount + 1);
      expect(updated.any((c) => c.id == 'cp_brand_new'), isTrue);
    });

    test('saveCoupon updates existing coupon', () async {
      final initial = await repo.fetchCoupons();
      final existing = initial.first;

      final updated = makeCoupon(
        id: existing.id,
        code: 'UPDTCODE',
        merchantId: existing.merchantId,
      );
      await repo.saveCoupon(updated);

      final result = await repo.fetchCoupons();
      final found = result.firstWhere((c) => c.id == existing.id);
      expect(found.code, 'UPDTCODE');
    });

    test('deleteCoupon removes coupon', () async {
      final initial = await repo.fetchCoupons();
      final id = initial.first.id;

      await repo.deleteCoupon(id);
      final result = await repo.fetchCoupons();
      expect(result.any((c) => c.id == id), isFalse);
    });
  });
}
