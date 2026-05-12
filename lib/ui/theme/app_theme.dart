import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  final TextTheme poppins = GoogleFonts.poppinsTextTheme();

  return ThemeData(
    scaffoldBackgroundColor: AppColors.offWhite,
    textTheme: poppins,
    colorScheme: const ColorScheme.light(
      primary: AppColors.black,
      surface: AppColors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  ).copyWith(
    textTheme: poppins.copyWith(
      headlineSmall: (poppins.headlineSmall ?? const TextStyle()).copyWith(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.4,
      ),
      titleMedium: (poppins.titleMedium ?? const TextStyle()).copyWith(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: (poppins.bodyMedium ?? const TextStyle()).copyWith(
        color: AppColors.textPrimary,
        fontSize: 14,
        height: 1.45,
      ),
    ),
  );
}
