import 'package:flutter/material.dart';

import '../../../data/models/schema/coupon_models.dart';
import '../../../data/repositories/coupons_repository.dart';
import '../../../data/service_locator.dart';
import '../../../data/services/coupon_validation_service.dart';
import '../../common/app_styles.dart';
import 'coupons_view.dart';

mixin CouponsLogic on State<CouponsView> {
  late final CouponsRepository repository =
      widget.repository ?? ServiceLocator.instance.couponsRepository;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController discountValueController = TextEditingController();
  final TextEditingController maxUsageController = TextEditingController();
  final TextEditingController allowedPhoneController = TextEditingController();
  final TextEditingController minOrderAmountController = TextEditingController();
  final TextEditingController maxDiscountAmountController = TextEditingController();
  final TextEditingController startsAtController = TextEditingController();
  final TextEditingController endsAtController = TextEditingController();
  final TextEditingController perCustomerLimitController = TextEditingController();

  List<Coupon> coupons = const <Coupon>[];
  String selectedFilter = 'All';
  CouponDiscountType selectedType = CouponDiscountType.percentage;
  CouponLifecycleStatus selectedLifecycleStatus = CouponLifecycleStatus.active;
  String? editingCouponId;
  bool isSaving = false;
  bool showInlineCreateForm = false;

  @override
  void initState() {
    super.initState();
    loadCoupons();
  }

  @override
  void dispose() {
    searchController.dispose();
    codeController.dispose();
    discountValueController.dispose();
    maxUsageController.dispose();
    allowedPhoneController.dispose();
    minOrderAmountController.dispose();
    maxDiscountAmountController.dispose();
    startsAtController.dispose();
    endsAtController.dispose();
    perCustomerLimitController.dispose();
    super.dispose();
  }

  Future<void> loadCoupons() async {
    try {
      final List<Coupon> result = await repository.fetchCoupons();
      if (!mounted) return;
      setState(() => coupons = result);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showSnack('Unable to load coupons right now. Please retry.');
    }
  }

  List<Coupon> get filteredCoupons {
    final String query = searchController.text.trim().toLowerCase();
    return coupons.where((Coupon c) {
      final bool queryMatch =
          query.isEmpty || c.code.toLowerCase().contains(query);
      final bool filterMatch =
          selectedFilter == 'All' || selectedFilter == couponStatus(c);
      return queryMatch && filterMatch;
    }).toList();
  }

  String couponStatus(Coupon coupon) =>
      coupon.lifecycleStatus == CouponLifecycleStatus.archived
      ? 'Archived'
      : coupon.lifecycleStatus == CouponLifecycleStatus.paused
      ? 'Paused'
      : coupon.usageTracker.currentUsageCount >= coupon.usageTracker.maxUsageLimit
      ? 'Expired'
      : _isOutsideSchedule(coupon)
      ? 'Scheduled'
      : 'Active';

  bool _isOutsideSchedule(Coupon coupon) {
    final DateTime now = DateTime.now().toUtc();
    final DateTime? startsAt = _tryParseUtc(coupon.startsAt);
    final DateTime? endsAt = _tryParseUtc(coupon.endsAt);
    if (startsAt != null && now.isBefore(startsAt)) {
      return true;
    }
    if (endsAt != null && now.isAfter(endsAt)) {
      return true;
    }
    return false;
  }

  DateTime? _tryParseUtc(String? value) {
    final String raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  void openCreate() {
    setState(() {
      showInlineCreateForm = true;
      editingCouponId = null;
      selectedType = CouponDiscountType.percentage;
      selectedLifecycleStatus = CouponLifecycleStatus.active;
      codeController.clear();
      discountValueController.clear();
      maxUsageController.text = '100';
      allowedPhoneController.clear();
      minOrderAmountController.clear();
      maxDiscountAmountController.clear();
      startsAtController.clear();
      endsAtController.clear();
      perCustomerLimitController.clear();
      isSaving = false;
    });
  }

  void openEdit(Coupon coupon) {
    setState(() {
      showInlineCreateForm = true;
      editingCouponId = coupon.id;
      selectedType = coupon.discountType;
      selectedLifecycleStatus = coupon.lifecycleStatus;
      codeController.text = coupon.code;
      discountValueController.text = coupon.discountValue.toString();
      maxUsageController.text = coupon.usageTracker.maxUsageLimit.toString();
      allowedPhoneController.text = coupon.allowedCustomerPhone ?? '';
      minOrderAmountController.text = coupon.minOrderAmount?.toString() ?? '';
      maxDiscountAmountController.text =
          coupon.maxDiscountAmount?.toString() ?? '';
      startsAtController.text = coupon.startsAt ?? '';
      endsAtController.text = coupon.endsAt ?? '';
      perCustomerLimitController.text = coupon.perCustomerLimit?.toString() ?? '';
      isSaving = false;
    });
  }

  void cancelInlineCreate() {
    setState(() {
      showInlineCreateForm = false;
      isSaving = false;
      editingCouponId = null;
      selectedType = CouponDiscountType.percentage;
      selectedLifecycleStatus = CouponLifecycleStatus.active;
    });
  }

  Future<void> saveInlineForm() async {
    final bool saved = await saveCoupon();
    if (!mounted) return;
    if (saved) {
      setState(() {
        showInlineCreateForm = false;
        selectedType = CouponDiscountType.percentage;
      });
    }
  }

  Future<bool> saveCoupon() async {
    final String code = codeController.text.trim().toUpperCase();
    final num? discountValue = num.tryParse(
      discountValueController.text.trim(),
    );
    final int? maxUsage = int.tryParse(maxUsageController.text.trim());
    final String allowedPhone = allowedPhoneController.text.trim();
    final num? minOrderAmount =
        minOrderAmountController.text.trim().isEmpty
            ? null
            : num.tryParse(minOrderAmountController.text.trim());
    final num? maxDiscountAmount =
        maxDiscountAmountController.text.trim().isEmpty
            ? null
            : num.tryParse(maxDiscountAmountController.text.trim());
    final DateTime? startsAt = _tryParseUtc(startsAtController.text.trim());
    final DateTime? endsAt = _tryParseUtc(endsAtController.text.trim());
    final int? perCustomerLimit =
        perCustomerLimitController.text.trim().isEmpty
            ? null
            : int.tryParse(perCustomerLimitController.text.trim());

    final List<String> validationErrors = CouponValidationService.validate(
      CouponValidationInput(
        code: code,
        discountType: selectedType,
        discountValue: discountValue,
        maxUsageLimit: maxUsage,
        allowedCustomerPhone: allowedPhone,
        minOrderAmount: minOrderAmount,
        maxDiscountAmount: maxDiscountAmount,
        startsAt: startsAt,
        endsAt: endsAt,
        perCustomerLimit: perCustomerLimit,
      ),
    );
    if (validationErrors.isNotEmpty) {
      showSnack(validationErrors.first);
      return false;
    }

    final num safeDiscountValue = discountValue!;
    final int safeMaxUsage = maxUsage!;

    final bool duplicateCode = coupons.any(
      (Coupon c) => c.code.toUpperCase() == code && c.id != editingCouponId,
    );
    if (duplicateCode) {
      showSnack('This coupon code already exists. Use a different code.');
      return false;
    }

    final Coupon existing = coupons.firstWhere(
      (Coupon c) => c.id == editingCouponId,
      orElse: () => Coupon(
        id: 'cp_${DateTime.now().millisecondsSinceEpoch}',
        merchantId: '',
        code: code,
        discountType: selectedType,
        discountValue: safeDiscountValue,
        usageTracker: CouponUsageTracker(
          currentUsageCount: 0,
          maxUsageLimit: safeMaxUsage,
        ),
        lifecycleStatus: selectedLifecycleStatus,
        startsAt: startsAt?.toIso8601String(),
        endsAt: endsAt?.toIso8601String(),
        minOrderAmount: minOrderAmount,
        maxDiscountAmount: maxDiscountAmount,
        perCustomerLimit: perCustomerLimit,
        allowedCustomerPhone: null,
      ),
    );

    final Coupon next = Coupon(
      id: existing.id,
      merchantId: existing.merchantId,
      code: code,
      discountType: selectedType,
      discountValue: safeDiscountValue,
      usageTracker: CouponUsageTracker(
        currentUsageCount: existing.usageTracker.currentUsageCount,
        maxUsageLimit: safeMaxUsage,
      ),
      lifecycleStatus: selectedLifecycleStatus,
      startsAt: startsAt?.toIso8601String(),
      endsAt: endsAt?.toIso8601String(),
      minOrderAmount: minOrderAmount,
      maxDiscountAmount: maxDiscountAmount,
      perCustomerLimit: perCustomerLimit,
      allowedCustomerPhone: allowedPhone.isEmpty ? null : allowedPhone,
      createdBy: existing.createdBy,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
      isDeleted: false,
    );

    setState(() => isSaving = true);
    await repository.saveCoupon(next);
    await loadCoupons();
    if (!mounted) return false;
    setState(() {
      isSaving = false;
      editingCouponId = null;
    });
    showSnack('Coupon saved successfully.');
    return true;
  }

  Future<void> deleteCoupon(Coupon coupon) async {
    await repository.deleteCoupon(coupon.id);
    await loadCoupons();
    if (!mounted) return;
    showSnack('Coupon deleted.');
  }

  Future<void> confirmDeleteCoupon(Coupon coupon) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Coupon'),
          content: Text(
            'Are you sure you want to delete coupon ${coupon.code}?',
          ),
          actions: [
            OutlinedButton(
              style: outlinedStyle(),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: blackButtonStyle(),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await deleteCoupon(coupon);
    }
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> pickStartsAt() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _tryParseUtc(startsAtController.text)?.toLocal() ?? now;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null || !mounted) {
      return;
    }
    final DateTime value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    ).toUtc();
    setState(() {
      startsAtController.text = value.toIso8601String();
    });
  }

  Future<void> pickEndsAt() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _tryParseUtc(endsAtController.text)?.toLocal() ?? now;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null || !mounted) {
      return;
    }
    final DateTime value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    ).toUtc();
    setState(() {
      endsAtController.text = value.toIso8601String();
    });
  }

  void clearStartsAt() {
    setState(() {
      startsAtController.clear();
    });
  }

  void clearEndsAt() {
    setState(() {
      endsAtController.clear();
    });
  }
}
