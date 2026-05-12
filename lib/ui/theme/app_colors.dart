import 'package:flutter/material.dart';

class AppColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF1E293B); // Dark slate/charcoal instead of pure black
  static const Color textSecondary = Color(0xFF64748B); // Slate secondary
  static const Color border = Color(0xFFE2E8F0); // Subtle slate border
  static const Color black = Color(0xFF0F172A); // Midnight slate instead of 000000

  // Standard delivery statuses
  static const Color deliveredBg = Color(0xFFF0FDF4); // Light emerald
  static const Color deliveredText = Color(0xFF166534); // Emerald-800
  static const Color rtoBg = Color(0xFFFEF2F2); // Light red
  static const Color rtoText = Color(0xFF991B1B); // Red-800
  static const Color pendingBg = Color(0xFFFFFBEB); // Light amber
  static const Color pendingText = Color(0xFF92400E); // Amber-800

  // Modern Indigo Theme for Actions/Accents
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFFEEF2FF); // Indigo-50
  static const Color accentBlue = Color(0xFF3B82F6); // Blue
  static const Color accentBlueLight = Color(0xFFEFF6FF); // Blue-50
}

const BorderRadius kRadiusSmall = BorderRadius.all(Radius.circular(8));
const BorderRadius kRadiusMedium = BorderRadius.all(Radius.circular(12));
const BorderRadius kRadiusLarge = BorderRadius.all(Radius.circular(16));
