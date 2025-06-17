// lib/widgets/book_card.dart (Example Structure)
import 'package:flutter/material.dart';
import 'package:Geecodex/models/book.dart';

// Crousal Book Card in Book Browser Screen
// ---Layout----
//     Book
//    Cover
//    Title
//   Author
// -------------

class BookCard extends StatelessWidget {
  final Book mBook;
  final VoidCallback onTap;

  const BookCard({super.key, required this.mBook, required this.onTap});

  // Tap then jump to Page of book details

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: double.infinity,
                  child:
                      mBook.coverUrl.isNotEmpty
                          ? Image.network(
                            mBook.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                            // Add loadingBuilder for better UX
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          )
                          : Container(
                            // Placeholder if no cover URL
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.book_outlined,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            ),
                          ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Book Title
            Text(
              mBook.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Author
            Text(
              mBook.author,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
