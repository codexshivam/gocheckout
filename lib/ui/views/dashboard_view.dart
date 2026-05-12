import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../common/widgets/app_panel.dart';
import '../common/widgets/status_badge.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/service_locator.dart';
import '../../data/models/schema/merchant_models.dart';
import '../../data/models/schema/order_models.dart';
import '../theme/app_colors.dart';
import '../utils/table_exporter.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardRepository _repository = ServiceLocator.instance.dashboardRepository;

  Merchant? _merchant;
  List<double> _salesPoints = const [];
  List<OrderDocument> _recentOrders = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final Merchant merchant = await _repository.fetchMerchant();
      final List<double> salesPoints = await _repository.fetchSalesPoints();
      final List<OrderDocument> recentOrders = await _repository.fetchRecentOrders();
      
      if (!mounted) return;
      setState(() {
        _merchant = merchant;
        _salesPoints = salesPoints;
        _recentOrders = recentOrders;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportRecentOrders(ExportFormat format) async {
    final List<List<String>> rows = _recentOrders
        .map(
          (order) => <String>[
            order.id,
            order.customerInfo.name,
            (order.financials['totalAmount'] as num? ?? 0).toStringAsFixed(0),
            _fmtDate(order.shipping.timeline.createdAt),
            _fmtShippingStatus(order.shipping.status),
          ],
        )
        .toList();

    final bool ok = await exportTabularData(
      baseFileName: 'dashboard_recent_orders_${DateTime.now().toIso8601String().split('T').first}',
      headers: const <String>[
        'Order ID',
        'Customer Name',
        'Amount',
        'Date',
        'Status',
      ],
      rows: rows,
      format: format,
    );

    if (!mounted) return;
    
    // Display a beautiful snackbar matching our design system
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Text(
              ok
                  ? '${format.label} export downloaded successfully.'
                  : '${format.label} export is available on web builds.',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime date) {
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _fmtShippingStatus(ShippingStatus status) {
    switch (status) {
      case ShippingStatus.delivered:
        return 'Delivered';
      case ShippingStatus.rto:
        return 'RTO';
      case ShippingStatus.shipped:
        return 'Pending';
      case ShippingStatus.created:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      );
    }

    final double width = MediaQuery.sizeOf(context).width;
    final _DashboardMetrics metrics = _buildMetrics(_recentOrders);
    final int statCols = width > 1200
        ? 4
        : width > 768
            ? 2
            : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26, 
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overview of your shop\'s performance and logistics health.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.border, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 20),
                onPressed: _loadData,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _WelcomeBanner(
            merchantName: _merchant?.businessName ?? 'Your Store',
            todayRevenue: metrics.revenue,
            deliveredCount: metrics.delivered,
            pendingCount: metrics.pending,
            rtoCount: metrics.rto,
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: statCols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: width > 1200 ? 1.6 : 1.7,
            children: _dashboardCards(),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stacked = constraints.maxWidth < 960;
              if (stacked) {
                return Column(
                  children: [
                    _SalesBarChart(
                      points: _salesPoints,
                      totalRevenue: metrics.revenue,
                    ),
                    const SizedBox(height: 20),
                    _DonutCard(
                      successRate: metrics.successRate,
                      delivered: metrics.delivered,
                      rto: metrics.rto,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _SalesBarChart(
                      points: _salesPoints,
                      totalRevenue: metrics.revenue,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _DonutCard(
                      successRate: metrics.successRate,
                      delivered: metrics.delivered,
                      rto: metrics.rto,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _PerformanceBreakdown(metrics: metrics),
          const SizedBox(height: 20),
          _RecentOrdersTable(
            rows: _recentOrders,
            onExport: _exportRecentOrders,
          ),
        ],
      ),
    );
  }

  _DashboardMetrics _buildMetrics(List<OrderDocument> orders) {
    int delivered = 0;
    int rto = 0;
    int pending = 0;
    num revenue = 0;

    for (final OrderDocument order in orders) {
      final num amount = order.financials['totalAmount'] as num? ?? 0;
      revenue += amount;
      switch (order.shipping.status) {
        case ShippingStatus.delivered:
          delivered++;
          break;
        case ShippingStatus.rto:
          rto++;
          break;
        case ShippingStatus.created:
        case ShippingStatus.shipped:
          pending++;
          break;
      }
    }

    final int total = orders.length;
    final double successRate = total == 0 ? 0 : (delivered / total) * 100;

    return _DashboardMetrics(
      delivered: delivered,
      pending: pending,
      rto: rto,
      revenue: revenue,
      successRate: successRate,
      totalOrders: total,
    );
  }

  List<Widget> _dashboardCards() {
    if (_merchant == null) {
      return const [
        _StatCard(
          title: 'Total Revenue',
          value: 'NPR 0',
          delta: '+0%',
          icon: Icons.payments_outlined,
          highlightColor: AppColors.deliveredText,
        ),
        _StatCard(
          title: 'Orders',
          value: '0',
          delta: '+0%',
          icon: Icons.shopping_bag_outlined,
          highlightColor: AppColors.primary,
        ),
        _StatCard(
          title: 'Delivered',
          value: '0',
          delta: '+0%',
          icon: Icons.local_shipping_outlined,
          highlightColor: AppColors.accentBlue,
        ),
        _StatCard(
          title: 'RTO Rate',
          value: '0%',
          delta: '+0%',
          icon: Icons.assignment_return_outlined,
          highlightColor: AppColors.rtoText,
        ),
      ];
    }

    final MerchantStats stats = _merchant!.stats;
    final int delivered = (stats.totalOrders - stats.rtoCount).clamp(0, 9999999);
    final double rtoRate = stats.totalOrders == 0 ? 0 : (stats.rtoCount / stats.totalOrders) * 100;

    return [
      _StatCard(
        title: 'Total Revenue',
        value: 'NPR ${stats.totalSales.toStringAsFixed(0)}',
        delta: '+13.2%',
        icon: Icons.payments_outlined,
        highlightColor: AppColors.deliveredText,
      ),
      _StatCard(
        title: 'Orders',
        value: '${stats.totalOrders}',
        delta: '+6.5%',
        icon: Icons.shopping_bag_outlined,
        highlightColor: AppColors.primary,
      ),
      _StatCard(
        title: 'Delivered',
        value: '$delivered',
        delta: '+4.7%',
        icon: Icons.local_shipping_outlined,
        highlightColor: AppColors.accentBlue,
      ),
      _StatCard(
        title: 'RTO Rate',
        value: '${rtoRate.toStringAsFixed(1)}%',
        delta: '-1.2%',
        icon: Icons.assignment_return_outlined,
        highlightColor: AppColors.rtoText,
      ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    this.highlightColor = AppColors.black,
  });

  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final bool isNegativeTrend = delta.startsWith('-');
    final Color trendColor = isNegativeTrend ? AppColors.rtoText : AppColors.deliveredText;
    final Color trendBg = isNegativeTrend ? AppColors.rtoBg : AppColors.deliveredBg;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: kRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 10,
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
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: highlightColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: highlightColor, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: trendBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: trendColor.withValues(alpha: 0.15), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNegativeTrend ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: trendColor,
                      size: 11,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      delta,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: trendColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'vs last month',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  const _SalesBarChart({required this.points, required this.totalRevenue});

  final List<double> points;
  final num totalRevenue;

  @override
  Widget build(BuildContext context) {
    final List<double> safePoints = points.isEmpty
        ? const [20, 30, 24, 40, 28, 45, 50, 38, 48, 60]
        : points;
    
    final double maxPoint = safePoints.reduce(math.max);
    final double gridMax = maxPoint == 0 ? 1.0 : maxPoint * 1.1;

    return AppPanel(
      title: 'Sales Last 30 Days',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NPR ${totalRevenue.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.deliveredBg,
                  borderRadius: kRadiusSmall,
                  border: Border.all(color: AppColors.deliveredText.withValues(alpha: 0.15)),
                ),
                child: Text(
                  '+12.4% vs last period',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.deliveredText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                // Background reference grid lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) => Container(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.5),
                  )),
                ),
                // Custom rendered bars
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: safePoints
                        .asMap()
                        .entries
                        .map(
                          (entry) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FractionallySizedBox(
                                alignment: Alignment.bottomCenter,
                                heightFactor: (entry.value / gridMax).clamp(0.05, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: entry.key.isEven
                                          ? [AppColors.black, AppColors.black.withValues(alpha: 0.85)]
                                          : [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Week 1', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Text('Week 2', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Text('Week 3', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Text('Week 4', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  const _DonutCard({
    required this.successRate,
    required this.delivered,
    required this.rto,
  });

  final double successRate;
  final int delivered;
  final int rto;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Fulfillment Metrics',
      child: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            width: 170,
            height: 170,
            child: CustomPaint(
              painter: _PremiumGaugePainter(
                successPercentage: successRate,
                trackColor: const Color(0xFFF1F5F9),
                activeColors: [AppColors.primary, const Color(0xFF10B981)],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${successRate.toStringAsFixed(0)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28, 
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Success Rate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _LegendItem(color: AppColors.primary, label: 'Delivered'),
              const SizedBox(width: 20),
              _LegendItem(color: AppColors.rtoText.withValues(alpha: 0.6), label: 'RTO'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: kRadiusSmall,
            ),
            child: Text(
              '$delivered delivered • $rto returned',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5, 
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumGaugePainter extends CustomPainter {
  _PremiumGaugePainter({
    required this.successPercentage,
    required this.trackColor,
    required this.activeColors,
  });

  final double successPercentage;
  final Color trackColor;
  final List<Color> activeColors;

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.13;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // Background track
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 1.25,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    // Active track representing success
    final double sweepAngle = (successPercentage / 100).clamp(0.0, 1.0) * (math.pi * 1.5);
    if (sweepAngle > 0) {
      final Paint activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      activePaint.shader = LinearGradient(
        colors: activeColors,
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 1.25,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PremiumGaugePainter oldDelegate) {
    return oldDelegate.successPercentage != successPercentage ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColors != activeColors;
  }
}

class _PerformanceBreakdown extends StatelessWidget {
  const _PerformanceBreakdown({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final int total = metrics.totalOrders == 0 ? 1 : metrics.totalOrders;
    final double deliveredFactor = (metrics.delivered / total).clamp(0, 1).toDouble();
    final double pendingFactor = (metrics.pending / total).clamp(0, 1).toDouble();
    final double rtoFactor = (metrics.rto / total).clamp(0, 1).toDouble();

    return AppPanel(
      title: 'Fulfillment Quality Breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keep tabs on overall operational performance across your active store catalog.',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondary, 
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _HealthRow(
            label: 'Delivered',
            value: metrics.delivered,
            factor: deliveredFactor,
            barColor: AppColors.deliveredText,
            chipColor: AppColors.deliveredBg,
          ),
          const SizedBox(height: 12),
          _HealthRow(
            label: 'Pending',
            value: metrics.pending,
            factor: pendingFactor,
            barColor: AppColors.pendingText,
            chipColor: AppColors.pendingBg,
          ),
          const SizedBox(height: 12),
          _HealthRow(
            label: 'RTO',
            value: metrics.rto,
            factor: rtoFactor,
            barColor: AppColors.rtoText,
            chipColor: AppColors.rtoBg,
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.label,
    required this.value,
    required this.factor,
    required this.barColor,
    required this.chipColor,
  });

  final String label;
  final int value;
  final double factor;
  final Color barColor;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label, 
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  color: const Color(0xFFF1F5F9),
                ),
                FractionallySizedBox(
                  widthFactor: factor,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [barColor.withValues(alpha: 0.8), barColor],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: kRadiusSmall,
            border: Border.all(color: barColor.withValues(alpha: 0.12), width: 1),
          ),
          child: Text(
            '$value orders', 
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: barColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.merchantName,
    required this.todayRevenue,
    required this.deliveredCount,
    required this.pendingCount,
    required this.rtoCount,
  });

  final String merchantName;
  final num todayRevenue;
  final int deliveredCount;
  final int pendingCount;
  final int rtoCount;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final int gridCols = width > 1024
        ? 4
        : width > 600
            ? 2
            : 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kRadiusLarge,
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $merchantName 👋',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Here is your store\'s performance summary at a glance for today:',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: gridCols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width > 1024 ? 2.1 : 2.5,
            children: [
              _MetricCard(
                label: 'Today\'s Revenue',
                value: 'NPR ${todayRevenue.toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
                baseColor: const Color(0xFF10B981),
              ),
              _MetricCard(
                label: 'Delivered Orders',
                value: '$deliveredCount',
                icon: Icons.local_shipping_outlined,
                baseColor: AppColors.accentBlue,
              ),
              _MetricCard(
                label: 'Pending Orders',
                value: '$pendingCount',
                icon: Icons.hourglass_empty_rounded,
                baseColor: const Color(0xFFF59E0B),
              ),
              _MetricCard(
                label: 'RTO Orders',
                value: '$rtoCount',
                icon: Icons.assignment_return_outlined,
                baseColor: AppColors.rtoText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.baseColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: baseColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    color: AppColors.black,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
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

class _DashboardMetrics {
  const _DashboardMetrics({
    required this.delivered,
    required this.pending,
    required this.rto,
    required this.revenue,
    required this.successRate,
    required this.totalOrders,
  });

  final int delivered;
  final int pending;
  final int rto;
  final num revenue;
  final double successRate;
  final int totalOrders;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

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
        const SizedBox(width: 6),
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

class _RecentOrdersTable extends StatelessWidget {
  const _RecentOrdersTable({
    required this.rows,
    required this.onExport,
  });

  final List<OrderDocument> rows;
  final Future<void> Function(ExportFormat format) onExport;

  String _fmtDate(DateTime date) {
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _fmtShippingStatus(ShippingStatus status) {
    switch (status) {
      case ShippingStatus.delivered:
        return 'Delivered';
      case ShippingStatus.rto:
        return 'RTO';
      case ShippingStatus.shipped:
        return 'Pending';
      case ShippingStatus.created:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'Recent Orders Grid',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Latest checkout transactions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<ExportFormat>(
                tooltip: 'Export Table',
                enabled: rows.isNotEmpty,
                onSelected: onExport,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (BuildContext context) => ExportFormat.values
                    .map(
                      (format) => PopupMenuItem<ExportFormat>(
                        value: format,
                        child: Text(
                          'Export as ${format.label}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.border, width: 1.2),
                    borderRadius: kRadiusSmall,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download_rounded, size: 16, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Export',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, size: 40, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'No recent orders found.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
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
                                'Customer Name',
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
                                'Status',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                          rows: rows
                              .map(
                                (order) => DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        order.id.length > 8
                                            ? '#${order.id.substring(0, 8)}'
                                            : '#${order.id}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: AppColors.black,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          order.customerInfo.name,
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
                                        'NPR ${(order.financials['totalAmount'] as num? ?? 0).toStringAsFixed(0)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _fmtDate(order.shipping.timeline.createdAt),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      StatusBadge(
                                        status: _fmtShippingStatus(order.shipping.status),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
