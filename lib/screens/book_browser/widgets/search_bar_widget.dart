// lib/screens/book_browser/widgets/search_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:Geecodex/constants/index.dart'; // For AppColors

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ), // Adjusted padding
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search books, authors, genres...', // More specific hint
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.primary.withOpacity(0.7),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100], // Lighter fill
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
          ), // Adjusted padding
          isDense: true,
        ),
        // Add onChanged or onSubmitted for actual search functionality later
      ),
    );
  }
}
