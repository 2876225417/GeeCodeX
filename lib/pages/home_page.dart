import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/book_card.dart';
import '../models/book.dart';

class home_page extends StatefulWidget {
  const home_page({super.key});

  @override
  State<home_page> createState() => _HomePageState();
}

class _HomePageState extends State<home_page> {
  final List<book> _featuredBooks = [
    book(id: '1', title: '活着', author: '余华', cover_url: '', rating: 9.4),
    book(
      id: '2',
      title: '百年孤独',
      author: '加西亚·马尔克斯',
      cover_url: '',
      rating: 9.2,
    ),
    book(id: '3', title: '三体', author: '刘慈欣', cover_url: '', rating: 8.8),
  ];

  final List<book> _recentBooks = [
    book(id: '4', title: '解忧杂货店', author: '东野圭吾', cover_url: '', rating: 8.5),
    book(id: '5', title: '人类简史', author: '尤瓦尔·赫拉利', cover_url: '', rating: 9.1),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildSectionTitle('Featured Books'),
            _buildFeaturedBooks(),
            _buildReadingStats(),
            _buildRecentlyReadingHeader(),
            _buildRecentlyReadingList(),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Geecodex',
        style: TextStyle(
          color: app_colors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_none, color: app_colors.primary),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.person_outline, color: app_colors.primary),
          onPressed: () {},
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search books...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: app_colors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(title, style: app_text_styles.section_title),
      ),
    );
  }

  SliverToBoxAdapter _buildFeaturedBooks() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: _featuredBooks.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: book_card(m_book: _featuredBooks[index], on_tap: () {}),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildReadingStats() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [app_colors.primary, app_colors.primary_light],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: app_colors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Reading Goal',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '3 Hours 34 Minutes',
                    style: app_text_styles.heading.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: app_colors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Reading',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildRecentlyReadingHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recently Reading', style: app_text_styles.section_title),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(foregroundColor: app_colors.accent),
              child: const Text(
                "Browse All",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildRecentlyReadingList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final book = _recentBooks[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 50,
                  height: 70,
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(Icons.book, color: Colors.grey[600]),
                  ),
                ),
              ),
              title: Text(
                book.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.author),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: 0.3 + (index * 0.2), // 示例进度
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(app_colors.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${30 + (index * 10)}% completed',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: app_colors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: app_colors.accent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${book.rating}',
                      style: TextStyle(
                        color: app_colors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {},
              isThreeLine: true,
            ),
          ),
        );
      }, childCount: _recentBooks.length),
    );
  }
}
