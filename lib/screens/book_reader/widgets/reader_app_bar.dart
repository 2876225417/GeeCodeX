// lib/screens/book_reader/widgets/reader_app_bar.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'search_bar_content.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? fileName;
  final int currentPage;
  final int totalPages;
  final bool isSearchVisible;
  final bool isNightMode;
  final VoidCallback onSearchToggle;
  final VoidCallback onJumpToPage;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final TextEditingController searchController;
  final PdfTextSearchResult searchResult;
  final VoidCallback onExecuteSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onSearchPrev;
  final VoidCallback onSearchNext;

  const ReaderAppBar({
    super.key,
    this.fileName,
    required this.currentPage,
    required this.totalPages,
    required this.isSearchVisible,
    required this.isNightMode,
    required this.onSearchToggle,
    required this.onJumpToPage,
    required this.onPrevPage,
    required this.onNextPage,
    required this.searchController,
    required this.searchResult,
    required this.onExecuteSearch,
    required this.onClearSearch,
    required this.onSearchPrev,
    required this.onSearchNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = isNightMode;

    return AppBar(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
      foregroundColor: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
      elevation: 2.0,
      title: Text(
        fileName ?? "PDF Reader",
        style: TextStyle(
          fontSize: 16,
          color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        _buildPageJumpWidget(theme, isDark, colorScheme),
        IconButton(
          onPressed: onSearchToggle,
          icon: Icon(
            isSearchVisible ? Icons.close : Icons.search,
            color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
          ),
          tooltip: isSearchVisible ? 'Close Search' : 'Search Text',
        ),
      ],
      bottom:
          isSearchVisible
              ? SearchBarContent(
                theme: theme,
                isNightMode: isNightMode,
                searchController: searchController,
                searchResult: searchResult,
                onExecuteSearch: onExecuteSearch,
                onClearSearch: onClearSearch,
                onSearchPrev: onSearchPrev,
                onSearchNext: onSearchNext,
              )
              : null,
    );
  }

  Widget _buildPageJumpWidget(
    ThemeData theme,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: totalPages > 0 && currentPage > 1 ? onPrevPage : null,
            icon: Icon(
              Icons.navigate_before,
              color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
            ),
            tooltip: 'Previous Page',
          ),
          GestureDetector(
            onTap: onJumpToPage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.grey[700] : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                totalPages > 0 ? '$currentPage / $totalPages' : '-/-',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : colorScheme.primary,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed:
                totalPages > 0 && currentPage < totalPages ? onNextPage : null,
            icon: Icon(
              Icons.navigate_next,
              color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
            ),
            tooltip: 'Next Page',
          ),
        ],
      ),
    );
  }

  @override // adjust height based on search bar
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (isSearchVisible ? kToolbarHeight + 15 : 0),
  );
}
