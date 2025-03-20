import 'package:flutter/material.dart';
import 'package:Geecodex/models/book.dart';

class book_card extends StatelessWidget {
  final book m_book;
  final VoidCallback on_tap;

  const book_card({super.key, required this.m_book, required this.on_tap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: on_tap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                m_book.cover_url,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            m_book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            //style: AppTextStyles.bodyMedium,
          ),
          Text(m_book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
