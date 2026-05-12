import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/schema/order_models.dart';
import '../../../data/models/schema/store_stats_models.dart';
import '../../../data/repositories/analytics_repository.dart';
import '../../../data/service_locator.dart';
import '../../utils/table_exporter.dart';
import '../../theme/app_colors.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticsRepository _repository = ServiceLocator.instance.analyticsRepository;

  StoreStatsDocument? _stats;
  List<OrderDocument> _recentOrders = const <OrderDocument>[];
  _TimelinePreset _timelinePreset = _TimelinePreset.last6Months;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final StoreStatsDocument stats = await _repository.fetchStoreStats(
      storeId: 'store_001',
    );
    final List<OrderDocument> recentOrders = await _repository.fetchRecentOrders();

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _recentOrders = recentOrders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final StoreStatsDocument? stats = _stats;
    final bool loading = stats == null;

    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    final StoreStatsDocument data = stats;
    final DateTimeRange activeRange = _activeDateRange(data.monthlyHistory);
    final List<StoreMonthlyHistoryItem> filteredMonths =
        _filterMonthlyHistory(data.monthlyHistory, activeRange);
    final List<OrderDocument> filteredOrders =
        _filterOrders(_recentOrders, activeRange);
    final _AnalyticsComputedMetrics metrics = _computeMetrics(
      base: data,
      filteredMonths: filteredMonths,
      filteredOrders: filteredOrders,
    );
    final List<MapEntry<String, int>> hotspotRows =
        _rtoHotspots(data, filteredOrders);

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
                  Icons.analytics_rounded,
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
                      'Analytics & Insights',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Performance intelligence for your store',
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
          _timelineFilterBar(data.monthlyHistory, activeRange),
          const SizedBox(height: 20),
          _kpiGrid(metrics),
          const SizedBox(height: 20),
          _visualInsights(filteredMonths, metrics),
          const SizedBox(height: 20),
          _actionableIntelligence(hotspotRows, filteredOrders),
        ],
      ),
    );
  }

  Widget _timelineFilterBar(
    List<StoreMonthlyHistoryItem> monthlyHistory,
    DateTimeRange activeRange,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: kRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stack = constraints.maxWidth < 760;
          final Widget controls = Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<_TimelinePreset>(
                  initialValue: _timelinePreset,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.offWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
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
                  items: _TimelinePreset.values
                      .map(
                        (preset) => DropdownMenuItem<_TimelinePreset>(
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
                  onChanged: (_TimelinePreset? value) async {
                    if (value == null) return;
                    if (value == _TimelinePreset.custom) {
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
                        _customRange = picked;
                        _timelinePreset = value;
                      });
                      return;
                    }
                    setState(() {
                      _timelinePreset = value;
                    });
                  },
                ),
              ),
              if (_timelinePreset == _TimelinePreset.custom)
                OutlinedButton.icon(
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
                    'Change Range',
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
                ),
            ],
          );

          final String rangeLabel =
              '${_fmtDate(activeRange.start)} → ${_fmtDate(activeRange.end)}';

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Timeline Filter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                controls,
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    rangeLabel,
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

          return Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Timeline Filter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              controls,
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  rangeLabel,
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

  Widget _kpiGrid(_AnalyticsComputedMetrics stats) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int columns = width >= 1100
            ? 4
            : width >= 700
                ? 2
                : 1;

        final bool highRto = stats.rtoAnalytics.overallRate > 15;
        // Perfect responsive aspect ratio calculation to completely avoid vertical overflows on narrow cards
        final double childAspectRatio = width >= 1100
            ? 1.9
            : width >= 700
                ? 2.1
                : 3.3;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _KpiCard(
              title: 'Net Earnings',
              value: 'Rs. ${stats.financials.totalCollected.toStringAsFixed(0)}',
              subtitle: 'Available in bank/cash',
              icon: Icons.payments_rounded,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFECFDF5),
            ),
            _KpiCard(
              title: 'Pending Settlements',
              value: 'Rs. ${stats.financials.pendingBalance.toStringAsFixed(0)}',
              subtitle: 'Out for delivery / COD pending',
              icon: Icons.hourglass_bottom_rounded,
              iconColor: AppColors.accentBlue,
              iconBgColor: AppColors.accentBlueLight,
            ),
            _KpiCard(
              title: 'RTO Rate',
              value: '${stats.rtoAnalytics.overallRate.toStringAsFixed(1)}%',
              subtitle: 'Est. Loss: Rs. ${stats.rtoAnalytics.lossEstimated.toStringAsFixed(0)}',
              valueColor: highRto ? AppColors.rtoText : AppColors.textPrimary,
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.rtoText,
              iconBgColor: AppColors.rtoBg,
            ),
            _KpiCard(
              title: 'Total Orders',
              value: '${stats.orderMetrics.totalOrders}',
              subtitle: '${stats.orderMetrics.deliveredCount} successfully delivered',
              icon: Icons.shopping_bag_rounded,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primaryLight,
            ),
          ],
        );
      },
    );
  }

  Widget _visualInsights(
    List<StoreMonthlyHistoryItem> months,
    _AnalyticsComputedMetrics metrics,
  ) {
    final List<StoreMonthlyHistoryItem> chartMonths = months.length <= 6
        ? months
        : months.sublist(months.length - 6);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stack = constraints.maxWidth < 920;
        if (stack) {
          return Column(
            children: [
              _RevenueHistoryCard(history: chartMonths),
              const SizedBox(height: 16),
              _OrderStatusDonutCard(metrics: metrics.orderMetrics),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _RevenueHistoryCard(history: chartMonths),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _OrderStatusDonutCard(metrics: metrics.orderMetrics),
            ),
          ],
        );
      },
    );
  }

  Widget _actionableIntelligence(
    List<MapEntry<String, int>> districts,
    List<OrderDocument> filteredOrders,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stack = constraints.maxWidth < 920;
        if (stack) {
          return Column(
            children: [
              _RtoHotspotTable(
                rows: districts,
                onExport: (format) => _exportHotspots(format, districts),
              ),
              const SizedBox(height: 16),
              _FinancialLedgerFeed(orders: filteredOrders),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _RtoHotspotTable(
                rows: districts,
                onExport: (format) => _exportHotspots(format, districts),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _FinancialLedgerFeed(orders: filteredOrders)),
          ],
        );
      },
    );
  }

  Future<void> _exportHotspots(
    ExportFormat format,
    List<MapEntry<String, int>> rows,
  ) async {
    final List<List<String>> exportRows = rows
        .map((entry) => <String>[entry.key, entry.value.toString()])
        .toList();

    final bool ok = await exportTabularData(
      baseFileName: 'analytics_rto_hotspots_${DateTime.now().toIso8601String().split('T').first}',
      headers: const <String>['District Name', 'RTO Count'],
      rows: exportRows,
      format: format,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.black : Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        content: Text(
          ok
              ? '${format.label} export downloaded.'
              : '${format.label} export is available on web builds.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }

  DateTimeRange _activeDateRange(List<StoreMonthlyHistoryItem> history) {
    if (_timelinePreset == _TimelinePreset.custom && _customRange != null) {
      return _customRange!;
    }

    final DateTime now = DateTime.now();
    switch (_timelinePreset) {
      case _TimelinePreset.last30Days:
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
      case _TimelinePreset.last3Months:
        return DateTimeRange(start: now.subtract(const Duration(days: 90)), end: now);
      case _TimelinePreset.last6Months:
        return DateTimeRange(start: now.subtract(const Duration(days: 180)), end: now);
      case _TimelinePreset.last12Months:
        return DateTimeRange(start: now.subtract(const Duration(days: 365)), end: now);
      case _TimelinePreset.custom:
        final List<DateTime> monthDates = history
            .map((item) => _monthDate(item.month))
            .whereType<DateTime>()
            .toList()
          ..sort();
        if (monthDates.isEmpty) {
          return DateTimeRange(start: now.subtract(const Duration(days: 180)), end: now);
        }
        return DateTimeRange(start: monthDates.first, end: now);
    }
  }

  List<StoreMonthlyHistoryItem> _filterMonthlyHistory(
    List<StoreMonthlyHistoryItem> all,
    DateTimeRange range,
  ) {
    final List<StoreMonthlyHistoryItem> filtered = all.where((item) {
      final DateTime? monthDate = _monthDate(item.month);
      if (monthDate == null) return false;
      return !monthDate.isBefore(DateTime(range.start.year, range.start.month)) &&
          !monthDate.isAfter(DateTime(range.end.year, range.end.month, 31));
    }).toList();

    return filtered;
  }

  List<OrderDocument> _filterOrders(List<OrderDocument> all, DateTimeRange range) {
    return all.where((order) {
      final DateTime date = order.shipping.timeline.createdAt;
      return !date.isBefore(range.start) && !date.isAfter(range.end);
    }).toList();
  }

  _AnalyticsComputedMetrics _computeMetrics({
    required StoreStatsDocument base,
    required List<StoreMonthlyHistoryItem> filteredMonths,
    required List<OrderDocument> filteredOrders,
  }) {
    final num revenue = filteredMonths.fold<num>(
      0,
      (sum, month) => sum + month.revenue,
    );
    final int totalOrders = filteredMonths.fold<int>(
      0,
      (sum, month) => sum + month.orders,
    );
    final int rto = filteredMonths.fold<int>(0, (sum, month) => sum + month.rto);
    final int pending = filteredOrders.where((order) {
      return order.shipping.status == ShippingStatus.created ||
          order.shipping.status == ShippingStatus.shipped;
    }).length;
    final int delivered = (totalOrders - rto - pending).clamp(0, totalOrders);

    final num pendingBalance = filteredOrders
        .where((order) {
          return order.shipping.status == ShippingStatus.created ||
              order.shipping.status == ShippingStatus.shipped;
        })
        .fold<num>(
          0,
          (sum, order) => sum + (order.financials['totalAmount'] as num? ?? 0),
        );

    final double rtoRate = totalOrders == 0 ? 0 : (rto / totalOrders) * 100;
    final num avgShippingCost = base.orderMetrics.rtoCount == 0
        ? 0
        : base.rtoAnalytics.lossEstimated / base.orderMetrics.rtoCount;
    final num estimatedLoss = rto * avgShippingCost;

    return _AnalyticsComputedMetrics(
      financials: StoreFinancials(
        totalRevenue: revenue,
        totalCollected: revenue,
        pendingBalance: pendingBalance,
      ),
      orderMetrics: StoreOrderMetrics(
        totalOrders: totalOrders,
        deliveredCount: delivered,
        rtoCount: rto,
        pendingCount: pending,
      ),
      rtoAnalytics: StoreRtoAnalytics(
        overallRate: rtoRate,
        lossEstimated: estimatedLoss,
        byDistrict: const <String, int>{},
      ),
    );
  }

  List<MapEntry<String, int>> _rtoHotspots(
    StoreStatsDocument base,
    List<OrderDocument> filteredOrders,
  ) {
    final Map<String, int> hotspot = <String, int>{};
    for (final OrderDocument order in filteredOrders) {
      if (order.shipping.status != ShippingStatus.rto) continue;
      final String district = order.customerInfo.district;
      hotspot[district] = (hotspot[district] ?? 0) + 1;
    }

    final Map<String, int> source = hotspot.isEmpty ? base.rtoAnalytics.byDistrict : hotspot;
    final List<MapEntry<String, int>> rows = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return rows;
  }

  DateTime? _monthDate(String yyyyMm) {
    final List<String> parts = yyyyMm.split('-');
    if (parts.length != 2) return null;
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return null;
    return DateTime(year, month, 1);
  }

  String _fmtDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

enum _TimelinePreset {
  last30Days('Last 30 days'),
  last3Months('Last 3 months'),
  last6Months('Last 6 months'),
  last12Months('Last 12 months'),
  custom('Custom range');

  const _TimelinePreset(this.label);
  final String label;
}

class _AnalyticsComputedMetrics {
  const _AnalyticsComputedMetrics({
    required this.financials,
    required this.orderMetrics,
    required this.rtoAnalytics,
  });

  final StoreFinancials financials;
  final StoreOrderMetrics orderMetrics;
  final StoreRtoAnalytics rtoAnalytics;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: kRadiusMedium,
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _RevenueHistoryCard extends StatelessWidget {
  const _RevenueHistoryCard({required this.history});

  final List<StoreMonthlyHistoryItem> history;

  @override
  Widget build(BuildContext context) {
    final List<StoreMonthlyHistoryItem> data = history.isEmpty
        ? const <StoreMonthlyHistoryItem>[
            StoreMonthlyHistoryItem(month: '2026-01', revenue: 0, orders: 0, rto: 0),
            StoreMonthlyHistoryItem(month: '2026-02', revenue: 0, orders: 0, rto: 0),
            StoreMonthlyHistoryItem(month: '2026-03', revenue: 0, orders: 0, rto: 0),
          ]
        : history;

    final num maxRevenue = data
        .map((StoreMonthlyHistoryItem e) => e.revenue)
        .fold<num>(0, (num p, num c) => p > c ? p : c);

    return _SectionCard(
      title: 'Revenue History (Last 6 Months)',
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            maxY: (maxRevenue * 1.2) == 0 ? 10 : (maxRevenue * 1.2).toDouble(),
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.border.withValues(alpha: 0.6),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1.2),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    if (value == meta.max) return const SizedBox.shrink();
                    return Text(
                      'Rs. ${(value / 1000).toStringAsFixed(0)}k',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _monthLabel(data[index].month),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.black,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    'Rs. ${rod.toY.toStringAsFixed(0)}',
                    GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),
            ),
            barGroups: data
                .asMap()
                .entries
                .map(
                  (entry) => BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.revenue.toDouble(),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF818CF8)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  String _monthLabel(String yyyyMm) {
    final List<String> parts = yyyyMm.split('-');
    if (parts.length != 2) return yyyyMm;

    const List<String> names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final int? month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) return yyyyMm;
    return names[month - 1];
  }
}

class _OrderStatusDonutCard extends StatelessWidget {
  const _OrderStatusDonutCard({required this.metrics});

  final StoreOrderMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final int delivered = metrics.deliveredCount;
    final int pending = metrics.pendingCount;
    final int rto = metrics.rtoCount;
    final int total = (delivered + pending + rto) == 0
        ? 1
        : (delivered + pending + rto);
    final double deliveryPercent = (delivered / total) * 100;

    return _SectionCard(
      title: 'Order Success Rate',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 54,
                    sectionsSpace: 0,
                    borderData: FlBorderData(show: false),
                    sections: [
                      PieChartSectionData(
                        value: delivered.toDouble(),
                        color: const Color(0xFF10B981),
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        value: pending.toDouble(),
                        color: AppColors.primary,
                        title: '',
                        radius: 20,
                      ),
                      PieChartSectionData(
                        value: rto.toDouble(),
                        color: const Color(0xFFEF4444),
                        title: '',
                        radius: 20,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${deliveryPercent.toStringAsFixed(1)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        color: AppColors.black,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Success Rate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _LegendRow(),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: const [
        _LegendDot(color: Color(0xFF10B981), label: 'Delivered'),
        _LegendDot(color: AppColors.primary, label: 'Pending'),
        _LegendDot(color: Color(0xFFEF4444), label: 'RTO'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RtoHotspotTable extends StatelessWidget {
  const _RtoHotspotTable({
    required this.rows,
    required this.onExport,
  });

  final List<MapEntry<String, int>> rows;
  final Future<void> Function(ExportFormat format) onExport;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'High-Risk Districts (RTO)',
      trailing: PopupMenuButton<ExportFormat>(
        tooltip: 'Export',
        enabled: rows.isNotEmpty,
        onSelected: onExport,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.border, width: 1.2),
            borderRadius: kRadiusSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download_rounded, size: 15, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                'Export',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1.2),
          borderRadius: kRadiusMedium,
        ),
        child: ClipRRect(
          borderRadius: kRadiusMedium,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                  ),
                  child: DataTable(
                    headingRowHeight: 42,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 48,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    horizontalMargin: 16,
                    columnSpacing: 20,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'District Name',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'RTO Count',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Risk Action',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    rows: rows.map((entry) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              entry.key,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.rtoBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${entry.value}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: AppColors.rtoText,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFEC2D2), width: 1.2),
                                backgroundColor: const Color(0xFFFFF1F2),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: const Size(110, 28),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: Text(
                                'Require Advance',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: const Color(0xFFE11D48),
                                  fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _FinancialLedgerFeed extends StatelessWidget {
  const _FinancialLedgerFeed({required this.orders});

  final List<OrderDocument> orders;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Financial Ledger Feed',
      child: SizedBox(
        height: 250,
        child: ListView.separated(
          itemCount: orders.length,
          physics: const BouncingScrollPhysics(),
          separatorBuilder: (_, index) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (BuildContext context, int index) {
            final OrderDocument order = orders[index];
            final _LedgerRow row = _ledgerFromOrder(order);

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: row.isIncoming ? AppColors.deliveredBg : AppColors.pendingBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: row.isIncoming
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFDE68A),
                    width: 1,
                  ),
                ),
                child: Icon(
                  row.isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 16,
                  color: row.isIncoming ? AppColors.deliveredText : AppColors.pendingText,
                ),
              ),
              title: Text(
                row.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                row.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Text(
                'Rs. ${row.amount.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: row.isIncoming ? const Color(0xFF16A34A) : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  _LedgerRow _ledgerFromOrder(OrderDocument order) {
    final num amount = order.financials['totalAmount'] as num? ?? 0;
    final String date = _formatDate(order.shipping.timeline.createdAt);

    switch (order.shipping.status) {
      case ShippingStatus.delivered:
        return _LedgerRow(
          title: 'COD Collected',
          subtitle: 'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id} • $date',
          amount: amount,
          isIncoming: true,
        );
      case ShippingStatus.rto:
        return _LedgerRow(
          title: 'RTO Adjustment',
          subtitle: 'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id} • $date',
          amount: amount,
          isIncoming: false,
        );
      case ShippingStatus.created:
      case ShippingStatus.shipped:
        return _LedgerRow(
          title: 'Pending COD Settlement',
          subtitle: 'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id} • $date',
          amount: amount,
          isIncoming: false,
        );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _LedgerRow {
  const _LedgerRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncoming,
  });

  final String title;
  final String subtitle;
  final num amount;
  final bool isIncoming;
}
