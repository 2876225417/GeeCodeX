// lib/screens/book_reader/widgets/add_note_dialog.dart
import 'package:flutter/material.dart';

class AddNoteDialog extends StatelessWidget {
  final String selectedText;
  final TextEditingController commentController;
  final bool isNightMode;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const AddNoteDialog({
    super.key,
    required this.selectedText,
    required this.commentController,
    required this.isNightMode,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = isNightMode;

    return Dialog(
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Note',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDark ? colorScheme.onSurface : colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  //color: isDark ? Colors.grey[600] : Colors.grey.shade300,
                ),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Text(
                    selectedText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? colorScheme.onSurface : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              style: TextStyle(
                color: isDark ? colorScheme.onSurface : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Add Annotation (Optional)',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: isDark ? colorScheme.secondary : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onSave,
                  child: const Text('Save Note'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
