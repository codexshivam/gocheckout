import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/schema/product_models.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/service_locator.dart';
import '../common/app_styles.dart';
import '../theme/app_colors.dart';
import '../utils/table_exporter.dart';

class ProductsView extends StatefulWidget {
  const ProductsView({super.key});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  final ProductsRepository _repository = ServiceLocator.instance.productsRepository;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _basePriceController = TextEditingController();
  final TextEditingController _attributeNameController = TextEditingController();
  final TextEditingController _attributeValuesController = TextEditingController();

  final List<_VariantDraft> _variantDrafts = <_VariantDraft>[];

  List<Product> _products = const <Product>[];
  String _stockFilter = 'All';
  String? _editingProductId;
  bool _showInlineForm = false;
  bool _showVariations = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _attributeNameController.dispose();
    _attributeValuesController.dispose();
    for (final _VariantDraft draft in _variantDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final List<Product> products = await _repository.fetchProducts();
    if (!mounted) return;
    setState(() => _products = products);
  }

  List<Product> get _filteredProducts {
    final String query = _searchController.text.trim().toLowerCase();
    return _products.where((Product product) {
      final int stock = product.variants.fold<int>(
        0,
        (int sum, ProductVariant v) => sum + v.inventoryCount,
      );
      final bool matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.id.toLowerCase().contains(query);
      final bool matchesFilter =
          _stockFilter == 'All' ||
          (_stockFilter == 'In Stock' && stock > 0) ||
          (_stockFilter == 'Out of Stock' && stock <= 0);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void _openCreate() {
    setState(() {
      _showInlineForm = true;
      _editingProductId = null;
      _isSaving = false;
      _showVariations = false;
      _nameController.clear();
      _descriptionController.clear();
      _basePriceController.clear();
      _attributeNameController.clear();
      _attributeValuesController.clear();
      for (final _VariantDraft draft in _variantDrafts) {
        draft.dispose();
      }
      _variantDrafts.clear();
    });
  }

  Future<void> _exportProducts(ExportFormat format, List<Product> rows) async {
    final List<List<String>> exportRows = rows.map((product) {
      final int stock = product.variants.fold<int>(
        0,
        (int sum, ProductVariant v) => sum + v.inventoryCount,
      );
      return <String>[
        product.id,
        product.name,
        product.basePrice.toStringAsFixed(0),
        product.variants.length.toString(),
        stock.toString(),
        stock > 0 ? 'In Stock' : 'Out of Stock',
      ];
    }).toList();

    final bool ok = await exportTabularData(
      baseFileName: 'products_${DateTime.now().toIso8601String().split('T').first}',
      headers: const <String>[
        'Product ID',
        'Product Name',
        'Base Price (NPR)',
        'Variants',
        'Stock',
        'Status',
      ],
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

  Future<void> _openCreateDialog() async {
    _openCreate();
    await _showProductFormDialog();
  }

  Future<void> _openEditDialog(Product product) async {
    _openEdit(product);
    await _showProductFormDialog();
  }

  Future<void> _showProductFormDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final NavigatorState dialogNavigator = Navigator.of(dialogContext);
        final Size size = MediaQuery.of(dialogContext).size;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final double dialogWidth = size.width * 0.84;
            final bool isDialogCompact = dialogWidth < 540;

            return Dialog(
              backgroundColor: AppColors.offWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
                vertical: size.height * 0.06,
              ),
              child: SizedBox(
                width: dialogWidth,
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
                              Icons.add_business_rounded,
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
                                _editingProductId == null ? 'Create Store Product' : 'Edit Store Product',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _editingProductId == null
                                    ? 'Launch a new retail product with custom prices, descriptions, and dynamic variations'
                                    : 'Modify retail parameters, variants, pricing structure, or store inventories',
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
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card 1: Basic details
                            _buildSectionCard(
                              title: 'Product Basic Details',
                              icon: Icons.info_outline_rounded,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _nameController,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                                    decoration: inputDecoration('Product Name', icon: const Icon(Icons.shopping_bag_outlined, size: 18)),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _descriptionController,
                                    maxLines: 2,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                                    decoration: inputDecoration('Product Description', icon: const Icon(Icons.description_outlined, size: 18)),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _basePriceController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                                    decoration: inputDecoration('Base Price (NPR)', icon: const Icon(Icons.sell_outlined, size: 18)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Card 2: Variations
                            _buildSectionCard(
                              title: 'Product Variations',
                              icon: Icons.alt_route_rounded,
                              action: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _showVariations ? Colors.redAccent : AppColors.primary,
                                    width: 1.2,
                                  ),
                                  backgroundColor: _showVariations
                                      ? Colors.redAccent.withValues(alpha: 0.05)
                                      : AppColors.primary.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    _showVariations = !_showVariations;
                                    if (!_showVariations) {
                                      _attributeNameController.clear();
                                      _attributeValuesController.clear();
                                      for (final _VariantDraft draft in _variantDrafts) {
                                        draft.dispose();
                                      }
                                      _variantDrafts.clear();
                                    }
                                  });
                                },
                                icon: Icon(
                                  _showVariations ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                                  size: 16,
                                  color: _showVariations ? Colors.redAccent : AppColors.primary,
                                ),
                                label: Text(
                                  _showVariations ? 'Remove Variations' : 'Add Variations',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: _showVariations ? Colors.redAccent : AppColors.primary,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!_showVariations)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'This product has no variations. Click "Add Variations" if sizes/colors are needed.',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else ...[
                                    // Variation input fields
                                    LayoutBuilder(
                                      builder: (context, inputConstraints) {
                                        final bool stackInputs = inputConstraints.maxWidth < 500;
                                        final Widget attrName = TextField(
                                          controller: _attributeNameController,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                                          decoration: inputDecoration('Attribute Name (e.g. Size, Color)', icon: const Icon(Icons.style_rounded, size: 18)),
                                        );

                                        final Widget attrVal = TextField(
                                          controller: _attributeValuesController,
                                          onChanged: (_) {
                                            _rebuildVariantDraftsFromAttributeValues();
                                            setDialogState(() {});
                                          },
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                                          decoration: inputDecoration('Values (comma separated, e.g. S, M, L)', icon: const Icon(Icons.list_alt_rounded, size: 18)),
                                        );

                                        if (stackInputs) {
                                          return Column(
                                            children: [
                                              attrName,
                                              const SizedBox(height: 12),
                                              attrVal,
                                            ],
                                          );
                                        }

                                        return Row(
                                          children: [
                                            Expanded(child: attrName),
                                            const SizedBox(width: 16),
                                            Expanded(child: attrVal),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    ListView.builder(
                                      itemCount: _variantDrafts.length,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final _VariantDraft draft = _variantDrafts[index];
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.offWhite,
                                            border: Border.all(color: AppColors.border, width: 1.2),
                                            borderRadius: kRadiusMedium,
                                          ),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final bool stackVariant = constraints.maxWidth < 620;
                                              final Widget imageContainer = InkWell(
                                                onTap: () {
                                                  setDialogState(
                                                    () => draft.imageUrl = 'variant_${index + 1}.png',
                                                  );
                                                },
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: draft.imageUrl.isEmpty ? AppColors.white : AppColors.primaryLight,
                                                    border: Border.all(
                                                      color: draft.imageUrl.isEmpty ? AppColors.border : AppColors.primary,
                                                      width: 1.2,
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    draft.imageUrl.isEmpty ? Icons.add_photo_alternate_rounded : Icons.image_rounded,
                                                    size: 18,
                                                    color: draft.imageUrl.isEmpty ? AppColors.textSecondary : AppColors.primary,
                                                  ),
                                                ),
                                              );

                                              final Widget labelText = SizedBox(
                                                width: stackVariant ? double.infinity : 100,
                                                child: Text(
                                                  draft.label,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13.5,
                                                    color: AppColors.black,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );

                                              final Widget priceInput = SizedBox(
                                                width: stackVariant ? double.infinity : 150,
                                                child: TextField(
                                                  controller: draft.price,
                                                  keyboardType: TextInputType.number,
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                                                  decoration: inputDecoration('Price (NPR)'),
                                                ),
                                              );

                                              final Widget inventoryInput = SizedBox(
                                                width: stackVariant ? double.infinity : 150,
                                                child: TextField(
                                                  controller: draft.inventory,
                                                  keyboardType: TextInputType.number,
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                                                  decoration: inputDecoration('Inventory Count'),
                                                ),
                                              );

                                              final Widget deleteButton = IconButton(
                                                onPressed: () {
                                                  final _VariantDraft removed = _variantDrafts.removeAt(index);
                                                  removed.dispose();
                                                  setDialogState(() {});
                                                },
                                                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                              );

                                              if (stackVariant) {
                                                return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            imageContainer,
                                                            const SizedBox(width: 12),
                                                            labelText,
                                                          ],
                                                        ),
                                                        deleteButton,
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    priceInput,
                                                    const SizedBox(height: 8),
                                                    inventoryInput,
                                                  ],
                                                );
                                              }

                                              return Row(
                                                children: [
                                                  imageContainer,
                                                  const SizedBox(width: 16),
                                                  labelText,
                                                  const Spacer(),
                                                  priceInput,
                                                  const SizedBox(width: 12),
                                                  inventoryInput,
                                                  const SizedBox(width: 12),
                                                  deleteButton,
                                                ],
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Footer actions inside the scroll content to ensure perfect fit
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.border, width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isDialogCompact ? 14 : 20,
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
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isDialogCompact ? 16 : 24,
                                      vertical: 14,
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _isSaving
                                      ? null
                                      : () async {
                                          await _saveProduct();
                                          if (!mounted) return;
                                          if (!_showInlineForm) {
                                            dialogNavigator.pop();
                                          } else {
                                            setDialogState(() {});
                                          }
                                        },
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2),
                                        )
                                      : const Icon(Icons.bookmark_added_rounded, size: 16),
                                  label: Text(
                                    _isSaving ? 'Saving...' : 'Save Product',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
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

  void _openEdit(Product product) {
    setState(() {
      _showInlineForm = true;
      _editingProductId = product.id;
      _isSaving = false;
      _showVariations = product.attributes.isNotEmpty;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _basePriceController.text = product.basePrice.toStringAsFixed(0);
      _attributeNameController.text =
          product.attributes.isEmpty ? '' : product.attributes.first;
      _attributeValuesController.text = product.variants
          .map((ProductVariant variant) {
            if (variant.options.isEmpty) return 'Default';
            return variant.options.values.join(' / ');
          })
          .join(', ');
      for (final _VariantDraft draft in _variantDrafts) {
        draft.dispose();
      }
      _variantDrafts
        ..clear()
        ..addAll(
          product.variants.map((ProductVariant variant) {
            final String label = variant.options.isEmpty
                ? 'Default'
                : variant.options.values.join(' / ');
            return _VariantDraft(
              label: label,
              price: TextEditingController(text: variant.price.toStringAsFixed(0)),
              inventory: TextEditingController(
                text: variant.inventoryCount.toString(),
              ),
              imageUrl: variant.imageUrl,
            );
          }),
        );
    });
  }

  void _cancelInlineForm() {
    setState(() {
      _showInlineForm = false;
      _isSaving = false;
      _editingProductId = null;
      _showVariations = false;
    });
  }

  void _rebuildVariantDraftsFromAttributeValues() {
    final String valuesRaw = _attributeValuesController.text.trim();
    final int basePrice = int.tryParse(_basePriceController.text.trim()) ?? 0;

    for (final _VariantDraft draft in _variantDrafts) {
      draft.dispose();
    }
    _variantDrafts.clear();

    if (valuesRaw.isEmpty) {
      setState(() {});
      return;
    }

    final List<String> values = valuesRaw
        .split(',')
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toSet()
        .toList();

    _variantDrafts.addAll(
      values.map(
        (String value) => _VariantDraft(
          label: value,
          price: TextEditingController(text: '$basePrice'),
          inventory: TextEditingController(text: '0'),
        ),
      ),
    );

    setState(() {});
  }

  Future<void> _saveProduct() async {
    final String name = _nameController.text.trim();
    final String description = _descriptionController.text.trim();
    final num? basePrice = num.tryParse(_basePriceController.text.trim());

    if (name.isEmpty || description.isEmpty || basePrice == null || basePrice < 0) {
      _showMessage('Please fill valid product details.');
      return;
    }

    final List<ProductVariant> variants;
    if (_showVariations && _variantDrafts.isNotEmpty) {
      final String attributeName = _attributeNameController.text.trim();
      if (attributeName.isEmpty) {
        _showMessage('Attribute name is required when using variations.');
        return;
      }

      variants = <ProductVariant>[];
      for (int index = 0; index < _variantDrafts.length; index++) {
        final _VariantDraft draft = _variantDrafts[index];
        final num? variantPrice = num.tryParse(draft.price.text.trim());
        final int? inventory = int.tryParse(draft.inventory.text.trim());
        if (variantPrice == null || inventory == null || inventory < 0) {
          _showMessage('Each variant must have valid price and inventory count.');
          return;
        }

        final String variantId =
            'v_${(_editingProductId ?? 'new').replaceAll('prod_', '')}_${index + 1}';
        variants.add(
          ProductVariant(
            variantId: variantId,
            options: <String, String>{attributeName: draft.label},
            price: variantPrice,
            inventoryCount: inventory,
            isInventoryTracked: true,
            imageUrl: draft.imageUrl,
          ),
        );
      }
    } else {
      variants = <ProductVariant>[
        ProductVariant(
          variantId: 'v_default',
          options: const <String, String>{'Type': 'Default'},
          price: basePrice,
          inventoryCount: 0,
          isInventoryTracked: true,
          imageUrl: '',
        ),
      ];
    }

    final Product next = Product(
      id: _editingProductId ?? 'prod_${DateTime.now().millisecondsSinceEpoch % 100000}',
      merchantId: 'store_001',
      name: name,
      description: description,
      basePrice: basePrice,
      attributes: _showVariations && _attributeNameController.text.trim().isNotEmpty
          ? <String>[_attributeNameController.text.trim()]
          : const <String>[],
      variants: variants,
    );

    setState(() => _isSaving = true);
    await _repository.saveProduct(next);
    await _loadProducts();
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _showInlineForm = false;
      _editingProductId = null;
    });
    _showMessage('Product saved successfully.');
  }

  Future<void> _confirmDelete(Product product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Product',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.black),
          ),
          content: Text(
            'Are you sure you want to delete ${product.name}?\nThis action is permanent and cannot be undone.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: AppColors.textSecondary, fontSize: 13.5),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _repository.deleteProduct(product.id);
      await _loadProducts();
      if (!mounted) return;
      _showMessage('Product deleted.');
    }
  }

  void _openDetails(Product product) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  product.name,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.black),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRODUCT METADATA',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Product ID: ',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                            Text(
                              product.id,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Base Price: ',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                            Text(
                              'NPR ${product.basePrice.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DESCRIPTION',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AVAILABLE CONFIGURATIONS',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border, width: 1.2),
                      borderRadius: kRadiusMedium,
                    ),
                    child: ClipRRect(
                      borderRadius: kRadiusMedium,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          columns: [
                            DataColumn(
                              label: Text(
                                'Variant Option',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Variant Price',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Inventory Track',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                          rows: product.variants.map((ProductVariant variant) {
                            final String label = variant.options.isEmpty
                                ? 'Default'
                                : variant.options.values.join(' / ');
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    label,
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.black),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    'NPR ${variant.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.textPrimary),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: variant.inventoryCount > 0 ? AppColors.deliveredBg : AppColors.rtoBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${variant.inventoryCount} units',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        color: variant.inventoryCount > 0 ? AppColors.deliveredText : AppColors.rtoText,
                                      ),
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
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close Details',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> rows = _filteredProducts;

    Widget filters() {
      final List<String> options = <String>['All', 'In Stock', 'Out of Stock'];
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
            final bool isSelected = _stockFilter == option;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _stockFilter = option),
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
                      fontSize: 12,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
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
                      'Store Products',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage catalogue inventory and variations',
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
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double screenWidth = constraints.maxWidth;
              
              final Widget searchField = SizedBox(
                height: 44,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                  decoration: inputDecoration('Search by product name or ID').copyWith(
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              );

              final Widget exportButton = PopupMenuButton<ExportFormat>(
                tooltip: 'Export',
                onSelected: (ExportFormat format) => _exportProducts(format, rows),
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
                    'Create Product',
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
                child: _ProductsTable(
                  products: rows,
                  onView: _openDetails,
                  onEdit: _openEditDialog,
                  onDelete: _confirmDelete,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({
    required this.products,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Product> products;
  final ValueChanged<Product> onView;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;

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
                        'Product',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Base Price',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Variants',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Stock',
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
                  rows: products.map((Product product) {
                    final int stock = product.variants.fold<int>(
                      0,
                      (int sum, ProductVariant v) => sum + v.inventoryCount,
                    );
                    final bool inStock = stock > 0;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            product.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            'NPR ${product.basePrice.toStringAsFixed(0)}',
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
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${product.variants.length} types',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '$stock units',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: inStock ? AppColors.textPrimary : Colors.redAccent,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: inStock ? AppColors.deliveredBg : AppColors.rtoBg,
                            ),
                            child: Text(
                              inStock ? 'In Stock' : 'Out of Stock',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: inStock ? AppColors.deliveredText : AppColors.rtoText,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionButton(
                                icon: Icons.visibility_outlined,
                                iconColor: AppColors.accentBlue,
                                bgColor: AppColors.accentBlueLight,
                                tooltip: 'View details',
                                onTap: () => onView(product),
                              ),
                              const SizedBox(width: 8),
                              _ActionButton(
                                icon: Icons.edit_outlined,
                                iconColor: AppColors.primary,
                                bgColor: AppColors.primaryLight,
                                tooltip: 'Edit product',
                                onTap: () => onEdit(product),
                              ),
                              const SizedBox(width: 8),
                              _ActionButton(
                                icon: Icons.delete_outline_rounded,
                                iconColor: Colors.redAccent,
                                bgColor: const Color(0xFFFFF1F2),
                                tooltip: 'Delete product',
                                onTap: () => onDelete(product),
                              ),
                            ],
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

class _VariantDraft {
  _VariantDraft({
    required this.label,
    required this.price,
    required this.inventory,
    this.imageUrl = '',
  });

  final String label;
  final TextEditingController price;
  final TextEditingController inventory;
  String imageUrl;

  void dispose() {
    price.dispose();
    inventory.dispose();
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
      textStyle: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(6)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 34,
            height: 34,
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
