import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

ButtonStyle blackButtonStyle() {
  return ElevatedButton.styleFrom(
    foregroundColor: AppColors.white,
    backgroundColor: AppColors.black,
    shape: const RoundedRectangleBorder(borderRadius: kRadiusMedium),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    elevation: 0,
    textStyle: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );
}

ButtonStyle primaryAccentButtonStyle() {
  return ElevatedButton.styleFrom(
    foregroundColor: AppColors.white,
    backgroundColor: AppColors.primary,
    shape: const RoundedRectangleBorder(borderRadius: kRadiusMedium),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    elevation: 0,
    textStyle: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );
}

ButtonStyle outlinedStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    backgroundColor: AppColors.white,
    side: const BorderSide(color: AppColors.border, width: 1.2),
    shape: const RoundedRectangleBorder(borderRadius: kRadiusMedium),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    elevation: 0,
    textStyle: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );
}

InputDecoration inputDecoration(String label, {Icon? icon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.plusJakartaSans(
      color: AppColors.textSecondary,
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: GoogleFonts.plusJakartaSans(
      color: AppColors.primary,
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
    ),
    filled: true,
    prefixIcon: icon,
    fillColor: AppColors.offWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: const OutlineInputBorder(
      borderRadius: kRadiusMedium,
      borderSide: BorderSide(color: AppColors.border, width: 1.0),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: kRadiusMedium,
      borderSide: BorderSide(color: AppColors.border, width: 1.0),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: kRadiusMedium,
      borderSide: BorderSide(color: AppColors.primary, width: 1.8),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: kRadiusMedium,
      borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.0),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: kRadiusMedium,
      borderSide: BorderSide(color: Color(0xFFEF4444), width: 1.8),
    ),
  );
}
