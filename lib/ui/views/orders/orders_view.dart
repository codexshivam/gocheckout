import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/schema/order_models.dart';
import '../../common/app_styles.dart';
import '../../theme/app_colors.dart';
import '../../utils/table_exporter.dart';
import 'orders_dialogs.dart';
import 'orders_logic.dart';
import 'orders_widgets.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> with OrdersLogic {
  Future<void> _exportOrders(
    ExportFormat format,
    List<OrderDocument> rows,
  ) async {
    final List<List<String>> exportRows = rows.map((order) {
      final num total = order.financials['totalAmount'] as num? ?? 0;
      return <String>[
        fmtDate(order.shipping.timeline.createdAt),
        order.id,
        order.customerInfo.name,
        order.customerInfo.phone,
        itemsSummary(order.items),
        paymentMethodLabel(order.payment.method),
        shippingStatusLabel(order.shipping.status),
        total.toStringAsFixed(0),
      ];
    }).toList();

    final bool ok = await exportTabularData(
      baseFileName:
          'orders_${DateTime.now().toIso8601String().split('T').first}',
      headers: const <String>[
        'Date',
        'Order ID',
        'Customer',
        'Phone',
        'Items',
        'Payment',
        'Status',
        'Amount (NPR)',
      ],
      rows: exportRows,
      format: format,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${format.label} export downloaded.'
              : '${format.label} export is available on web builds.',
        ),
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    openCreate();
    await _showOrderFormDialog();
  }

  Future<void> _openEditDialog(OrderDocument order) async {
    openEdit(order);
    await _showOrderFormDialog();
  }

  Future<void> _showOrderFormDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final NavigatorState dialogNavigator = Navigator.of(dialogContext);
        final Size size = MediaQuery.of(dialogContext).size;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              backgroundColor: AppColors.offWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
                vertical: size.height * 0.06,
              ),
              child: SizedBox(
                width: size.width * 0.84,
                height: size.height * 0.88,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Block
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                editingOrderId == null
                                    ? 'Create Store Order'
                                    : 'Edit Store Order',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                editingOrderId == null
                                    ? 'Register a new verified sale transaction manually'
                                    : 'Modify existing billing, customer, or shipping options',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Discard and close',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.offWhite,
                              foregroundColor: AppColors.textPrimary,
                            ),
                            onPressed: () {
                              cancelInlineForm();
                              dialogNavigator.pop();
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OrdersInlineFormFields(
                              customerNameController: customerNameController,
                              phoneController: phoneController,
                              addressController: addressController,
                              districtController: districtController,
                              discountController: discountController,
                              products: products,
                              draftItems: draftItems,
                              selectedPaymentMethod: selectedPaymentMethod,
                              selectedShippingStatus: selectedShippingStatus,
                              subtotal: draftSubtotal,
                              discount: draftDiscount,
                              total: draftGrandTotal,
                              variantLabel: variantLabel,
                              onPaymentMethodChanged: (PaymentMethod method) {
                                setDialogState(
                                  () => selectedPaymentMethod = method,
                                );
                              },
                              onShippingStatusChanged: (ShippingStatus status) {
                                setDialogState(
                                  () => selectedShippingStatus = status,
                                );
                              },
                              onAddItem: () {
                                setDialogState(() => addDraftItem());
                              },
                              onRemoveItem: (int index) {
                                removeDraftItem(index);
                                setDialogState(() {});
                              },
                              onProductChanged: (int index, String? productId) {
                                if (index < 0 || index >= draftItems.length) {
                                  return;
                                }
                                final product = productById(productId);
                                setDialogState(() {
                                  draftItems[index].selectedProductId =
                                      productId;
                                  draftItems[index].selectedVariantId =
                                      product?.variants.isNotEmpty == true
                                      ? product!.variants.first.variantId
                                      : null;
                                });
                              },
                              onVariantChanged: (int index, String? variantId) {
                                if (index < 0 || index >= draftItems.length) {
                                  return;
                                }
                                setDialogState(
                                  () => draftItems[index].selectedVariantId =
                                      variantId,
                                );
                              },
                              onItemsChanged: () => setDialogState(() {}),
                            ),
                            const SizedBox(height: 24),
                            // Save & Cancel controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    side: const BorderSide(
                                      color: AppColors.border,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                  ),
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                          cancelInlineForm();
                                          dialogNavigator.pop();
                                        },
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          await saveInlineForm();
                                          if (!mounted) return;
                                          if (!showInlineOrderForm) {
                                            dialogNavigator.pop();
                                          } else {
                                            setDialogState(() {});
                                          }
                                        },
                                  icon: const Icon(
                                    Icons.bookmark_added_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isSaving
                                        ? 'Saving Details...'
                                        : editingOrderId == null
                                        ? 'Create & Register'
                                        : 'Save Updates',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (showInlineOrderForm) {
      cancelInlineForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<OrderDocument> rows = filteredOrders;

    Widget filters() {
      final List<String> options = <String>[
        'All',
        'Created',
        'Shipped',
        'Delivered',
        'RTO',
      ];
      return Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          border: Border.all(color: AppColors.border, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: options.map((option) {
            final bool isSelected = statusFilter == option;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => statusFilter = option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    option,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Unified Header Block
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Orders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track transactions, customer delivery timelines, and order financials',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search, filters switcher, and actions responsive layout
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double screenWidth = constraints.maxWidth;

              final Widget searchField = SizedBox(
                height: 44,
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  decoration: inputDecoration('Search by ID, name or phone')
                      .copyWith(
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                ),
              );

              final Widget exportButton = PopupMenuButton<ExportFormat>(
                tooltip: 'Export',
                onSelected: (ExportFormat format) =>
                    _exportOrders(format, rows),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (BuildContext context) => ExportFormat.values
                    .map(
                      (format) => PopupMenuItem<ExportFormat>(
                        value: format,
                        child: Text(
                          'Export as ${format.label}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.border, width: 1.2),
                    borderRadius: kRadiusSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Export',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              final Widget createButton = SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 0,
                  ),
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Create Order',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              );

              // 📱 Mobile Stack (width < 600) — Multirow blocks to secure layouts
              if (screenWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: filters()),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: exportButton),
                        const SizedBox(width: 12),
                        Expanded(child: createButton),
                      ],
                    ),
                  ],
                );
              }

              // 📟 Tablet Stack (600 <= width < 960) — Double row dynamic layouts
              if (screenWidth < 960) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 300, child: filters()),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            exportButton,
                            const SizedBox(width: 12),
                            createButton,
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              }

              // 🖥️ Desktop Row (width >= 960) — Full inline sleek layout
              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 12),
                  SizedBox(width: 320, child: filters()),
                  const SizedBox(width: 12),
                  exportButton,
                  const SizedBox(width: 12),
                  createButton,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border, width: 1.2),
                borderRadius: kRadiusMedium,
              ),
              child: ClipRRect(
                borderRadius: kRadiusMedium,
                child: OrdersTable(
                  orders: rows,
                  fmtDate: fmtDate,
                  itemsSummary: itemsSummary,
                  paymentMethodLabel: paymentMethodLabel,
                  shippingStatusLabel: shippingStatusLabel,
                  onView: openDetails,
                  onEdit: _openEditDialog,
                  onDelete: confirmDeleteOrder,
                  actionButtonStyle: actionButtonStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
