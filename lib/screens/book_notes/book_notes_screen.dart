// lib/screens/book_notes/book_notes_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // For Clipboard

// Import your Note model and NoteService (adjust paths if needed)
import 'package:Geecodex/services/note_service.dart';
// Import the reader screen components (adjust paths if needed)
import 'package:Geecodex/screens/book_reader/index.dart'; // Assuming ReaderScreen is here
import 'package:Geecodex/screens/book_reader/widgets/pdf_viewer_wrapper.dart'; // For PdfSourceType

class BookNotesScreen extends StatefulWidget {
  const BookNotesScreen({super.key});

  @override
  State<BookNotesScreen> createState() => _BookNotesScreenState();
}

class _BookNotesScreenState extends State<BookNotesScreen> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  // Key for RefreshIndicator if needed for programmatic trigger (optional)
  // final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadNotes();
    // Optional: Listen to search controller changes if needed elsewhere
    // _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Renamed method to reflect pull-to-refresh action
  Future<void> _handleRefresh() async {
    // Clear search when refreshing, or keep it? User preference.
    // Let's clear it for simplicity, assuming refresh means "show all fresh data"
    if (_searchQuery.isNotEmpty) {
      if (mounted) {
        setState(() {
          _searchController.clear();
          _searchQuery = '';
          // _applyFilters will be called within _loadNotes after fetching
        });
      }
    }
    await _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      // Introduce a small delay for visual feedback on refresh (optional)
      // await Future.delayed(const Duration(milliseconds: 500));
      final notes = await NoteService.getNotes();
      if (mounted) {
        setState(() {
          _notes = notes;
          // Sort notes initially (e.g., by creation date descending)
          _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _applyFilters(); // Apply search filter (if any) to the newly loaded notes
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false); // Stop loading on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notes: ${e.toString()}')),
        );
      }
    }
    // No finally block needed as _isLoading is set in both try and catch
  }

  void _applyFilters() {
    final String normalizedQuery = _searchQuery.trim().toLowerCase();
    // No need for mounted check here as it's called within setState or initState
    setState(() {
      if (normalizedQuery.isEmpty) {
        _filteredNotes = List.from(_notes); // Show all if no query
      } else {
        _filteredNotes =
            _notes.where((note) {
              return note.text.toLowerCase().contains(normalizedQuery) ||
                  note.comment.toLowerCase().contains(normalizedQuery) ||
                  note.source.toLowerCase().contains(normalizedQuery) ||
                  note.pageNumber.toString().contains(normalizedQuery);
            }).toList();
      }
      // Sorting is now done once in _loadNotes
      // _filteredNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _deleteNote(String id) async {
    // Optional: Show a confirmation dialog *before* deleting
    // bool? confirmDelete = await showDialog<bool>(...);
    // if (confirmDelete != true) return;

    // Indicate processing (optional)
    // setState(() => _isDeleting = true); // Need an _isDeleting flag

    try {
      await NoteService.deleteNote(id);
      if (mounted) {
        setState(() {
          _notes.removeWhere((note) => note.id == id);
          _applyFilters(); // Update the filtered list immediately
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete note: ${e.toString()}')),
        );
      }
    } finally {
      // if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _updateNote(Note updatedNote) async {
    try {
      await NoteService.saveNote(updatedNote); // saveNote handles updates

      if (mounted) {
        setState(() {
          final index = _notes.indexWhere((n) => n.id == updatedNote.id);
          if (index != -1) {
            _notes[index] = updatedNote;
          }
          // Re-sort if editing might change order (e.g., if sorting by comment)
          // _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _applyFilters(); // Re-apply filters to update the view
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note Updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update note: ${e.toString()}')),
        );
      }
    }
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        // Remove the refresh button action
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh),
        //     onPressed: _loadNotes, // Changed to _handleRefresh if needed
        //     tooltip: 'Refresh Notes',
        //   ),
        // ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            // Wrap the list/content area with RefreshIndicator
            child: RefreshIndicator(
              // key: _refreshIndicatorKey, // Assign key if needed
              onRefresh: _handleRefresh, // Call _handleRefresh on pull
              child:
                  _buildContentArea(), // Build the content (list, empty, loading)
            ),
          ),
        ],
      ),
    );
  }

  // Helper to decide what to show in the main content area
  Widget _buildContentArea() {
    if (_isLoading && _notes.isEmpty) {
      // Show loading only on initial load
      return const Center(child: CircularProgressIndicator());
    } else if (_filteredNotes.isEmpty) {
      // If loading is finished OR notes were already loaded (refreshing)
      // show empty state
      return LayoutBuilder(
        // Use LayoutBuilder to make empty state scrollable for refresh
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Make it always scrollable
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _buildEmptyState(),
            ),
          );
        },
      );
    } else {
      // Show the note list
      return _buildNoteList();
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        8.0,
        16.0,
        12.0,
      ), // Adjusted padding
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search notes...', // Simplified hint text
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    tooltip: 'Clear Search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _applyFilters();
                      });
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0), // Slightly less round
            borderSide: BorderSide(
              color: Colors.grey.shade400, // Slightly darker grey
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5, // Keep focus highlight subtle
            ),
          ),
          filled: true, // Keep filled
          fillColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors
                      .grey
                      .shade800 // Darker fill for dark mode
                  : Colors.grey.shade100, // Lighter fill for light mode
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12, // Standard padding
            horizontal: 16,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final bool isSearching = _searchQuery.isNotEmpty;

    return Padding(
      // Add padding around the content
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.note_alt_outlined,
            size: 70, // Slightly smaller icon
            color: Colors.grey.shade500, // Consistent grey
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'No Results' : 'No Notes Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade700, // Darker grey for title
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            isSearching
                ? 'No notes found matching "$_searchQuery".\nTry a different search term.'
                : 'Your highlights and notes from books will appear here. Pull down to refresh.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600, // Medium grey for body
              height: 1.4, // Improved line spacing
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteList() {
    // Use ListView.separated for dividers (optional but nice)
    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(), // Ensure scroll works with RefreshIndicator
      padding: const EdgeInsets.only(
        left: 12.0, // Slightly less horizontal padding for list itself
        right: 12.0,
        bottom: 20.0, // More bottom padding
        top: 4.0, // Add some top padding below search bar
      ),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final Note note = _filteredNotes[index];
        return _buildNoteCard(note);
      },
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: 8), // Spacing between cards
    );
  }

  Widget _buildNoteCard(Note note) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Simpler, more common date format
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    // Determine card background color based on theme
    final cardBackgroundColor =
        theme.brightness == Brightness.dark
            ? colorScheme.surfaceVariant.withOpacity(
              0.5,
            ) // Subtle background in dark mode
            : colorScheme.surface; // Default surface color in light mode

    // Determine text colors for better contrast
    final primaryTextColor =
        theme.brightness == Brightness.dark
            ? Colors
                .grey
                .shade300 // Lighter text for dark mode
            : Colors.black87; // Darker text for light mode
    final secondaryTextColor =
        Colors.grey.shade500; // Consistent secondary text color

    return Card(
      // margin: const EdgeInsets.symmetric(vertical: 0), // Removed by separatorBuilder
      elevation: 1.0, // Reduced elevation for a flatter look
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Slightly less rounded
        side: BorderSide(
          // Add a subtle border
          color:
              theme.brightness == Brightness.dark
                  ? Colors
                      .grey
                      .shade700 // Border for dark mode
                  : Colors.grey.shade300, // Border for light mode
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showNoteDetailDialog(note),
        onLongPress: () => _showActionBottomSheet(note),
        child: Padding(
          padding: const EdgeInsets.all(14.0), // Slightly reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row (Source & Page) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book, // Keep book icon
                    size: 15,
                    color: colorScheme.primary, // Use primary color
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.source,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600, // Bolder source
                        color: primaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    // Simplified page number display
                    "Page ${note.pageNumber}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // --- Highlighted Text ---
              if (note.text.isNotEmpty) // Only show if text exists
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    note.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.4, // Improve line spacing for readability
                      color: primaryTextColor,
                    ),
                    maxLines: 5, // Limit lines shown in card
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // --- Annotation (Comment) ---
              if (note.comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                    // Optional: border
                    // border: Border.all(
                    //   color: colorScheme.secondary.withOpacity(0.3),
                    // ),
                  ),
                  child: Text(
                    note.comment,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                    maxLines: 3, // Limit lines shown in card
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // --- Footer Row (Date) ---
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  dateFormat.format(
                    note.createdAt.toLocal(),
                  ), // Show in local time
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: secondaryTextColor, // Use secondary text color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Dialogs and Bottom Sheets ---

  // Method remains the same, potentially style AlertDialog more if needed
  void _showDeleteConfirmationDialog(Note note) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text('Delete Note'),
            content: const Text(
              'Are you sure you want to permanently delete this note?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteNote(note.id);
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }

  // Edit Dialog - improved styling
  void _showEditNoteDialog(Note note) {
    final commentController = TextEditingController(text: note.comment);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text('Edit Annotation'),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            content: SingleChildScrollView(
              // Allow content to scroll if needed
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Highlight:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.text,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Your Annotation',
                      hintText: 'Add or edit your thoughts...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true, // Give text field a background
                      fillColor:
                          theme.brightness == Brightness.dark
                              ? Colors
                                  .grey
                                  .shade800 // Dark mode fill
                              : Colors.grey.shade100, // Light mode fill
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    maxLines: 5, // Allow more lines
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                // Make Save more prominent
                style: ElevatedButton.styleFrom(
                  // backgroundColor: theme.colorScheme.primary, // Optional: explicit color
                  // foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: () {
                  final updatedNote = Note(
                    id: note.id,
                    text: note.text,
                    comment: commentController.text.trim(),
                    source: note.source,
                    pageNumber: note.pageNumber,
                    createdAt: note.createdAt,
                    pdfPath: note.pdfPath,
                  );

                  Navigator.of(
                    context,
                  ).pop(); // Close dialog *before* async operation
                  _updateNote(updatedNote); // Call separate update method
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
    );
  }

  // Detail Dialog - improved styling
  void _showNoteDetailDialog(Note note) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              10,
            ), // Adjust padding
            title: Text(
              note.source,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2, // Allow slightly more lines for title
              overflow: TextOverflow.ellipsis,
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Page: ${note.pageNumber} ・ Created: ${dateFormat.format(note.createdAt.toLocal())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (note.text.isNotEmpty)
                    Column(
                      // Add label for highlight
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Highlight:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade100.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            note.text,
                          ), // Make text selectable
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  if (note.comment.isNotEmpty) ...[
                    Text(
                      'Annotation:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        note.comment,
                        style: const TextStyle(height: 1.4),
                      ), // Make selectable
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Date is now combined with Page number above
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            actions: [
              // Added Go to Page button here too for consistency
              TextButton.icon(
                icon: const Icon(Icons.open_in_new_outlined, size: 18),
                label: const Text('Go to Page'),
                onPressed: () => _navigateToPdfPage(note),
              ),
              const Spacer(), // Push buttons to sides
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showEditNoteDialog(note);
                },
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // Bottom Sheet - minor style refinements
  void _showActionBottomSheet(Note note) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        // Add rounded corners to top
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Annotation'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditNoteDialog(note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy Highlight Text'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (note.text.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: note.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Highlight copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                enabled: note.text.isNotEmpty, // Disable if no text
              ),
              if (note.comment.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('Copy Annotation Text'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Clipboard.setData(ClipboardData(text: note.comment));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Annotation copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.open_in_new_outlined),
                title: const Text('Go to Page in PDF'),
                onTap: () => _navigateToPdfPage(note), // Already closes sheet
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Delete Note',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmationDialog(note);
                },
              ),
              const SizedBox(height: 10), // Add padding at the bottom
            ],
          ),
        );
      },
    );
  }

  // Navigate to PDF - Keep logic, ensure ReaderScreen handles args
  void _navigateToPdfPage(Note note) {
    // Close the current dialog/bottom sheet first if it's open
    // Check if a modal route is present before popping.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (note.pdfPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF path not found for this note.')),
      );
      return;
    }

    // Page number parsing should ideally be int from the start in Note model
    // final pageNum = note.pageNumber; // Assuming pageNumber is already int

    // Example if pageNumber is String:
    final int? pageNum = int.tryParse(note.pageNumber.toString());
    if (pageNum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid page number for this note.')),
      );
      return;
    }

    // Determine PdfSourceType (same logic as before)
    PdfSourceType sourceType;
    if (note.pdfPath.startsWith('http://') ||
        note.pdfPath.startsWith('https://')) {
      sourceType = PdfSourceType.network;
    } else if (note.pdfPath.startsWith('/')) {
      sourceType = PdfSourceType.file;
    } else {
      sourceType = PdfSourceType.asset; // Adjust if necessary
    }

    // Navigate to ReaderScreen
    // IMPORTANT: Ensure '/reader' route is defined in your MaterialApp
    // and that ReaderScreen accepts these arguments.
    Navigator.pushNamed(
      context,
      '/reader',
      arguments: {
        'source': note.pdfPath,
        'sourceType': sourceType,
        // Pass the page number (0-based index for most viewers)
        // Check if your PDF viewer uses 0-based or 1-based indexing
        'initialPage': pageNum - 1, // Assuming viewer is 0-based
      },
    ).then((_) {
      // Optional: Refresh notes when returning from reader?
      // _handleRefresh();
    });

    // TODO: Modify ReaderScreen's initState or equivalent to check for
    // 'initialPage' in arguments and use `_pdfViewerController.jumpToPage(initialPage)`
    // *after* the document is loaded (e.g., in `onDocumentLoaded` callback).
    // Example in ReaderScreen:
    // int? initialPage;
    // @override
    // void didChangeDependencies() {
    //   super.didChangeDependencies();
    //   final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    //   if (args != null && args.containsKey('initialPage')) {
    //     initialPage = args['initialPage'];
    //   }
    // }
    // ... inside SfPdfViewer.onDocumentLoaded callback:
    // if (initialPage != null) {
    //   _pdfViewerController.jumpToPage(initialPage!);
    //   initialPage = null; // Prevent jumping again on rebuilds
    // }
  }
}

// --- Assume Note Model looks something like this ---
// (You should have this defined elsewhere)
/*
class Note {
  final String id;
  final String text; // Highlighted text
  final String comment; // Annotation
  final String source; // Book title or filename
  final int pageNumber; // Page number (ideally int)
  final DateTime createdAt;
  final String pdfPath; // Path or URL to the PDF

  Note({
    required this.id,
    required this.text,
    required this.comment,
    required this.source,
    required this.pageNumber,
    required this.createdAt,
    required this.pdfPath,
  });

  // Add factory constructors for fromJson, toJson if needed for storage
}
*/
