
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/book_card.dart';
import '../models/book.dart';


class home_page extends StatefulWidget {
    const home_page({super.key});

    @override
    State<home_page> createState() => _home_page_state();
}

class _home_page_state extends State<home_page> {
  final List<book> _featured_books = [
    // book(
    //   id: '1',
    //   title: '活着',
    //   author: '余华',
    //   cover_url: '',
    //   rating: 9.4,
    // ),
    // book(
    //   id: '2',
    //   title: '百年孤独',
    //   author: '加西亚·马尔克斯',
    //   cover_url: '',
    //   rating: 9.2,
    // ),
    // book(
    //   id: '3',
    //   title: '三体',
    //   author: '刘慈欣',
    //   cover_url: '',
    //   rating: 8.8,
    // ),
  ];

  final List<book> _recent_books = [
    // book(
    //   id: '4',
    //   title: '解忧杂货店',
    //   author: '东野圭吾',
    //   cover_url: 'https://img1.doubanio.com/view/subject/s/public/s27264181.jpg',
    //   rating: 8.5,
    // ),
    // book(
    //   id: '5',
    //   title: '人类简史',
    //   author: '尤瓦尔·赫拉利',
    //   cover_url: 'https://img3.doubanio.com/view/subject/s/public/s27814883.jpg',
    //   rating: 9.1,
    // ),
  ];

  @override
  Widget build(BuildContext buildCtx) {
      return Scaffold( 
        body: SafeArea( 
            child: CustomScrollView( 
                slivers: [
                    SliverAppBar( 
                        floating: true,
                        title: const Text('My Library'),
                        actions: [
                            IconButton( 
                                icon: const Icon(Icons.notifications_none),
                                onPressed: () {},
                            ),
                        ],
                    ),
                    SliverToBoxAdapter( 
                        child: Padding( 
                            padding: const EdgeInsets.all(16.0),
                            child: TextField( 
                                decoration: InputDecoration( 
                                    hintText: 'Searching books...',
                                    prefixIcon: const Icon(Icons.search),
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
                    ),
                    SliverToBoxAdapter( 
                        child: SizedBox( 
                            height: 220,
                            child: ListView.builder( 
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                scrollDirection: Axis.horizontal,
                                itemCount: _featured_books.length,
                                itemBuilder: (context, index) {
                                    return Padding( 
                                        padding: const EdgeInsets.all(4.0),
                                        child: book_card( 
                                            m_book: _featured_books[index],
                                            on_tap: (){},
                                        ),
                                    );
                                },
                            ),
                        ),
                    ),
                    SliverToBoxAdapter( 
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
                                ),
                                child: Row( 
                                    children: [
                                        const Icon(Icons.auto_stories, color: Colors.white, size: 40),
                                        const SizedBox(width: 16),
                                        Column( 
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                const Text('Weekly Reading', style: TextStyle(color: Colors.white70)),
                                                const SizedBox(height: 4),
                                                Text('3 Hours 34 Minutes', style: app_text_styles.heading.copyWith(color: Colors.white)),
                                            ],
                                        ),
                                        const Spacer(),
                                        ElevatedButton( 
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: app_colors.primary),
                                            child: const Text('Reading')
                                        ),
                                    ],
                                ), 
                            ),
                        ),
                    ),
                    SliverToBoxAdapter( 
                        child: Padding( 
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Row( 
                                children: [
                                    Text('Recently Reading', style: app_text_styles.section_title),
                                    TextButton( 
                                        onPressed: (){},
                                        child: const Text("Browsering All"),
                                    ),
                                ],
                            ),
                        ),
                    ),
                    SliverList( 
                        delegate: SliverChildBuilderDelegate( 
                            (context, index) {
                                final book = _recent_books[index];
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
                                        contentPadding: const EdgeInsets.all(8),
                                        leading: ClipRRect( 
                                           borderRadius: BorderRadius.circular(8),
                                           child: Image.network( 
                                                book.cover_url, 
                                                width: 50,
                                                fit: BoxFit.cover
                                            ),
                                        ),
                                        title: Text(book.title),
                                        subtitle: Text(book.author),
                                        trailing: Text( 
                                            '${book.rating}',
                                            style: TextStyle( 
                                                color: app_colors.accent,
                                                fontWeight: FontWeight.bold
                                            ),
                                        ),
                                        onTap: (){},
                                    )
                                    ),
                                    
                                );
                            },
                            childCount: _recent_books.length,
                        ),
                    ),
                    const SliverToBoxAdapter( 
                        child: SizedBox(height: 20),
                    ),
                ],
            ),
        ),
      );
  }
}
