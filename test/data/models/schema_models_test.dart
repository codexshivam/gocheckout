import 'package:flutter_test/flutter_test.dart';

import 'package:merchantportal/data/models/schema/product_models.dart';
import 'package:merchantportal/data/models/schema/order_models.dart';
import 'package:merchantportal/data/models/schema/coupon_models.dart';
import 'package:merchantportal/data/models/schema/checkout_link_models.dart';
import 'package:merchantportal/data/models/schema/store_stats_models.dart';
import 'package:merchantportal/data/models/schema/merchant_models.dart';
import 'package:merchantportal/data/models/schema/schema_adapter.dart';
import 'package:merchantportal/data/models/schema/private_settings_models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SchemaAdapter
  // ---------------------------------------------------------------------------
  group('SchemaAdapter', () {
    test('asString returns value for String', () {
      expect(SchemaAdapter.asString('hello'), 'hello');
    });

    test('asString converts non-String to string', () {
      expect(SchemaAdapter.asString(42), '42');
    });

    test('asString returns fallback for null', () {
      expect(SchemaAdapter.asString(null, fallback: 'default'), 'default');
    });

    test('asNullableString returns null for empty string', () {
      expect(SchemaAdapter.asNullableString(''), isNull);
    });

    test('asNullableString trims and returns null for whitespace', () {
      expect(SchemaAdapter.asNullableString('   '), isNull);
    });

    test('asBool parses bool literals', () {
      expect(SchemaAdapter.asBool(true), true);
      expect(SchemaAdapter.asBool(false), false);
    });

    test('asBool parses string truthy values', () {
      expect(SchemaAdapter.asBool('true'), true);
      expect(SchemaAdapter.asBool('1'), true);
      expect(SchemaAdapter.asBool('yes'), true);
    });

    test('asBool parses string falsy values', () {
      expect(SchemaAdapter.asBool('false'), false);
      expect(SchemaAdapter.asBool('0'), false);
      expect(SchemaAdapter.asBool('no'), false);
    });

    test('asBool returns fallback for unknown string', () {
      expect(SchemaAdapter.asBool('maybe', fallback: true), true);
    });

    test('asMap handles Map<String, dynamic>', () {
      final Map<String, dynamic> input = {'a': 1};
      expect(SchemaAdapter.asMap(input), {'a': 1});
    });

    test('asMap returns empty for null', () {
      expect(SchemaAdapter.asMap(null), isEmpty);
    });

    test('asListOfMaps returns list of maps', () {
      final List<dynamic> input = [
        {'a': 1},
        {'b': 2},
      ];
      final result = SchemaAdapter.asListOfMaps(input);
      expect(result.length, 2);
      expect(result.first['a'], 1);
    });

    test('asListOfMaps returns empty for non-list', () {
      expect(SchemaAdapter.asListOfMaps('not a list'), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Product model
  // ---------------------------------------------------------------------------
  group('Product.fromMap / toMap round-trip', () {
    test('basic product serializes and deserializes correctly', () {
      const Product product = Product(
        id: 'p1',
        merchantId: 'store_01',
        name: 'Test Shirt',
        description: 'A test shirt',
        basePrice: 1200,
        attributes: ['Color', 'Size'],
        variants: [],
      );

      final Map<String, dynamic> map = product.toMap();
      final Product restored = Product.fromMap('p1', map);

      expect(restored.id, 'p1');
      expect(restored.merchantId, 'store_01');
      expect(restored.name, 'Test Shirt');
      expect(restored.basePrice, 1200);
      expect(restored.attributes, ['Color', 'Size']);
    });

    test('ProductVariant serializes and deserializes', () {
      const ProductVariant variant = ProductVariant(
        variantId: 'v1',
        options: {'Color': 'Red', 'Size': 'M'},
        price: 1500,
        inventoryCount: 10,
        isInventoryTracked: true,
        imageUrl: 'https://example.com/img.jpg',
      );

      final Map<String, dynamic> map = variant.toMap();
      final ProductVariant restored = ProductVariant.fromMap(map);

      expect(restored.variantId, 'v1');
      expect(restored.options['Color'], 'Red');
      expect(restored.price, 1500);
      expect(restored.inventoryCount, 10);
      expect(restored.isInventoryTracked, true);
    });

    test('Product.fromMap resolves storeId from merchantId alias', () {
      final Product p = Product.fromMap('p2', {
        'merchantId': 'store_99',
        'name': 'N',
        'description': '',
        'basePrice': 0,
        'attributes': [],
        'variants': [],
      });
      expect(p.merchantId, 'store_99');
      expect(p.storeId, 'store_99');
    });

    test('Product.fromMap handles missing fields gracefully', () {
      final Product p = Product.fromMap('p3', {});
      expect(p.name, '');
      expect(p.variants, isEmpty);
      expect(p.attributes, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Merchant model
  // ---------------------------------------------------------------------------
  group('Merchant.fromMap / toMap', () {
    test('round-trip preserves all fields', () {
      final Merchant merchant = Merchant.fromMap('m1', {
        'businessName': 'Test Store',
        'businessAddress': '123 Main St',
        'contactInfo': {
          'email': 'store@test.com',
          'phone': '9800000000',
          'whatsapp': '9800000001',
        },
        'storeLogoUrl': 'https://example.com/logo.png',
        'verificationStatus': 'verified',
        'stats': {
          'totalSales': 50000,
          'totalOrders': 100,
          'rtoCount': 5,
        },
      });

      expect(merchant.businessName, 'Test Store');
      expect(merchant.verificationStatus, MerchantVerificationStatus.verified);
      expect(merchant.stats.totalOrders, 100);
      expect(merchant.contactInfo.email, 'store@test.com');
    });

    test('fromMap defaults to pending verification for unknown status', () {
      final Merchant m = Merchant.fromMap('m2', {'verificationStatus': 'unknown'});
      expect(m.verificationStatus, MerchantVerificationStatus.pending);
    });
  });

  // ---------------------------------------------------------------------------
  // Coupon model
  // ---------------------------------------------------------------------------
  group('Coupon.fromMap / toMap', () {
    test('round-trip preserves all fields', () {
      final Coupon coupon = Coupon(
        id: 'c1',
        merchantId: 'store_01',
        code: 'SAVE20',
        discountType: CouponDiscountType.percentage,
        discountValue: 20,
        usageTracker: const CouponUsageTracker(
          currentUsageCount: 5,
          maxUsageLimit: 100,
        ),
        lifecycleStatus: CouponLifecycleStatus.active,
        isDeleted: false,
      );

      final Map<String, dynamic> map = coupon.toMap();
      final Coupon restored = Coupon.fromMap(coupon.id, map);

      expect(restored.code, 'SAVE20');
      expect(restored.discountValue, 20);
      expect(restored.discountType, CouponDiscountType.percentage);
      expect(restored.usageTracker.maxUsageLimit, 100);
      expect(restored.isDeleted, false);
    });
  });

  // ---------------------------------------------------------------------------
  // StoreStatsDocument model
  // ---------------------------------------------------------------------------
  group('StoreStatsDocument.fromMap', () {
    test('empty map returns zero-value document', () {
      final doc = StoreStatsDocument.fromMap('s1', {});
      expect(doc.storeId, 's1');
      expect(doc.financials.totalRevenue, 0);
      expect(doc.orderMetrics.totalOrders, 0);
      expect(doc.monthlyHistory, isEmpty);
    });

    test('parses monthly history correctly', () {
      final doc = StoreStatsDocument.fromMap('s1', {
        'financials': {'totalRevenue': 100000},
        'orderMetrics': {'totalOrders': 50},
        'monthlyHistory': [
          {'month': 'Jan', 'revenue': 10000, 'orders': 10, 'rto': 1},
          {'month': 'Feb', 'revenue': 15000, 'orders': 15, 'rto': 0},
        ],
      });
      expect(doc.monthlyHistory.length, 2);
      expect(doc.monthlyHistory.first.revenue, 10000);
    });
  });

  // ---------------------------------------------------------------------------
  // CheckoutLink model
  // ---------------------------------------------------------------------------
  group('CheckoutLink.fromMap / toMap', () {
    test('round-trip with items and financials', () {
      final CheckoutLink link = CheckoutLink(
        linkId: 'l1',
        merchantId: 'store_01',
        items: const [
          CheckoutLinkItem(
            productId: 'p1',
            variantId: 'v1',
            productName: 'Shirt',
            variantName: 'Red / M',
            quantity: 2,
            unitPrice: 1200,
          ),
        ],
        financials: const CheckoutFinancials(
          subtotal: 2400,
          shippingFee: 100,
          discountAmount: 0,
          totalAmount: 2500,
        ),
        status: CheckoutLinkStatus.active,
        createdAt: DateTime(2026, 1, 1),
      );

      final Map<String, dynamic> map = link.toMap();
      final CheckoutLink restored = CheckoutLink.fromMap('l1', map);

      expect(restored.linkId, 'l1');
      expect(restored.items.length, 1);
      expect(restored.items.first.quantity, 2);
      expect(restored.financials.totalAmount, 2500);
      expect(restored.status, CheckoutLinkStatus.active);
    });
  });

  // ---------------------------------------------------------------------------
  // OrderDocument model
  // ---------------------------------------------------------------------------
  group('OrderDocument.fromMap / toMap', () {
    test('handles empty map with defaults', () {
      final order = OrderDocument.fromMap('o1', {});
      expect(order.id, 'o1');
      expect(order.items, isEmpty);
      expect(order.origin, OrderOrigin.manual);
    });

    test('resolves storeId from merchantId alias', () {
      final order = OrderDocument.fromMap('o2', {'merchantId': 'store_99'});
      expect(order.merchantId, 'store_99');
      expect(order.storeId, 'store_99');
    });
  });

  // ---------------------------------------------------------------------------
  // MerchantPaymentsPrivateSettings model
  // ---------------------------------------------------------------------------
  group('MerchantPaymentsPrivateSettings.fromMap / toMap', () {
    test('serializes and deserializes payment methods including COD correctly', () {
      const MerchantPaymentsPrivateSettings settings = MerchantPaymentsPrivateSettings(
        esewa: PaymentMethodSecrets(
          isActive: true,
          credentials: {'merchantCode': 'MC1', 'secretKey': 'SK1'},
        ),
        khalti: PaymentMethodSecrets(
          isActive: false,
          credentials: {},
        ),
        bankTransfer: PaymentMethodSecrets(
          isActive: true,
          credentials: {'bankName': 'Nabil', 'accountName': 'John', 'accountNumber': '1234'},
        ),
        cod: PaymentMethodSecrets(
          isActive: true,
          credentials: {},
        ),
        lastModifiedAt: '2026-05-09T09:00:00Z',
        lastModifiedBy: 'admin',
      );

      final Map<String, dynamic> map = settings.toMap();
      final MerchantPaymentsPrivateSettings restored = MerchantPaymentsPrivateSettings.fromMap(map);

      expect(restored.esewa.isActive, true);
      expect(restored.esewa.credentials['merchantCode'], 'MC1');
      expect(restored.khalti.isActive, false);
      expect(restored.bankTransfer.isActive, true);
      expect(restored.bankTransfer.credentials['bankName'], 'Nabil');
      expect(restored.cod.isActive, true);
      expect(restored.cod.credentials, isEmpty);
      expect(restored.lastModifiedAt, '2026-05-09T09:00:00Z');
      expect(restored.lastModifiedBy, 'admin');
    });

    test('decodes older records lacking cod field with default inactive COD method', () {
      final Map<String, dynamic> mapWithoutCod = {
        'esewa': {
          'isActive': true,
          'credentials': {'merchantCode': 'MC1', 'secretKey': 'SK1'}
        },
        'khalti': {
          'isActive': false,
          'credentials': <String, dynamic>{}
        },
        'bankTransfer': {
          'isActive': false,
          'credentials': <String, dynamic>{}
        },
        'lastModifiedAt': '2026-05-09T08:00:00Z',
        'lastModifiedBy': 'user123'
      };

      final MerchantPaymentsPrivateSettings restored = MerchantPaymentsPrivateSettings.fromMap(mapWithoutCod);

      expect(restored.esewa.isActive, true);
      expect(restored.cod.isActive, false); // Fallback default
      expect(restored.cod.credentials, isEmpty);
    });
  });
}
