import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/schema/order_models.dart';
import '../../data/repositories/orders_repository.dart';
import '../../data/service_locator.dart';
import '../common/app_styles.dart';
import '../theme/app_colors.dart';
import '../utils/table_exporter.dart';

class FinancialLedgerView extends StatefulWidget {
  const FinancialLedgerView({super.key});

  @override
  State<FinancialLedgerView> createState() => _FinancialLedgerViewState();
}

class _FinancialLedgerViewState extends State<FinancialLedgerView> {
  final OrdersRepository _ordersRepository = ServiceLocator.instance.ordersRepository;
  final TextEditingController _searchController = TextEditingController();

  List<OrderDocument> _orders = const <OrderDocument>[];
  _LedgerTimelinePreset _timelinePreset = _LedgerTimelinePreset.last30Days;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final List<OrderDocument> orders = await _ordersRepository.fetchOrders();
    if (!mounted) return;
    setState(() => _orders = orders);
  }

  @override
  Widget build(BuildContext context) {
    final List<_LedgerRecord> records = _ledgerRecords;
    final DateTimeRange activeRange = _activeRange(records);
    final List<_LedgerRecord> filtered = _filteredRecords(records, activeRange);

    final num totalCollected = filtered
        .where((entry) => entry.isIncoming)
        .fold<num>(0, (num sum, _LedgerRecord entry) => sum + entry.amount);
    final num totalPending = filtered
        .where((entry) => !entry.isIncoming)
        .fold<num>(0, (num sum, _LedgerRecord entry) => sum + entry.amount);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
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
                      'Financial Ledger',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search, filter, and inspect payment movements by order',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _summaryCards(
            totalCollected: totalCollected,
            totalPending: totalPending,
            totalRecords: filtered.length,
          ),
          const SizedBox(height: 20),
          _filterBar(activeRange, filtered),
          const SizedBox(height: 20),
          _ledgerTable(filtered),
        ],
      ),
    );
  }

  Widget _summaryCards({
    required num totalCollected,
    required num totalPending,
    required int totalRecords,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int columns = width >= 1100
            ? 3
            : width >= 680
                ? 2
                : 1;

        // Adaptive child aspect ratio to prevent rigid vertical content clipping inside summary blocks
        final double childAspectRatio = width >= 1100
            ? 2.2
            : width >= 680
                ? 2.5
                : 3.4;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _MetricCard(
              title: 'Collected Amount',
              value: 'Rs. ${totalCollected.toStringAsFixed(0)}',
              subtitle: 'Verified and received entries',
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFECFDF5),
            ),
            _MetricCard(
              title: 'Pending / Outgoing',
              value: 'Rs. ${totalPending.toStringAsFixed(0)}',
              subtitle: 'Pending COD / unresolved settlements',
              valueColor: AppColors.pendingText,
              icon: Icons.hourglass_empty_rounded,
              iconColor: AppColors.pendingText,
              iconBgColor: AppColors.pendingBg,
            ),
            _MetricCard(
              title: 'Ledger Rows',
              value: '$totalRecords',
              subtitle: 'Rows after current filters',
              icon: Icons.format_list_bulleted_rounded,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primaryLight,
            ),
          ],
        );
      },
    );
  }

  Widget _filterBar(DateTimeRange activeRange, List<_LedgerRecord> filteredRows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: kRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stack = constraints.maxWidth < 920;
          final Widget search = SizedBox(
            width: stack ? double.infinity : 280,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
              decoration: inputDecoration('Search by Order Number').copyWith(
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          );

          final Widget timeline = SizedBox(
            width: stack ? double.infinity : 220,
            child: DropdownButtonFormField<_LedgerTimelinePreset>(
              initialValue: _timelinePreset,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColors.offWhite,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: kRadiusSmall,
                  borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: kRadiusSmall,
                  borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1.2),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: kRadiusSmall,
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              items: _LedgerTimelinePreset.values
                  .map(
                    (preset) => DropdownMenuItem<_LedgerTimelinePreset>(
                      value: preset,
                      child: Text(
                        preset.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (_LedgerTimelinePreset? value) async {
                if (value == null) return;
                if (value == _LedgerTimelinePreset.custom) {
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020, 1, 1),
                    lastDate: DateTime.now(),
                    initialDateRange: _customRange,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked == null) return;
                  setState(() {
                    _timelinePreset = value;
                    _customRange = picked;
                  });
                  return;
                }
                setState(() => _timelinePreset = value);
              },
            ),
          );

          final Widget customAction = _timelinePreset == _LedgerTimelinePreset.custom
              ? OutlinedButton.icon(
                  onPressed: () async {
                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020, 1, 1),
                      lastDate: DateTime.now(),
                      initialDateRange: _customRange,
                    );
                    if (picked == null) return;
                    setState(() => _customRange = picked);
                  },
                  icon: const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
                  label: Text(
                    'Change Date Range',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                )
              : const SizedBox.shrink();

          final Widget exportAction = PopupMenuButton<ExportFormat>(
            tooltip: 'Export',
            enabled: filteredRows.isNotEmpty,
            onSelected: (ExportFormat format) => _exportLedger(format, filteredRows),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (BuildContext context) => ExportFormat.values
                .map(
                  (format) => PopupMenuItem<ExportFormat>(
                    value: format,
                    child: Text(
                      'Export as ${format.label}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border, width: 1.2),
                borderRadius: kRadiusSmall,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download_rounded, size: 16, color: AppColors.textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Export',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          );

          final String label = '${_fmtDate(activeRange.start)} → ${_fmtDate(activeRange.end)}';

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                search,
                const SizedBox(height: 12),
                timeline,
                if (_timelinePreset == _LedgerTimelinePreset.custom) ...[
                  const SizedBox(height: 12),
                  customAction,
                ],
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: exportAction),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          }

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              search,
              timeline,
              if (_timelinePreset == _LedgerTimelinePreset.custom) customAction,
              exportAction,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ledgerTable(List<_LedgerRecord> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: kRadiusMedium,
      ),
      child: ClipRRect(
        borderRadius: kRadiusMedium,
        child: rows.isEmpty
            ? SizedBox(
                height: 180,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'No ledger records found for the selected filters.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
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
                              'Order #',
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
                              'Type',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Method',
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
                              'Balance',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Note',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                        rows: rows.map((entry) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  _fmtDate(entry.recordedAt),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  entry.orderId.length > 8
                                      ? '#${entry.orderId.substring(0, 8)}'
                                      : '#${entry.orderId}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    entry.customerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  entry.typeLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.offWhite,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    entry.methodLabel,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: entry.isIncoming
                                        ? AppColors.deliveredBg
                                        : AppColors.pendingBg,
                                  ),
                                  child: Text(
                                    entry.statusLabel,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: entry.isIncoming
                                          ? AppColors.deliveredText
                                          : AppColors.pendingText,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'Rs. ${entry.amount.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: entry.isIncoming
                                        ? const Color(0xFF16A34A)
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  'Rs. ${entry.balance.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: entry.balance > 0
                                        ? AppColors.pendingText
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 180),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: entry.note.contains('Receipt')
                                          ? AppColors.primaryLight
                                          : AppColors.offWhite,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      entry.note,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: entry.note.contains('Receipt')
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  DateTimeRange _activeRange(List<_LedgerRecord> records) {
    if (_timelinePreset == _LedgerTimelinePreset.custom && _customRange != null) {
      return _customRange!;
    }

    final DateTime now = DateTime.now();
    switch (_timelinePreset) {
      case _LedgerTimelinePreset.last7Days:
        return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
      case _LedgerTimelinePreset.last30Days:
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
      case _LedgerTimelinePreset.last90Days:
        return DateTimeRange(start: now.subtract(const Duration(days: 90)), end: now);
      case _LedgerTimelinePreset.last180Days:
        return DateTimeRange(start: now.subtract(const Duration(days: 180)), end: now);
      case _LedgerTimelinePreset.custom:
        if (records.isEmpty) {
          return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
        }
        final List<DateTime> dates = records.map((e) => e.recordedAt).toList()..sort();
        return DateTimeRange(start: dates.first, end: now);
    }
  }

  List<_LedgerRecord> _filteredRecords(
    List<_LedgerRecord> all,
    DateTimeRange range,
  ) {
    final String query = _searchController.text.trim().toLowerCase();

    final List<_LedgerRecord> result = all.where((entry) {
      final bool matchesDate =
          !entry.recordedAt.isBefore(range.start) && !entry.recordedAt.isAfter(range.end);
      final bool matchesQuery =
          query.isEmpty || entry.orderId.toLowerCase().contains(query);
      return matchesDate && matchesQuery;
    }).toList();

    result.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return result;
  }

  Future<void> _exportLedger(ExportFormat format, List<_LedgerRecord> rows) async {
    final List<List<String>> exportRows = rows
        .map(
          (row) => <String>[
            _fmtDate(row.recordedAt),
            row.orderId,
            row.customerName,
            row.typeLabel,
            row.methodLabel,
            row.statusLabel,
            row.amount.toStringAsFixed(0),
            row.balance.toStringAsFixed(0),
            row.note,
          ],
        )
        .toList();

    final String dateStamp = DateTime.now().toIso8601String().split('T').first;
    final bool downloaded = await exportTabularData(
      baseFileName: 'financial_ledger_$dateStamp',
      headers: const <String>[
        'Date',
        'Order #',
        'Customer',
        'Type',
        'Method',
        'Status',
        'Amount',
        'Balance',
        'Note',
      ],
      rows: exportRows,
      format: format,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: downloaded ? AppColors.black : Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        content: Text(
          downloaded
              ? '${format.label} export downloaded.'
              : '${format.label} export is available on web builds.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }

  List<_LedgerRecord> get _ledgerRecords {
    final List<_LedgerRecord> rows = <_LedgerRecord>[];

    for (final OrderDocument order in _orders) {
      final num totalAmount = order.financials['totalAmount'] as num? ?? 0;
      final num balanceDue = order.paymentSummary.balanceDue;

      if (order.paymentLedger.isEmpty) {
        rows.add(
          _LedgerRecord(
            orderId: order.id,
            customerName: order.customerInfo.name,
            recordedAt: order.shipping.timeline.createdAt,
            typeLabel: 'Pending Settlement',
            methodLabel: _orderPaymentMethodLabel(order.payment.method),
            statusLabel: _collectionStatusLabel(order.paymentSummary.paymentStatus),
            amount: balanceDue > 0 ? balanceDue : totalAmount,
            balance: balanceDue,
            isIncoming: false,
            note: 'No payment entries logged yet',
          ),
        );
      } else {
        for (final OrderPaymentLedgerEntry entry in order.paymentLedger) {
          rows.add(
            _LedgerRecord(
              orderId: order.id,
              customerName: order.customerInfo.name,
              recordedAt: entry.recordedAt ?? order.shipping.timeline.createdAt,
              typeLabel: entry.status == OrderLedgerPaymentStatus.verified
                  ? 'Collected Payment'
                  : 'Payment Attempt',
              methodLabel: _ledgerMethodLabel(entry.method),
              statusLabel: _ledgerStatusLabel(entry.status),
              amount: entry.amount,
              balance: order.paymentSummary.balanceDue,
              isIncoming: entry.status == OrderLedgerPaymentStatus.verified,
              note: (entry.proofUrl?.isNotEmpty ?? false)
                  ? 'Receipt attached'
                  : 'No receipt',
            ),
          );
        }
      }
    }

    return rows;
  }

  String _fmtDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _orderPaymentMethodLabel(PaymentMethod method) {
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

  String _ledgerMethodLabel(OrderLedgerPaymentMethod method) {
    switch (method) {
      case OrderLedgerPaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case OrderLedgerPaymentMethod.codCash:
        return 'COD Cash';
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

  String _collectionStatusLabel(OrderPaymentCollectionStatus status) {
    switch (status) {
      case OrderPaymentCollectionStatus.unpaid:
        return 'Unpaid';
      case OrderPaymentCollectionStatus.partiallyPaid:
        return 'Partial';
      case OrderPaymentCollectionStatus.fullyPaid:
        return 'Paid';
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.valueColor = AppColors.textPrimary,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: kRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21,
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRecord {
  const _LedgerRecord({
    required this.orderId,
    required this.customerName,
    required this.recordedAt,
    required this.typeLabel,
    required this.methodLabel,
    required this.statusLabel,
    required this.amount,
    required this.balance,
    required this.isIncoming,
    required this.note,
  });

  final String orderId;
  final String customerName;
  final DateTime recordedAt;
  final String typeLabel;
  final String methodLabel;
  final String statusLabel;
  final num amount;
  final num balance;
  final bool isIncoming;
  final String note;
}

enum _LedgerTimelinePreset {
  last7Days('Last 7 days'),
  last30Days('Last 30 days'),
  last90Days('Last 90 days'),
  last180Days('Last 180 days'),
  custom('Custom range');

  const _LedgerTimelinePreset(this.label);
  final String label;
}
