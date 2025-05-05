// lib/screens/book_browser/book_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // For HttpException

import 'package:Geecodex/constants/index.dart';
import 'package:Geecodex/models/book.dart';
// Import widgets using the index file
import 'widgets/index.dart';

import 'widgets/recently_reading_list.dart';
import 'widgets/recently_reading_header.dart';
import 'package:Geecodex/services/reading_time_service.dart';
import 'package:Geecodex/services/recent_reading_service.dart';

class BookBrowserScreen extends StatefulWidget {
  const BookBrowserScreen({super.key});

  @override
  State<BookBrowserScreen> createState() => _BookBrowserScreenState();
}

class _BookBrowserScreenState extends State<BookBrowserScreen> {
  List<Book> _latestBooks = [];
  bool _isLoadingLatest = true;
  String? _errorLoadingLatest;

  // State variable to hold recent books
  List<RecentReadingItem> _recentBooks = [];
  bool _isLoadingRecents = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestBooks();
    _loadRecentBooks();
  }

  Future<void> _loadRecentBooks() async {
    if (!mounted) return;
    setState(() => _isLoadingRecents = true);
    try {
      final recents = await RecentReadingService.getRecentBooks();
      if (mounted) {
        setState(() {
          _recentBooks = recents;
          _isLoadingRecents = false;
        });
      }
    } catch (e) {
      print("Error loading recent books for browser: $e");
      if (mounted) {
        setState(() => _isLoadingRecents = false);
        // Show error?
      }
    }
  }

  void _onBrowseAllRecents() {
    // TODO: Implement navigation to a screen showing all recent books
    print("Browse All Recents tapped");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Browse All Recents - Not Implemented Yet')),
    );
  }

  Future<void> _fetchLatestBooks() async {
    // Ensure state is reset before fetching
    if (mounted) {
      setState(() {
        _isLoadingLatest = true;
        _errorLoadingLatest = null;
      });
    }

    // final url = Uri.parse('http://localhost:8080/geecodex/books/latest'); // For local testing
    final url = Uri.parse('http://jiaxing.website/geecodex/books/latest');
    const maxBooks = 5; // Limit to 5 books

    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10)); // Add timeout

      if (!mounted) return; // Check if widget is still mounted after await

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        ); // Handle UTF8
        setState(() {
          _latestBooks =
              data
                  .map(
                    (jsonItem) =>
                        Book.fromJson(jsonItem as Map<String, dynamic>),
                  )
                  .take(maxBooks) // Take only the first 5
                  .toList();
          _isLoadingLatest = false;
        });
      } else {
        setState(() {
          _errorLoadingLatest =
              'Failed to load books (Status code: ${response.statusCode})';
          _isLoadingLatest = false;
        });
      }
    } on SocketException {
      // Specific error for network issues
      if (!mounted) return;
      setState(() {
        _errorLoadingLatest = 'Network error. Please check your connection.';
        _isLoadingLatest = false;
      });
    } on FormatException {
      // Specific error for bad JSON
      if (!mounted) return;
      setState(() {
        _errorLoadingLatest = 'Error parsing server response.';
        _isLoadingLatest = false;
      });
    } catch (e) {
      // Catch other potential errors
      if (!mounted) return;
      setState(() {
        _errorLoadingLatest = 'An unexpected error occurred: $e';
        _isLoadingLatest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        // Wrap CustomScrollView with RefreshIndicator
        child: RefreshIndicator(
          onRefresh: _fetchLatestBooks, // Call the fetch method on pull
          color: AppColors.primary, // Customize indicator color
          child: CustomScrollView(
            // Make sure the scroll view can always scroll slightly to trigger refresh,
            // even if content fits on screen.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              const SliverToBoxAdapter(child: SearchBarWidget()),
              const SliverToBoxAdapter(
                child: SectionTitleWidget(title: 'Latest Books'),
              ),
              SliverToBoxAdapter(
                child: FeaturedBooksSection(
                  isLoading: _isLoadingLatest,
                  books: _latestBooks,
                  errorMessage: _errorLoadingLatest,
                  onRetry: _fetchLatestBooks,
                ),
              ),
              const SliverToBoxAdapter(child: ReadingStatsCard()),
              SliverToBoxAdapter(
                child: RecentlyReadingHeader(
                  title: "Continue Reading", // Or "Recently Opened"
                  onBrowseAllPressed: _onBrowseAllRecents,
                ),
              ),
              // Show loading indicator or the list
              _isLoadingRecents
                  ? const SliverFillRemaining(
                    // Use SliverFillRemaining for loading state in CustomScrollView
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : SliverToBoxAdapter(
                    // Use SliverToBoxAdapter for non-sliver list
                    child: RecentlyReadingList(
                      // Pass the fetched recent items
                      recentItems: _recentBooks,
                    ),
                  ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  // Keep SliverAppBar build logic here or in a local function
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      floating: true, // App bar appears when scrolling down
      pinned: false, // Does not stay pinned at the top
      snap: true, // Snaps into view
      backgroundColor: Colors.grey[50], // Match background
      elevation: 0,
      title: Text(
        'Geecodex Library', // More descriptive title
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_none,
            color: AppColors.primary.withOpacity(0.8),
          ),
          tooltip: 'Notifications',
          onPressed: () {
            // TODO: Implement notifications action
          },
        ),
        // IconButton( // Example: Add profile button if needed
        //   icon: Icon(Icons.person_outline, color: AppColors.primary.withOpacity(0.8)),
        //   tooltip: 'Profile',
        //   onPressed: () {
        //      // TODO: Navigate to profile
        //   },
        // ),
        const SizedBox(width: 8), // Add some padding
      ],
    );
  }
}
