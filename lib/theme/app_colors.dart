import 'package:flutter/material.dart';

/// SlotSync design tokens — light (default) + dark themes.
class AppColors {
  AppColors._();

  // Light theme (default — keep original names for backward compat)
  static const background = Color(0xFFF5F7FB);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF2D7FF9);
  static const secondary = Color(0xFF5BA4FF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFF3F4F6);

  // Dark theme — pure black background with neon glow
  static const darkBackground = Color(0xFF000000);
  static const darkCard = Color(0xFF111111);
  static const darkPrimary = Color(0xFF60A5FA);
  static const darkSecondary = Color(0xFF93C5FD);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkSuccess = Color(0xFF4ADE80);
  static const darkWarning = Color(0xFFFBBF24);
  static const darkDanger = Color(0xFFF87171);
  static const darkBorder = Color(0xFF1F1F1F);
  static const darkDivider = Color(0xFF1A1A1A);

  // Glow shadows for dark mode
  static List<BoxShadow> glow(Color color, {double radius = 8}) => [
    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: radius, spreadRadius: 1),
    BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: radius * 2, spreadRadius: -1),
  ];

  static const primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkPrimaryGradient = LinearGradient(
    colors: [darkPrimary, darkSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const glassHeader = LinearGradient(
    colors: [Color(0xE6FFFFFF), Color(0xCCFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const darkGlassHeader = LinearGradient(
    colors: [Color(0xE6111111), Color(0xCC111111)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
