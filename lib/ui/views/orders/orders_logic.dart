import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../data/models/schema/order_models.dart';
import '../../../data/models/schema/product_models.dart';
import '../../../data/repositories/orders_repository.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/service_locator.dart';
import '../../common/app_styles.dart';
import '../../theme/app_colors.dart';
import 'orders_view.dart';
import 'orders_widgets.dart';

class OrderDraftItem {
  OrderDraftItem({
    this.selectedProductId,
    this.selectedVariantId,
    required this.quantityController,
  });

  String? selectedProductId;
  String? selectedVariantId;
  final TextEditingController quantityController;

  void dispose() {
    quantityController.dispose();
  }
}

mixin OrdersLogic on State<OrdersView> {
  final OrdersRepository ordersRepository = ServiceLocator.instance.ordersRepository;
  final ProductsRepository productsRepository = ServiceLocator.instance.productsRepository;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController discountController = TextEditingController(
    text: '0',
  );

  final List<OrderDraftItem> draftItems = <OrderDraftItem>[];

  List<OrderDocument> orders = const <OrderDocument>[];
  List<Product> products = const <Product>[];

  String statusFilter = 'All';
  PaymentMethod selectedPaymentMethod = PaymentMethod.cod;
  ShippingStatus selectedShippingStatus = ShippingStatus.created;

  String? editingOrderId;
  bool isSaving = false;
  bool showInlineOrderForm = false;

  @override
  void initState() {
    super.initState();
    loadProducts();
    loadOrders();
    addDraftItem();
  }

  @override
  void dispose() {
    searchController.dispose();
    customerNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    districtController.dispose();
    discountController.dispose();
    disposeDraftItems();
    super.dispose();
  }

  Future<void> loadProducts() async {
    final List<Product> result = await productsRepository.fetchProducts();
    if (!mounted) return;
    setState(() {
      products = result;
      for (final OrderDraftItem item in draftItems) {
        if (item.selectedProductId == null && products.isNotEmpty) {
          item.selectedProductId = products.first.id;
          item.selectedVariantId = products.first.variants.isNotEmpty
              ? products.first.variants.first.variantId
              : null;
        }
      }
    });
  }

  Future<void> loadOrders() async {
    final List<OrderDocument> result = await ordersRepository.fetchOrders();
    if (!mounted) return;
    setState(() => orders = result);
  }

  void disposeDraftItems() {
    for (final OrderDraftItem item in draftItems) {
      item.dispose();
    }
    draftItems.clear();
  }

  Product? productById(String? productId) {
    if (productId == null) return null;
    for (final Product product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  ProductVariant? variantByIds(String? productId, String? variantId) {
    final Product? product = productById(productId);
    if (product == null || variantId == null) return null;
    for (final ProductVariant variant in product.variants) {
      if (variant.variantId == variantId) return variant;
    }
    return null;
  }

  void addDraftItem({
    String? productId,
    String? variantId,
    String quantity = '1',
  }) {
    final Product? fallbackProduct = products.isNotEmpty ? products.first : null;
    final String? selectedProductId = productId ?? fallbackProduct?.id;
    final Product? selectedProduct = productById(selectedProductId);
    final String? selectedVariantId =
        variantId ??
        (selectedProduct?.variants.isNotEmpty == true
            ? selectedProduct!.variants.first.variantId
            : null);

    draftItems.add(
      OrderDraftItem(
        selectedProductId: selectedProductId,
        selectedVariantId: selectedVariantId,
        quantityController: TextEditingController(text: quantity),
      ),
    );
  }

  void removeDraftItem(int index) {
    if (draftItems.length <= 1) return;
    final OrderDraftItem removed = draftItems.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  num get draftSubtotal {
    num subtotal = 0;
    for (final OrderDraftItem item in draftItems) {
      final int quantity = int.tryParse(item.quantityController.text.trim()) ?? 0;
      final ProductVariant? variant =
          variantByIds(item.selectedProductId, item.selectedVariantId);
      final num unitPrice = variant?.price ?? 0;
      if (quantity > 0) subtotal += quantity * unitPrice;
    }
    return subtotal;
  }

  num get draftDiscount {
    final num parsed = num.tryParse(discountController.text.trim()) ?? 0;
    if (parsed < 0) return 0;
    return parsed;
  }

  num get draftGrandTotal {
    final num total = draftSubtotal - draftDiscount;
    return total < 0 ? 0 : total;
  }

  List<OrderDocument> get filteredOrders {
    final String query = searchController.text.trim().toLowerCase();
    return orders.where((OrderDocument order) {
      final bool queryMatch =
          query.isEmpty ||
          order.id.toLowerCase().contains(query) ||
          order.customerInfo.name.toLowerCase().contains(query) ||
          order.customerInfo.phone.toLowerCase().contains(query);
      final bool statusMatch =
          statusFilter == 'All' ||
          statusFilter == shippingStatusLabel(order.shipping.status);
      return queryMatch && statusMatch;
    }).toList();
  }

  void openCreate() {
    setState(() {
      showInlineOrderForm = true;
      editingOrderId = null;
      customerNameController.clear();
      phoneController.clear();
      addressController.clear();
      districtController.clear();
      discountController.text = '0';
      selectedPaymentMethod = PaymentMethod.cod;
      selectedShippingStatus = ShippingStatus.created;
      isSaving = false;
      disposeDraftItems();
      addDraftItem();
    });
  }

  void openEdit(OrderDocument order) {
    setState(() {
      showInlineOrderForm = true;
      editingOrderId = order.id;
      customerNameController.text = order.customerInfo.name;
      phoneController.text = order.customerInfo.phone;
      addressController.text = order.customerInfo.address;
      districtController.text = order.customerInfo.district;
        discountController.text =
          (order.financials['discountAmount'] as num? ?? 0).toStringAsFixed(0);
      selectedPaymentMethod = order.payment.method;
      selectedShippingStatus = order.shipping.status;
      isSaving = false;

      disposeDraftItems();
      for (final Map<String, dynamic> raw in order.items) {
        addDraftItem(
          productId: raw['productId']?.toString(),
          variantId: raw['variantId']?.toString(),
          quantity: (raw['quantity'] as int?)?.toString() ?? '1',
        );
      }
      if (draftItems.isEmpty) addDraftItem();
    });
  }

  void cancelInlineForm() {
    setState(() {
      showInlineOrderForm = false;
      isSaving = false;
      editingOrderId = null;
      selectedPaymentMethod = PaymentMethod.cod;
      selectedShippingStatus = ShippingStatus.created;
      discountController.text = '0';
      disposeDraftItems();
      addDraftItem();
    });
  }

  Future<void> saveInlineForm() async {
    final bool saved = await saveOrder();
    if (!mounted) return;
    if (saved) {
      setState(() => showInlineOrderForm = false);
    }
  }

  Future<bool> saveOrder() async {
    final String customerName = customerNameController.text.trim();
    final String phone = phoneController.text.trim();
    final String address = addressController.text.trim();
    final String district = districtController.text.trim();

    if (customerName.isEmpty ||
        phone.isEmpty ||
        address.isEmpty ||
        district.isEmpty) {
      showMessage('Please fill customer details.');
      return false;
    }

    final bool phoneValid =
        phone.length >= 10 && phone.length <= 14 && int.tryParse(phone) != null;
    if (!phoneValid) {
      showMessage('Customer phone must be 10 to 14 digits.');
      return false;
    }

    if (products.isEmpty) {
      showMessage('No products available to create order.');
      return false;
    }

    if (draftItems.isEmpty) {
      showMessage('Add at least one order item.');
      return false;
    }

    final List<Map<String, dynamic>> orderItems = <Map<String, dynamic>>[];
    for (final OrderDraftItem draft in draftItems) {
      final Product? product = productById(draft.selectedProductId);
      final ProductVariant? variant =
          variantByIds(draft.selectedProductId, draft.selectedVariantId);
      final int? quantity = int.tryParse(draft.quantityController.text.trim());

      if (product == null ||
          variant == null ||
          quantity == null ||
          quantity <= 0) {
        showMessage('Each item must have product, variant and valid quantity.');
        return false;
      }

      final String variantName = variantLabel(variant);
      orderItems.add(<String, dynamic>{
        'productId': product.id,
        'variantId': variant.variantId,
        'productName': product.name,
        'variantName': variantName.isEmpty ? 'Default' : variantName,
        'quantity': quantity,
        'unitPrice': variant.price,
      });
    }

    final num subtotal = draftSubtotal;
    if (subtotal <= 0) {
      showMessage('Order total must be greater than zero.');
      return false;
    }

    final num discountAmount = draftDiscount;
    if (discountAmount > subtotal) {
      showMessage('Discount cannot be greater than subtotal.');
      return false;
    }
    final num totalAmount = subtotal - discountAmount;

    final OrderDocument? existing = orders
        .where((OrderDocument order) => order.id == editingOrderId)
        .firstOrNull;

    final String orderId =
        existing?.id ?? '#${DateTime.now().millisecondsSinceEpoch % 100000}';

    final DateTime now = DateTime.now();
    final ShippingTimeline timeline = ShippingTimeline(
      createdAt: existing?.shipping.timeline.createdAt ?? now,
      shippedAt:
          selectedShippingStatus == ShippingStatus.shipped ||
              selectedShippingStatus == ShippingStatus.delivered ||
              selectedShippingStatus == ShippingStatus.rto
          ? (existing?.shipping.timeline.shippedAt ?? now)
          : null,
      deliveredAt: selectedShippingStatus == ShippingStatus.delivered
          ? (existing?.shipping.timeline.deliveredAt ?? now)
          : null,
      rtoAt: selectedShippingStatus == ShippingStatus.rto
          ? (existing?.shipping.timeline.rtoAt ?? now)
          : null,
    );

    final bool isCod = selectedPaymentMethod == PaymentMethod.cod;
    final OrderLedgerPaymentMethod ledgerMethod;
    switch (selectedPaymentMethod) {
      case PaymentMethod.cod:
        ledgerMethod = OrderLedgerPaymentMethod.codCash;
      case PaymentMethod.esewa:
        ledgerMethod = OrderLedgerPaymentMethod.esewa;
      case PaymentMethod.khalti:
        ledgerMethod = OrderLedgerPaymentMethod.khalti;
      case PaymentMethod.bankTransfer:
        ledgerMethod = OrderLedgerPaymentMethod.bankTransfer;
    }

    final List<OrderPaymentLedgerEntry> paymentLedger = isCod
        ? <OrderPaymentLedgerEntry>[
            OrderPaymentLedgerEntry(
              method: ledgerMethod,
              amount: totalAmount,
              status: OrderLedgerPaymentStatus.pending,
              recordedAt: now,
            ),
          ]
        : <OrderPaymentLedgerEntry>[
            OrderPaymentLedgerEntry(
              method: ledgerMethod,
              amount: totalAmount,
              status: OrderLedgerPaymentStatus.verified,
              proofUrl: selectedPaymentMethod == PaymentMethod.bankTransfer
                  ? 'https://pub-merchantportal-assets.r2.dev/receipts/${orderId.replaceAll('#', '').toLowerCase()}.pdf'
                  : null,
              recordedAt: now,
            ),
          ];

    final OrderPaymentSummary paymentSummary = isCod
        ? OrderPaymentSummary(
            totalPaid: 0,
            balanceDue: totalAmount,
            paymentStatus: OrderPaymentCollectionStatus.unpaid,
          )
        : OrderPaymentSummary(
            totalPaid: totalAmount,
            balanceDue: 0,
            paymentStatus: OrderPaymentCollectionStatus.fullyPaid,
          );

    final OrderDocument next = OrderDocument(
      id: orderId,
      merchantId: existing?.merchantId ?? 'm_001',
      checkoutLinkId: existing?.checkoutLinkId ?? 'manual',
      sourceLinkId: existing?.sourceLinkId ?? 'manual',
      origin: existing?.origin ?? OrderOrigin.manual,
      items: orderItems,
      financials: <String, dynamic>{
        'subtotal': subtotal,
        'shippingFee': 0,
        'discountAmount': discountAmount,
        'totalAmount': totalAmount,
      },
      customerInfo: OrderCustomerInfo(
        name: customerName,
        phone: phone,
        address: address,
        district: district,
      ),
      payment: OrderPayment(
        method: selectedPaymentMethod,
        status: selectedPaymentMethod == PaymentMethod.cod
            ? PaymentStatus.pending
            : PaymentStatus.completed,
        proofUrl: selectedPaymentMethod == PaymentMethod.bankTransfer
            ? 'https://pub-merchantportal-assets.r2.dev/receipts/${orderId.replaceAll('#', '').toLowerCase()}.pdf'
            : '',
      ),
      shipping: OrderShipping(status: selectedShippingStatus, timeline: timeline),
      paymentSummary: paymentSummary,
      paymentLedger: paymentLedger,
    );

    setState(() => isSaving = true);
    await ordersRepository.saveOrder(next);
    await loadOrders();
    if (!mounted) return false;
    setState(() {
      isSaving = false;
      editingOrderId = null;
    });
    showMessage('Order saved successfully.');
    return true;
  }

  Future<void> confirmDeleteOrder(OrderDocument order) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Order'),
          content: Text('Are you sure you want to delete order ${order.id}?'),
          actions: [
            OutlinedButton(
              style: outlinedStyle(),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: blackButtonStyle(),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Feather.trash_2, size: 18),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ordersRepository.deleteOrder(order.id);
      await loadOrders();
      if (!mounted) return;
      showMessage('Order deleted.');
    }
  }

  void openDetails(OrderDocument order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailsView(
          order: order,
          paymentMethodLabel: paymentMethodLabel,
          shippingStatusLabel: shippingStatusLabel,
          fmtDate: fmtDate,
        ),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String fmtDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String shippingStatusLabel(ShippingStatus status) {
    switch (status) {
      case ShippingStatus.created:
        return 'Created';
      case ShippingStatus.shipped:
        return 'Shipped';
      case ShippingStatus.delivered:
        return 'Delivered';
      case ShippingStatus.rto:
        return 'RTO';
    }
  }

  String paymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cod:
        return 'COD';
      case PaymentMethod.esewa:
        return 'eSewa';
      case PaymentMethod.khalti:
        return 'Khalti';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String itemsSummary(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 'No items';
    final String name = items.first['productName']?.toString() ?? 'Item';
    return items.length == 1 ? name : '$name + ${items.length - 1} more';
  }

  String variantLabel(ProductVariant variant) {
    if (variant.options.isEmpty) return 'Default';
    return variant.options.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' • ');
  }

  ButtonStyle get actionButtonStyle {
    return OutlinedButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: const Size(40, 36),
      visualDensity: VisualDensity.compact,
      side: const BorderSide(color: AppColors.black, width: 0.4),
      shape: const RoundedRectangleBorder(borderRadius: kRadiusSmall),
    );
  }
}
