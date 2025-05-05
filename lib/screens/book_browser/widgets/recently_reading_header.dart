// lib/screens/book_browser/widgets/recently_reading_header.dart
import 'package:flutter/material.dart';
// Removed constants import - using Theme

class RecentlyReadingHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBrowseAllPressed;

  const RecentlyReadingHeader({
    super.key,
    required this.title,
    required this.onBrowseAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        10,
        8,
      ), // Increased top padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
        children: [
          // Use theme for section title
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextButton.icon(
            // Use TextButton.icon for consistency
            onPressed: onBrowseAllPressed,
            icon: Text(
              "Browse All",
              style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
            ),
            label: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: colorScheme.primary,
            ),
            style: TextButton.styleFrom(
              foregroundColor:
                  colorScheme
                      .primary, // Affects icon and text if not specified directly
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              // Add splash factory for better feedback
              splashFactory: InkRipple.splashFactory,
            ),
          ),
        ],
      ),
    );
  }
}
