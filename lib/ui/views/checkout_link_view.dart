import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/schema/checkout_link_models.dart';
import '../../data/models/schema/product_models.dart';
import '../../data/repositories/checkout_links_repository.dart';
import '../../data/service_locator.dart';
import '../common/app_styles.dart';
import '../theme/app_colors.dart';
import '../utils/table_exporter.dart';

class CheckoutLinkView extends StatefulWidget {
  const CheckoutLinkView({super.key});

  @override
  State<CheckoutLinkView> createState() => _CheckoutLinkViewState();
}

class _CheckoutLinkViewState extends State<CheckoutLinkView> {
  final CheckoutLinksRepository _repository = ServiceLocator.instance.checkoutLinksRepository;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountCodeController = TextEditingController();
  final TextEditingController _discountAmountController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController();

  final List<_SelectedCheckoutItem> _selectedItems = <_SelectedCheckoutItem>[];
  final List<_ChargeRow> _charges = <_ChargeRow>[];

  List<Product> _products = const <Product>[];
  List<CheckoutLink> _links = const <CheckoutLink>[];

  String _statusFilter = 'All';
  String? _editingLinkId;
  bool _showInlineForm = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountCodeController.dispose();
    _discountAmountController.dispose();
    _productSearchController.dispose();
    for (final _ChargeRow row in _charges) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final List<Product> products = await _repository.fetchProducts();
    final List<CheckoutLink> history = await _repository.fetchHistory();
    if (!mounted) return;
    setState(() {
      _products = products;
      _links = history;
    });
  }

  List<CheckoutLink> get _filteredLinks {
    final String query = _searchController.text.trim().toLowerCase();
    return _links.where((CheckoutLink link) {
      final bool queryMatch =
          query.isEmpty ||
          link.linkId.toLowerCase().contains(query) ||
          link.items.any(
            (CheckoutLinkItem item) => item.productName.toLowerCase().contains(query),
          );
      final bool statusMatch =
          _statusFilter == 'All' || _statusFilter == _statusLabel(link.status);
      return queryMatch && statusMatch;
    }).toList();
  }

  List<Product> get _matchedProducts {
    final String query = _productSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return const <Product>[];
    return _products
        .where((Product product) => product.name.toLowerCase().contains(query))
        .toList();
  }

  num get _subtotal {
    return _selectedItems.fold<num>(
      0,
      (num sum, _SelectedCheckoutItem item) => sum + (item.qty * item.unitPrice),
    );
  }

  num get _extraChargesTotal {
    return _charges.fold<num>(0, (num sum, _ChargeRow row) {
      final num amount = num.tryParse(row.amount.text.trim()) ?? 0;
      return sum + (amount < 0 ? 0 : amount);
    });
  }

  num get _discountAmount {
    final num amount = num.tryParse(_discountAmountController.text.trim()) ?? 0;
    return amount < 0 ? 0 : amount;
  }

  num get _finalTotal {
    final num total = _subtotal + _extraChargesTotal - _discountAmount;
    return total < 0 ? 0 : total;
  }

  String _checkoutLinkUrl(CheckoutLink link) {
    final String storeSegment = link.storeId.isEmpty ? 'store' : link.storeId;
    return 'https://checkout.gocheckout.com/$storeSegment/${link.linkId}';
  }

  Future<void> _copyCheckoutLink(CheckoutLink link) async {
    await Clipboard.setData(ClipboardData(text: _checkoutLinkUrl(link)));
    if (!mounted) return;
    _showMessage('Checkout link copied.');
  }

  Future<void> _exportCheckoutLinks(
    ExportFormat format,
    List<CheckoutLink> rows,
  ) async {
    final List<List<String>> exportRows = rows.map((link) {
      return <String>[
        link.linkId,
        _itemsSummary(link.items),
        link.financials.subtotal.toStringAsFixed(0),
        link.financials.totalAmount.toStringAsFixed(0),
        _statusLabel(link.status),
        _checkoutLinkUrl(link),
      ];
    }).toList();

    final bool ok = await exportTabularData(
      baseFileName: 'checkout_links_${DateTime.now().toIso8601String().split('T').first}',
      headers: const <String>[
        'Link ID',
        'Items',
        'Subtotal (NPR)',
        'Final Total (NPR)',
        'Status',
        'Checkout URL',
      ],
      rows: exportRows,
      format: format,
    );

    if (!mounted) return;
    _showMessage(
      ok
          ? '${format.label} export downloaded.'
          : '${format.label} export is available on web builds.',
    );
  }

  void _openCreate() {
    setState(() {
      _showInlineForm = true;
      _editingLinkId = null;
      _isSaving = false;
      _productSearchController.clear();
      _discountCodeController.clear();
      _discountAmountController.text = '0';
      _selectedItems.clear();
      for (final _ChargeRow row in _charges) {
        row.dispose();
      }
      _charges
        ..clear()
        ..add(
          _ChargeRow(
            name: TextEditingController(text: 'Delivery'),
            amount: TextEditingController(text: '100'),
          ),
        );
    });
  }

  Future<void> _openCreateDialog() async {
    _openCreate();
    await _showCheckoutFormDialog();
  }

  Future<void> _openEditDialog(CheckoutLink link) async {
    _openEdit(link);
    await _showCheckoutFormDialog();
  }

  Future<void> _showCheckoutFormDialog() async {
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
                              Icons.link_rounded,
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
                                _editingLinkId == null ? 'Generate Checkout Link' : 'Edit Checkout Link',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _editingLinkId == null
                                    ? 'Create a pre-filled secure checkout page link to share with customers'
                                    : 'Modify items, extra charges, or discount criteria on this link',
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
                              _cancelInlineForm();
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
                            // Section 1: Products selection card
                            _buildSectionCard(
                              title: 'Products Selection',
                              icon: Icons.shopping_bag_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _productSearchController,
                                    onChanged: (_) => setDialogState(() {}),
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                    decoration: inputDecoration(
                                      'Search product to add',
                                      icon: const Icon(Icons.search_rounded, size: 18),
                                    ),
                                  ),
                                  if (_matchedProducts.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        border: Border.all(color: AppColors.border, width: 1.2),
                                        borderRadius: kRadiusMedium,
                                      ),
                                      child: Column(
                                        children: _matchedProducts
                                            .map(
                                              (Product product) => ListTile(
                                                dense: true,
                                                title: Text(
                                                  product.name,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                trailing: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
                                                onTap: () {
                                                  _addSelectedItem(product);
                                                  setDialogState(() {});
                                                },
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  if (_selectedItems.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'No items selected. Search for products above to add.',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    ..._selectedItems.asMap().entries.map((entry) {
                                      final int index = entry.key;
                                      final _SelectedCheckoutItem item = entry.value;
                                      final Product? product = _products
                                          .where((Product p) => p.id == item.productId)
                                          .firstOrNull;
                                      final List<ProductVariant> variants =
                                          product?.variants ?? const <ProductVariant>[];

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.offWhite,
                                          border: Border.all(color: AppColors.border, width: 1.2),
                                          borderRadius: kRadiusMedium,
                                        ),
                                        child: Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 180,
                                              child: Text(
                                                item.productName,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 180,
                                              child: DropdownButtonFormField<String>(
                                                initialValue: item.variantId,
                                                decoration: inputDecoration('Variant'),
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
                                                          _variantLabel(variant),
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                            color: AppColors.textPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: (String? value) {
                                                  if (value == null) return;
                                                  final ProductVariant selected = variants.firstWhere(
                                                    (ProductVariant v) => v.variantId == value,
                                                  );
                                                  setDialogState(() {
                                                    item.variantId = selected.variantId;
                                                    item.variantName = _variantLabel(selected);
                                                    item.unitPrice = selected.price;
                                                  });
                                                },
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.white,
                                                border: Border.all(color: AppColors.border, width: 1.2),
                                                borderRadius: kRadiusMedium,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      setDialogState(() {
                                                        item.qty = item.qty > 1 ? item.qty - 1 : 1;
                                                      });
                                                    },
                                                    icon: const Icon(Icons.remove_rounded, size: 14),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  Text(
                                                    '${item.qty}',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.black,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () => setDialogState(() => item.qty++),
                                                    icon: const Icon(Icons.add_rounded, size: 14),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              'NPR ${item.unitPrice.toStringAsFixed(0)}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton.filled(
                                              style: IconButton.styleFrom(
                                                backgroundColor: AppColors.rtoBg,
                                                foregroundColor: AppColors.rtoText,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                padding: const EdgeInsets.all(8),
                                              ),
                                              onPressed: () => setDialogState(() => _selectedItems.removeAt(index)),
                                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Section 2: Extra charges card
                            _buildSectionCard(
                              title: 'Fulfillment Charges',
                              icon: Icons.local_shipping_outlined,
                              action: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.black,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: () {
                                  _addCharge();
                                  setDialogState(() {});
                                },
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                label: Text(
                                  'Add Charge',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
                                ),
                              ),
                              child: Column(
                                children: [
                                  if (_charges.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'No extra fulfillment charges added. Click "Add Charge" if needed.',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    ..._charges.asMap().entries.map((entry) {
                                      final int index = entry.key;
                                      final _ChargeRow charge = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final double w = constraints.maxWidth;
                                            if (w < 500) {
                                              return Column(
                                                children: [
                                                  TextField(
                                                    controller: charge.name,
                                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                                    decoration: inputDecoration('Charge Name', icon: const Icon(Icons.label_outline_rounded, size: 18)),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextField(
                                                          controller: charge.amount,
                                                          keyboardType: TextInputType.number,
                                                          onChanged: (_) => setDialogState(() {}),
                                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                                          decoration: inputDecoration('Amount (NPR)', icon: const Icon(Icons.sell_outlined, size: 18)),
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
                                                        onPressed: () {
                                                          final _ChargeRow removed = _charges.removeAt(index);
                                                          removed.dispose();
                                                          setDialogState(() {});
                                                        },
                                                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            }
                                            return Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: TextField(
                                                    controller: charge.name,
                                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                                    decoration: inputDecoration('Charge Name', icon: const Icon(Icons.label_outline_rounded, size: 18)),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  flex: 2,
                                                  child: TextField(
                                                    controller: charge.amount,
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (_) => setDialogState(() {}),
                                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                                    decoration: inputDecoration('Amount (NPR)', icon: const Icon(Icons.sell_outlined, size: 18)),
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
                                                  onPressed: () {
                                                    final _ChargeRow removed = _charges.removeAt(index);
                                                    removed.dispose();
                                                    setDialogState(() {});
                                                  },
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Section 3: Discount options
                            _buildSectionCard(
                              title: 'Discount Options',
                              icon: Icons.sell_outlined,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final double w = constraints.maxWidth;
                                  if (w < 500) {
                                    return Column(
                                      children: [
                                        TextField(
                                          controller: _discountCodeController,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                          decoration: inputDecoration('Discount Code (Optional)', icon: const Icon(Icons.discount_outlined, size: 18)),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _discountAmountController,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setDialogState(() {}),
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                          decoration: inputDecoration('Discount Value (NPR)', icon: const Icon(Icons.price_change_outlined, size: 18)),
                                        ),
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _discountCodeController,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                          decoration: inputDecoration('Discount Code (Optional)', icon: const Icon(Icons.discount_outlined, size: 18)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _discountAmountController,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setDialogState(() {}),
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                          decoration: inputDecoration('Discount Value (NPR)', icon: const Icon(Icons.price_change_outlined, size: 18)),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
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
                                  _buildInvoiceRow('ITEMS SUBTOTAL', 'NPR ${_subtotal.toStringAsFixed(0)}'),
                                  const SizedBox(height: 8),
                                  _buildInvoiceRow('EXTRA CHARGES', 'NPR ${_extraChargesTotal.toStringAsFixed(0)}'),
                                  const SizedBox(height: 8),
                                  _buildInvoiceRow('PROMOTIONAL DISCOUNT', '- NPR ${_discountAmount.toStringAsFixed(0)}', isDiscount: true),
                                  Divider(height: 20, thickness: 0.6, color: AppColors.border.withValues(alpha: 0.8)),
                                  _buildInvoiceRow(
                                    'FINAL TOTAL VALUE',
                                    'NPR ${_finalTotal.toStringAsFixed(0)}',
                                    isGrandTotal: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Dialog buttons row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.border,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          _cancelInlineForm();
                                          dialogNavigator.pop();
                                        },
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
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
                                      horizontal: 22,
                                      vertical: 14,
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _isSaving
                                      ? null
                                      : () async {
                                          await _saveLink();
                                          if (!mounted) return;
                                          if (!_showInlineForm) {
                                            dialogNavigator.pop();
                                          } else {
                                            setDialogState(() {});
                                          }
                                        },
                                  icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                                  label: Text(
                                    _isSaving ? 'Saving...' : 'Save Link',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
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
    if (_showInlineForm) {
      _cancelInlineForm();
    }
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

  void _openEdit(CheckoutLink link) {
    setState(() {
      _showInlineForm = true;
      _editingLinkId = link.linkId;
      _isSaving = false;
      _productSearchController.clear();
      _discountCodeController.text = link.financials.discount?.type.name == 'fixed'
          ? 'FLAT'
          : '';
      _discountAmountController.text =
          link.financials.discountAmount.toStringAsFixed(0);
      _selectedItems
        ..clear()
        ..addAll(
          link.items.map(
            (CheckoutLinkItem item) => _SelectedCheckoutItem(
              productId: item.productId,
              productName: item.productName,
              variantId: item.variantId,
              variantName: item.variantName,
              qty: item.quantity,
              unitPrice: item.unitPrice,
            ),
          ),
        );
      for (final _ChargeRow row in _charges) {
        row.dispose();
      }
      _charges
        ..clear()
        ..addAll(
          (link.financials.extraCharges.isEmpty
                  ? <CheckoutExtraCharge>[
                      CheckoutExtraCharge(name: 'Delivery', amount: 0),
                    ]
                  : link.financials.extraCharges)
              .map(
                (CheckoutExtraCharge charge) => _ChargeRow(
                  name: TextEditingController(text: charge.name),
                  amount: TextEditingController(text: charge.amount.toStringAsFixed(0)),
                ),
              ),
        );
    });
  }

  void _cancelInlineForm() {
    setState(() {
      _showInlineForm = false;
      _editingLinkId = null;
      _isSaving = false;
    });
  }

  void _addSelectedItem(Product product) {
    final ProductVariant variant = product.variants.first;
    setState(() {
      _selectedItems.add(
        _SelectedCheckoutItem(
          productId: product.id,
          productName: product.name,
          variantId: variant.variantId,
          variantName: _variantLabel(variant),
          qty: 1,
          unitPrice: variant.price,
        ),
      );
      _productSearchController.clear();
    });
  }

  void _addCharge() {
    setState(() {
      _charges.add(
        _ChargeRow(
          name: TextEditingController(),
          amount: TextEditingController(text: '0'),
        ),
      );
    });
  }

  Future<void> _saveLink() async {
    if (_selectedItems.isEmpty) {
      _showMessage('Add at least one product item.');
      return;
    }

    setState(() => _isSaving = true);

    if (_editingLinkId == null) {
      await _repository.generateLink(
        storeId: 'store_001',
        items: _selectedItems
            .map(
              (_SelectedCheckoutItem item) => CheckoutLinkItem(
                productId: item.productId,
                variantId: item.variantId,
                productName: item.productName,
                variantName: item.variantName,
                quantity: item.qty,
                unitPrice: item.unitPrice,
              ),
            )
            .toList(),
        extraChargeName: _charges.isEmpty ? 'Extra Charge' : _charges.first.name.text.trim(),
        extraChargeAmount: _extraChargesTotal.toStringAsFixed(0),
        discount: _discountAmount.toStringAsFixed(0),
        currentHistoryCount: _links.length,
        createdAt: DateTime.now(),
      );
    } else {
      final CheckoutLink updated = CheckoutLink(
        linkId: _editingLinkId!,
        merchantId: 'store_001',
        items: _selectedItems
            .map(
              (_SelectedCheckoutItem item) => CheckoutLinkItem(
                productId: item.productId,
                variantId: item.variantId,
                productName: item.productName,
                variantName: item.variantName,
                quantity: item.qty,
                unitPrice: item.unitPrice,
              ),
            )
            .toList(),
        financials: CheckoutFinancials(
          subtotal: _subtotal,
          shippingFee: _extraChargesTotal,
          discountAmount: _discountAmount,
          totalAmount: _finalTotal,
          extraCharges: _charges
              .where((row) => row.name.text.trim().isNotEmpty)
              .map(
                (_ChargeRow row) => CheckoutExtraCharge(
                  name: row.name.text.trim(),
                  amount: num.tryParse(row.amount.text.trim()) ?? 0,
                ),
              )
              .toList(),
          discount: _discountAmount > 0
              ? CheckoutDiscount(
                  type: CheckoutDiscountType.fixed,
                  amountDeducted: _discountAmount,
                )
              : null,
        ),
        status: CheckoutLinkStatus.active,
        createdAt: DateTime.now(),
      );
      await _repository.saveLink(updated);
    }

    await _loadData();
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _showInlineForm = false;
      _editingLinkId = null;
    });
    _showMessage('Checkout link saved.');
  }

  Future<void> _confirmDelete(CheckoutLink link) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Checkout Link'),
          content: Text('Delete link ${link.linkId}?'),
          actions: [
            OutlinedButton(
              style: outlinedStyle(),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: blackButtonStyle(),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _repository.deleteLink(link.linkId);
      await _loadData();
      if (!mounted) return;
      _showMessage('Checkout link deleted.');
    }
  }

  void _openDetails(CheckoutLink link) {
    final String checkoutUrl = _checkoutLinkUrl(link);
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Checkout Link ${link.linkId}'),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${_statusLabel(link.status)}'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          'Link: $checkoutUrl',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: outlinedStyle(),
                        onPressed: () => _copyCheckoutLink(link),
                        icon: const Icon(Feather.copy, size: 16),
                        label: const Text('Copy Link'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Subtotal: NPR ${link.financials.subtotal.toStringAsFixed(0)}'),
                  Text('Extra Charges: NPR ${link.financials.shippingFee.toStringAsFixed(0)}'),
                  Text('Discount: NPR ${link.financials.discountAmount.toStringAsFixed(0)}'),
                  Text('Total: NPR ${link.financials.totalAmount.toStringAsFixed(0)}'),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Variant')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Unit Price')),
                      ],
                      rows: link.items
                          .map(
                            (CheckoutLinkItem item) => DataRow(
                              cells: [
                                DataCell(Text(item.productName)),
                                DataCell(Text(item.variantName)),
                                DataCell(Text('${item.quantity}')),
                                DataCell(Text('NPR ${item.unitPrice.toStringAsFixed(0)}')),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              style: outlinedStyle(),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(CheckoutLinkStatus status) {
    switch (status) {
      case CheckoutLinkStatus.active:
        return 'Active';
      case CheckoutLinkStatus.completed:
        return 'Completed';
      case CheckoutLinkStatus.converted:
        return 'Converted';
      case CheckoutLinkStatus.expired:
        return 'Expired';
    }
  }

  String _itemsSummary(List<CheckoutLinkItem> items) {
    if (items.isEmpty) return 'No items';
    final CheckoutLinkItem first = items.first;
    return items.length == 1
        ? '${first.productName} x${first.quantity}'
        : '${first.productName} x${first.quantity} + ${items.length - 1} more';
  }

  String _variantLabel(ProductVariant variant) {
    if (variant.options.isEmpty) return 'Default';
    return variant.options.values.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final List<CheckoutLink> rows = _filteredLinks;

    Widget filters() {
      final List<String> options = <String>[
        'All',
        'Active',
        'Completed',
        'Converted',
        'Expired',
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
            final bool isSelected = _statusFilter == option;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _statusFilter = option),
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
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
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
          // Premium modern header block
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.link_rounded,
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
                      'Smart Checkout Links',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generate and manage instant payment checkout links',
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

          // Search, filter switcher, export, and create row layout
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double screenWidth = constraints.maxWidth;

              final Widget searchField = SizedBox(
                height: 44,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  decoration: inputDecoration('Search by link ID or item name').copyWith(
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              );

              final Widget exportButton = PopupMenuButton<ExportFormat>(
                tooltip: 'Export',
                onSelected: (ExportFormat format) => _exportCheckoutLinks(format, rows),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      const Icon(Icons.download_rounded, size: 16, color: AppColors.textPrimary),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 0,
                  ),
                  onPressed: _openCreateDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Generate Link',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              );

              // 📱 Mobile Stack (width < 600) — Individual rows to completely eliminate overflows
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

              // 📟 Tablet Stack (600 <= width < 960) — Compact double rows
              if (screenWidth < 960) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 320, child: filters()),
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

              // 🖥️ Desktop Row (width >= 960) — Single line alignment
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
          if (_showInlineForm) ...[
            const SizedBox(height: 20),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.border, width: 1.2),
                    borderRadius: kRadiusMedium,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _editingLinkId == null ? Icons.add_link_rounded : Icons.edit_road_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _editingLinkId == null ? 'Generate Checkout Link' : 'Edit Checkout Link',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _productSearchController,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: inputDecoration('Search product to add').copyWith(
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        ),
                      ),
                      if (_matchedProducts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border, width: 1.2),
                            borderRadius: kRadiusSmall,
                            color: AppColors.white,
                          ),
                          child: Column(
                            children: _matchedProducts
                                .map(
                                  (Product product) => ListTile(
                                    dense: true,
                                    title: Text(
                                      product.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onTap: () => _addSelectedItem(product),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ..._selectedItems.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final _SelectedCheckoutItem item = entry.value;
                        final Product? product = _products
                            .where((Product p) => p.id == item.productId)
                            .firstOrNull;
                        final List<ProductVariant> variants =
                            product?.variants ?? const <ProductVariant>[];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border, width: 1),
                            borderRadius: kRadiusSmall,
                            color: AppColors.offWhite,
                          ),
                          child: LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints itemConstraints) {
                              final double blockWidth = itemConstraints.maxWidth;

                              final Widget prodLabel = Expanded(
                                flex: 3,
                                child: Text(
                                  item.productName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              );

                              final Widget varDropdown = SizedBox(
                                width: blockWidth < 500 ? double.infinity : 180,
                                child: DropdownButtonFormField<String>(
                                  initialValue: item.variantId,
                                  decoration: inputDecoration('Variant'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: variants
                                      .map(
                                        (ProductVariant variant) => DropdownMenuItem<String>(
                                          value: variant.variantId,
                                          child: Text(
                                            _variantLabel(variant),
                                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (String? value) {
                                    if (value == null) return;
                                    final ProductVariant selected = variants.firstWhere(
                                      (ProductVariant v) => v.variantId == value,
                                    );
                                    setState(() {
                                      item.variantId = selected.variantId;
                                      item.variantName = _variantLabel(selected);
                                      item.unitPrice = selected.price;
                                    });
                                  },
                                ),
                              );

                              final Widget qtyControl = Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border, width: 1),
                                  borderRadius: kRadiusSmall,
                                  color: AppColors.white,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          item.qty = item.qty > 1 ? item.qty - 1 : 1;
                                        });
                                      },
                                      icon: const Icon(Icons.remove, size: 14),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Text(
                                      '${item.qty}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setState(() => item.qty++),
                                      icon: const Icon(Icons.add, size: 14),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              );

                              final Widget rowPrice = Text(
                                'NPR ${item.unitPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              );

                              final Widget deleteButton = IconButton(
                                onPressed: () => setState(() => _selectedItems.removeAt(index)),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rtoText),
                              );

                              if (blockWidth < 500) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    varDropdown,
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        qtyControl,
                                        rowPrice,
                                        deleteButton,
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  prodLabel,
                                  const SizedBox(width: 12),
                                  varDropdown,
                                  const SizedBox(width: 12),
                                  qtyControl,
                                  const SizedBox(width: 16),
                                  rowPrice,
                                  const SizedBox(width: 8),
                                  deleteButton,
                                ],
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Extra Charges',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onPressed: _addCharge,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(
                              'Add Charge',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._charges.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final _ChargeRow charge = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints chargeConstraints) {
                              final double chargeWidth = chargeConstraints.maxWidth;

                              final Widget nameField = Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: charge.name,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                  decoration: inputDecoration('Charge Name'),
                                ),
                              );

                              final Widget amountField = SizedBox(
                                width: chargeWidth < 500 ? double.infinity : 180,
                                child: TextField(
                                  controller: charge.amount,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                  decoration: inputDecoration('Amount'),
                                ),
                              );

                              final Widget trashBtn = IconButton(
                                onPressed: () {
                                  final _ChargeRow removed = _charges.removeAt(index);
                                  removed.dispose();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rtoText),
                              );

                              if (chargeWidth < 500) {
                                return Column(
                                  children: [
                                    TextField(
                                      controller: charge.name,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: inputDecoration('Charge Name'),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(child: amountField),
                                        const SizedBox(width: 8),
                                        trashBtn,
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  nameField,
                                  const SizedBox(width: 12),
                                  amountField,
                                  const SizedBox(width: 8),
                                  trashBtn,
                                ],
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Discount',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints discConstraints) {
                          final double discWidth = discConstraints.maxWidth;

                          final Widget codeField = Expanded(
                            child: TextField(
                              controller: _discountCodeController,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: inputDecoration('Discount Code'),
                            ),
                          );

                          final Widget discAmtField = SizedBox(
                            width: discWidth < 500 ? double.infinity : 180,
                            child: TextField(
                              controller: _discountAmountController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                              decoration: inputDecoration('Amount'),
                            ),
                          );

                          if (discWidth < 500) {
                            return Column(
                              children: [
                                TextField(
                                  controller: _discountCodeController,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                                  decoration: inputDecoration('Discount Code'),
                                ),
                                const SizedBox(height: 8),
                                discAmtField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              codeField,
                              const SizedBox(width: 12),
                              discAmtField,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.offWhite,
                          border: Border.all(color: AppColors.border, width: 1.2),
                          borderRadius: kRadiusSmall,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'NPR ${_subtotal.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Extra Charges',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'NPR ${_extraChargesTotal.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Discount Applied',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '-NPR ${_discountAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.rtoText, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Final Total',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.black, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'NPR ${_finalTotal.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                            onPressed: _isSaving ? null : _cancelInlineForm,
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              elevation: 0,
                            ),
                            onPressed: _isSaving ? null : _saveLink,
                            icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Link',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                child: _CheckoutLinksTable(
                  links: rows,
                  statusLabel: _statusLabel,
                  itemsSummary: _itemsSummary,
                  onView: _openDetails,
                  onEdit: _openEditDialog,
                  onDelete: _confirmDelete,
                  onCopy: _copyCheckoutLink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutLinksTable extends StatelessWidget {
  const _CheckoutLinksTable({
    required this.links,
    required this.statusLabel,
    required this.itemsSummary,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onCopy,
  });

  final List<CheckoutLink> links;
  final String Function(CheckoutLinkStatus) statusLabel;
  final String Function(List<CheckoutLinkItem>) itemsSummary;
  final ValueChanged<CheckoutLink> onView;
  final ValueChanged<CheckoutLink> onEdit;
  final ValueChanged<CheckoutLink> onDelete;
  final ValueChanged<CheckoutLink> onCopy;

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
                        'Link ID',
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
                        'Subtotal',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Final Total',
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
                  rows: links.asMap().entries.map((entry) {
                    final int rowIndex = entry.key;
                    final CheckoutLink link = entry.value;

                    // Colored status configuration matching Stripe/Linear style
                    final String label = statusLabel(link.status);
                    final Color labelColor;
                    final Color badgeBg;

                    switch (label) {
                      case 'Active':
                        labelColor = AppColors.accentBlue;
                        badgeBg = AppColors.accentBlueLight;
                        break;
                      case 'Completed':
                      case 'Converted':
                        labelColor = AppColors.deliveredText;
                        badgeBg = AppColors.deliveredBg;
                        break;
                      case 'Expired':
                        labelColor = AppColors.rtoText;
                        badgeBg = AppColors.rtoBg;
                        break;
                      default:
                        labelColor = AppColors.textSecondary;
                        badgeBg = AppColors.offWhite;
                        break;
                    }

                    return DataRow(
                      color: WidgetStateProperty.all(
                        rowIndex.isEven ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
                      ),
                      cells: [
                        DataCell(
                          Text(
                            link.linkId,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              itemsSummary(link.items),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text('NPR ${link.financials.subtotal.toStringAsFixed(0)}'),
                        ),
                        DataCell(
                          Text(
                            'NPR ${link.financials.totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(
                          Container(
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
                                  label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: labelColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 170,
                            child: Row(
                              children: [
                                _ActionButton(
                                  icon: Icons.visibility_outlined,
                                  iconColor: AppColors.primary,
                                  bgColor: AppColors.primary.withValues(alpha: 0.08),
                                  tooltip: 'View details',
                                  onTap: () => onView(link),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  icon: Icons.edit_rounded,
                                  iconColor: AppColors.accentBlue,
                                  bgColor: AppColors.accentBlueLight,
                                  tooltip: 'Edit link',
                                  onTap: () => onEdit(link),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  icon: Icons.copy_rounded,
                                  iconColor: Colors.purple,
                                  bgColor: Colors.purple.withValues(alpha: 0.08),
                                  tooltip: 'Copy link',
                                  onTap: () => onCopy(link),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  icon: Icons.delete_outline_rounded,
                                  iconColor: AppColors.rtoText,
                                  bgColor: AppColors.rtoBg,
                                  tooltip: 'Delete link',
                                  onTap: () => onDelete(link),
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

class _SelectedCheckoutItem {
  _SelectedCheckoutItem({
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
  });

  final String productId;
  final String productName;
  String variantId;
  String variantName;
  int qty;
  num unitPrice;
}

class _ChargeRow {
  _ChargeRow({required this.name, required this.amount});

  final TextEditingController name;
  final TextEditingController amount;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
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
