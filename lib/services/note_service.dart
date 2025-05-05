// lib/services/note_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kDebugMode or logging

// Renamed class to UpperCamelCase
class Note {
  final String id;
  final String text;
  final String comment;
  final String source; // PDF file name
  // Renamed fields to lowerCamelCase
  final String pageNumber;
  final DateTime createdAt;
  final String pdfPath; // Added field to store the PDF path

  Note({
    required this.id,
    required this.text,
    required this.comment,
    required this.source,
    required this.pageNumber,
    required this.createdAt,
    required this.pdfPath, // Added required parameter
  });

  // Renamed method to lowerCamelCase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'comment': comment,
      'source': source,
      'pageNumber': pageNumber, // Use lowerCamelCase key
      'createdAt': createdAt.toIso8601String(), // Use lowerCamelCase key
      'pdfPath': pdfPath, // Added field to JSON
    };
  }

  // Renamed factory constructor
  factory Note.fromJson(Map<String, dynamic> json) {
    // Defensive check for createdAt type
    DateTime parsedDate;
    if (json['createdAt'] is String) {
      parsedDate = DateTime.parse(json['createdAt']);
    } else if (json['createdAt'] is int) {
      // Handle potential timestamp storage (optional)
      parsedDate = DateTime.fromMillisecondsSinceEpoch(json['createdAt']);
    } else {
      // Fallback or error handling
      parsedDate = DateTime.now(); // Or throw an error
      if (kDebugMode) {
        print("Warning: Could not parse createdAt field: ${json['createdAt']}");
      }
    }

    return Note(
      id: json['id'] ?? '', // Provide default if null
      text: json['text'] ?? '',
      comment: json['comment'] ?? '',
      source: json['source'] ?? 'Unknown Source',
      // Use lowerCamelCase keys, provide defaults
      pageNumber: json['pageNumber']?.toString() ?? '0',
      createdAt: parsedDate,
      // Handle missing pdfPath for backward compatibility
      pdfPath: json['pdfPath'] ?? '',
    );
  }
}

// Renamed class to UpperCamelCase
class NoteService {
  // Renamed constant key
  static const String _notesKey =
      'pdf_notes_v2'; // Consider versioning key if model changes

  // Renamed method to lowerCamelCase
  static Future<void> saveNote(Note note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];

      // Remove existing note with the same ID to prevent duplicates / allow updates
      notesJson.removeWhere((noteJson) {
        try {
          final existingNote = Note.fromJson(jsonDecode(noteJson));
          return existingNote.id == note.id;
        } catch (e) {
          // Handle potential decoding error for an existing invalid entry
          if (kDebugMode) {
            print("Error decoding existing note during save: $e");
          }
          return false; // Keep malformed entry for now, or decide to remove it
        }
      });

      notesJson.add(jsonEncode(note.toJson()));
      await prefs.setStringList(_notesKey, notesJson);
    } catch (e) {
      if (kDebugMode) {
        print("Error saving note: $e");
      }
      // Optionally re-throw or handle the error appropriately
      // throw Exception("Failed to save note");
    }
  }

  // Renamed method to lowerCamelCase
  static Future<List<Note>> getNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];

      List<Note> notes = [];
      for (final noteJson in notesJson) {
        try {
          notes.add(Note.fromJson(jsonDecode(noteJson)));
        } catch (e) {
          if (kDebugMode) {
            print("Error decoding note: $e. Skipping entry: $noteJson");
          }
          // Skip corrupted entries
        }
      }

      // Sort by date descending
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting notes: $e");
      }
      return []; // Return empty list on error
    }
  }

  // Renamed method to lowerCamelCase
  static Future<void> deleteNote(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];

      // More efficient removal using removeWhere
      notesJson.removeWhere((noteJson) {
        try {
          // Only decode enough to get the ID if possible, but full decode is safer
          final note = Note.fromJson(jsonDecode(noteJson));
          return note.id == id;
        } catch (e) {
          if (kDebugMode) {
            print(
              "Error decoding note during delete check: $e. Skipping entry: $noteJson",
            );
          }
          return false; // Don't remove potentially corrupted entries unless intended
        }
      });

      await prefs.setStringList(_notesKey, notesJson);
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting note: $e");
      }
      // Optionally re-throw or handle
      // throw Exception("Failed to delete note");
    }
  }

  // Optional: Method to get notes for a specific PDF
  static Future<List<Note>> getNotesForPdf(String pdfPath) async {
    final allNotes = await getNotes();
    return allNotes.where((note) => note.pdfPath == pdfPath).toList();
  }
}
