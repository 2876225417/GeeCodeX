// lib/constants/app_text_styles.dart

/// App Text Styles
///
/// Defines the common text styles used throughout the application.
/// References colors from [AppColors].
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: AppColors.white,
  );

  static TextStyle bodyTextSecondary = bodyText.copyWith(
    color: AppColors.textSecondary,
  );

  static TextStyle link = bodyText.copyWith(
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );
}
