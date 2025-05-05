// lib/screens/book_reader/widgets/reader_tools_menu.dart

import 'package:flutter/material.dart';

class ReaderToolsMenu extends StatelessWidget {
  final bool isVisible;
  final bool isNightMode;
  final VoidCallback onOpenFile;

  final VoidCallback onAddBookmark;
  final VoidCallback onViewBookmarks;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onShowDetails;
  final VoidCallback onToggleNightMode;

  const ReaderToolsMenu({
    super.key,
    required this.isVisible,
    required this.isNightMode,
    required this.onOpenFile,
    required this.onAddBookmark,
    required this.onViewBookmarks,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onShowDetails,
    required this.onToggleNightMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = isNightMode;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Card(
          color: isDark ? Colors.grey[800] : Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ToolMenuItem(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.folder_open_outlined,
                  title: 'Open File',
                  onTap: onOpenFile,
                ),
                _Divider(isDark),
                _ToolMenuItem(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.bookmark_border,
                  title: 'Add Bookmark',
                  onTap: onAddBookmark,
                ),
                _ToolMenuItem(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.bookmarks_outlined,
                  title: 'View Bookmarks',
                  onTap: onViewBookmarks,
                ),
                _Divider(isDark),
                _ToolMenuItem(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.zoom_in,
                  title: 'Zoom In',
                  onTap: onZoomIn,
                ),
                _ToolMenuItem(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.zoom_out,
                  title: 'Zoom Out',
                  onTap: onZoomOut,
                ),
                _Divider(isDark),
                _ToolMenuItem(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.info_outline,
                  title: 'PDF Details',
                  onTap: onShowDetails,
                ),
                _Divider(isDark),
                _ToolMenuItem(
                  theme: theme,
                  isDark: isDark,
                  icon:
                      isNightMode
                          ? Icons.wb_sunny_outlined
                          : Icons.nightlight_round,
                  title: isNightMode ? 'Light Mode' : 'Dark Mode',
                  onTap: onToggleNightMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolMenuItem extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ToolMenuItem({
    required this.theme,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color:
                  isDark ? colorScheme.onSurfaceVariant : colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isDark
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider(this.isDark);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? Colors.grey[700] : Colors.grey.shade200,
    );
  }
}
