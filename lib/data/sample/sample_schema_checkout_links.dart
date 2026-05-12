import '../models/schema/checkout_link_models.dart';

final List<CheckoutLink> sampleSchemaCheckoutLinks = [
  CheckoutLink(
    linkId: 'a73k2',
    merchantId: 'm_001',
    items: [
      CheckoutLinkItem(
        productId: 'prod_001',
        variantId: 'v_001_red',
        productName: 'Yuva Watch',
        variantName: 'Red',
        quantity: 1,
        unitPrice: 2200,
      ),
    ],
    financials: CheckoutFinancials(
      subtotal: 2200,
      shippingFee: 100,
      discountAmount: 0,
      totalAmount: 2300,
    ),
    status: CheckoutLinkStatus.active,
    createdAt: DateTime(2026, 3, 8),
  ),
  CheckoutLink(
    linkId: 'b52m1',
    merchantId: 'm_001',
    items: [
      CheckoutLinkItem(
        productId: 'prod_003',
        variantId: 'v_003_m',
        productName: 'Flex Tee',
        variantName: 'M',
        quantity: 2,
        unitPrice: 950,
      ),
    ],
    financials: CheckoutFinancials(
      subtotal: 1900,
      shippingFee: 80,
      discountAmount: 50,
      totalAmount: 1930,
    ),
    status: CheckoutLinkStatus.completed,
    createdAt: DateTime(2026, 3, 7),
  ),
];
