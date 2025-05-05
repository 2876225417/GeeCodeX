//lib/screens/book_reader/widgets/initial_reader_view.dart

import 'package:flutter/material.dart';

class InitialReaderView extends StatelessWidget {
  final VoidCallback onOpenFile;
  final bool isNightMode;

  const InitialReaderView({
    super.key,
    required this.onOpenFile,
    required this.isNightMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = isNightMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No PDF file is open',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: onOpenFile,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('Open PDF File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: theme.textTheme.labelLarge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
