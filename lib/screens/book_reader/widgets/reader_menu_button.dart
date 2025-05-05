//lib/screens/book_reader/widgets/reader_menu_button.dart

import 'package:flutter/material.dart';

class ReaderMenuButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onPressed;

  const ReaderMenuButton({
    super.key,
    required this.isOpen,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FloatingActionButton(
      heroTag: 'tools_menu_fab',
      backgroundColor: colorScheme.secondary,
      foregroundColor: colorScheme.onSecondary,
      tooltip: isOpen ? 'Close Menu' : 'Open Tools Menu',
      onPressed: onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(microseconds: 300),
        transitionBuilder:
            (child, animation) =>
                ScaleTransition(scale: animation, child: child),
        child: Icon(
          isOpen ? Icons.close : Icons.menu,
          key: ValueKey<bool>(isOpen),
        ),
      ),
    );
  }
}
