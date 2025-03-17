// lib/screens/book_reader_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';

enum pdf_source_type { asset, network, file, none }

class reader_screen extends StatefulWidget {
  /// *source filename
  final String? source;

  /// *source filetype
  /// @default value: none
  final pdf_source_type source_type;

  const reader_screen({
    super.key,
    this.source,
    this.source_type = pdf_source_type.none,
  });

  @override
  State<reader_screen> createState() => _reader_screen_state();
}

class _reader_screen_state extends State<reader_screen> {
  late PdfViewerController _pdf_viewer_controller;
  final TextEditingController _page_input_controller = TextEditingController();

  PdfTextSearchResult _search_result = PdfTextSearchResult();

  /// *loading status
  bool _is_loading = true;

  /// *text searching bar visible status
  bool _is_search_text_view_visible = false;

  /// *current source attributes
  String? _current_pdf_path;
  pdf_source_type _current_source_type = pdf_source_type.none;
  int _current_page = 1;
  int _total_pages = 0;

  /// *menu visible visible status
  bool _show_menu = false;

  @override
  void initState() {
    super.initState();
    _pdf_viewer_controller = PdfViewerController();

    _current_pdf_path = widget.source;
    _current_source_type = widget.source_type;

    if (_current_page == pdf_source_type.none || _current_pdf_path == null)
      Future.delayed(Duration.zero, () => _pick_pdf_file());
    else
      _initialize_page();
  }

  Future<void> _initialize_page() async {
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() => _is_loading = false);
    });
  }

  @override
  void dispose() {
    _pdf_viewer_controller.dispose();
    _page_input_controller.dispose();
    super.dispose();
  }

  Future<void> _pick_pdf_file() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _current_pdf_path = result.files.single.path!;
          _current_source_type = pdf_source_type.file;
          _is_loading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No selected PDF file')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error occurs: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext build_ctx) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              /// @top page indicator
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 8,
                  left: 8,
                  right: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade200, Colors.grey.shade100],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _build_page_tool_bar(),
              ),
              if (_is_search_text_view_visible)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Text...',
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          String search_query = _page_input_controller.text;
                          if (search_query.isNotEmpty) {
                            _search_result = _pdf_viewer_controller.searchText(
                              search_query,
                            );
                            _search_result.addListener(() {
                              if (mounted) setState(() {});
                            });
                          }
                        },
                      ),
                    ),
                    controller: _page_input_controller,
                  ),
                ),
              if (_search_result.hasResult)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '${_search_result.currentInstanceIndex}/${_search_result.totalInstanceCount}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_before),
                        onPressed: () {
                          _search_result.previousInstance();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_next),
                        onPressed: () {
                          _search_result.nextInstance();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _search_result.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child:
                    _is_loading ||
                            _current_source_type == pdf_source_type.none ||
                            _current_pdf_path == null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No open PDF file'),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _pick_pdf_file,
                                child: const Text('Open PDF file'),
                              ),
                            ],
                          ),
                        )
                        : _build_pdf_viewer(),
              ),
            ],
          ),

          if (_current_source_type != pdf_source_type.none &&
              _current_pdf_path != null)
            Positioned(
              left: 16,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: 'tools_menu',
                backgroundColor: Colors.blue.shade700,
                child: Icon(_show_menu ? Icons.close : Icons.menu),
                onPressed: () {
                  setState(() {
                    _show_menu = !_show_menu;
                  });
                },
              ),
            ),

          if (_show_menu &&
              _current_source_type != pdf_source_type.none &&
              _current_pdf_path != null)
            Positioned(
              left: 16,
              bottom: 80,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _build_tool_menu_item(
                        icon: Icons.search,
                        title: 'Search Text',
                        on_tap: () {
                          setState(() {
                            _is_search_text_view_visible =
                                !_is_search_text_view_visible;
                            if (!_is_search_text_view_visible)
                              _search_result.clear();
                            _show_menu = false;
                          });
                        },
                      ),
                      _build_divider(),
                      _build_tool_menu_item(
                        icon: Icons.bookmark_border,
                        title: 'Bookmark',
                        on_tap: () {
                          //_pdf_viewer_controller
                          setState(() {
                            _show_menu = false;
                          });
                        },
                      ),
                      _build_divider(),
                      _build_tool_menu_item(
                        icon: Icons.zoom_in,
                        title: 'Zoom In',
                        on_tap: () {
                          _pdf_viewer_controller.zoomLevel =
                              _pdf_viewer_controller.zoomLevel + 0.25;
                          setState(() {
                            _show_menu = false;
                          });
                        },
                      ),
                      _build_divider(),
                      _build_tool_menu_item(
                        icon: Icons.zoom_out,
                        title: 'Zoom Out',
                        on_tap: () {
                          _pdf_viewer_controller.zoomLevel =
                              _pdf_viewer_controller.zoomLevel - 0.25;
                          setState(() {
                            _show_menu = false;
                          });
                        },
                      ),
                      _build_divider(),
                      _build_tool_menu_item(
                        icon: Icons.folder_open,
                        title: 'Open File',
                        on_tap: () {
                          _pick_pdf_file();
                          setState(() {
                            _show_menu = false;
                          });
                        },
                      ),
                      _build_divider(),
                      _build_tool_menu_item(
                        icon: Icons.text_fields,
                        title: 'Pick Text',
                        on_tap: () {
                          setState(() {
                            _show_menu = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _build_tool_menu_item({
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

  Widget _build_divider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }

  Widget _build_page_tool_bar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.first_page, color: Colors.grey.shade700),
          onPressed:
              _total_pages > 0
                  ? () => _pdf_viewer_controller.firstPage()
                  : null,
        ),
        IconButton(
          icon: Icon(Icons.navigate_before, color: Colors.grey.shade700),
          onPressed:
              _total_pages > 0
                  ? () => _pdf_viewer_controller.previousPage()
                  : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _total_pages > 0 ? '$_current_page / $_total_pages' : '-/-',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.navigate_next, color: Colors.grey.shade700),
          onPressed:
              _total_pages > 0 ? () => _pdf_viewer_controller.lastPage() : null,
        ),
        IconButton(
          icon: Icon(Icons.last_page, color: Colors.grey.shade700),
          onPressed:
              _total_pages > 0 ? () => _pdf_viewer_controller.lastPage() : null,
        ),
      ],
    );
  }

  Widget _build_pdf_viewer() {
    switch (_current_source_type) {
      case pdf_source_type.network:
        return SfPdfViewer.network(
          _current_pdf_path!,
          controller: _pdf_viewer_controller,
          enableTextSelection: true,
          enableDoubleTapZooming: true,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            setState(() {
              _total_pages = details.document.pages.count;
              _page_input_controller.text = '1';
              _current_page = 1;
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            setState(() {
              _current_page = details.newPageNumber;
              _page_input_controller.text = _current_page.toString();
            });
          },
        );
      case pdf_source_type.asset:
        return SfPdfViewer.asset(
          _current_pdf_path!,
          controller: _pdf_viewer_controller,
          enableTextSelection: true,
          enableDocumentLinkAnnotation: true,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            setState(() {
              _total_pages = details.document.pages.count;
              _page_input_controller.text = '1';
              _current_page = 1;
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            setState(() {
              _current_page = details.newPageNumber;
              _page_input_controller.text = _current_page.toString();
            });
          },
        );
      case pdf_source_type.file:
        return SfPdfViewer.file(
          File(_current_pdf_path!),
          controller: _pdf_viewer_controller,
          enableTextSelection: true,
          enableDocumentLinkAnnotation: true,
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            setState(() {
              _total_pages = details.document.pages.count;
              _page_input_controller.text = '1';
              _current_page = 1;
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            setState(() {
              _current_page = details.newPageNumber;
              _page_input_controller.text = _current_page.toString();
            });
          },
        );
      default:
        return const Center(child: Text('Please pick a PDF file'));
    }
  }
}
