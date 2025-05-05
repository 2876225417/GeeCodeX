// lib/screens/book_browser/widgets/featured_books_section.dart
import 'package:flutter/material.dart';
import 'package:Geecodex/models/book.dart';
import 'package:Geecodex/widgets/book_card.dart'; // Import your BookCard

class FeaturedBooksSection extends StatelessWidget {
  final bool isLoading;
  final List<Book> books;
  final String? errorMessage;
  final VoidCallback onRetry; // Callback for retry button

  const FeaturedBooksSection({
    super.key,
    required this.isLoading,
    required this.books,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the content based on state
    Widget content;
    if (isLoading) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 80.0,
          ), // Give loading indicator space
          child: CircularProgressIndicator(),
        ),
      );
    } else if (errorMessage != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 40),
              const SizedBox(height: 10),
              Text(
                'Error: $errorMessage',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      );
    } else if (books.isEmpty) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80.0),
          child: Text('No latest books found.'),
        ),
      );
    } else {
      // Build the horizontal list view
      content = SizedBox(
        height: 230, // Increased height slightly for better spacing
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 8.0,
              ), // Added vertical padding
              child: BookCard(
                mBook: book,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/book_details',
                    arguments: book,
                  );
                  // TODO: Implement navigation to book details screen
                  print('Tapped on book: ${books[index].title}');
                  // Navigator.pushNamed(context, '/book_details', arguments: books[index]);
                },
              ),
            );
          },
        ),
      );
    }

    return content; // Return the determined content widget
  }
}
