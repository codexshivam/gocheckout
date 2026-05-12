import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Map<String, (Color, Color)> colors = {
      'Delivered': (AppColors.deliveredBg, AppColors.deliveredText),
      'Verified': (AppColors.deliveredBg, AppColors.deliveredText),
      'Verified Merchant': (AppColors.deliveredBg, AppColors.deliveredText),
      'Verified Store': (AppColors.deliveredBg, AppColors.deliveredText),
      'RTO': (AppColors.rtoBg, AppColors.rtoText),
      'Pending': (AppColors.pendingBg, AppColors.pendingText),
    };

    final (Color bg, Color fg) =
        colors[status] ?? (AppColors.offWhite, AppColors.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: kRadiusSmall),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
