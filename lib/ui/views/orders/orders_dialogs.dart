import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/schema/order_models.dart';
import '../../../data/models/schema/product_models.dart';
import '../../common/app_styles.dart';
import '../../theme/app_colors.dart';
import 'orders_logic.dart';

class OrdersInlineFormFields extends StatelessWidget {
  const OrdersInlineFormFields({
    super.key,
    required this.customerNameController,
    required this.phoneController,
    required this.addressController,
    required this.districtController,
    required this.discountController,
    required this.products,
    required this.draftItems,
    required this.selectedPaymentMethod,
    required this.selectedShippingStatus,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.variantLabel,
    required this.onPaymentMethodChanged,
    required this.onShippingStatusChanged,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onProductChanged,
    required this.onVariantChanged,
    required this.onItemsChanged,
  });

  final TextEditingController customerNameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController districtController;
  final TextEditingController discountController;
  final List<Product> products;
  final List<OrderDraftItem> draftItems;
  final PaymentMethod selectedPaymentMethod;
  final ShippingStatus selectedShippingStatus;
  final num subtotal;
  final num discount;
  final num total;
  final String Function(ProductVariant variant) variantLabel;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final ValueChanged<ShippingStatus> onShippingStatusChanged;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;
  final void Function(int index, String? productId) onProductChanged;
  final void Function(int index, String? variantId) onVariantChanged;
  final VoidCallback onItemsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Customer details card
        _buildSectionCard(
          title: 'Customer Details',
          icon: Icons.person_outline_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width = constraints.maxWidth;
                  if (width < 600) {
                    return Column(
                      children: [
                        TextField(
                          controller: customerNameController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: inputDecoration('Customer Name', icon: const Icon(Icons.badge_outlined, size: 18)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: inputDecoration('Phone Number', icon: const Icon(Icons.phone_outlined, size: 18)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: districtController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: inputDecoration('District', icon: const Icon(Icons.map_outlined, size: 18)),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customerNameController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: inputDecoration('Customer Name', icon: const Icon(Icons.badge_outlined, size: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: inputDecoration('Phone Number', icon: const Icon(Icons.phone_outlined, size: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: districtController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: inputDecoration('District', icon: const Icon(Icons.map_outlined, size: 18)),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: inputDecoration('Full Delivery Address', icon: const Icon(Icons.pin_drop_outlined, size: 18)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section 2: Order items details
        _buildSectionCard(
          title: 'Order Items',
          icon: Icons.shopping_bag_outlined,
          action: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: onAddItem,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            label: Text(
              'Add Product',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (draftItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: Text(
                    'No items added to this order. Click "Add Product" to start.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: draftItems.length,
                  separatorBuilder: (context, index) => Divider(height: 20, thickness: 0.6, color: AppColors.border.withValues(alpha: 0.8)),
                  itemBuilder: (context, index) {
                    final OrderDraftItem item = draftItems[index];
                    final Product? selectedProduct = _findProduct(products, item.selectedProductId);
                    final List<ProductVariant> variants =
                        selectedProduct?.variants ?? const <ProductVariant>[];

                    return LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final double width = constraints.maxWidth;
                        if (width < 640) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                key: ValueKey<String>("product_${index}_${item.selectedProductId ?? 'none'}"),
                                initialValue: _validProductValue(products, item.selectedProductId),
                                decoration: inputDecoration('Select Product'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                dropdownColor: AppColors.white,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                                items: products
                                    .map(
                                      (Product product) => DropdownMenuItem<String>(
                                        value: product.id,
                                        child: Text(
                                          product.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: products.isEmpty
                                    ? null
                                    : (String? productId) {
                                        onProductChanged(index, productId);
                                        onItemsChanged();
                                      },
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                key: ValueKey<String>("variant_${index}_${item.selectedVariantId ?? 'none'}"),
                                initialValue: _validVariantValue(variants, item.selectedVariantId),
                                decoration: inputDecoration('Variant Option'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                dropdownColor: AppColors.white,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                                items: variants
                                    .map(
                                      (ProductVariant variant) => DropdownMenuItem<String>(
                                        value: variant.variantId,
                                        child: Text(
                                          variantLabel(variant),
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: variants.isEmpty
                                    ? null
                                    : (String? variantId) {
                                        onVariantChanged(index, variantId);
                                        onItemsChanged();
                                      },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: item.quantityController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => onItemsChanged(),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: inputDecoration('Quantity'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.rtoBg,
                                      foregroundColor: AppColors.rtoText,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.all(12),
                                    ),
                                    onPressed: draftItems.length <= 1 ? null : () => onRemoveItem(index),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                key: ValueKey<String>("product_${index}_${item.selectedProductId ?? 'none'}"),
                                initialValue: _validProductValue(products, item.selectedProductId),
                                decoration: inputDecoration('Select Product'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                dropdownColor: AppColors.white,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                                items: products
                                    .map(
                                      (Product product) => DropdownMenuItem<String>(
                                        value: product.id,
                                        child: Text(
                                          product.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: products.isEmpty
                                    ? null
                                    : (String? productId) {
                                        onProductChanged(index, productId);
                                        onItemsChanged();
                                      },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                key: ValueKey<String>("variant_${index}_${item.selectedVariantId ?? 'none'}"),
                                initialValue: _validVariantValue(variants, item.selectedVariantId),
                                decoration: inputDecoration('Variant Option'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                dropdownColor: AppColors.white,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                                items: variants
                                    .map(
                                      (ProductVariant variant) => DropdownMenuItem<String>(
                                        value: variant.variantId,
                                        child: Text(
                                          variantLabel(variant),
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: variants.isEmpty
                                    ? null
                                    : (String? variantId) {
                                        onVariantChanged(index, variantId);
                                        onItemsChanged();
                                      },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: item.quantityController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => onItemsChanged(),
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                decoration: inputDecoration('Quantity'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.rtoBg,
                                foregroundColor: AppColors.rtoText,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.all(12),
                              ),
                              onPressed: draftItems.length <= 1 ? null : () => onRemoveItem(index),
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section 3: Billing & fulfillment options
        _buildSectionCard(
          title: 'Billing & Fulfillment',
          icon: Icons.payments_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double width = constraints.maxWidth;
                  if (width < 600) {
                    return Column(
                      children: [
                        TextField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => onItemsChanged(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: inputDecoration('Flat Discount (NPR)', icon: const Icon(Icons.sell_outlined, size: 18)),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PaymentMethod>(
                          key: ValueKey<PaymentMethod>(selectedPaymentMethod),
                          initialValue: selectedPaymentMethod,
                          decoration: inputDecoration('Fulfillment Type'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          dropdownColor: AppColors.white,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                          items: PaymentMethod.values
                              .map(
                                (PaymentMethod method) => DropdownMenuItem<PaymentMethod>(
                                  value: method,
                                  child: Text(
                                    _paymentMethodText(method),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (PaymentMethod? method) {
                            if (method != null) onPaymentMethodChanged(method);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ShippingStatus>(
                          key: ValueKey<ShippingStatus>(selectedShippingStatus),
                          initialValue: selectedShippingStatus,
                          decoration: inputDecoration('Delivery Status'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          dropdownColor: AppColors.white,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                          items: ShippingStatus.values
                              .map(
                                (ShippingStatus status) => DropdownMenuItem<ShippingStatus>(
                                  value: status,
                                  child: Text(
                                    _shippingStatusText(status),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (ShippingStatus? status) {
                            if (status != null) onShippingStatusChanged(status);
                          },
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => onItemsChanged(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: inputDecoration('Flat Discount (NPR)', icon: const Icon(Icons.sell_outlined, size: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<PaymentMethod>(
                          key: ValueKey<PaymentMethod>(selectedPaymentMethod),
                          initialValue: selectedPaymentMethod,
                          decoration: inputDecoration('Fulfillment Type'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          dropdownColor: AppColors.white,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                          items: PaymentMethod.values
                              .map(
                                (PaymentMethod method) => DropdownMenuItem<PaymentMethod>(
                                  value: method,
                                  child: Text(
                                    _paymentMethodText(method),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (PaymentMethod? method) {
                            if (method != null) onPaymentMethodChanged(method);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ShippingStatus>(
                          key: ValueKey<ShippingStatus>(selectedShippingStatus),
                          initialValue: selectedShippingStatus,
                          decoration: inputDecoration('Delivery Status'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          dropdownColor: AppColors.white,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                          items: ShippingStatus.values
                              .map(
                                (ShippingStatus status) => DropdownMenuItem<ShippingStatus>(
                                  value: status,
                                  child: Text(
                                    _shippingStatusText(status),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (ShippingStatus? status) {
                            if (status != null) onShippingStatusChanged(status);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Invoice summary breakdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Column(
                  children: [
                    _buildInvoiceRow('ITEMS SUBTOTAL', 'NPR ${subtotal.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    _buildInvoiceRow('PROMOTIONAL DISCOUNT', '- NPR ${discount.toStringAsFixed(0)}', isDiscount: true),
                    Divider(height: 20, thickness: 0.6, color: AppColors.border.withValues(alpha: 0.8)),
                    _buildInvoiceRow(
                      'TOTAL GRAND VALUE',
                      'NPR ${total.toStringAsFixed(0)}',
                      isGrandTotal: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Widget? action,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: AppColors.black,
                ),
              ),
              if (action != null) ...[
                const Spacer(),
                action,
              ],
            ],
          ),
          Divider(height: 24, thickness: 0.6, color: AppColors.border.withValues(alpha: 0.8)),
          child,
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isDiscount = false, bool isGrandTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isGrandTotal ? 11 : 10,
            fontWeight: FontWeight.w800,
            color: isGrandTotal ? AppColors.black : AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isGrandTotal ? 15 : 12.5,
            fontWeight: isGrandTotal ? FontWeight.w800 : FontWeight.w700,
            color: isDiscount
                ? AppColors.rtoText
                : isGrandTotal
                    ? AppColors.deliveredText
                    : AppColors.black,
          ),
        ),
      ],
    );
  }

  Product? _findProduct(List<Product> products, String? productId) {
    if (productId == null) return null;
    for (final Product product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  String? _validProductValue(List<Product> products, String? productId) {
    if (productId == null) return null;
    for (final Product product in products) {
      if (product.id == productId) return productId;
    }
    return null;
  }

  String? _validVariantValue(List<ProductVariant> variants, String? variantId) {
    if (variantId == null) return null;
    for (final ProductVariant variant in variants) {
      if (variant.variantId == variantId) return variantId;
    }
    return null;
  }

  String _paymentMethodText(PaymentMethod method) {
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

  String _shippingStatusText(ShippingStatus status) {
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
}
