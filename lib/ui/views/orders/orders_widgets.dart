import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/schema/order_models.dart';
import '../../theme/app_colors.dart';

class OrdersTable extends StatelessWidget {
  const OrdersTable({
    super.key,
    required this.orders,
    required this.fmtDate,
    required this.itemsSummary,
    required this.paymentMethodLabel,
    required this.shippingStatusLabel,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.actionButtonStyle,
  });

  final List<OrderDocument> orders;
  final String Function(DateTime) fmtDate;
  final String Function(List<Map<String, dynamic>>) itemsSummary;
  final String Function(PaymentMethod) paymentMethodLabel;
  final String Function(ShippingStatus) shippingStatusLabel;
  final ValueChanged<OrderDocument> onView;
  final ValueChanged<OrderDocument> onEdit;
  final ValueChanged<OrderDocument> onDelete;
  final ButtonStyle actionButtonStyle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowHeight: 46,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 52,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.8),
                      width: 1,
                    ),
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        'Date',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Order ID',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Customer',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Items',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Amount',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Payment',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Collection',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Action',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                  rows: orders.asMap().entries.map((MapEntry<int, OrderDocument> entry) {
                    final int rowIndex = entry.key;
                    final OrderDocument order = entry.value;
                    final String customer =
                        '${order.customerInfo.name} • ${order.customerInfo.phone}';
                    final String total =
                        'NPR ${(order.financials['totalAmount'] as num? ?? 0).toStringAsFixed(0)}';
                    final String collectionStatus = _paymentStatusLabel(
                      order.paymentSummary.paymentStatus,
                    );

                    return DataRow(
                      color: WidgetStateProperty.all(
                        rowIndex.isEven ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
                      ),
                      cells: [
                        DataCell(Text(fmtDate(order.shipping.timeline.createdAt))),
                        DataCell(
                          Text(
                            order.id,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(customer, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(itemsSummary(order.items), overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        DataCell(
                          Text(
                            total,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(Text(paymentMethodLabel(order.payment.method))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: order.paymentSummary.paymentStatus == OrderPaymentCollectionStatus.fullyPaid
                                  ? AppColors.deliveredBg
                                  : order.paymentSummary.paymentStatus == OrderPaymentCollectionStatus.partiallyPaid
                                      ? Colors.amber.withValues(alpha: 0.08)
                                      : AppColors.rtoBg,
                            ),
                            child: Text(
                              collectionStatus,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: order.paymentSummary.paymentStatus == OrderPaymentCollectionStatus.fullyPaid
                                    ? AppColors.deliveredText
                                    : order.paymentSummary.paymentStatus == OrderPaymentCollectionStatus.partiallyPaid
                                        ? Colors.amber[800]
                                        : AppColors.rtoText,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          OrderStatusPill(status: shippingStatusLabel(order.shipping.status)),
                        ),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: Row(
                              children: [
                                _ActionButton(
                                  icon: Icons.visibility_outlined,
                                  iconColor: AppColors.primary,
                                  bgColor: AppColors.primary.withValues(alpha: 0.08),
                                  tooltip: 'View details',
                                  onTap: () => onView(order),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  icon: Icons.edit_rounded,
                                  iconColor: AppColors.accentBlue,
                                  bgColor: AppColors.accentBlueLight,
                                  tooltip: 'Edit order',
                                  onTap: () => onEdit(order),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  icon: Icons.delete_outline_rounded,
                                  iconColor: AppColors.rtoText,
                                  bgColor: AppColors.rtoBg,
                                  tooltip: 'Delete order',
                                  onTap: () => onDelete(order),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrderDetailsView extends StatefulWidget {
  const OrderDetailsView({
    super.key,
    required this.order,
    required this.paymentMethodLabel,
    required this.shippingStatusLabel,
    required this.fmtDate,
  });

  final OrderDocument order;
  final String Function(PaymentMethod) paymentMethodLabel;
  final String Function(ShippingStatus) shippingStatusLabel;
  final String Function(DateTime) fmtDate;

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  late List<OrderPaymentLedgerEntry> _ledger;
  late OrderPaymentSummary _summary;

  @override
  void initState() {
    super.initState();
    _ledger = List<OrderPaymentLedgerEntry>.from(widget.order.paymentLedger);
    _summary = widget.order.paymentSummary;
  }

  @override
  Widget build(BuildContext context) {
    final OrderDocument order = widget.order;
    final num totalAmount = order.financials['totalAmount'] as num? ?? 0;
    final num subtotal = order.financials['subtotal'] as num? ?? totalAmount;
    final num discountAmount = order.financials['discountAmount'] as num? ?? 0;
    final String originLabel = order.origin == OrderOrigin.checkoutLink
        ? 'Checkout Link'
        : 'Manual';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Order #${order.id}',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        shape: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row Layout for summary and delivery blocks
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double width = constraints.maxWidth;
                if (width < 800) {
                  return Column(
                    children: [
                      _buildSummaryCard(order, totalAmount, subtotal, discountAmount, originLabel),
                      const SizedBox(height: 20),
                      _buildDeliveryCard(order),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildSummaryCard(order, totalAmount, subtotal, discountAmount, originLabel),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildDeliveryCard(order),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _OrderLedgerPanel(
              totalOrderValue: totalAmount,
              summary: _summary,
              ledger: _ledger,
              onLogPayment: _openLogPaymentDialog,
            ),
            const SizedBox(height: 20),
            _DetailsPanel(
              title: 'Purchased Items',
              icon: Icons.shopping_bag_outlined,
              child: Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.offWhite),
                    headingTextStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                    dataTextStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    columns: const [
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('Variant')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('Unit Price')),
                      DataColumn(label: Text('Line Total')),
                    ],
                    rows: order.items.map((Map<String, dynamic> item) {
                      final int quantity = item['quantity'] as int? ?? 0;
                      final num unitPrice = item['unitPrice'] as num? ?? 0;
                      final num lineTotal = quantity * unitPrice;
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item['productName']?.toString() ?? 'Item',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                            ),
                          ),
                          DataCell(Text(item['variantName']?.toString() ?? 'Default')),
                          DataCell(Text('$quantity')),
                          DataCell(Text('NPR ${unitPrice.toStringAsFixed(0)}')),
                          DataCell(
                            Text(
                              'NPR ${lineTotal.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    OrderDocument order,
    num totalAmount,
    num subtotal,
    num discountAmount,
    String originLabel,
  ) {
    return _DetailsPanel(
      title: 'Order Overview',
      icon: Icons.analytics_outlined,
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        children: [
          _buildSummaryMetaTile('Customer Name', order.customerInfo.name),
          _buildSummaryMetaTile('Phone Number', order.customerInfo.phone),
          _buildSummaryMetaTile('Creation Date', widget.fmtDate(order.shipping.timeline.createdAt)),
          _buildSummaryMetaTile('Fulfillment Method', widget.paymentMethodLabel(order.payment.method)),
          _buildSummaryMetaTile('Origin Source', originLabel),
          _buildSummaryMetaTile(
            'Order Subtotal',
            'NPR ${subtotal.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          _buildSummaryMetaTile(
            'Promotional Discount',
            'NPR ${discountAmount.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(color: AppColors.rtoText, fontWeight: FontWeight.w700),
          ),
          _buildSummaryMetaTile(
            'Total Paid Value',
            'NPR ${totalAmount.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(color: AppColors.deliveredText, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetaTile(String label, String value, {TextStyle? style}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style ??
              GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
        ),
      ],
    );
  }

  Widget _buildDeliveryCard(OrderDocument order) {
    return _DetailsPanel(
      title: 'Delivery Details',
      icon: Icons.pin_drop_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHIPPING ADDRESS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order.customerInfo.address,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.customerInfo.district,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SHIPPING STATUS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          OrderStatusPill(status: widget.shippingStatusLabel(order.shipping.status)),
        ],
      ),
    );
  }

  Future<void> _openLogPaymentDialog() async {
    final _LogPaymentResult? result = await showDialog<_LogPaymentResult>(
      context: context,
      builder: (BuildContext context) => const _LogPaymentDialog(),
    );

    if (result == null) return;

    final num totalOrderValue =
        widget.order.financials['totalAmount'] as num? ?? 0;
    final num newTotalPaid = _summary.totalPaid + result.amount;
    final num newBalanceDue = (totalOrderValue - newTotalPaid).clamp(0, totalOrderValue);

    final OrderPaymentCollectionStatus status;
    if (newBalanceDue <= 0) {
      status = OrderPaymentCollectionStatus.fullyPaid;
    } else if (newTotalPaid > 0) {
      status = OrderPaymentCollectionStatus.partiallyPaid;
    } else {
      status = OrderPaymentCollectionStatus.unpaid;
    }

    setState(() {
      _ledger = <OrderPaymentLedgerEntry>[
        OrderPaymentLedgerEntry(
          method: result.method,
          amount: result.amount,
          status: OrderLedgerPaymentStatus.verified,
          proofUrl: result.receiptProvided ? 'dummy-receipt' : null,
          recordedAt: DateTime.now(),
        ),
        ..._ledger,
      ];
      _summary = OrderPaymentSummary(
        totalPaid: newTotalPaid,
        balanceDue: newBalanceDue,
        paymentStatus: status,
      );
    });
  }
}

class _OrderLedgerPanel extends StatelessWidget {
  const _OrderLedgerPanel({
    required this.totalOrderValue,
    required this.summary,
    required this.ledger,
    required this.onLogPayment,
  });

  final num totalOrderValue;
  final OrderPaymentSummary summary;
  final List<OrderPaymentLedgerEntry> ledger;
  final VoidCallback onLogPayment;

  @override
  Widget build(BuildContext context) {
    return _DetailsPanel(
      title: 'Transaction & Payment Ledger',
      icon: Icons.receipt_long_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [
                    _LedgerMetricCard(
                      label: 'Total Order Value',
                      value: 'Rs. ${totalOrderValue.toStringAsFixed(0)}',
                      icon: Icons.payments_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    _LedgerMetricCard(
                      label: 'Total Paid Amount',
                      value: 'Rs. ${summary.totalPaid.toStringAsFixed(0)}',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.deliveredText,
                    ),
                    const SizedBox(height: 12),
                    _LedgerMetricCard(
                      label: 'Outstanding Balance',
                      value: 'Rs. ${summary.balanceDue.toStringAsFixed(0)}',
                      icon: Icons.info_outline_rounded,
                      color: summary.balanceDue > 0 ? AppColors.rtoText : AppColors.textSecondary,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _LedgerMetricCard(
                      label: 'Total Order Value',
                      value: 'Rs. ${totalOrderValue.toStringAsFixed(0)}',
                      icon: Icons.payments_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LedgerMetricCard(
                      label: 'Total Paid Amount',
                      value: 'Rs. ${summary.totalPaid.toStringAsFixed(0)}',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.deliveredText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LedgerMetricCard(
                      label: 'Outstanding Balance',
                      value: 'Rs. ${summary.balanceDue.toStringAsFixed(0)}',
                      icon: Icons.info_outline_rounded,
                      color: summary.balanceDue > 0 ? AppColors.rtoText : AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: onLogPayment,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(
                'Log Verified Payment',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (ledger.isEmpty)
            Text(
              'No verified payments registered inside this order.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Column(
              children: ledger.map((OrderPaymentLedgerEntry entry) {
                final String dateLabel = entry.recordedAt == null
                    ? '-'
                    : '${entry.recordedAt!.day}/${entry.recordedAt!.month}/${entry.recordedAt!.year}';
                return _LedgerTimelineItem(
                  dateLabel: dateLabel,
                  methodLabel: _ledgerMethodLabel(entry.method),
                  amountLabel: 'Rs. ${entry.amount.toStringAsFixed(0)}',
                  statusLabel: _ledgerStatusLabel(entry.status),
                  showReceiptLink:
                      entry.method == OrderLedgerPaymentMethod.bankTransfer &&
                      entry.proofUrl != null &&
                      entry.proofUrl!.isNotEmpty,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _LedgerMetricCard extends StatelessWidget {
  const _LedgerMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerTimelineItem extends StatelessWidget {
  const _LedgerTimelineItem({
    required this.dateLabel,
    required this.methodLabel,
    required this.amountLabel,
    required this.statusLabel,
    required this.showReceiptLink,
  });

  final String dateLabel;
  final String methodLabel;
  final String amountLabel;
  final String statusLabel;
  final bool showReceiptLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildItemSpan('DATE', dateLabel),
          _buildItemSpan('METHOD', methodLabel),
          _buildItemSpan('AMOUNT', amountLabel, valueColor: AppColors.deliveredText),
          _buildItemSpan('STATUS', statusLabel, valueColor: AppColors.accentBlue),
          if (showReceiptLink)
            GestureDetector(
              onTap: () => _openDummyReceiptDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attachment_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'View Proof',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemSpan(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _openDummyReceiptDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Transfer Receipt Attachment',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: Container(
            width: 380,
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              border: Border.all(color: AppColors.border, width: 1.2),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image_outlined, size: 36, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  'Bank Transfer Receipt Preview Image',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Dismiss View',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LogPaymentDialog extends StatefulWidget {
  const _LogPaymentDialog();

  @override
  State<_LogPaymentDialog> createState() => _LogPaymentDialogState();
}

class _LogPaymentDialogState extends State<_LogPaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  OrderLedgerPaymentMethod _method = OrderLedgerPaymentMethod.bankTransfer;
  bool _receiptProvided = false;

  bool get _requiresReceipt =>
      _method == OrderLedgerPaymentMethod.bankTransfer ||
      _method == OrderLedgerPaymentMethod.esewa ||
      _method == OrderLedgerPaymentMethod.khalti;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Log Verify Payment',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<OrderLedgerPaymentMethod>(
              initialValue: _method,
              decoration: _inputDecoration('Payment Method'),
              items: OrderLedgerPaymentMethod.values
                  .map(
                    (OrderLedgerPaymentMethod m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                        _ledgerMethodLabel(m),
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (OrderLedgerPaymentMethod? method) {
                if (method == null) return;
                setState(() => _method = method);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
              decoration: _inputDecoration('Amount Paid (NPR)'),
            ),
            if (_requiresReceipt) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _receiptProvided = true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    border: Border.all(color: AppColors.border, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _receiptProvided ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                        color: _receiptProvided ? AppColors.deliveredText : AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _receiptProvided
                            ? 'Fulfillment Proof Registered'
                            : 'Upload Attachment Screenshot',
                        style: GoogleFonts.plusJakartaSans(
                          color: _receiptProvided ? AppColors.deliveredText : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
          onPressed: _save,
          child: Text(
            'Save Payment',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  void _save() {
    final num amount = num.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount paid.')),
      );
      return;
    }

    if (_requiresReceipt && !_receiptProvided) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a receipt/screenshot.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _LogPaymentResult(
        method: _method,
        amount: amount,
        receiptProvided: _receiptProvided,
      ),
    );
  }
}

class _LogPaymentResult {
  const _LogPaymentResult({
    required this.method,
    required this.amount,
    required this.receiptProvided,
  });

  final OrderLedgerPaymentMethod method;
  final num amount;
  final bool receiptProvided;
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
            ],
          ),
          const Divider(height: 28, thickness: 1),
          child,
        ],
      ),
    );
  }
}

class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color badgeBg;
    final Color labelColor;

    switch (status) {
      case 'Created':
        badgeBg = Colors.amber.withValues(alpha: 0.08);
        labelColor = Colors.amber[800]!;
        break;
      case 'Shipped':
        badgeBg = AppColors.accentBlueLight;
        labelColor = AppColors.accentBlue;
        break;
      case 'Delivered':
        badgeBg = AppColors.deliveredBg;
        labelColor = AppColors.deliveredText;
        break;
      case 'RTO':
        badgeBg = AppColors.rtoBg;
        labelColor = AppColors.rtoText;
        break;
      default:
        badgeBg = AppColors.offWhite;
        labelColor = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: badgeBg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: labelColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

String _paymentStatusLabel(OrderPaymentCollectionStatus status) {
  switch (status) {
    case OrderPaymentCollectionStatus.unpaid:
      return 'Unpaid';
    case OrderPaymentCollectionStatus.partiallyPaid:
      return 'Partially Paid';
    case OrderPaymentCollectionStatus.fullyPaid:
      return 'Fully Paid';
  }
}

String _ledgerMethodLabel(OrderLedgerPaymentMethod method) {
  switch (method) {
    case OrderLedgerPaymentMethod.bankTransfer:
      return 'Bank Transfer';
    case OrderLedgerPaymentMethod.codCash:
      return 'Cash';
    case OrderLedgerPaymentMethod.esewa:
      return 'eSewa';
    case OrderLedgerPaymentMethod.khalti:
      return 'Khalti';
  }
}

String _ledgerStatusLabel(OrderLedgerPaymentStatus status) {
  switch (status) {
    case OrderLedgerPaymentStatus.pending:
      return 'Pending';
    case OrderLedgerPaymentStatus.verified:
      return 'Verified';
    case OrderLedgerPaymentStatus.failed:
      return 'Failed';
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.plusJakartaSans(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    fillColor: AppColors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border, width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.black, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }
}
