import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../data/models/schema/coupon_models.dart';
import '../../../data/repositories/coupons_repository.dart';
import '../../common/app_styles.dart';
import '../../theme/app_colors.dart';
import '../../utils/table_exporter.dart';
import 'coupons_dialogs.dart';
import 'coupons_logic.dart';
import 'coupons_widgets.dart';

class CouponsView extends StatefulWidget {
  const CouponsView({
    super.key,
    this.repository,
  });

  final CouponsRepository? repository;

  @override
  State<CouponsView> createState() => _CouponsViewState();
}

class _CouponsViewState extends State<CouponsView> with CouponsLogic {
  Future<void> _exportCoupons(ExportFormat format, List<Coupon> rows) async {
    final List<List<String>> exportRows = rows.map((coupon) {
      final String type = coupon.discountType == CouponDiscountType.flat
          ? 'Flat'
          : 'Percentage';
      final String discount = coupon.discountType == CouponDiscountType.flat
          ? coupon.discountValue.toStringAsFixed(0)
          : '${coupon.discountValue.toStringAsFixed(0)}%';
      final String usage =
          '${coupon.usageTracker.currentUsageCount}/${coupon.usageTracker.maxUsageLimit}';
      return <String>[
        coupon.code,
        type,
        discount,
        usage,
        coupon.allowedCustomerPhone ?? 'All customers',
        couponStatus(coupon),
      ];
    }).toList();

    final bool ok = await exportTabularData(
      baseFileName: 'coupons_${DateTime.now().toIso8601String().split('T').first}',
      headers: const <String>['Code', 'Type', 'Discount', 'Usage', 'Scope', 'Status'],
      rows: exportRows,
      format: format,
    );

    if (!mounted) return;
    showSnack(
      ok
          ? '${format.label} export downloaded.'
          : '${format.label} export is available on web builds.',
    );
  }

  Future<void> _openCreateDialog() async {
    openCreate();
    await _showCouponFormDialog();
  }

  Future<void> _openEditDialog(Coupon coupon) async {
    openEdit(coupon);
    await _showCouponFormDialog();
  }

  Future<void> _showCouponFormDialog() async {
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
                              Icons.confirmation_num_rounded,
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
                                editingCouponId == null ? 'Create Store Coupon' : 'Edit Store Coupon',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                editingCouponId == null
                                    ? 'Configure a new dynamic, flat, or percentage-based coupon code'
                                    : 'Modify usage policies, active duration, or eligibility thresholds',
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
                              cancelInlineCreate();
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
                            CouponFormFields(
                              codeController: codeController,
                              discountValueController: discountValueController,
                              maxUsageController: maxUsageController,
                              allowedPhoneController: allowedPhoneController,
                              minOrderAmountController: minOrderAmountController,
                              maxDiscountAmountController: maxDiscountAmountController,
                              startsAtController: startsAtController,
                              endsAtController: endsAtController,
                              perCustomerLimitController: perCustomerLimitController,
                              selectedType: selectedType,
                              selectedLifecycleStatus: selectedLifecycleStatus,
                              onTypeChanged: (CouponDiscountType type) {
                                setDialogState(() => selectedType = type);
                              },
                              onLifecycleStatusChanged: (CouponLifecycleStatus status) {
                                setDialogState(() => selectedLifecycleStatus = status);
                              },
                              onPickStartsAt: pickStartsAt,
                              onPickEndsAt: pickEndsAt,
                              onClearStartsAt: clearStartsAt,
                              onClearEndsAt: clearEndsAt,
                            ),
                            const SizedBox(height: 24),
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
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                          cancelInlineCreate();
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
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          await saveInlineForm();
                                          if (!mounted) return;
                                          if (!showInlineCreateForm) {
                                            dialogNavigator.pop();
                                          } else {
                                            setDialogState(() {});
                                          }
                                        },
                                  icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                                  label: Text(
                                    isSaving
                                        ? 'Saving...'
                                        : editingCouponId == null
                                            ? 'Save Coupon'
                                            : 'Update Coupon',
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
    if (showInlineCreateForm) {
      cancelInlineCreate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Coupon> rows = filteredCoupons;

    Widget filters() {
      final List<String> options = <String>['All', 'Active', 'Expired'];
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
            final bool isSelected = selectedFilter == option;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedFilter = option),
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
                  Icons.confirmation_num_rounded,
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
                      'Store Coupons',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create, launch, and manage promotional coupon codes',
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

          // Search filters and actions responsive block
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
                  decoration: inputDecoration('Search coupon code').copyWith(
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              );

              final Widget exportButton = PopupMenuButton<ExportFormat>(
                tooltip: 'Export',
                onSelected: (ExportFormat format) => _exportCoupons(format, rows),
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
                    'Create Coupon',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              );

              // 📱 Mobile Stack (width < 600) — Individual elements per row to prevent overlaps
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

              // 📟 Tablet Stack (600 <= width < 960) — Double row compact grids
              if (screenWidth < 960) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 280, child: filters()),
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

              // 🖥️ Desktop Row (width >= 960) — Sleek single file row
              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 12),
                  SizedBox(width: 280, child: filters()),
                  const SizedBox(width: 12),
                  exportButton,
                  const SizedBox(width: 12),
                  createButton,
                ],
              );
            },
          ),
          if (showInlineCreateForm) ...[
            const SizedBox(height: 20),
            Container(
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
                      const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        editingCouponId == null ? 'Create Coupon' : 'Edit Coupon',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CouponFormFields(
                    codeController: codeController,
                    discountValueController: discountValueController,
                    maxUsageController: maxUsageController,
                    allowedPhoneController: allowedPhoneController,
                    minOrderAmountController: minOrderAmountController,
                    maxDiscountAmountController: maxDiscountAmountController,
                    startsAtController: startsAtController,
                    endsAtController: endsAtController,
                    perCustomerLimitController: perCustomerLimitController,
                    selectedType: selectedType,
                    selectedLifecycleStatus: selectedLifecycleStatus,
                    onTypeChanged: (CouponDiscountType type) {
                      setState(() => selectedType = type);
                    },
                    onLifecycleStatusChanged: (CouponLifecycleStatus status) {
                      setState(() => selectedLifecycleStatus = status);
                    },
                    onPickStartsAt: pickStartsAt,
                    onPickEndsAt: pickEndsAt,
                    onClearStartsAt: clearStartsAt,
                    onClearEndsAt: clearEndsAt,
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
                        onPressed: isSaving ? null : cancelInlineCreate,
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: isSaving ? null : saveInlineForm,
                        icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                        label: Text(
                          isSaving
                              ? 'Saving...'
                              : editingCouponId == null
                                  ? 'Save Coupon'
                                  : 'Update Coupon',
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
                child: CouponsTable(
                  coupons: rows,
                  onEdit: _openEditDialog,
                  onDelete: confirmDeleteCoupon,
                  statusOf: couponStatus,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
