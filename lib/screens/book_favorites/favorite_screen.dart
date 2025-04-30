// lib/screens/favorite_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:Geecodex/screens/book_reader/book_reader_screen.dart';

class favorite_item {
  final String id;
  final String file_path;
  final String file_name;
  final DateTime added_date;
  final String? cover_image_path;
  final int last_page;
  final String? notes;

  favorite_item({
    required this.id,
    required this.file_path,
    required this.file_name,
    required this.added_date,
    this.cover_image_path,
    this.last_page = 1,
    this.notes,
  });

  Map<String, dynamic> to_json() {
    return {
      'id': id,
      'file_path': file_path,
      'file_name': file_name,
      'added_date': added_date.toIso8601String(),
      'cover_image_path': cover_image_path,
      'last_page': last_page,
      'notes': notes,
    };
  }

  factory favorite_item.from_json(Map<String, dynamic> json) {
    return favorite_item(
      id: json['id'],
      file_path: json['file_path'],
      file_name: json['file_name'],
      added_date: json['added_date'],
      cover_image_path: json['cover_image_path'],
      last_page: json['last_page'],
      notes: json['notes'],
    );
  }
}

class favorite_service {
  static const String _favorites_key = 'pdf_favorites';

  static Future<void> save_favorite(favorite_item item) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites_json =
        prefs.getStringList(_favorites_key) ?? [];

    bool exists = false;
    List<String> updated_favorites_json = [];

    for (final favorite_json in favorites_json) {
      final favorite = favorite_item.from_json(jsonDecode(favorite_json));
      if (favorite.id == item.id) {
        updated_favorites_json.add(jsonEncode(item.to_json()));
        exists = true;
      } else {
        updated_favorites_json.add(favorite_json);
      }
    }

    if (!exists) {
      updated_favorites_json.add(jsonEncode(item.to_json()));
    }

    await prefs.setStringList(_favorites_key, updated_favorites_json);
  }

  static Future<List<favorite_item>> get_favorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites_json =
        prefs.getStringList(_favorites_key) ?? [];

    return favorites_json
        .map(
          (favorite_json) => favorite_item.from_json(jsonDecode(favorite_json)),
        )
        .toList()
      ..sort((a, b) => b.added_date.compareTo(a.added_date));
  }

  static Future<void> delete_favorites(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites_json =
        prefs.getStringList(_favorites_key) ?? [];

    final List<String> updated_favorites_json = [];
    for (final favorite_json in favorites_json) {
      final favorite = favorite_item.from_json(jsonDecode(favorite_json));
      if (favorite.id != id) {
        updated_favorites_json.add(favorite_json);
      }
    }

    await prefs.setStringList(_favorites_key, updated_favorites_json);
  }

  static Future<void> updated_last_page(String id, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites_json =
        prefs.getStringList(_favorites_key) ?? [];

    List<String> updated_favorites_json = [];

    for (final favorite_json in favorites_json) {
      final favorite = favorite_item.from_json(jsonDecode(favorite_json));
      if (favorite.id == id) {
        final updated_favorite = favorite_item(
          id: favorite.id,
          file_path: favorite.file_path,
          file_name: favorite.file_name,
          added_date: favorite.added_date,
          cover_image_path: favorite.cover_image_path,
          last_page: page,
          notes: favorite.notes,
        );
        updated_favorites_json.add(jsonEncode(updated_favorite.to_json()));
      } else {
        updated_favorites_json.add(favorite_json);
      }
    }
    await prefs.setStringList(_favorites_key, updated_favorites_json);
  }
}

class favorite_screen extends StatefulWidget {
  const favorite_screen({Key? key}) : super(key: key);

  @override
  State<favorite_screen> createState() => _favorite_screen_state();
}

enum view_mode { grid, list }

enum sort_method { newest, oldest, name }

class _favorite_screen_state extends State<favorite_screen> {
  List<favorite_item> _favorites = [];
  bool _is_loading = true;
  String _search_query = '';
  List<favorite_item> _filtered_favorites = [];

  sort_method _current_sort_method = sort_method.newest;
  view_mode _current_view_mode = view_mode.grid;

  @override
  void initState() {
    super.initState();
    _load_favorites();
  }

  Future<void> _load_favorites() async {
    setState(() {
      _is_loading = true;
    });
    try {
      final favorites = await favorite_service.get_favorites();
      setState(() {
        _favorites = favorites;
        _apply_filters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load favorites: $e')));
      }
    } finally {
      setState(() {
        _is_loading = false;
      });
    }
  }

  void _apply_filters() {
    List<favorite_item> filtered = List.from(_favorites);

    if (_search_query.isNotEmpty) {
      filtered =
          filtered
              .where(
                (item) => item.file_name.toLowerCase().contains(
                  _search_query.toLowerCase(),
                ),
              )
              .toList();
    }

    switch (_current_sort_method) {
      case sort_method.newest:
        filtered.sort((a, b) => b.added_date.compareTo(a.added_date));
        break;
      case sort_method.oldest:
        filtered.sort((a, b) => a.added_date.compareTo(b.added_date));
        break;
      case sort_method.name:
        filtered.sort((a, b) => a.file_name.compareTo(b.file_name));
        break;
    }

    setState(() {
      _filtered_favorites = filtered;
    });
  }

  void _open_pdf(favorite_item item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => reader_screen(
              source: item.file_path,
              source_type: pdf_source_type.file,
            ),
      ),
    ).then((_) {
      _load_favorites();
    });
  }

  Future<void> _delete_favorite(favorite_item item) async {
    final comfired =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Remove from Favorites'),
                content: Text(
                  'Ready to remove "${item.file_name}" from favorites?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (comfired) {
      try {
        await favorite_service.delete_favorites(item.id);
        _load_favorites();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
        }
      }
    }
  }

  void _edit_notes(favorite_item item) {
    final TextEditingController notes_controller = TextEditingController(
      text: item.notes,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Notes'),
            content: TextField(
              controller: notes_controller,
              decoration: const InputDecoration(
                hintText: 'Add notes about this book...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final updated_item = favorite_item(
                    id: item.id,
                    file_path: item.file_path,
                    file_name: item.file_name,
                    added_date: item.added_date,
                    cover_image_path: item.cover_image_path,
                    last_page: item.last_page,
                    notes: notes_controller.text,
                  );

                  await favorite_service.save_favorite(updated_item);
                  _load_favorites();
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext build_ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _favorite_search_delegate(
                  favorites: _favorites,
                  on_select: _open_pdf,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _current_view_mode == view_mode.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
            onPressed: () {
              setState(() {
                _current_view_mode =
                    _current_view_mode == view_mode.grid
                        ? view_mode.list
                        : view_mode.grid;
              });
            },
          ),
          PopupMenuButton<sort_method>(
            icon: const Icon(Icons.sort),
            onSelected: (sort_method method) {
              setState(() {
                _current_sort_method = method;
                _apply_filters();
              });
            },
            itemBuilder:
                (build_ctx) => [
                  const PopupMenuItem(
                    value: sort_method.newest,
                    child: Text('Newest first'),
                  ),
                  const PopupMenuItem(
                    value: sort_method.oldest,
                    child: Text('Oldest first'),
                  ),
                  const PopupMenuItem(
                    value: sort_method.name,
                    child: Text('By name'),
                  ),
                ],
          ),
        ],
      ),
      body:
          _is_loading
              ? const Center(child: CircularProgressIndicator())
              : _favorites.isEmpty
              ? _build_empty_state()
              : _build_favorites_list(),
    );
  }

  Widget _build_empty_state() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No favorites Yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add PDF files to your favorites for quick access',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _build_favorites_list() {
    return _current_sort_method == view_mode.grid
        ? _build_grid_view()
        : _build_list_view();
  }

  Widget _build_grid_view() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filtered_favorites.length,
      itemBuilder: (context, index) {
        final item = _filtered_favorites[index];
        return _build_grid_item(item);
      },
    );
  }

  Widget _build_grid_item(favorite_item item) {
    final data_format = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: () => _open_pdf(item),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.file_name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Page ${item.last_page}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data_format.format(item.added_date),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_note,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                    onPressed: () => _edit_notes(item),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => _delete_favorite(item),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build_list_view() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filtered_favorites.length,
      itemBuilder: (context, index) {
        final item = _filtered_favorites[index];
        return _build_list_item(item);
      },
    );
  }

  Widget _build_list_item(favorite_item item) {
    final date_format = DateFormat('MMM d, yyyy');
    final file = File(item.file_path);
    final file_exists = file.existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.picture_as_pdf, color: Colors.blue.shade700),
        ),
        title: Text(
          item.file_name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Added: ${date_format.format(item.added_date)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Page ${item.last_page}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                if (!file_exists)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'File missing',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_note, color: Colors.blue.shade700),
              onPressed: () => _edit_notes(item),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: () => _delete_favorite(item),
            ),
          ],
        ),
        onTap: file_exists ? () => _open_pdf(item) : null,
      ),
    );
  }
}

class _favorite_search_delegate extends SearchDelegate<favorite_item?> {
  final List<favorite_item> favorites;
  final Function(favorite_item) on_select;

  _favorite_search_delegate({required this.favorites, required this.on_select});

  @override
  List<Widget> buildActions(BuildContext build_ctx) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext build_ctx) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(build_ctx, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext build_ctx) {
    return _build_search_results();
  }

  @override
  Widget buildSuggestions(BuildContext build_ctx) {
    return _build_search_results();
  }

  Widget _build_search_results() {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search for favorites'));
    }
    final results =
        favorites
            .where(
              (item) =>
                  item.file_name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found for $query',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (build_ctx, index) {
        final item = results[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.picture_as_pdf, color: Colors.blue.shade700),
          ),
          title: Text(
            item.file_name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Page ${item.last_page}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            close(build_ctx, item);
            on_select(item);
          },
        );
      },
    );
  }
}
