// lib/constants/app_colors.dart

/// App Colors
/// Defines the color palette used throughout the application.
/// Follows Material Design color naming conventions where applicable.
library;

import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // --- Primary Palette ---
  static const Color primary = Color(0xFF3F5185);
  static const Color primaryLight = Color(0xFF757DE8);
  static const Color primaryDark = Color(0xFF002984);

  // --- Accent Palette ---
  static const Color accent = Color(0xFFFF4081);
  static const Color accentLight = Color(0xFFFF7980);
  static const Color accentDark = Color(0xFFC60055);

  // --- Background & Surface ---
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  // --- Text Colors ---
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // --- Signal Colors ---
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(
    0xFF197602,
  ); // Note: Might consider a bluer info color like Colors.blue

  // --- Navigation Bar ---
  static const Color navBarBackground = primary;
  static const Color navBarActiveItem = accent;
  static const Color navBarInactiveItem = Colors.white70;

  // --- UI Elements ---
  static const Color divider = Color(0xFFBDBDBD);
  static const Color shadow = Color(0x40000000); // 25% black shadow

  // --- Common Colors ---
  // Add common colors like white, black, transparent if needed frequently
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
}
