// lib/screens/book_browser/widgets/section_title_widget.dart
import 'package:flutter/material.dart';
import 'package:Geecodex/constants/index.dart'; // For AppTextStyles

class SectionTitleWidget extends StatelessWidget {
  final String title;

  const SectionTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Adjusted padding
      child: Text(title, style: AppTextStyles.sectionTitle),
    );
  }
}
