import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/schema/coupon_models.dart';
import '../../common/app_styles.dart';
import '../../theme/app_colors.dart';

class CouponFormFields extends StatelessWidget {
  const CouponFormFields({
    super.key,
    required this.codeController,
    required this.discountValueController,
    required this.maxUsageController,
    required this.allowedPhoneController,
    required this.minOrderAmountController,
    required this.maxDiscountAmountController,
    required this.startsAtController,
    required this.endsAtController,
    required this.perCustomerLimitController,
    required this.selectedType,
    required this.selectedLifecycleStatus,
    required this.onTypeChanged,
    required this.onLifecycleStatusChanged,
    required this.onPickStartsAt,
    required this.onPickEndsAt,
    required this.onClearStartsAt,
    required this.onClearEndsAt,
  });

  final TextEditingController codeController;
  final TextEditingController discountValueController;
  final TextEditingController maxUsageController;
  final TextEditingController allowedPhoneController;
  final TextEditingController minOrderAmountController;
  final TextEditingController maxDiscountAmountController;
  final TextEditingController startsAtController;
  final TextEditingController endsAtController;
  final TextEditingController perCustomerLimitController;
  final CouponDiscountType selectedType;
  final CouponLifecycleStatus selectedLifecycleStatus;
  final ValueChanged<CouponDiscountType> onTypeChanged;
  final ValueChanged<CouponLifecycleStatus> onLifecycleStatusChanged;
  final Future<void> Function() onPickStartsAt;
  final Future<void> Function() onPickEndsAt;
  final VoidCallback onClearStartsAt;
  final VoidCallback onClearEndsAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Core details
        _buildSectionCard(
          title: 'Coupon Core Details',
          icon: Icons.card_giftcard_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: codeController,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: inputDecoration('Coupon Code', icon: const Icon(Icons.qr_code_rounded, size: 18)),
              ),
              const SizedBox(height: 16),
              Text(
                'Discount Type',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double segmentWidth = (constraints.maxWidth - 2) / 2;
                    return ToggleButtons(
                      direction: Axis.horizontal,
                      isSelected: <bool>[
                        selectedType == CouponDiscountType.flat,
                        selectedType == CouponDiscountType.percentage,
                      ],
                      onPressed: (int index) {
                        onTypeChanged(
                          index == 0
                              ? CouponDiscountType.flat
                              : CouponDiscountType.percentage,
                        );
                      },
                      constraints: BoxConstraints(minHeight: 44, minWidth: segmentWidth),
                      borderRadius: BorderRadius.circular(8),
                      borderColor: AppColors.border,
                      selectedBorderColor: AppColors.black,
                      fillColor: AppColors.white,
                      color: AppColors.textSecondary,
                      selectedColor: AppColors.textPrimary,
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      children: const <Widget>[
                        Text('Flat Amount'),
                        Text('Percentage'),
                      ],
                    );
                  }
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: discountValueController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: inputDecoration('Discount Value (NPR or %)', icon: const Icon(Icons.price_change_outlined, size: 18)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card 2: Usage rules
        _buildSectionCard(
          title: 'Usage & Limit Policies',
          icon: Icons.lock_clock_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: maxUsageController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: inputDecoration('Global Max Usage Limit', icon: const Icon(Icons.people_alt_outlined, size: 18)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: perCustomerLimitController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: inputDecoration('Per-Customer Limit (Optional)', icon: const Icon(Icons.person_outline_rounded, size: 18)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CouponLifecycleStatus>(
                initialValue: selectedLifecycleStatus,
                decoration: inputDecoration('Coupon Lifecycle Status'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                dropdownColor: AppColors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
                items: CouponLifecycleStatus.values
                    .map(
                      (status) => DropdownMenuItem<CouponLifecycleStatus>(
                        value: status,
                        child: Text(
                          status.name[0].toUpperCase() + status.name.substring(1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (status) {
                  if (status != null) {
                    onLifecycleStatusChanged(status);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card 3: Criteria & Eligibilities
        _buildSectionCard(
          title: 'Eligibilities & Criteria',
          icon: Icons.playlist_add_check_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: minOrderAmountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: inputDecoration('Minimum Order Amount (Optional)', icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxDiscountAmountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: inputDecoration('Maximum Discount Cap (Optional)', icon: const Icon(Icons.money_off_csred_rounded, size: 18)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: allowedPhoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: inputDecoration('Allowed Customer Phone (Optional)', icon: const Icon(Icons.phone_iphone_rounded, size: 18)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card 4: Date Scheduling
        _buildSectionCard(
          title: 'Active Duration Scheduling',
          icon: Icons.calendar_today_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startsAtController,
                      readOnly: true,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: inputDecoration('Starts At (Optional, UTC)', icon: const Icon(Icons.date_range_rounded, size: 18)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onPressed: onPickStartsAt,
                    child: Text(
                      'Pick',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.rtoBg,
                      foregroundColor: AppColors.rtoText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: onClearStartsAt,
                    icon: const Icon(Icons.clear_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: endsAtController,
                      readOnly: true,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: inputDecoration('Ends At (Optional, UTC)', icon: const Icon(Icons.event_busy_rounded, size: 18)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onPressed: onPickEndsAt,
                    child: Text(
                      'Pick',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.rtoBg,
                      foregroundColor: AppColors.rtoText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: onClearEndsAt,
                    icon: const Icon(Icons.clear_rounded, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
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
            ],
          ),
          Divider(height: 24, thickness: 0.6, color: AppColors.border.withValues(alpha: 0.8)),
          child,
        ],
      ),
    );
  }
}
