// lib/screens/book_reader/widgets/search_bar_content.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SearchBarContent extends StatelessWidget implements PreferredSizeWidget {
  final ThemeData theme;
  final bool isNightMode;
  final TextEditingController searchController;
  final PdfTextSearchResult searchResult;
  final VoidCallback onExecuteSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onSearchPrev;
  final VoidCallback onSearchNext;

  const SearchBarContent({
    super.key,
    required this.theme,
    required this.isNightMode,
    required this.searchController,
    required this.searchResult,
    required this.onExecuteSearch,
    required this.onClearSearch,
    required this.onSearchPrev,
    required this.onSearchNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final isDark = isNightMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: searchController,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Search in document...',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                onPressed: onExecuteSearch,
                icon: const Icon(Icons.search),
                tooltip: 'Execute Search',
                color: isDark ? colorScheme.onSurface : colorScheme.primary,
              ),
            ),
            onSubmitted: (_) => onExecuteSearch(),
          ),
          if (searchResult.hasResult)
            _buildSearchResultNavigation(theme, isDark, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSearchResultNavigation(
    ThemeData theme,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (searchResult.totalInstanceCount > 0)
          Text(
            '${searchResult.currentInstanceIndex}/${searchResult.totalInstanceCount}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  isDark ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            ),
          ),
        IconButton(
          onPressed:
              searchResult.hasResult && searchResult.totalInstanceCount > 0
                  ? onSearchPrev
                  : null,
          icon: const Icon(Icons.navigate_before),
          tooltip: 'Previous Match',
          color: isDark ? colorScheme.onSurface : colorScheme.primary,
        ),
        IconButton(
          onPressed:
              searchResult.hasResult && searchResult.totalInstanceCount > 0
                  ? onSearchNext
                  : null,
          icon: const Icon(Icons.navigate_next),
          tooltip: 'Next Match',
          color: isDark ? colorScheme.onSurface : colorScheme.primary,
        ),
        IconButton(
          onPressed: onClearSearch,
          icon: const Icon(Icons.clear),
          tooltip: 'Clear Match',
          color: isDark ? colorScheme.onSurface : colorScheme.error,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 15);
}
