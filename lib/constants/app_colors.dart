/// App Colors
///
/// Defines the color palette used throughout the application.
/// Follows Material Design color naming conventions where applicable.

import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // --- Primary Palette ---
  static const Color primary = Color(0xFF3F5185);
  static const Color primaryLight = Color(0xFF757DE8); // Was: primary_light
  static const Color primaryDark = Color(0xFF002984); // Was: primary_dark

  // --- Accent Palette ---
  static const Color accent = Color(0xFFFF4081);
  static const Color accentLight = Color(0xFFFF7980); // Was: accent_light
  static const Color accentDark = Color(0xFFC60055); // Was: accent_dark

  // --- Background & Surface ---
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  // --- Text Colors ---
  static const Color textPrimary = Color(0xFF212121); // Was: text_primary
  static const Color textSecondary = Color(0xFF757575); // Was: text_secondary
  static const Color textHint = Color(0xFFBDBDBD); // Was: text_hint

  // --- Signal Colors ---
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(
    0xFF197602,
  ); // Note: Might consider a bluer info color like Colors.blue

  // --- Navigation Bar ---
  static const Color navBarBackground = primary; // Was: nav_bar_background
  static const Color navBarActiveItem = accent; // Was: nav_bar_active_item
  static const Color navBarInactiveItem =
      Colors.white70; // Was: nav_bar_inactive_item

  // --- UI Elements ---
  static const Color divider = Color(0xFFBDBDBD);
  static const Color shadow = Color(0x40000000); // 25% black shadow

  // --- Common Colors ---
  // Add common colors like white, black, transparent if needed frequently
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
}
