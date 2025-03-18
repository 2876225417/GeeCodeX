
// lib/screens/noter_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'book_reader_screen.dart';

class noter_screen extends StatefulWidget {
  const noter_screen({Key? key}) : super(key: key);

  @override
  State<noter_screen> createState() => _noter_screen_state();
}

class _noter_screen_state extends State<noter_screen> {
  List<note> _notes = [];
  bool _is_loading = true;

  @override
  void initState() {
    super.initState();
    _load_notes();
  }

  Future<void> _load_notes() async {
    setState(() {
      _is_loading = true;
    });

    try {
      final notes = await note_service.get_notes();
      setState(() {
        _notes = notes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notes: $e')),
        );
      } 
    } finally {
      setState(() {
        _is_loading = false;
      });
    }
  }

  Future<void> _delete_notes(String id) async {
    try {
      await note_service.delete_node(id);
      await _load_notes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted')),
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete note: $e')),
        );
      }
    }
  }

  
  @override
  Widget build(BuildContext build_ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load_notes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _is_loading 
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? _build_empty_state()
              : _build_note_list(),
    );
  }

  Widget _build_empty_state() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add notes when reading...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build_note_list() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note_ = _notes[index];
        return _build_note_card(note_);
      },
    );
  }

  Widget _build_note_card(note note_) {
    final date_format = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note_.source,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${note_.page_number} page",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                note_.text,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            if (note_.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note_.comment,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date_format.format(note_.created_at),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      onPressed: () { _show_edit_note_dialog(note_); },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Edit',
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red.shade400
                      ),
                      onPressed: () { _show_delete_confirmation_dialog(note_); },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _show_delete_confirmation_dialog(note note_) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Confirm to delete this note?'),
        actions: [
          TextButton(
            onPressed: () { Navigator.of(context).pop(); },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _delete_notes(note_.id);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _show_edit_note_dialog(note note_) {
    final comment_controller = TextEditingController(text: note_.comment);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                note_.text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: comment_controller,
              decoration: const InputDecoration(
                labelText: 'Annotation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.of(context).pop(); },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final updated_note = note(
                id: note_.id,
                text: note_.text,
                comment: note_.comment,
                source: note_.source,
                page_number: note_.page_number,
                created_at: note_.created_at,
              );

              await note_service.delete_node(note_.id);
              
              await note_service.save_note(updated_note);
              
              await _load_notes();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Noted Updated')),
                );
              }
            }, 
            child: const Text('Save'), 
          ),
        ],
      ),
    );
  }

  void _show_note_detail_dialog(note note_) {
    final date_format = DateFormat('yyyy-MM-dd HH;mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          note_.source,
          style: const TextStyle(fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(note_.text),
              ),
              const SizedBox(height: 16),
              if (note_.comment.isNotEmpty) ...[
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(note_.comment),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page: ${note_.page_number}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    date_format.format(note_.created_at),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () { 
              Navigator.of(context).pop();
              _show_edit_note_dialog(note_);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () { Navigator.of(context).pop(); },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _show_categories_dialog() {
    final Map<String, List<note>> categorized_by_source = {};
    for (final note_ in _notes) {
      if (!categorized_by_source.containsKey(note_.source)) {
        categorized_by_source[note_.source] = [];
      }
      categorized_by_source[note_.source]!.add(note_);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Categorized by Source'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categorized_by_source.length,
            itemBuilder: (context, index) {
              final source = categorized_by_source.keys.elementAt(index);
              final count = categorized_by_source[source]!.length;

              return ListTile(
                title: Text(source),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _show_notes_from_source(source, categorized_by_source[source]!);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.of(context).pop(); },
          child: const Text('Close'),),
        ],
      ),
    );
  }

  void _show_notes_from_source(String source, List<note> notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('From: $source'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note_ = notes[index];
              return ListTile(
                title: Text(
                  note_.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${note_.page_number}page'),
                onTap: () {
                  Navigator.of(context).pop();
                  _show_note_detail_dialog(note_);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}