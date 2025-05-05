// lib/models/favorite_item.dart
import 'dart:convert';

class FavoriteItem {
  final String id; // Unique identifier (e.g., book.id as String)
  final String filePath; // Path where the PDF is (or should be) stored
  final String fileName; // Display name (usually the book title)
  final DateTime addedDate; // When it was added to favorites
  final String? coverImagePath; // URL or local path to the cover image
  final int lastPage; // Last read page (defaults to 1)
  final String? notes; // User notes about the favorite

  FavoriteItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.addedDate,
    this.coverImagePath,
    this.lastPage = 1, // Default to page 1 if not specified
    this.notes,
  });

  // Convert a FavoriteItem into a Map for JSON encoding
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'added_date': addedDate.toIso8601String(), // Store date as standard string
      'cover_image_path': coverImagePath,
      'last_page': lastPage,
      'notes': notes,
    };
  }

  // Create a FavoriteItem from a Map (decoded from JSON)
  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      // Ensure the date string exists and is valid before parsing
      parsedDate = json['added_date'] != null
          ? DateTime.parse(json['added_date'] as String)
          : DateTime.now(); // Fallback if date is missing/invalid
    } catch (e) {
      print(
        "Error parsing date from JSON: ${json['added_date']}. Using current time. Error: $e",
      );
      parsedDate = DateTime.now(); // Fallback
    }

    return FavoriteItem(
      // Provide default values for required fields if missing in JSON
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(), // Fallback ID
      filePath: json['file_path'] ?? '',
      fileName: json['file_name'] ?? 'Unknown File',
      addedDate: parsedDate,
      coverImagePath: json['cover_image_path'], // Nullable is fine
      lastPage: json['last_page'] ?? 1, // Default to 1 if missing
      notes: json['notes'], // Nullable is fine
    );
  }

  // Optional: Override equality and hashCode for easier comparison/use in sets
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Optional: toString for debugging
  @override
  String toString() {
    return 'FavoriteItem{id: $id, fileName: $fileName, filePath: $filePath, addedDate: $addedDate, lastPage: $lastPage}';
  }
}