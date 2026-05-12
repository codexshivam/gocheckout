enum PortalSection {
  dashboard('Dashboard'),
  analytics('Analytics'),
  financialLedger('Financial Ledger'),
  products('Products'),
  checkoutLinks('Checkout Links'),
  orders('Orders'),
  coupons('Coupons'),
  settings('Settings');

  const PortalSection(this.label);
  final String label;
}
