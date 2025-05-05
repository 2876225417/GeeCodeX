// lib/screens/book_browser/widgets/recently_reading_list.dart
import 'package:flutter/material.dart';
import 'package:Geecodex/services/recent_reading_service.dart'; // Import the item model
import 'package:Geecodex/screens/book_reader/book_reader_screen.dart'; // Import reader
import 'package:Geecodex/screens/book_reader/widgets/pdf_viewer_wrapper.dart'; // For PdfSourceType

class RecentlyReadingList extends StatelessWidget {
  // Accept list of RecentReadingItem
  final List<RecentReadingItem> recentItems;

  const RecentlyReadingList({super.key, required this.recentItems});

  // Helper to build cover image (similar to FavoriteScreen)
  Widget _buildCoverImage(String imagePath, ColorScheme colorScheme) {
    Widget placeholder = Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.book_outlined,
        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
        size: 30,
      ),
    );
    if (imagePath.isEmpty) return placeholder;

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
              strokeWidth: 2,
            ),
          );
        },
      );
    } else {
      // Handle potential local file path (if needed, though coverUrl is likely http)
      return placeholder; // Placeholder for now if not http
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (recentItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 40,
        ), // More padding when empty
        child: Center(
          child: Text(
            'Start reading a book to see it here!',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Use ListView.separated for dividers (optional) or just padding
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16, top: 0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentItems.length,
      itemBuilder: (context, index) {
        final item = recentItems[index];
        final double progress = item.progress; // Use calculated progress
        final String progressPercent = '${(progress * 100).toInt()}%';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Card(
            // Use Card for elevation and shape
            elevation: 1,
            shadowColor: colorScheme.shadow.withOpacity(0.1),
            color: colorScheme.surfaceContainer, // Use themed container color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias, // Clip InkWell ripple
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Navigate to ReaderScreen with the stored path
                if (item.filePath != null && item.filePath!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ReaderScreen(
                            source: item.filePath!,
                            sourceType:
                                PdfSourceType
                                    .file, // Assuming it's always a file
                            // Optionally pass the RecentReadingItem or Book model if needed
                          ),
                      // You might want to pass the item itself as arguments
                      // settings: RouteSettings(arguments: item)
                    ),
                  );
                } else {
                  // Handle case where file path is missing (e.g., show details screen)
                  print('File path missing for recent item: ${item.title}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot open book: File path not found.'),
                    ),
                  );
                  // Maybe navigate to details instead?
                  // Navigator.pushNamed(context, '/book_details', arguments: /* Need Book object */);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Book Cover
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50,
                        height: 70,
                        child: _buildCoverImage(item.coverUrl, colorScheme),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Book Info and Progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.author,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(
                            height: 8,
                          ), // More space before progress
                          // Progress Bar and Text
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor:
                                      colorScheme
                                          .surfaceContainerHighest, // Themed background
                                  valueColor: AlwaysStoppedAnimation(
                                    colorScheme.primary,
                                  ), // Themed value color
                                  minHeight: 6, // Slightly thicker
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                progressPercent,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          // Optional: Show last page read / total pages
                          // const SizedBox(height: 4),
                          // Text(
                          //    'Page ${item.lastPageRead} of ${item.totalPages}',
                          //    style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          // ),
                        ],
                      ),
                    ),
                    // Optional: Add chevron or other indicator if needed
                    // Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
