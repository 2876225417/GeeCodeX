// lib/screens/home_screen.dart

import 'package:Geecodex/screens/book_reader_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../pages/home_page.dart';
import 'package:Geecodex/screens/noter_screen.dart';
import 'package:Geecodex/screens/profile_screen.dart';

class home_screen extends StatefulWidget {
  const home_screen({super.key});

  @override
  State<home_screen> createState() => _home_screen_state();
}

class _home_screen_state extends State<home_screen>
    with AutomaticKeepAliveClientMixin {
  int _selected_idx = 2;

  final List<Widget> _pages = [
    home_page(key: const PageStorageKey('home')),
    const Center(child: Text('Favorite')),
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
