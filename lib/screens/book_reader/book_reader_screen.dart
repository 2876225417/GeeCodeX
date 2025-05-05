// lib/screens/book_reader/book_reader_screen.dart

import 'dart:convert'; // Keep for NoteService potentially
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Keep for bookmarks/notes
import 'package:path/path.dart' as p;

// Project specific imports
import 'package:Geecodex/models/index.dart'; // Assuming Note is exported here
import 'package:Geecodex/services/note_service.dart';
// Import widgets from the new index file
import 'widgets/index.dart';
import 'package:Geecodex/services/reading_time_service.dart';
// Import other screens if needed (like details)
// import 'pdf_details_screen.dart';
import 'package:Geecodex/services/recent_reading_service.dart';
// Enum definition (can be moved to a constants file if used elsewhere)
// enum PdfSourceType { asset, network, file, none } - Now defined in pdf_viewer_wrapper.dart

class ReaderScreen extends StatefulWidget {
  final String? source;
  final PdfSourceType sourceType;

  const ReaderScreen({
    super.key,
    this.source,
    this.sourceType = PdfSourceType.none,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with WidgetsBindingObserver {
  // --- Controllers ---
  late PdfViewerController _pdfViewerController;
  final TextEditingController _searchInputController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  // FocusNode might be needed if managing focus explicitly for page jump/search
  // final FocusNode _pageInputFocusNode = FocusNode();

  // --- State Variables ---
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  bool _isLoading = true;
  bool _isSearchTextViewVisible = false;
  bool _showMenu = false;
  // bool _showNoteDialog = false; // Dialog visibility managed by showDialog now
  bool _isTextSelectionOverlayVisible = false;
  bool _showTopToolbar = true;
  bool _isNightMode = false; // Default to light mode

  String? _currentPdfPath;
  String? _currentFileName;
  PdfSourceType _currentSourceType = PdfSourceType.none;
  int _currentPage = 1;
  int _totalPages = 0;

  String _selectedText = '';
  OverlayEntry? _textSelectionOverlay;
  Offset _textSelectionPosition = Offset.zero;

  // <<< --- Variables for Time Tracking --- >>>
  DateTime? _sessionStartTime; // When the current visible session started
  bool _isPdfCurrentlyLoaded = false; // Track if a PDF is actually loaded
  Book? _currentBookModel; // <<< Add this (optional, see usage below)

  // --- Lifecycle & Initialization ---
  @override
  void initState() {
    super.initState();
    print("ReaderScreen: initState");
    // <<< Add observer for lifecycle events >>>
    WidgetsBinding.instance.addObserver(this);

    _pdfViewerController = PdfViewerController();
    _currentSourceType = widget.sourceType;
    _currentPdfPath = widget.source;

    if (_currentSourceType != PdfSourceType.none && _currentPdfPath != null) {
      _isPdfCurrentlyLoaded = true; // Assume PDF will load
      _loadInitialPdf();
      _startReadingSession(); // Start timer when loading a PDF initially
      // <<< Add to recents when initially loaded >>>
      _addCurrentBookToRecents();
    } else {
      _isPdfCurrentlyLoaded = false;
      _setLoadingState(false);
    }
    _searchResult.addListener(_updateSearchState);
  }

  @override
  void dispose() {
    print("ReaderScreen: dispose");
    // <<< Save duration before disposing >>>
    // <<< Update last page read before disposing >>>
    _updateRecentBookPage();
    _endReadingSessionAndSaveTime();

    // <<< Remove observer >>>
    WidgetsBinding.instance.removeObserver(this);

    _pdfViewerController.dispose();
    _searchInputController.dispose();
    _commentController.dispose();
    _searchResult.removeListener(_updateSearchState);
    _removeTextSelectionOverlay();
    super.dispose();
  }

  // <<< --- Lifecycle Change Handler --- >>>
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("ReaderScreen: AppLifecycleState changed to $state");
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isPdfCurrentlyLoaded) {
          _startReadingSession();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // <<< Update last page read when pausing >>>
        _updateRecentBookPage();
        _endReadingSessionAndSaveTime();
        break;
    }
  }

  // <<< --- Time Tracking Methods --- >>>
  void _startReadingSession() {
    // Only start if not already started and a PDF is loaded
    if (_sessionStartTime == null && _isPdfCurrentlyLoaded) {
      _sessionStartTime = DateTime.now();
      print("ReaderScreen: Started reading session at $_sessionStartTime");
    }
  }

  void _endReadingSessionAndSaveTime() {
    if (_sessionStartTime != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_sessionStartTime!);
      print(
        "ReaderScreen: Ended reading session. Duration: ${duration.inSeconds}s",
      );

      // Save the duration using the service
      if (duration.inSeconds > 0) {
        // Only save meaningful durations
        ReadingTimeService.addReadingDuration(duration);
      }

      // Reset start time for the next session
      _sessionStartTime = null;
    } else {
      print("ReaderScreen: Tried to end session, but no start time recorded.");
    }
  }

  // --- Core Logic Methods (Keep in State) ---

  Future<void> _loadInitialPdf() async {
    // Reset state related to PDF loading
    _isPdfCurrentlyLoaded = true; // Set flag
    _setLoadingState(true);
    if (_currentPdfPath != null) {
      try {
        _currentFileName = p.basename(_currentPdfPath!);
      } catch (e) {
        _currentFileName = "Unknown File";
      }
    }
    await Future.delayed(Duration.zero);
    // Loading state set to false in _onDocumentLoaded
    // Timer started in initState if PDF path is valid
  }

  void _setLoadingState(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

  Future<void> _pickAndLoadPdfFile() async {
    print("ReaderScreen: Picking new PDF file...");
    // <<< End previous session before loading new file >>>
    _endReadingSessionAndSaveTime();

    _setLoadingState(true);
    _removeTextSelectionOverlay();
    _closeSearch();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        final newPath = result.files.single.path!;
        if (newPath == _currentPdfPath) {
          _setLoadingState(false);
          _showSnackBar('This PDF is already open.');
          return;
        }

        if (mounted) {
          _pdfViewerController.dispose(); // Dispose old controller
          _pdfViewerController = PdfViewerController(); // Create new one
          setState(() {
            _currentPdfPath = newPath;
            _currentSourceType = PdfSourceType.file;
            _currentFileName = result.files.single.name;
            _currentPage = 1;
            _totalPages = 0;
            _selectedText = '';
            _searchResult.clear();
            _isSearchTextViewVisible = false;
            _showMenu = false;
            _showTopToolbar = true;
            _isPdfCurrentlyLoaded = true; // Set flag for new PDF
          });
          // <<< Add newly picked file to recents >>>
          // Reset _currentBookModel if it was from a previous book
          _currentBookModel = null;
          // Add basic entry (Option 2 from _addCurrentBookToRecents)
          _addCurrentBookToRecents();

          // <<< Start new session timer after state is updated >>>
          _startReadingSession();
          // _isLoading will be set to false in _onDocumentLoaded
        }
      } else {
        _setLoadingState(false);
        if (mounted) _showSnackBar('No PDF file selected');
      }
    } catch (e) {
      _setLoadingState(false);
      if (mounted) _showSnackBar('Error picking file: $e');
    }
  }

  // --- PDF Event Handlers (Keep in State) ---

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    print(
      "ReaderScreen: Document loaded - ${details.document.pages.count} pages.",
    );
    if (mounted) {
      setState(() {
        _totalPages = details.document.pages.count;
        _currentPage = _pdfViewerController.pageNumber;
        _isLoading = false;
        _showTopToolbar = true;
        _isPdfCurrentlyLoaded = true; // Confirm PDF is loaded
      });
      // Ensure timer is running if it wasn't already (e.g., if initial load failed then succeeded)
      _startReadingSession();
    }
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    print("ReaderScreen: Document load FAILED. Error: ${details.error}");
    // <<< End session if load fails >>>
    _endReadingSessionAndSaveTime();
    _setLoadingState(false);
    if (mounted) {
      setState(() {
        _currentSourceType = PdfSourceType.none;
        _currentPdfPath = null;
        _currentFileName = null;
        _totalPages = 0;
        _currentPage = 1;
        _isPdfCurrentlyLoaded = false; // PDF is not loaded
      });
      _showSnackBar(
        'Error loading PDF: ${details.error}\n${details.description}',
      );
    }
  }

  // <<< --- Recent Reading Methods --- >>>

  // Add/Update the current book in the recent list
  Future<void> _addCurrentBookToRecents() async {
    // Need book details (ID, Title, Author, Cover) and path/page info
    // Option 1: Get Book details from _currentBookModel if passed via arguments
    if (_currentBookModel != null && _currentPdfPath != null) {
      final recentItem = RecentReadingItem.fromBook(
        _currentBookModel!,
        _currentPdfPath,
        _currentPage, // Use current page
        _totalPages, // Use total pages
      );
      await RecentReadingService.addOrUpdateRecentBook(recentItem);
    }
    // Option 2: If only path is known, create a basic entry
    else if (_currentPdfPath != null && _currentFileName != null) {
      // You might need a way to get a unique ID if not from a Book model
      // Using path hashcode is simple but not ideal. A proper ID is better.
      String bookId = _currentPdfPath.hashCode.toString(); // Placeholder ID

      final basicItem = RecentReadingItem(
        bookId: bookId,
        title: _currentFileName ?? "Unknown PDF",
        author: "Unknown Author", // Placeholder
        coverUrl: "", // Placeholder - maybe generate thumbnail later?
        filePath: _currentPdfPath,
        lastPageRead: _currentPage,
        totalPages: _totalPages,
        lastOpened: DateTime.now(),
      );
      await RecentReadingService.addOrUpdateRecentBook(basicItem);
    }
  }

  // Update the last page read for the current book in the recent list
  Future<void> _updateRecentBookPage() async {
    if (!_isPdfCurrentlyLoaded || _currentPdfPath == null) return;

    // Determine the book ID (needs to be consistent with how it was added)
    String? bookId;
    if (_currentBookModel != null) {
      bookId = _currentBookModel!.id.toString();
    } else {
      // Fallback to placeholder ID (use the same logic as in _addCurrentBookToRecents)
      bookId = _currentPdfPath?.hashCode.toString();
    }

    if (bookId != null) {
      await RecentReadingService.updateLastPageRead(
        bookId,
        _currentPage,
        _totalPages,
      );
    }
  }

  // Modify event handlers to update recent page number
  void _onPageChanged(PdfPageChangedDetails details) {
    if (mounted) {
      setState(() {
        _currentPage = details.newPageNumber;
      });
      _removeTextSelectionOverlay();
      // <<< Update recent page number on page change (optional, can be frequent) >>>
      // Consider debouncing this if performance is an issue
      _updateRecentBookPage();
    }
  }

  // --- Search Logic (Keep in State) ---

  void _toggleSearch() {
    setState(() {
      _isSearchTextViewVisible = !_isSearchTextViewVisible;
      if (!_isSearchTextViewVisible) {
        _closeSearch();
      } else {
        _searchInputController.clear();
      }
      _showMenu = false; // Close menu when toggling search
    });
  }

  void _executeSearch() {
    final query = _searchInputController.text.trim();
    if (query.isNotEmpty) {
      // No need to remove/add listener if it's already added in initState/dispose
      _searchResult = _pdfViewerController.searchText(query);
      // Listener will trigger _updateSearchState
    } else {
      _searchResult.clear();
    }
    // Force UI update immediately after search command
    _updateSearchState();
    // Hide keyboard
    FocusScope.of(context).unfocus();
  }

  void _updateSearchState() {
    // This function is called by the listener.
    // We just need to trigger a rebuild if the state is managed here.
    if (mounted) {
      setState(() {
        // Update UI based on _searchResult properties (e.g., currentInstanceIndex)
      });
    }
  }

  void _closeSearch() {
    _searchInputController.clear();
    _searchResult.clear();
    // No need for setState here if _isSearchTextViewVisible is handled elsewhere
  }

  void _clearSearch() {
    _searchInputController.clear();
    _searchResult.clear();
    // Listener will call _updateSearchState, triggering rebuild
  }

  void _searchPrevious() {
    _searchResult.previousInstance();
    // Listener will call _updateSearchState
  }

  void _searchNext() {
    _searchResult.nextInstance();
    // Listener will call _updateSearchState
  }

  // --- Text Selection & Overlay (Keep in State) ---

  void _handleTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    if (details.selectedText != null &&
        details.selectedText!.trim().isNotEmpty) {
      final trimmedText = details.selectedText!.trim();
      // Check if selection actually changed to avoid flicker
      if (_selectedText != trimmedText || !_isTextSelectionOverlayVisible) {
        _selectedText = trimmedText;
        // Use post frame callback to ensure layout is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              details.globalSelectedRegion != null &&
              _selectedText.isNotEmpty) {
            final region = details.globalSelectedRegion!;
            // Improved position calculation
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox;
            final position = renderBox.globalToLocal(
              Offset(
                region.left + (region.width / 2),
                region.top, // Use top for potential placement above
              ),
              ancestor: overlay,
            );

            // Determine position (above or below)
            final screenHeight = MediaQuery.of(context).size.height;
            final safeAreaTop = MediaQuery.of(context).padding.top;
            const menuHeightEstimate = 60.0; // Estimated height of the menu
            final topPosition =
                position.dy - menuHeightEstimate - 10; // Position above text
            final bottomPosition =
                position.dy + region.height + 10; // Position below text

            Offset finalPosition;
            if (topPosition > safeAreaTop) {
              finalPosition = Offset(
                position.dx,
                topPosition,
              ); // Place above if space
            } else {
              finalPosition = Offset(
                position.dx,
                bottomPosition,
              ); // Otherwise place below
            }

            _showTextSelectionMenu(finalPosition, _selectedText);
          } else if (_isTextSelectionOverlayVisible) {
            _removeTextSelectionOverlay(); // Remove if region is null
          }
        });
      }
    } else {
      if (_isTextSelectionOverlayVisible) {
        _selectedText = '';
        _removeTextSelectionOverlay();
      }
    }
  }

  void _showTextSelectionMenu(Offset position, String selectedText) {
    _removeTextSelectionOverlay();

    _textSelectionPosition = position;
    _selectedText = selectedText;

    _textSelectionOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            // Center the menu horizontally, clamp to screen edges
            left: (position.dx - 75).clamp(
              8.0,
              MediaQuery.of(context).size.width - 158.0,
            ), // Approx width 150 + padding
            top: position.dy.clamp(
              MediaQuery.of(context).padding.top,
              MediaQuery.of(context).size.height - 70.0,
            ), // Clamp vertically
            child: TextSelectionMenuItems(
              // Use the extracted widget
              isNightMode: _isNightMode,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: _selectedText));
                _showSnackBar('Copied to clipboard');
                _removeTextSelectionOverlay();
              },
              onAddNote: () {
                _removeTextSelectionOverlay();
                _showAddNoteDialog(); // Call method to show dialog
              },
              // onSearch: () { ... } // Add search callback if implemented
            ),
          ),
    );
    if (mounted) {
      Overlay.of(context).insert(_textSelectionOverlay!);
      setState(() => _isTextSelectionOverlayVisible = true);
    }
  }

  void _removeTextSelectionOverlay() {
    if (_textSelectionOverlay != null) {
      try {
        _textSelectionOverlay!.remove();
      } catch (e) {
        // print("Error removing overlay: $e");
      }
      _textSelectionOverlay = null;
      if (mounted && _isTextSelectionOverlayVisible) {
        // Only call setState if the state is actually changing
        setState(() => _isTextSelectionOverlayVisible = false);
      } else if (mounted) {
        // Ensure state is consistent even if remove is called multiple times
        _isTextSelectionOverlayVisible = false;
      }
    }
  }

  // --- Note Dialog Logic (Keep in State) ---

  void _showAddNoteDialog() {
    if (_selectedText.isEmpty) return;
    // Clear previous comment before showing
    _commentController.clear();
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder:
          (_) => AddNoteDialog(
            // Use the extracted widget
            selectedText: _selectedText,
            commentController: _commentController, // Pass the controller
            isNightMode: _isNightMode,
            onSave: _saveNote,
            onCancel: () {
              Navigator.of(context).pop(); // Close the dialog
              setState(() {
                _selectedText = ''; // Clear selection on cancel
                _commentController.clear();
              });
            },
          ),
    );
  }

  Future<void> _saveNote() async {
    if (_selectedText.isEmpty) return;
    Navigator.of(context).pop(); // Close the dialog first

    // Ensure Note model is correctly imported/defined
    final note = Note(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: _selectedText,
      comment: _commentController.text.trim(),
      source: _currentFileName ?? "Unknown PDF",
      pageNumber: _currentPage.toString(),
      createdAt: DateTime.now(),
      pdfPath: _currentPdfPath ?? "",
    );

    try {
      await NoteService.saveNote(note);
      _showSnackBar('Note saved successfully');
    } catch (e) {
      _showSnackBar('Error saving note: $e');
    }

    if (mounted) {
      setState(() {
        _selectedText = ''; // Clear selection after saving
        _commentController.clear();
      });
    }
  }

  // --- Menu and Action Logic (Keep in State) ---

  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;
      if (_showMenu) {
        _removeTextSelectionOverlay(); // Close selection if opening tools
      }
    });
  }

  void _closeMenu() {
    if (mounted && _showMenu) setState(() => _showMenu = false);
  }

  void _addBookmark() async {
    _closeMenu();
    if (_currentPdfPath == null) {
      _showSnackBar('Cannot add bookmark: No PDF loaded.');
      return;
    }
    // --- Actual Bookmark Logic ---
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use a unique key per PDF, hash code is simple but can collide, path is better if not too long
      String pdfKey = 'bookmarks_${_currentPdfPath.hashCode}';
      List<String> bookmarks = prefs.getStringList(pdfKey) ?? [];
      // Store page number as string or part of a JSON
      String newBookmark =
          _currentPage.toString(); // Simple page number storage
      // Or JSON: String newBookmark = jsonEncode({'page': _currentPage, 'label': 'Page $_currentPage'});

      if (!bookmarks.contains(newBookmark)) {
        bookmarks.add(newBookmark);
        await prefs.setStringList(pdfKey, bookmarks);
        _showSnackBar('Bookmark added for Page $_currentPage');
      } else {
        _showSnackBar('Bookmark already exists for Page $_currentPage');
      }
    } catch (e) {
      _showSnackBar('Error saving bookmark: $e');
    }
  }

  void _viewBookmarks() async {
    _closeMenu();
    if (_currentPdfPath == null) {
      _showSnackBar('Cannot view bookmarks: No PDF loaded.');
      return;
    }
    // --- Show Bookmarks Dialog/Panel ---
    try {
      final prefs = await SharedPreferences.getInstance();
      String pdfKey = 'bookmarks_${_currentPdfPath.hashCode}';
      List<String> bookmarks = prefs.getStringList(pdfKey) ?? [];
      bookmarks.sort(
        (a, b) => int.parse(a).compareTo(int.parse(b)),
      ); // Sort numerically

      if (bookmarks.isEmpty) {
        _showSnackBar('No bookmarks found for this PDF.');
        return;
      }

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Bookmarks'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final pageNum = bookmarks[index];
                    return ListTile(
                      title: Text('Page $pageNum'),
                      onTap: () {
                        Navigator.of(context).pop(); // Close dialog
                        int? page = int.tryParse(pageNum);
                        if (page != null) {
                          _pdfViewerController.jumpToPage(page);
                        }
                      },
                      // Optional: Add delete button
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[300],
                        ),
                        tooltip: 'Delete Bookmark',
                        onPressed: () async {
                          Navigator.of(context).pop(); // Close dialog first
                          bookmarks.removeAt(index);
                          await prefs.setStringList(pdfKey, bookmarks);
                          _showSnackBar('Bookmark deleted.');
                          // Optionally re-open the dialog or update UI
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } catch (e) {
      _showSnackBar('Error loading bookmarks: $e');
    }
  }

  void _zoomIn() {
    _pdfViewerController.zoomLevel += 0.25;
    _closeMenu();
  }

  void _zoomOut() {
    _pdfViewerController.zoomLevel -= 0.25;
    _closeMenu();
  }

  void _showDetails() {
    _closeMenu();
    if (_currentPdfPath != null) {
      Navigator.pushNamed(
        context,
        '/pdf_details', // Ensure this route is defined in your main.dart
        arguments: {'title': _currentFileName, 'path': _currentPdfPath},
      );
    } else {
      _showSnackBar('No PDF loaded to show details.');
    }
  }

  void _toggleNightMode() {
    _closeMenu();
    setState(() => _isNightMode = !_isNightMode);
    _showSnackBar(_isNightMode ? 'Night Mode Enabled' : 'Night Mode Disabled');
  }

  // --- Page Jump Dialog (Keep in State) ---
  void _showPageJumpDialog() {
    final TextEditingController jumpController = TextEditingController(
      text: _currentPage.toString(),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = _isNightMode;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? Colors.grey[850] : Colors.white,
            title: Text(
              'Jump to Page',
              style: TextStyle(
                color: isDark ? colorScheme.onSurface : colorScheme.primary,
              ),
            ),
            content: TextField(
              controller: jumpController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                color: isDark ? colorScheme.onSurface : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Enter page number (1 - $_totalPages)',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _performPageJump(jumpController.text),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? colorScheme.secondary : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _performPageJump(jumpController.text),
                child: Text(
                  'Jump',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  void _performPageJump(String input) {
    Navigator.pop(context); // Close dialog first
    final page = int.tryParse(input);
    if (page != null && page >= 1 && page <= _totalPages) {
      _pdfViewerController.jumpToPage(page);
    } else {
      _showSnackBar(
        'Invalid page number. Please enter a value between 1 and $_totalPages.',
      );
    }
  }

  // --- Utility Methods (Keep in State) ---
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).removeCurrentSnackBar(); // Remove previous snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine if a valid PDF is loaded
    final bool isPdfLoaded = _isPdfCurrentlyLoaded; // Use our state flag

    return Scaffold(
      // Use the extracted AppBar widget
      appBar:
          isPdfLoaded && _showTopToolbar
              ? ReaderAppBar(
                fileName: _currentFileName,
                currentPage: _currentPage,
                totalPages: _totalPages,
                isSearchVisible: _isSearchTextViewVisible,
                isNightMode: _isNightMode,
                onSearchToggle: _toggleSearch,
                onJumpToPage: _showPageJumpDialog,
                onPrevPage: _pdfViewerController.previousPage,
                onNextPage: _pdfViewerController.nextPage,
                searchController: _searchInputController,
                searchResult: _searchResult,
                onExecuteSearch: _executeSearch,
                onClearSearch: _clearSearch, // Pass the correct clear function
                onSearchPrev: _searchPrevious,
                onSearchNext: _searchNext,
              )
              : null, // Hide AppBar if no PDF or if toolbar hidden
      backgroundColor: _isNightMode ? Colors.black : Colors.grey[50],
      body: Stack(
        children: [
          // Main Content Area
          Padding(
            // Adjust top padding if AppBar is hidden BUT content should still avoid status bar
            padding: EdgeInsets.only(
              top:
                  (isPdfLoaded && !_showTopToolbar)
                      ? MediaQuery.of(context).padding.top
                      : 0,
            ),
            child:
                isPdfLoaded
                    ? PdfViewerWrapper(
                      key: ValueKey(
                        _currentPdfPath,
                      ), // Ensure viewer rebuilds on path change
                      sourceType: _currentSourceType,
                      sourcePath: _currentPdfPath!,
                      controller: _pdfViewerController,
                      isNightMode: _isNightMode,
                      onDocumentLoaded: _onDocumentLoaded,
                      onDocumentLoadFailed: _onDocumentLoadFailed,
                      onPageChanged: _onPageChanged,
                      onTextSelectionChanged: _handleTextSelectionChanged,
                      onTap: () {
                        // Toggle toolbar visibility on tap
                        setState(() => _showTopToolbar = !_showTopToolbar);
                        _removeTextSelectionOverlay(); // Hide selection menu on tap
                        _closeMenu(); // Hide tools menu on tap
                      },
                    )
                    : InitialReaderView(
                      // Show initial view if no PDF
                      onOpenFile: _pickAndLoadPdfFile,
                      isNightMode: _isNightMode,
                    ),
          ),

          // Loading Indicator Overlay
          if (_isLoading && isPdfLoaded) // Show only when loading a valid PDF
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Floating Action Button Menu (Bottom Left)
          if (isPdfLoaded) // Only show if PDF is loaded
            Positioned(
              left: 16,
              bottom: 16,
              child: ReaderMenuButton(
                isOpen: _showMenu,
                onPressed: _toggleMenu,
              ),
            ),

          // Tools Menu Card
          if (isPdfLoaded &&
              _showMenu) // Only show if PDF loaded and menu toggled
            Positioned(
              left: 16,
              bottom: 80, // Position above the FAB
              child: ReaderToolsMenu(
                isVisible: _showMenu, // Controls opacity/ignorepointer
                isNightMode: _isNightMode,
                onOpenFile: () {
                  _closeMenu();
                  _pickAndLoadPdfFile();
                },
                // onSearchText: () { _closeMenu(); _toggleSearch(); }, // Removed
                onAddBookmark: _addBookmark,
                onViewBookmarks: _viewBookmarks,
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onShowDetails: _showDetails,
                onToggleNightMode: _toggleNightMode,
                // onTestHttp: kDebugMode ? () { ... } : null, // Conditional based on build mode
              ),
            ),

          // Note Dialog is shown via showDialog, no longer needs to be in the stack here.
        ],
      ),
    );
  }
}

// Ensure Note and NoteService classes/imports are correctly set up
// Ensure PdfSourceType enum is accessible (defined in pdf_viewer_wrapper.dart or globally)
