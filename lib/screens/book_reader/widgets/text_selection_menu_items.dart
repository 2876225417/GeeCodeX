// lib/screens/book_reader/widgets/text_selection_menu_items.dart
import 'package:flutter/material.dart';

class TextSelectionMenuItems extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onAddNote;
  // final VoidCallback onSearch;
  final bool isNightMode;

  const TextSelectionMenuItems({
    super.key,
    required this.onCopy,
    required this.onAddNote,
    required this.isNightMode,
    // required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final colorScheme = theme.colorScheme;

    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isNightMode ? Colors.grey[700] : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildItem(theme, isNightMode, Icons.content_copy, 'Copy', onCopy),
            Container(width: 1, height: 30, color: Colors.grey.shade400),
            _buildItem(
              theme,
              isNightMode,
              Icons.note_add_outlined,
              'Add Note',
              onAddNote,
            ),
            // Container(width: 1, height: 30, color: Colors.grey.shade400),
            // _buildItem(theme, isNightMode, Icons.search, 'Search', onSearch),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDark ? colorScheme.onSurface : colorScheme.primary,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? colorScheme.onSurface : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
