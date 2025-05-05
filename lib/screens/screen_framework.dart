// lib/screens/screen_framework.dart

import 'package:flutter/material.dart';
import 'package:Geecodex/screens/book_browser/index.dart';
import 'package:Geecodex/screens/book_favorites/index.dart';
import 'package:Geecodex/screens/book_reader/index.dart';
import 'package:Geecodex/screens/book_notes/index.dart';
import 'package:Geecodex/screens/profile/index.dart';
import 'package:Geecodex/widgets/index.dart';

class ScreenFramework extends StatefulWidget {
  const ScreenFramework({super.key});

  @override
  State<ScreenFramework> createState() => _ScreenFramewokrState();
}

class _ScreenFramewokrState extends State<ScreenFramework>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    BookBrowserScreen(key: const PageStorageKey('book_browser')),
    //const Center(child: Text('Favorite')),
    const FavoriteScreen(),
    // 修改这里，将sourceType设置为none，让用户选择文件
    const ReaderScreen(),
    const BookNotesScreen(),
    //const Center(child: Text('Notes')),
    //const Center(child: Text('Profile')),
    const ProfileScreen(),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext buildCtx) {
    super.build(buildCtx);
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: ConvexBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
