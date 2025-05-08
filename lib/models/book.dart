// lib/models/book.dart
import 'package:flutter/foundation.dart';

class Book {
  final int id; // API uses int ID
  final String title;
  final String author;
  final String? description;
  final String? isbn;
  final String? language;
  final int? pageCount;
  final String? publishDate; // Keep as String or parse to DateTime
  final String? publisher;
  final List<String>? tags; // Assuming tags are strings
  final int? downloadCount;
  final DateTime? createdAt; // Parse from String
  String coverUrl; // This will be constructed

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.isbn,
    this.language,
    this.pageCount,
    this.publishDate,
    this.publisher,
    this.tags,
    this.downloadCount,
    this.createdAt,
    required this.coverUrl, // Make required or provide default
  });

  // Factory constructor to parse JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(String? dateString) {
      if (dateString == null) return null;
      try {
        // Adjust format if needed, API example has timezone info
        return DateTime.parse(dateString);
      } catch (e) {
        if (kDebugMode) {
          print("Error parsing date: $dateString, Error: $e");
        }
        return null;
      }
    }

    // Construct the cover URL
    final int bookId = json['id'] as int; // Assume ID is always present and int
    final String constructedCoverUrl =
        'http://jiaxing.website/geecodex/books/cover/$bookId';

    return Book(
      id: bookId,
      title: json['title'] ?? 'Unknown Title',
      author: json['author'] ?? 'Unknown Author',
      description: json['description'] as String?,
      isbn: json['isbn'] as String?,
      language: json['language'] as String?,
      pageCount: json['page_count'] as int?,
      publishDate: json['publish_date'] as String?,
      publisher: json['publisher'] as String?,
      // Handle tags list (ensure it's List<dynamic> then cast)
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList(),
      downloadCount: json['download_count'] as int?,
      createdAt: parseDateTime(json['created_at'] as String?),
      coverUrl: constructedCoverUrl, // Use the constructed URL
    );
  }

  // Optional: Add a toJson method if you need to send Book data
}
