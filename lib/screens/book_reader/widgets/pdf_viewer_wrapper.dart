// lib/screens/book_reader/widgets/pdf_viewer_wrapper.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

enum PdfSourceType { asset, network, file, none }

class PdfViewerWrapper extends StatelessWidget {
  final PdfSourceType sourceType;
  final String sourcePath;
  final PdfViewerController controller;
  final bool isNightMode;
  final Function(PdfDocumentLoadedDetails) onDocumentLoaded;
  final Function(PdfDocumentLoadFailedDetails) onDocumentLoadFailed;
  final Function(PdfPageChangedDetails) onPageChanged;
  final Function(PdfTextSelectionChangedDetails) onTextSelectionChanged;
  final VoidCallback? onTap;

  const PdfViewerWrapper({
    super.key,
    required this.sourceType,
    required this.sourcePath,
    required this.controller,
    required this.isNightMode,
    required this.onDocumentLoaded,
    required this.onDocumentLoadFailed,
    required this.onPageChanged,
    required this.onTextSelectionChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget viewer;

    switch (sourceType) {
      case PdfSourceType.network:
        viewer = SfPdfViewer.network(
          sourcePath,
          key: ValueKey('pdf_viewer_$sourcePath'),
          controller: controller,
          enableTextSelection: true,
          enableDocumentLinkAnnotation: true,
          canShowTextSelectionMenu: false,
          onDocumentLoaded: onDocumentLoaded,
          onDocumentLoadFailed: onDocumentLoadFailed,
          onPageChanged: onPageChanged,
          onTextSelectionChanged: onTextSelectionChanged,
        );
        break;
      case PdfSourceType.asset:
        viewer = SfPdfViewer.asset(
          sourcePath,
          key: ValueKey('pdf_viewer_$sourcePath'),
          controller: controller,
          enableTextSelection: true,
          enableDocumentLinkAnnotation: true,
          canShowTextSelectionMenu: false,
          onDocumentLoaded: onDocumentLoaded,
          onDocumentLoadFailed: onDocumentLoadFailed,
          onPageChanged: onPageChanged,
          onTextSelectionChanged: onTextSelectionChanged,
        );
        break;
      case PdfSourceType.file:
        viewer = SfPdfViewer.file(
          File(sourcePath),
          key: ValueKey('pdf_viewer_$sourcePath'),
          controller: controller,
          enableTextSelection: true,
          enableDocumentLinkAnnotation: true,
          canShowTextSelectionMenu: false,
          onDocumentLoaded: onDocumentLoaded,
          onDocumentLoadFailed: onDocumentLoadFailed,
          onPageChanged: onPageChanged,
          onTextSelectionChanged: onTextSelectionChanged,
        );
        break;
      default:
        viewer = const Center(child: Text('Invalid PDF source.'));
    }

    return onTap != null
        ? GestureDetector(onTap: onTap, child: viewer)
        : viewer;
  }
}
