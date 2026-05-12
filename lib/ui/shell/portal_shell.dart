import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../common/widgets/status_badge.dart';
import '../models/portal_section.dart';
import '../theme/app_colors.dart';
import '../views/analytics/analytics_page.dart';
import '../views/checkout_link_view.dart';
import '../views/coupons_view.dart';
import '../views/dashboard_view.dart';
import '../views/financial_ledger_view.dart';
import '../views/orders_view.dart';
import '../views/products_view.dart';
import '../views/settings_view.dart';

class PortalShell extends StatefulWidget {
  final VoidCallback onLogout;

  const PortalShell({super.key, required this.onLogout});

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PortalSection _selected = PortalSection.dashboard;

  @override
  Widget build(BuildContext context) {
    final bool desktop = MediaQuery.sizeOf(context).width > 1024;
    return Scaffold(
      key: _scaffoldKey,
      drawer: desktop
          ? null
          : Drawer(
              width: 280,
              child: _Sidebar(
                onSelect: _onSelect,
                selected: _selected,
                onLogout: widget.onLogout,
              ),
            ),
      appBar: desktop
          ? null
          : AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              shape: const Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GoCheckout',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (desktop)
            SizedBox(
              width: 260,
              child: _Sidebar(
                onSelect: _onSelect,
                selected: _selected,
                onLogout: widget.onLogout,
              ),
            ),
          Expanded(
            child: Container(
              color: AppColors.offWhite,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _buildPageStack(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSelect(PortalSection section) {
    setState(() {
      _selected = section;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  Widget _buildPageStack() {
    return IndexedStack(
      index: _selected.index,
      children: const [
        DashboardView(),
        AnalyticsPage(),
        FinancialLedgerView(),
        ProductsView(),
        CheckoutLinkView(),
        OrdersView(),
        CouponsView(),
        SettingsView(),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.onSelect,
    required this.selected,
    required this.onLogout,
  });

  final void Function(PortalSection section) onSelect;
  final PortalSection selected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.border, width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GoCheckout',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Merchant Portal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Navigation Items (with the user's loved bordered styling)
          Expanded(
            child: ListView.builder(
              itemCount: PortalSection.values.length,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                final PortalSection item = PortalSection.values[index];
                final bool isActive = selected == item;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isActive ? AppColors.offWhite : AppColors.white,
                    borderRadius: kRadiusSmall,
                    child: InkWell(
                      borderRadius: kRadiusSmall,
                      onTap: () => onSelect(item),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: kRadiusSmall,
                          border: Border.all(
                            color: isActive ? AppColors.black : AppColors.border,
                            width: isActive ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _sectionIcon(item),
                              size: 18,
                              color: isActive ? AppColors.black : AppColors.textPrimary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.label,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textPrimary,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 24, thickness: 1.2),
          // Store profile section at the bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: kRadiusMedium,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'Y',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yuva Store',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const UnconstrainedBox(
                        child: StatusBadge(status: 'Verified'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
              label: Text(
                'Sign Out',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: const Color(0xFFEF4444),
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFFEE2E2), width: 1.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _sectionIcon(PortalSection section) {
  return switch (section) {
    PortalSection.dashboard => Icons.dashboard_rounded,
    PortalSection.analytics => Icons.analytics_rounded,
    PortalSection.financialLedger => Icons.account_balance_wallet_rounded,
    PortalSection.products => Icons.inventory_2_rounded,
    PortalSection.checkoutLinks => Icons.link_rounded,
    PortalSection.orders => Icons.receipt_long_rounded,
    PortalSection.coupons => Icons.local_offer_rounded,
    PortalSection.settings => Icons.settings_rounded,
  };
}
