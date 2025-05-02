

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:Geecodex/screens/book_reader/pdf_details_screen.dart';
import 'dart:io';


class book_reader_builder {
  
  static Widget _build_tool_menu_item({
    required IconData icon,
    required String title,
    required VoidCallback on_tap,
  }) {
    return InkWell(
      onTap: on_tap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade700),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _build_divider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }
}