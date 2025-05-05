// lib/services/recent_reading_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Geecodex/models/book.dart'; // Assuming Book model is here or in index

// --- Model for Recent Item (can be in a separate file or here) ---
class RecentReadingItem {
  final String bookId; // Use book ID as the unique key
  final String title;
  final String author;
  final String coverUrl;
  final String? filePath; // Store the path to reopen
  final int lastPageRead;
  final int totalPages;
  final DateTime lastOpened;

  RecentReadingItem({
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.filePath,
    required this.lastPageRead,
    required this.totalPages,
    required this.lastOpened,
  });

  double get progress =>
      (totalPages > 0) ? (lastPageRead / totalPages).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
    'book_id': bookId,
    'title': title,
    'author': author,
    'cover_url': coverUrl,
    'file_path': filePath,
    'last_page_read': lastPageRead,
    'total_pages': totalPages,
    'last_opened': lastOpened.toIso8601String(),
  };

  factory RecentReadingItem.fromJson(Map<String, dynamic> json) {
    DateTime openedDate;
    try {
      openedDate = DateTime.parse(json['last_opened'] as String);
    } catch (_) {
      openedDate = DateTime.now(); // Fallback
    }
    return RecentReadingItem(
      bookId: json['book_id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      author: json['author'] ?? 'Unknown Author',
      coverUrl: json['cover_url'] ?? '',
      filePath: json['file_path'],
      lastPageRead: json['last_page_read'] ?? 1,
      totalPages: json['total_pages'] ?? 0,
      lastOpened: openedDate,
    );
  }

  // Convert Book model to RecentReadingItem (needs path, page info)
  static RecentReadingItem fromBook(
    Book book,
    String? path,
    int currentPage,
    int totalPg,
  ) {
    return RecentReadingItem(
      bookId: book.id.toString(),
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      filePath: path,
      lastPageRead: currentPage,
      totalPages: totalPg,
      lastOpened: DateTime.now(),
    );
  }
}

// --- Service Logic ---
class RecentReadingService {
  static const String _prefsKey = 'recent_reading_list';
  static const int _maxRecentItems = 10; // Max number of recent books to store

  // Get the list of recent items, sorted by lastOpened (most recent first)
  static Future<List<RecentReadingItem>> getRecentBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = prefs.getStringList(_prefsKey) ?? [];
      final List<RecentReadingItem> items =
          jsonList
              .map((jsonString) {
                try {
                  return RecentReadingItem.fromJson(jsonDecode(jsonString));
                } catch (e) {
                  print("Error decoding recent item: $e");
                  return null; // Skip corrupted items
                }
              })
              .whereType<RecentReadingItem>() // Filter out nulls
              .toList();

      // Sort by date, most recent first
      items.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
      print("RecentReadingService: Fetched ${items.length} recent items.");
      return items;
    } catch (e) {
      print("Error getting recent books: $e");
      return [];
    }
  }

  // Add or update a recently read book
  static Future<void> addOrUpdateRecentBook(RecentReadingItem newItem) async {
    if (newItem.bookId.isEmpty) return; // Need an ID

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = prefs.getStringList(_prefsKey) ?? [];
      List<RecentReadingItem> items =
          jsonList
              .map((jsonString) {
                try {
                  return RecentReadingItem.fromJson(jsonDecode(jsonString));
                } catch (e) {
                  return null;
                }
              })
              .whereType<RecentReadingItem>()
              .toList();

      // Remove existing entry for this book ID, if any
      items.removeWhere((item) => item.bookId == newItem.bookId);

      // Insert the new/updated item at the beginning (most recent)
      items.insert(0, newItem);

      // Limit the list size
      if (items.length > _maxRecentItems) {
        items = items.sublist(0, _maxRecentItems);
      }

      // Save back to SharedPreferences
      final List<String> updatedJsonList =
          items.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_prefsKey, updatedJsonList);
      print(
        "RecentReadingService: Added/Updated recent book: ${newItem.title}",
      );
    } catch (e) {
      print("Error adding/updating recent book: $e");
    }
  }

  // Optional: Update only the last page read for a specific book
  static Future<void> updateLastPageRead(
    String bookId,
    int page,
    int totalPages,
  ) async {
    if (bookId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = prefs.getStringList(_prefsKey) ?? [];
      List<RecentReadingItem> items =
          jsonList
              .map((jsonString) {
                try {
                  return RecentReadingItem.fromJson(jsonDecode(jsonString));
                } catch (e) {
                  return null;
                }
              })
              .whereType<RecentReadingItem>()
              .toList();

      int foundIndex = items.indexWhere((item) => item.bookId == bookId);

      if (foundIndex != -1) {
        // Update the existing item
        final currentItem = items[foundIndex];
        final updatedItem = RecentReadingItem(
          bookId: currentItem.bookId,
          title: currentItem.title,
          author: currentItem.author,
          coverUrl: currentItem.coverUrl,
          filePath: currentItem.filePath,
          lastPageRead: page, // Update page
          totalPages: totalPages, // Update total pages
          lastOpened: DateTime.now(), // Update last opened time
        );
        // Remove old and insert updated at the beginning
        items.removeAt(foundIndex);
        items.insert(0, updatedItem);

        // Save back
        final List<String> updatedJsonList =
            items.map((item) => jsonEncode(item.toJson())).toList();
        await prefs.setStringList(_prefsKey, updatedJsonList);
        print(
          "RecentReadingService: Updated page for book ID $bookId to $page/$totalPages",
        );
      } else {
        print(
          "RecentReadingService: Book ID $bookId not found in recents for page update.",
        );
        // Optionally add it if not found? Depends on desired behavior.
      }
    } catch (e) {
      print("Error updating last page read for recent book: $e");
    }
  }
}
