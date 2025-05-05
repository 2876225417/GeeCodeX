// lib/services/favorite_service.dart
import 'dart:convert';
import 'package:Geecodex/models/favorite_item.dart'; // Import the model
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  // Use a unique key for storing favorites list in SharedPreferences
  static const String _favoritesKey = 'geecodex_pdf_favorites';

  // Saves or updates a favorite item.
  // If an item with the same ID exists, it's updated; otherwise, it's added.
  static Future<void> saveFavorite(FavoriteItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> favoritesJson =
          prefs.getStringList(_favoritesKey) ?? [];
      bool itemExists = false;
      List<String> updatedFavoritesJson = [];

      // Iterate through existing favorites to check for updates
      for (final String favoriteJson in favoritesJson) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(favoriteJson);
          // Check if the current JSON object has the same ID as the item being saved
          if (decoded['id'] == item.id) {
            // Update existing item by adding the new JSON representation
            updatedFavoritesJson.add(jsonEncode(item.toJson()));
            itemExists = true;
          } else {
            // Keep the existing item if IDs don't match
            updatedFavoritesJson.add(favoriteJson);
          }
        } catch (e) {
          print(
            "Error decoding favorite JSON during save check: $favoriteJson. Skipping. Error: $e",
          );
          // Decide whether to keep potentially corrupted entries or discard
          // updatedFavoritesJson.add(favoriteJson); // Option to keep
        }
      }

      // If the item wasn't found (and thus not updated), add it as a new entry
      if (!itemExists) {
        updatedFavoritesJson.add(jsonEncode(item.toJson()));
      }

      // Save the updated list back to SharedPreferences
      await prefs.setStringList(_favoritesKey, updatedFavoritesJson);
      print("Favorite saved/updated: ${item.fileName}");
    } catch (e) {
      print("Error saving favorite: ${item.fileName}. Error: $e");
      // Rethrow or handle as needed
      rethrow;
    }
  }

  // Retrieves all favorite items, sorted by added date (newest first).
  static Future<List<FavoriteItem>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> favoritesJson =
          prefs.getStringList(_favoritesKey) ?? [];
      List<FavoriteItem> favorites = [];

      // Decode each JSON string into a FavoriteItem object
      for (final String favoriteJson in favoritesJson) {
        try {
          favorites.add(FavoriteItem.fromJson(jsonDecode(favoriteJson)));
        } catch (e) {
          print(
            "Error decoding favorite JSON during get: $favoriteJson. Skipping. Error: $e",
          );
          // Skip corrupted entries
        }
      }

      // Sort the list by addedDate, newest first
      favorites.sort((a, b) => b.addedDate.compareTo(a.addedDate));
      print("Fetched ${favorites.length} favorites.");
      return favorites;
    } catch (e) {
      print("Error getting favorites: $e");
      return []; // Return empty list on error
    }
  }

  // Deletes a favorite item based on its ID.
  static Future<void> deleteFavorite(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> favoritesJson =
          prefs.getStringList(_favoritesKey) ?? [];
      final List<String> updatedFavoritesJson = [];

      // Filter out the favorite with the matching ID
      for (final String favoriteJson in favoritesJson) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(favoriteJson);
          if (decoded['id'] != id) {
            updatedFavoritesJson.add(favoriteJson); // Keep if ID doesn't match
          } else {
            print("Deleting favorite with ID: $id");
          }
        } catch (e) {
          print(
            "Error decoding favorite JSON during delete: $favoriteJson. Skipping. Error: $e",
          );
          // Decide how to handle corrupted entries during delete
          // Option: Try to parse only the ID if possible, otherwise skip/keep based on policy
        }
      }

      // Save the filtered list back
      await prefs.setStringList(_favoritesKey, updatedFavoritesJson);
    } catch (e) {
      print("Error deleting favorite with ID: $id. Error: $e");
      rethrow;
    }
  }

  // Checks if a specific item (by ID) is already favorited.
  static Future<bool> isFavorite(String id) async {
    try {
      final List<FavoriteItem> favorites = await getFavorites();
      return favorites.any((item) => item.id == id);
    } catch (e) {
      print("Error checking if favorite (ID: $id): $e");
      return false; // Assume not favorite on error
    }
  }

  // --- Optional: Update Last Page (if needed, based on FavoriteScreen code) ---
  // Updates only the last read page for a specific favorite item.
  static Future<void> updateLastPage(String id, int page) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> favoritesJson =
          prefs.getStringList(_favoritesKey) ?? [];
      List<String> updatedFavoritesJson = [];
      bool updated = false;

      for (final String favoriteJson in favoritesJson) {
        try {
          final favorite = FavoriteItem.fromJson(jsonDecode(favoriteJson));
          if (favorite.id == id) {
            // Create a new item with the updated page number
            final updatedFavorite = FavoriteItem(
              id: favorite.id,
              filePath: favorite.filePath,
              fileName: favorite.fileName,
              addedDate: favorite.addedDate,
              coverImagePath: favorite.coverImagePath,
              lastPage: page, // The updated value
              notes: favorite.notes,
            );
            updatedFavoritesJson.add(jsonEncode(updatedFavorite.toJson()));
            updated = true;
            print("Updated last page for favorite ID: $id to $page");
          } else {
            updatedFavoritesJson.add(favoriteJson); // Keep others as is
          }
        } catch (e) {
          print(
            "Error decoding/updating favorite JSON during updateLastPage: $favoriteJson. Skipping update for this item. Error: $e",
          );
          updatedFavoritesJson.add(favoriteJson); // Keep original if error
        }
      }

      if (updated) {
        await prefs.setStringList(_favoritesKey, updatedFavoritesJson);
      } else {
        print("Favorite with ID $id not found for page update.");
      }
    } catch (e) {
      print("Error updating last page for ID $id: $e");
      rethrow;
    }
  }
}
