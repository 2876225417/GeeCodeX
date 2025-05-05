/// App Text Styles
///
/// Defines the common text styles used throughout the application.
/// References colors from [AppColors].

import 'package:flutter/material.dart';
import 'app_colors.dart'; // Ensure this import points to the correct file

// Class name changed to UpperCamelCase
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // Constant names changed to lowerCamelCase
  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary, // Updated reference
  );

  static const TextStyle sectionTitle = TextStyle(
    // Was: section_title
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, // Updated reference
  );

  static const TextStyle bodyText = TextStyle(
    // Was: body_text
    fontSize: 16,
    color: AppColors.textPrimary, // Updated reference
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary, // Updated reference
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    // Consider adding a default color, e.g., color: AppColors.white or AppColors.primary
  );

  // Example of a style variation
  static TextStyle bodyTextSecondary = bodyText.copyWith(
    // New example
    color: AppColors.textSecondary,
  );

  static TextStyle link = bodyText.copyWith(
    // New example for links
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );
}
