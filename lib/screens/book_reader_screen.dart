// lib/screens/book_reader.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';

enum PdfSourceType { asset, network, file, none }

class ReaderScreen extends StatefulWidget {
  final String? source;
  final PdfSourceType sourceType;

  const ReaderScreen({
    super.key,
    this.source,
    this.sourceType = PdfSourceType.none,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PdfViewerController _pdfViewerController;
  final TextEditingController _pageInputController = TextEditingController();
  bool _isLoading = true;
  bool _isSearchViewVisible = false;
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  // 当前PDF文件路径
  String? _currentPdfPath;
  PdfSourceType _currentSourceType = PdfSourceType.none;
  int _currentPage = 1;
  int _totalPages = 0;

  // 控制菜单是否显示
  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();

    // 初始化PDF来源
    _currentPdfPath = widget.source;
    _currentSourceType = widget.sourceType;

    // 如果没有提供源，则提示用户选择文件
    if (_currentSourceType == PdfSourceType.none || _currentPdfPath == null) {
      // 延迟调用以避免在build过程中调用setState
      Future.delayed(Duration.zero, () => _pickPdfFile());
    } else {
      _initializePage();
    }
  }

  Future<void> _initializePage() async {
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  // 选择PDF文件
  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _currentPdfPath = result.files.single.path!;
          _currentSourceType = PdfSourceType.file;
          _isLoading = false;
        });
      } else {
        // 用户取消了选择
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('未选择PDF文件')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择文件时出错: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 去掉AppBar，完全隐藏标题栏
      body: Stack(
        children: [
          Column(
            children: [
              // 顶部页码工具栏
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8, // 考虑状态栏高度
                  bottom: 8,
                  left: 8,
                  right: 8,
                ),
                color: Colors.white,
                child: _buildPageToolbar(),
              ),

              // 搜索栏（如果可见）
              if (_isSearchViewVisible)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜索文本',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          String searchQuery = _pageInputController.text;
                          if (searchQuery.isNotEmpty) {
                            _searchResult = _pdfViewerController.searchText(
                              searchQuery,
                            );
                            _searchResult.addListener(() {
                              if (mounted) setState(() {});
                            });
                          }
                        },
                      ),
                    ),
                    controller: _pageInputController,
                  ),
                ),

              // 搜索结果导航（如果有结果）
              if (_searchResult.hasResult)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_before),
                        onPressed: () {
                          _searchResult.previousInstance();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_next),
                        onPressed: () {
                          _searchResult.nextInstance();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchResult.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),

              // PDF查看器
              Expanded(
                child:
                    _isLoading ||
                            _currentSourceType == PdfSourceType.none ||
                            _currentPdfPath == null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('没有打开的PDF文件'),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _pickPdfFile,
                                child: const Text('打开PDF文件'),
                              ),
                            ],
                          ),
                        )
                        : GestureDetector(
                          onTap: () {
                            // 点击PDF区域时切换菜单显示状态
                            setState(() {
                              _showMenu = !_showMenu;
                            });
                          },
                          child: _buildPdfViewer(),
                        ),
              ),
            ],
          ),

          // 浮动菜单按钮
          if (_showMenu)
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'search',
                    child: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearchViewVisible = !_isSearchViewVisible;
                        if (!_isSearchViewVisible) {
                          _searchResult.clear();
                        }
                        _showMenu = false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'bookmark',
                    child: const Icon(Icons.bookmark),
                    onPressed: () {
                      //_pdfViewerController.openBookmarkView();
                      setState(() {
                        _showMenu = false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'zoomIn',
                    child: const Icon(Icons.zoom_in),
                    onPressed: () {
                      _pdfViewerController.zoomLevel =
                          _pdfViewerController.zoomLevel + 0.25;
                      setState(() {
                        _showMenu = false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'zoomOut',
                    child: const Icon(Icons.zoom_out),
                    onPressed: () {
                      _pdfViewerController.zoomLevel =
                          _pdfViewerController.zoomLevel - 0.25;
                      setState(() {
                        _showMenu = false;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'file',
                    child: const Icon(Icons.folder_open),
                    onPressed: () {
                      _pickPdfFile();
                      setState(() {
                        _showMenu = false;
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed:
              _totalPages > 0 ? () => _pdfViewerController.firstPage() : null,
        ),
        IconButton(
          icon: const Icon(Icons.navigate_before),
          onPressed:
              _totalPages > 0
                  ? () => _pdfViewerController.previousPage()
                  : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _totalPages > 0 ? '$_currentPage / $_totalPages' : '- / -',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.navigate_next),
          onPressed:
              _totalPages > 0 ? () => _pdfViewerController.nextPage() : null,
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          onPressed:
              _totalPages > 0 ? () => _pdfViewerController.lastPage() : null,
        ),
      ],
    );
  }

  Widget _buildPdfViewer() {
    switch (_currentSourceType) {
      case PdfSourceType.network:
        return SfPdfViewer.network(
          _currentPdfPath!,
          controller: _pdfViewerController,
          enableTextSelection: true,
          enableDocumentLinkAnnotation: true,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            setState(() {
              _totalPages = details.document.pages.count;
              _pageInputController.text = '1';
              _currentPage = 1;
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            setState(() {
              _currentPage = details.newPageNumber;
              _pageInputController.text = _currentPage.toString();
            });
          },
        );
      case PdfSourceType.asset:
        return SfPdfViewer.asset(
          _currentPdfPath!,
          controller: _pdfViewerController,
          enableTextSelection: true,
          enableDocumentLinkAnnotation: true,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            setState(() {
              _totalPages = details.document.pages.count;
              _pageInputController.text = '1';
              _currentPage = 1;
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            setState(() {
              _currentPage = details.newPageNumber;
              _pageInputController.text = _currentPage.toString();
            });
          },
        );
      case PdfSourceType.file:
        return SfPdfViewer.file(
          File(_currentPdfPath!),
          controller: _pdfViewerController,
          enableTextSelection: true,
          enableDocumentLinkAnnotation: true,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            setState(() {
              _totalPages = details.document.pages.count;
              _pageInputController.text = '1';
              _currentPage = 1;
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            setState(() {
              _currentPage = details.newPageNumber;
              _pageInputController.text = _currentPage.toString();
            });
          },
        );
      default:
        return const Center(child: Text('请选择PDF文件'));
    }
  }
}
