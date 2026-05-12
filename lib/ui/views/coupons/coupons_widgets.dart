import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/schema/coupon_models.dart';
import '../../theme/app_colors.dart';

class CouponsTable extends StatelessWidget {
  const CouponsTable({
    super.key,
    required this.coupons,
    required this.onEdit,
    required this.onDelete,
    required this.statusOf,
  });

  final List<Coupon> coupons;
  final ValueChanged<Coupon> onEdit;
  final ValueChanged<Coupon> onDelete;
  final String Function(Coupon) statusOf;

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
                        'Code',
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
                        'Discount',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Usage',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Scope',
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
                  rows: coupons.asMap().entries.map((entry) {
                    final int rowIndex = entry.key;
                    final Coupon coupon = entry.value;

                    final String type =
                        coupon.discountType == CouponDiscountType.flat
                        ? 'Flat'
                        : 'Percentage';
                    final String discount =
                        coupon.discountType == CouponDiscountType.flat
                        ? 'NPR ${coupon.discountValue.toStringAsFixed(0)}'
                        : '${coupon.discountValue.toStringAsFixed(0)}%';
                    final String scope =
                        coupon.allowedCustomerPhone ?? 'All customers';
                    final String usage =
                        '${coupon.usageTracker.currentUsageCount}/${coupon.usageTracker.maxUsageLimit}';

                    return DataRow(
                      color: WidgetStateProperty.all(
                        rowIndex.isEven ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
                      ),
                      cells: [
                        DataCell(
                          Text(
                            coupon.code,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        DataCell(Text(type)),
                        DataCell(
                          Text(
                            discount,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(Text(usage)),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(scope, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        DataCell(CouponStatusPill(status: statusOf(coupon))),
                        DataCell(
                          SizedBox(
                            width: 80,
                            child: Row(
                              children: [
                                _ActionButton(
                                  icon: Icons.edit_rounded,
                                  iconColor: AppColors.accentBlue,
                                  bgColor: AppColors.accentBlueLight,
                                  tooltip: 'Edit coupon',
                                  onTap: () => onEdit(coupon),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  icon: Icons.delete_outline_rounded,
                                  iconColor: AppColors.rtoText,
                                  bgColor: AppColors.rtoBg,
                                  tooltip: 'Delete coupon',
                                  onTap: () => onDelete(coupon),
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

class CouponStatusPill extends StatelessWidget {
  const CouponStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final bool active = status == 'Active';
    final Color badgeBg = active ? AppColors.deliveredBg : AppColors.rtoBg;
    final Color labelColor = active ? AppColors.deliveredText : AppColors.rtoText;

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
