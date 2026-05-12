import '../models/schema/order_models.dart';

final List<OrderDocument> sampleSchemaOrders = [
  OrderDocument(
    id: '#9412',
    merchantId: 'm_001',
    checkoutLinkId: 'a73k2',
    items: [
      {
        'productId': 'prod_001',
        'variantId': 'v_001_red',
        'productName': 'Yuva Watch',
        'variantName': 'Red',
        'quantity': 1,
        'unitPrice': 2200,
      },
    ],
    financials: {
      'subtotal': 2200,
      'shippingFee': 100,
      'discountAmount': 0,
      'totalAmount': 2300,
    },
    customerInfo: OrderCustomerInfo(
      name: 'Sita Shah',
      phone: '9801000001',
      address: 'Gongabu, Kathmandu',
      district: 'Kathmandu',
    ),
    payment: OrderPayment(
      method: PaymentMethod.cod,
      status: PaymentStatus.pending,
      proofUrl: '',
    ),
    shipping: OrderShipping(
      status: ShippingStatus.created,
      timeline: ShippingTimeline(createdAt: DateTime(2026, 3, 8, 9, 10)),
    ),
  ),
  OrderDocument(
    id: '#9408',
    merchantId: 'm_001',
    checkoutLinkId: 'b52m1',
    items: [
      {
        'productId': 'prod_002',
        'variantId': 'v_002_default',
        'productName': 'Urban Bottle',
        'variantName': 'Default',
        'quantity': 1,
        'unitPrice': 1100,
      },
    ],
    financials: {
      'subtotal': 1100,
      'shippingFee': 0,
      'discountAmount': 0,
      'totalAmount': 1100,
    },
    customerInfo: OrderCustomerInfo(
      name: 'Rabin KC',
      phone: '9818000002',
      address: 'Banasthali, Kathmandu',
      district: 'Kathmandu',
    ),
    payment: OrderPayment(
      method: PaymentMethod.esewa,
      status: PaymentStatus.completed,
      proofUrl: '',
    ),
    shipping: OrderShipping(
      status: ShippingStatus.delivered,
      timeline: ShippingTimeline(
        createdAt: DateTime(2026, 3, 8, 8, 50),
        shippedAt: DateTime(2026, 3, 8, 10, 10),
        deliveredAt: DateTime(2026, 3, 8, 18, 5),
      ),
    ),
  ),
  OrderDocument(
    id: '#9399',
    merchantId: 'm_001',
    checkoutLinkId: 'b52m1',
    items: [
      {
        'productId': 'prod_003',
        'variantId': 'v_003_l',
        'productName': 'Flex Tee',
        'variantName': 'L',
        'quantity': 2,
        'unitPrice': 950,
      },
      {
        'productId': 'prod_001',
        'variantId': 'v_001_blue',
        'productName': 'Yuva Watch',
        'variantName': 'Blue',
        'quantity': 1,
        'unitPrice': 2250,
      },
    ],
    financials: {
      'subtotal': 4150,
      'shippingFee': 100,
      'discountAmount': 150,
      'totalAmount': 4100,
    },
    customerInfo: OrderCustomerInfo(
      name: 'Mina Rai',
      phone: '9841000003',
      address: 'Koteshwor, Kathmandu',
      district: 'Kathmandu',
    ),
    payment: OrderPayment(
      method: PaymentMethod.bankTransfer,
      status: PaymentStatus.completed,
      proofUrl: 'https://r2.example.com/receipts/order-9399.pdf',
    ),
    shipping: OrderShipping(
      status: ShippingStatus.rto,
      timeline: ShippingTimeline(
        createdAt: DateTime(2026, 3, 7, 11, 10),
        shippedAt: DateTime(2026, 3, 7, 14, 20),
        rtoAt: DateTime(2026, 3, 8, 13, 30),
      ),
    ),
  ),
];
