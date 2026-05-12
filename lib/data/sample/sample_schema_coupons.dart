import '../models/schema/coupon_models.dart';

const List<Coupon> sampleSchemaCoupons = [
  Coupon(
    id: 'cp_001',
    merchantId: 'm_001',
    code: 'DASHAI25',
    discountType: CouponDiscountType.percentage,
    discountValue: 25,
    usageTracker: CouponUsageTracker(currentUsageCount: 12, maxUsageLimit: 200),
    allowedCustomerPhone: null,
  ),
  Coupon(
    id: 'cp_002',
    merchantId: 'm_001',
    code: 'WELCOME100',
    discountType: CouponDiscountType.flat,
    discountValue: 100,
    usageTracker: CouponUsageTracker(currentUsageCount: 30, maxUsageLimit: 300),
    allowedCustomerPhone: '9801000001',
  ),
];
