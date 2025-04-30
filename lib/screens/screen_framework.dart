// lib/screens/screen_framework.dart

import 'package:flutter/material.dart';
import 'package:Geecodex/screens/book_browser/index.dart';
import 'package:Geecodex/screens/book_favorites/index.dart';
import 'package:Geecodex/screens/book_reader/index.dart';
import 'package:Geecodex/screens/book_notes/index.dart';
import 'package:Geecodex/screens/profile/index.dart';
import 'package:Geecodex/widgets/index.dart';

class screen_framework extends StatefulWidget {
  const screen_framework({super.key});

  @override
  State<screen_framework> createState() => _screen_framework_state();
}

class _screen_framework_state extends State<screen_framework>
    with AutomaticKeepAliveClientMixin {
  int _selected_idx = 2;

  final List<Widget> _pages = [
    book_browser_screen(key: const PageStorageKey('book_browser')),
    //const Center(child: Text('Favorite')),
    const favorite_screen(),
    // 修改这里，将sourceType设置为none，让用户选择文件
    const reader_screen(source_type: pdf_source_type.none),
    const noter_screen(),
    //const Center(child: Text('Notes')),
    //const Center(child: Text('Profile')),
    const profile_screen(),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext buildCtx) {
    super.build(buildCtx);
    return Scaffold(
      body: IndexedStack(index: _selected_idx, children: _pages),
      bottomNavigationBar: convex_bottom_nav_bar(
        selected_idx: _selected_idx,
        on_item_selected: (index) => setState(() => _selected_idx = index),
      ),
    );
  }
}
