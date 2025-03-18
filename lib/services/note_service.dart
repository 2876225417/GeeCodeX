

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

class note { 
  final String id;
  final String text;
  final String comment;
  final String source;
  final String page_number;
  final DateTime created_at;

  note({
    required this.id,
    required this.text,
    required this.comment,
    required this.source,
    required this.page_number,
    required this.created_at
  });

  Map<String, dynamic> to_json() {
    return {
      'id': id,
      'text': text,
      'comment': comment,
      'source': source,
      'page_number': page_number,
      'created_at': created_at.toIso8601String(),
    };
  }

  factory note.from_json(Map<String, dynamic> json) {
    return note(
      id: json['id'],
      text: json['text'],
      comment: json['comment'],
      source: json['source'],
      page_number: json['page_number'],
      created_at: json['created_at'] is String 
                ? DateTime.parse(json['created_at']) 
                : json['created_at'],
    );
  }
}

class note_service {
  static const String _note_key = 'pdf_notes';
  
  static Future<void> save_note(note note_) async {
    final prefs = await SharedPreferences.getInstance();
    final note_json = prefs.getStringList(_note_key) ?? [];
    
    note_json.add(jsonEncode(note_.to_json()));
    await prefs.setStringList(_note_key, note_json);
  }

  static Future<List<note>> get_notes() async {
    final prefs = await SharedPreferences.getInstance();
    final notes_json = prefs.getStringList(_note_key) ?? [];

    return notes_json
      .map((note_json) => note.from_json(jsonDecode(note_json)))
      .toList()
      ..sort((a, b) => b.created_at.compareTo(a.created_at));
  }

  static Future<void> delete_note(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notes_json = prefs.getStringList(_note_key) ?? [];
    
    final List<String> update_note_json = [];
    for (final note_json in notes_json) {
      final note_ = note.from_json(jsonDecode(note_json));
      if (note_.id != id) {
        update_note_json.add(note_json);
      }
    }
    await prefs.setStringList(_note_key, update_note_json);
  }
}