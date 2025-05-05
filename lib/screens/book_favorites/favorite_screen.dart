// lib/screens/book_favorites/favorite_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

// Import the models and services
import 'package:Geecodex/models/favorite_item.dart';
import 'package:Geecodex/services/favorite_service.dart';

// Import the reader screen
import 'package:Geecodex/screens/book_reader/book_reader_screen.dart';
// Import the PdfSourceType enum (ensure path is correct or define locally)
import 'package:Geecodex/screens/book_reader/widgets/pdf_viewer_wrapper.dart';

// --- Enums (keep as before) ---
enum ViewMode { grid, list }

enum SortMethod { newest, oldest, name }

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<FavoriteItem> _favorites = []; // Holds the raw list from service
  List<FavoriteItem> _filteredFavorites =
      []; // Holds the list after filtering/sorting
  bool _isLoading = true;
  String _searchQuery = ''; // Keep track of search query for filtering

  SortMethod _currentSortMethod = SortMethod.newest;
  ViewMode _currentViewMode = ViewMode.grid; // Default view mode

  @override
  void initState() {
    super.initState();
    print("FavoriteScreen: initState called");
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    print("FavoriteScreen: Loading favorites...");
    if (!mounted) return; // Check mounted at the beginning
    setState(() => _isLoading = true);
    try {
      // Fetch favorites from the service
      final loadedFavorites = await FavoriteService.getFavorites();
      print(
        "FavoriteScreen: Loaded ${loadedFavorites.length} items from service.",
      );

      // Update state only if the widget is still in the tree
      if (mounted) {
        setState(() {
          _favorites = loadedFavorites;
          // Apply current filters and sort to the newly loaded data
          _applyFiltersAndSort();
          _isLoading = false; // Loading complete
        });
        print("FavoriteScreen: State updated with loaded favorites.");
      }
    } catch (e) {
      print("FavoriteScreen: Failed to load favorites - $e");
      if (mounted) {
        setState(() => _isLoading = false); // Stop loading on error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load favorites: $e')));
      }
    }
    // No finally block needed if isLoading is set within setState
  }

  // Applies search filter and sorting method to the _favorites list
  // and updates the _filteredFavorites list.
  void _applyFiltersAndSort() {
    print(
      "FavoriteScreen: Applying filters and sort. Search query: '$_searchQuery', Sort: $_currentSortMethod",
    );
    // Start with the full list
    List<FavoriteItem> filtered = List.from(_favorites);

    // Apply search filter if query exists
    if (_searchQuery.isNotEmpty) {
      final lowerCaseQuery = _searchQuery.toLowerCase();
      filtered =
          filtered
              .where(
                (item) => item.fileName.toLowerCase().contains(lowerCaseQuery),
              )
              .toList();
      print(
        "FavoriteScreen: Filtered by search, ${filtered.length} items remain.",
      );
    }

    // Apply sorting
    switch (_currentSortMethod) {
      case SortMethod.newest:
        filtered.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
      case SortMethod.oldest:
        filtered.sort((a, b) => a.addedDate.compareTo(b.addedDate));
        break;
      case SortMethod.name:
        filtered.sort(
          (a, b) =>
              a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()),
        );
        break;
    }
    print("FavoriteScreen: Sorted list, ${filtered.length} items remain.");

    // No need for setState here if called from within another setState or if
    // the build method directly uses the result. But it's safer to update the state variable.
    // Update the state variable that the UI uses
    if (mounted) {
      setState(() {
        _filteredFavorites = filtered;
      });
    } else {
      _filteredFavorites =
          filtered; // Update directly if not mounted (less likely needed)
    }
  }

  // Method and parameter names updated
  void _openPdf(FavoriteItem item) {
    print("FavoriteScreen: Opening PDF: ${item.fileName} at ${item.filePath}");

    // <<< ADD File Existence Check >>>
    final file = File(item.filePath);
    if (!file.existsSync()) {
      print(
        "FavoriteScreen: File does not exist for ${item.fileName}. Cannot open.",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open: File not found for "${item.fileName}"'),
          backgroundColor: Colors.red[700], // Make error more visible
        ),
      );
      return; // Stop execution
    }
    // <<< END File Existence Check >>>

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReaderScreen(
              // Parameter and property names updated
              source: item.filePath,
              // <<< ENSURE sourceType is passed correctly >>>
              sourceType:
                  PdfSourceType
                      .file, // Assuming PdfSourceType enum is accessible
            ),
      ),
    ).then((_) {
      // Reload favorites when returning, in case page number changed etc.
      // Method name updated
      print("FavoriteScreen: Returned from ReaderScreen, reloading favorites.");
      _loadFavorites();
    });
  }

  // Delete a favorite item
  Future<void> _deleteFavorite(FavoriteItem item) async {
    print("FavoriteScreen: Attempting to delete: ${item.fileName}");
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove from Favorites'),
            content: Text('Remove "${item.fileName}" from favorites?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await FavoriteService.deleteFavorite(item.id);
        print("FavoriteScreen: Deleted ${item.fileName} from service.");
        // Optimistic UI update (remove immediately)
        if (mounted) {
          setState(() {
            _favorites.removeWhere((fav) => fav.id == item.id);
            _filteredFavorites.removeWhere(
              (fav) => fav.id == item.id,
            ); // Remove from both lists
          });
        }
        // _loadFavorites(); // Alternatively, reload fully from service
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        print("FavoriteScreen: Failed to delete ${item.fileName} - $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
        }
      }
    }
  }

  // Edit notes for a favorite item
  void _editNotes(FavoriteItem item) {
    print("FavoriteScreen: Editing notes for: ${item.fileName}");
    final TextEditingController notesController = TextEditingController(
      text: item.notes,
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Notes'),
            content: TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Add notes about this book...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final updatedItem = FavoriteItem(
                    id: item.id,
                    filePath: item.filePath,
                    fileName: item.fileName,
                    addedDate: item.addedDate,
                    coverImagePath: item.coverImagePath,
                    lastPage: item.lastPage,
                    notes: notesController.text.trim(),
                  );
                  Navigator.of(context).pop(); // Close dialog first
                  try {
                    await FavoriteService.saveFavorite(
                      updatedItem,
                    ); // Save updates
                    print("FavoriteScreen: Notes saved for ${item.fileName}.");
                    _loadFavorites(); // Reload to reflect changes
                  } catch (e) {
                    print(
                      "FavoriteScreen: Failed to save notes for ${item.fileName} - $e",
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save notes: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    print(
      "FavoriteScreen: build called. isLoading: $_isLoading, favorite count: ${_favorites.length}, filtered count: ${_filteredFavorites.length}",
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          // Search Button
          // Inside build method -> AppBar -> actions -> search IconButton
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Favorites',
            onPressed: () async {
              // Use showSearch and handle the result
              final String? queryResult = await showSearch<String?>(
                // <<< ENSURE <String?> is here
                context: context,
                delegate: _FavoriteSearchDelegate(
                  // Pass necessary arguments if the delegate constructor needs them
                  // In the provided delegate code, the constructor was removed,
                  // so no arguments are needed here based on that version.
                ),
              );
              // Update the state with the new search query and re-apply filters
              if (mounted && queryResult != null) {
                // Check if a query was actually returned
                setState(() {
                  _searchQuery = queryResult; // Use the returned query
                  _applyFiltersAndSort();
                  print("FavoriteScreen: Search returned: $_searchQuery");
                });
              } else if (mounted &&
                  queryResult == null &&
                  _searchQuery.isNotEmpty) {
                // If search was cancelled (returned null) and there was a previous query, clear it
                setState(() {
                  _searchQuery = '';
                  _applyFiltersAndSort();
                  print("FavoriteScreen: Search cancelled/cleared.");
                });
              }
            },
          ),
          // View Mode Toggle Button
          IconButton(
            icon: Icon(
              _currentViewMode == ViewMode.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
            tooltip:
                _currentViewMode == ViewMode.grid ? 'List View' : 'Grid View',
            onPressed: () {
              setState(() {
                _currentViewMode =
                    _currentViewMode == ViewMode.grid
                        ? ViewMode.list
                        : ViewMode.grid;
                print("FavoriteScreen: View mode changed to $_currentViewMode");
              });
            },
          ),
          // Sort Menu Button
          PopupMenuButton<SortMethod>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Favorites',
            onSelected: (SortMethod method) {
              setState(() {
                _currentSortMethod = method;
                _applyFiltersAndSort(); // Re-apply sort
                print(
                  "FavoriteScreen: Sort method changed to $_currentSortMethod",
                );
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: SortMethod.newest,
                    child: Text('Sort by Newest'),
                  ),
                  const PopupMenuItem(
                    value: SortMethod.oldest,
                    child: Text('Sort by Oldest'),
                  ),
                  const PopupMenuItem(
                    value: SortMethod.name,
                    child: Text('Sort by Name (A-Z)'),
                  ),
                ],
          ),
        ],
      ),
      // Use RefreshIndicator for pull-to-refresh functionality
      body: RefreshIndicator(
        onRefresh: _loadFavorites, // Call load favorites on pull
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(), // Delegate content building
      ),
    );
  }

  // Builds the main content area (empty state or list/grid)
  Widget _buildContent() {
    // Check the filtered list first, after loading is complete
    if (_filteredFavorites.isEmpty) {
      // If search is active and list is empty, show "no results"
      if (_searchQuery.isNotEmpty) {
        // Make this stand out more
        return LayoutBuilder(
          // Use LayoutBuilder to ensure ListView has constraints
          builder:
              (context, constraints) => SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(), // Allow refresh even when empty
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No favorites found matching "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              ),
        );
      } else {
        // If no search and list is empty, show the main empty state
        return _buildEmptyState();
      }
    }

    // If we have items, build the grid or list
    return _currentViewMode == ViewMode.grid
        ? _buildGridView()
        : _buildListView();
  }

  // Builds the empty state widget
  Widget _buildEmptyState() {
    print("FavoriteScreen: Building empty state.");
    // Ensure the empty state is scrollable for RefreshIndicator
    return LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey.shade400,
                      ), // Changed icon
                      const SizedBox(height: 16),
                      Text(
                        'No Favorites Yet',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add books to your favorites from the details screen using the heart icon.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // Builds the GridView
  Widget _buildGridView() {
    print(
      "FavoriteScreen: Building grid view with ${_filteredFavorites.length} items.",
    );
    // Ensure GridView is scrollable within RefreshIndicator
    return GridView.builder(
      // Add physics to ensure scrolling works with RefreshIndicator, especially if few items
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            MediaQuery.of(context).size.width > 600 ? 3 : 2, // Adaptive columns
        childAspectRatio: 0.75, // Adjust aspect ratio
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredFavorites.length,
      itemBuilder: (context, index) {
        final item = _filteredFavorites[index];
        return _buildGridItem(item);
      },
    );
  }

  // Method name updated, parameter type and name updated
  Widget _buildGridItem(FavoriteItem item) {
    // Variable name updated
    final dateFormat = DateFormat('MMM d, yyyy'); // Consistent naming
    final file = File(item.filePath);
    final fileExists = file.existsSync(); // Check if file exists for visual cue

    return GestureDetector(
      // Use updated method name
      onTap:
          fileExists
              ? () => _openPdf(item)
              : null, // <<< Ensure this calls _openPdf
      child: Opacity(
        // Dim item if file missing
        opacity: fileExists ? 1.0 : 0.6,
        child: Card(
          elevation: 3, // Slightly reduced elevation
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias, // Clip content to rounded corners
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch horizontally
            children: [
              Expanded(
                flex: 3, // Give more space to the icon/cover area
                child: Container(
                  color: Colors.grey[200], // Default background
                  child:
                      item.coverImagePath != null &&
                              item.coverImagePath!.isNotEmpty
                          ? _buildCoverImage(
                            item.coverImagePath!,
                          ) // Use helper for image
                          : Center(
                            child: Icon(
                              Icons.book_outlined,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                          ),
                ),
              ),
              Expanded(
                flex: 2, // Give less space to text details
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Reduced padding
                  child: Column(
                    // <<< This is the inner Column causing potential overflow
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween, // REMOVE or CHANGE this
                    mainAxisAlignment:
                        MainAxisAlignment.start, // <<< CHANGE TO THIS
                    children: [
                      // <<< WRAP filename Text with Flexible >>>
                      Flexible(
                        child: Text(
                          // Property name updated
                          item.fileName,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ), // Use theme
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4), // <<< ADD some space
                      // --- Inner Column for page/date/warning ---
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!fileExists) // Show missing file warning prominently
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child: Text(
                                'File Missing!',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Text(
                            'Page ${item.lastPage}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ), // Use theme
                          ),
                          const SizedBox(height: 2),
                          // Use updated variable and property names
                          Text(
                            dateFormat.format(item.addedDate),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ), // Use theme
                          ),
                        ],
                      ),
                      // --- End Inner Column ---
                    ],
                  ),
                ),
              ),
              // Actions row (Keep as before)
              Padding(
                /* ... actions row ... */
                padding: const EdgeInsets.only(
                  left: 4.0,
                  right: 4.0,
                  bottom: 4.0,
                ), // Adjust padding
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // Align buttons to the right
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_note,
                        size: 20,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      tooltip: 'Edit Notes',
                      onPressed: () => _editNotes(item),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      splashRadius: 20,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      tooltip: 'Remove Favorite',
                      onPressed: () => _deleteFavorite(item),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the ListView
  Widget _buildListView() {
    print(
      "FavoriteScreen: Building list view with ${_filteredFavorites.length} items.",
    );
    // Ensure ListView is scrollable within RefreshIndicator
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _filteredFavorites.length,
      itemBuilder: (context, index) {
        final item = _filteredFavorites[index];
        return _buildListItem(item);
      },
    );
  }

  // Builds a single List item
  Widget _buildListItem(FavoriteItem item) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final file = File(item.filePath);
    final fileExists = file.existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 56, // Slightly wider for list view
          height: 70, // Taller for list view aspect ratio
          decoration: BoxDecoration(
            color: Colors.grey[200], // Default background
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias, // Clip the image/icon
          child:
              item.coverImagePath != null && item.coverImagePath!.isNotEmpty
                  ? _buildCoverImage(item.coverImagePath!) // Use helper
                  : Center(
                    child: Icon(Icons.book_outlined, color: Colors.grey[600]),
                  ),
        ),
        title: Text(
          item.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Added: ${dateFormat.format(item.addedDate)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'Page ${item.lastPage}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                if (!fileExists)
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          // Keep trailing actions compact
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_note,
                color: Theme.of(context).colorScheme.secondary,
              ),
              tooltip: 'Edit Notes',
              onPressed: () => _editNotes(item),
              splashRadius: 20,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Remove Favorite',
              onPressed: () => _deleteFavorite(item),
              splashRadius: 20,
            ),
          ],
        ),
        onTap:
            fileExists
                ? () => _openPdf(item)
                : null, // Disable tap if file missing
        enabled: fileExists, // Visual cue for disabled state
      ),
    );
  }

  // Helper to build cover image with error handling
  Widget _buildCoverImage(String imagePath) {
    // Check if it's a network URL or local path
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity, // Fill container
        height: double.infinity,
        errorBuilder:
            (context, error, stackTrace) => Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
            ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
      );
    } else {
      // Assume local file path
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder:
              (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey[400],
                ),
              ),
        );
      } else {
        // File path exists in model but not on disk
        return Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey[400],
          ),
        );
      }
    }
  }
} // End of _FavoriteScreenState

// --- Search Delegate (Modified for better state handling) ---
class _FavoriteSearchDelegate extends SearchDelegate<String?> {
  // Return query string or null

  // No need to pass favorites list if we search directly in the delegate
  // final List<FavoriteItem> favorites;
  // final Function(FavoriteItem) onSelect; // Removed, selection happens via result

  // _FavoriteSearchDelegate({required this.favorites, required this.onSelect}); // Constructor removed

  List<FavoriteItem> _searchResults = []; // Store results locally

  // Helper to perform the search based on the current query
  Future<void> _performSearch(String currentQuery) async {
    if (currentQuery.isEmpty) {
      _searchResults = [];
      return;
    }
    // Fetch ALL favorites and filter here - might be inefficient for huge lists
    // Alternatively, modify FavoriteService to support search
    final allFavorites = await FavoriteService.getFavorites();
    final lowerCaseQuery = currentQuery.toLowerCase();
    _searchResults =
        allFavorites
            .where(
              (item) => item.fileName.toLowerCase().contains(lowerCaseQuery),
            )
            .toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'Clear',
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ) // Refresh suggestions on clear
      else
        const SizedBox.shrink(),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Back',
      onPressed: () {
        close(context, null);
      },
    ); // Close with null result
  }

  // buildResults is called when user presses search/enter on keyboard
  @override
  Widget buildResults(BuildContext context) {
    // Return the current query to the screen to trigger filtering there
    // Or, display results directly here if preferred
    close(
      context,
      query.trim().isNotEmpty ? query.trim() : null,
    ); // Return query or null if empty
    return const SizedBox.shrink(); // Close immediately
    // --- Alternative: Display results directly ---
    // return FutureBuilder<void>(
    //    future: _performSearch(query), // Perform search based on final query
    //    builder: (context, snapshot) {
    //       if (snapshot.connectionState == ConnectionState.waiting) {
    //          return const Center(child: CircularProgressIndicator());
    //       }
    //       return _buildResultsList(context); // Build list based on _searchResults
    //    },
    // );
  }

  // buildSuggestions is called as the user types
  @override
  Widget buildSuggestions(BuildContext context) {
    // Perform search dynamically as user types and update suggestions
    return FutureBuilder<void>(
      future: _performSearch(query), // Search based on current query
      builder: (context, snapshot) {
        // Optionally show loading indicator while searching suggestions
        // if (snapshot.connectionState == ConnectionState.waiting) { return Center(child: CircularProgressIndicator()); }
        return _buildSuggestionsList(
          context,
        ); // Build list based on _searchResults
      },
    );
  }

  // Helper to build the list view for both results and suggestions
  Widget _buildSuggestionsList(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search favorites by name'));
    }
    if (_searchResults.isEmpty) {
      return Center(child: Text('No results found for "$query"'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return ListTile(
          leading: Icon(
            Icons.book_outlined,
            color: Theme.of(context).colorScheme.secondary,
          ),
          title: Text(item.fileName),
          subtitle: Text('Page ${item.lastPage}'),
          onTap: () {
            query = item.fileName; // Optionally fill query field
            close(
              context,
              item.fileName,
            ); // Return the selected item's name as the query result
          },
        );
      },
    );
  }

  // --- Alternative: Helper to build results list directly in delegate ---
  // Widget _buildResultsList(BuildContext context) {
  //    if (_searchResults.isEmpty) { return Center(child: Text('No results found for "$query"')); }
  //    return ListView.builder(
  //       itemCount: _searchResults.length,
  //       itemBuilder: (context, index) {
  //          final item = _searchResults[index];
  //          return ListTile(
  //             leading: Icon(Icons.book_outlined),
  //             title: Text(item.fileName),
  //             subtitle: Text('Page ${item.lastPage}'),
  //             onTap: () {
  //                close(context, null); // Close search
  //                // Navigate directly from here if needed, or let the screen handle it
  //                // Navigator.push(... ReaderScreen ...);
  //             },
  //          );
  //       },
  //    );
  // }
}
