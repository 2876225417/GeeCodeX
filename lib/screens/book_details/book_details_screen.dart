// lib/screens/book_details/book_details_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Geecodex/models/book.dart';
import 'package:Geecodex/constants/index.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p; // Import path package for basename
import 'dart:async';

// Reader Screen and PDF Viewer Wrapper imports (keep as before)
import 'package:Geecodex/screens/book_reader/book_reader_screen.dart';
import 'package:Geecodex/screens/book_reader/widgets/pdf_viewer_wrapper.dart';

// <<< --- ADD FAVORITE IMPORTS --- >>>
import 'package:Geecodex/models/favorite_item.dart';
import 'package:Geecodex/services/favorite_service.dart';

// Enum definition (keep as before or ensure imported)
// enum PdfSourceType { asset, network, file, none }

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});
  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  // Download state variables (keep as before)
  bool _isDownloading = false;
  double? _downloadProgress;
  String _downloadStatus = 'Checking...';
  String? _downloadedFilePath;

  // <<< --- ADD FAVORITE STATE VARIABLES --- >>>
  bool _isFavorite = false;
  bool _isLoadingFavorite = true; // To manage initial check

  @override
  void initState() {
    super.initState();
    // Run both checks concurrently or sequentially
    _initializeScreenState();
  }

  // Combined initialization
  Future<void> _initializeScreenState() async {
    // Start both checks
    final downloadCheckFuture = _checkIfAlreadyDownloaded();
    final favoriteCheckFuture = _checkIfFavorite(); // <<< Call favorite check

    // Wait for both to complete
    await Future.wait([downloadCheckFuture, favoriteCheckFuture]);

    // No need for setState here as individual checks handle it
    print("Screen state initialized.");
  }

  // --- Check if favorite on init ---
  Future<void> _checkIfFavorite() async {
    if (mounted) {
      setState(() => _isLoadingFavorite = true);
    }
    try {
      final favorites = await FavoriteService.getFavorites();
      // Ensure consistent ID comparison (assuming Book.id is int and FavoriteItem.id is String)
      final String currentBookIdStr = widget.book.id.toString();
      final isFav = favorites.any((fav) => fav.id == currentBookIdStr);

      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _isLoadingFavorite = false;
        });
        print("Initial favorite check: Is favorite? $_isFavorite");
      }
    } catch (e) {
      print("Error checking favorite status: $e");
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
        // Optionally show an error or default to not favorite
      }
    }
  }

  // --- Download related functions (keep as before) ---
  Future<String?> _getPotentialFilePath() async {
    /* ... same ... */
    try {
      final String sanitizedTitle = widget.book.title.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final String baseFileName = p.basename(
        '${sanitizedTitle}_${widget.book.id}.pdf',
      );
      Directory? directory;
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        directory ??= await getApplicationSupportDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }
      if (directory == null) return null;
      final downloadsDirPath = p.join(directory.path, 'GeecodexDownloads');
      return p.join(downloadsDirPath, baseFileName);
    } catch (e) {
      print("Error getting potential file path: $e");
      return null;
    }
  }

  Future<void> _checkIfAlreadyDownloaded() async {
    /* ... same ... */
    final potentialPath = await _getPotentialFilePath();
    if (potentialPath == null) {
      if (mounted) setState(() => _downloadStatus = 'Download PDF');
      return;
    }
    final file = File(potentialPath);
    final exists = await file.exists();
    if (mounted) {
      setState(() {
        if (exists) {
          _downloadedFilePath = potentialPath;
          _downloadStatus = 'Open PDF';
          _downloadProgress = 1.0;
        } else {
          _downloadedFilePath = null;
          _downloadStatus = 'Download PDF';
          _downloadProgress = null;
        }
      });
    }
    print("Initial check: File '$potentialPath' exists: $exists");
  }

  Future<bool> _requestStoragePermission() async {
    /* ... same ... */
    if (!Platform.isAndroid) return true;
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    PermissionStatus status;
    if (androidInfo.version.sdkInt >= 33) return true;
    status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) await openAppSettings();
    return false;
  }

  Future<void> _startDownload() async {
    /* ... same ... */
    if (_isDownloading || _downloadedFilePath != null) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = null;
      _downloadStatus = 'Requesting Permission...';
    });
    final bool permissionGranted = await _requestStoragePermission();
    if (!mounted) return;
    if (!permissionGranted) {
      setState(() {
        _isDownloading = false;
        _downloadStatus = 'Permission Denied';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied.')),
      );
      return;
    }
    setState(() {
      _downloadStatus = 'Starting Download...';
    });
    await _performDownload();
  }

  Future<void> _performDownload() async {
    /* ... same ... */
    final String downloadUrl =
        'http://jiaxing.website/geecodex/books/${widget.book.id}';
    final String? filePath = await _getPotentialFilePath();
    if (filePath == null) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadStatus = 'Error: Invalid Path';
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not determine download path.')),
      );
      return;
    }
    final File file = File(filePath);
    final Directory parentDir = file.parent;
    http.Client? client;
    try {
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      if (await file.exists()) {
        /* ... handle already exists ... */
        return;
      }
      client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final http.StreamedResponse response = await client.send(request);
      if (response.statusCode == 200) {
        final contentLength = response.contentLength;
        int bytesReceived = 0;
        final fileSink = file.openWrite();
        Completer<void> downloadCompleter = Completer<void>();
        response.stream.listen(
          (List<int> chunk) {
            try {
              fileSink.add(chunk);
              bytesReceived += chunk.length;
              if (mounted) {
                setState(() {
                  if (contentLength != null && contentLength > 0) {
                    _downloadProgress = bytesReceived / contentLength;
                    _downloadStatus =
                        'Downloading (${(_downloadProgress! * 100).toStringAsFixed(0)}%)';
                  } else {
                    _downloadProgress = null;
                    _downloadStatus =
                        'Downloading (${NumberFormat.compact().format(bytesReceived)} B)';
                  }
                });
              }
            } catch (e) {
              if (!downloadCompleter.isCompleted)
                downloadCompleter.completeError(e);
              fileSink.close();
            }
          },
          onDone: () async {
            try {
              await fileSink.flush();
              await fileSink.close();
              if (mounted) {
                setState(() {
                  _isDownloading = false;
                  _downloadStatus = 'Open PDF';
                  _downloadedFilePath = filePath;
                  _downloadProgress = 1.0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Download complete: ${p.basename(filePath)}'),
                  ),
                );
              }
              if (!downloadCompleter.isCompleted) downloadCompleter.complete();
            } catch (e) {
              if (!downloadCompleter.isCompleted)
                downloadCompleter.completeError(e);
            }
          },
          onError: (e, s) {
            fileSink.close();
            if (mounted) {
              setState(() {
                _isDownloading = false;
                _downloadStatus = 'Download Error';
                _downloadedFilePath = null;
              });
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
            if (!downloadCompleter.isCompleted)
              downloadCompleter.completeError(e);
          },
          cancelOnError: true,
        );
        await downloadCompleter.future;
      } else {
        throw HttpException('Status code: ${response.statusCode}');
      }
    } catch (e, s) {
      print("!!! ERROR in _performDownload block !!!\nError: $e\nStack: $s");
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadStatus = 'Download Error';
          _downloadedFilePath = null;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during download: $e')));
    } finally {
      client?.close();
    }
  }

  Future<void> _openPdf() async {
    /* ... same ... */
    if (_downloadedFilePath == null) {
      await _checkIfAlreadyDownloaded();
      return;
    }
    final file = File(_downloadedFilePath!);
    if (!await file.exists()) {
      setState(() {
        _downloadedFilePath = null;
        _downloadStatus = 'Download PDF';
        _downloadProgress = null;
      });
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReaderScreen(
              source: _downloadedFilePath!,
              sourceType: PdfSourceType.file,
            ),
      ),
    );
  }

  // <<< --- NEW: Toggle Favorite Logic --- >>>
  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite)
      return; // Don't do anything if still loading initial state

    // Indicate processing visually (optional)
    // setState(() => _isLoadingFavorite = true); // Can reuse loading flag

    final String bookIdStr = widget.book.id.toString();
    final bool currentlyIsFavorite = _isFavorite; // Store current state

    try {
      if (currentlyIsFavorite) {
        // --- Remove from Favorites ---
        await FavoriteService.deleteFavorite(bookIdStr);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from Favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // --- Add to Favorites ---
        // Get the potential path, even if not downloaded yet. FavoriteScreen handles missing files.
        final potentialPath =
            await _getPotentialFilePath() ??
            "book_id_$bookIdStr"; // Use placeholder if path fails

        final newItem = FavoriteItem(
          id: bookIdStr,
          // Use book title as filename, path package helps ensure it's just the name part
          fileName:
              p.basename(potentialPath).isNotEmpty
                  ? widget.book.title
                  : "Unknown Title",
          filePath: potentialPath, // Store the potential path
          addedDate: DateTime.now(),
          coverImagePath: widget.book.coverUrl, // Use book cover URL
          // lastPage: 1, // Default value handled by model
          // notes: null, // Default value handled by model
        );
        await FavoriteService.saveFavorite(newItem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to Favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      // Update the UI state only after the operation succeeds
      if (mounted) {
        setState(() {
          _isFavorite = !currentlyIsFavorite;
        });
      }
    } catch (e) {
      print("Error toggling favorite: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating favorites: $e')));
      }
    } finally {
      // Finish processing indicator (optional)
      // if (mounted) {
      //   setState(() => _isLoadingFavorite = false);
      // }
    }
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // ... (Date formatting - same) ...
    String formattedPublishDate = book.publishDate ?? 'N/A';
    try {
      if (book.publishDate != null && book.publishDate!.isNotEmpty) {
        final date = DateTime.parse(book.publishDate!);
        formattedPublishDate = DateFormat.yMMMd().format(date);
      }
    } catch (_) {}

    // Download button state (same as before)
    final bool isDownloaded = _downloadedFilePath != null;
    final IconData downloadButtonIcon =
        _isDownloading
            ? Icons.hourglass_empty
            : (isDownloaded
                ? Icons.folder_open_outlined
                : Icons.download_outlined);
    final String downloadButtonText =
        _isDownloading
            ? _downloadStatus
            : (isDownloaded ? 'Open PDF' : 'Download PDF');
    final Color downloadButtonColor =
        isDownloaded ? Colors.green : colorScheme.primary;
    final VoidCallback? downloadOnPressedAction =
        _isDownloading ? null : (isDownloaded ? _openPdf : _startDownload);

    // --- Favorite Button State ---
    final IconData favoriteIcon =
        _isFavorite ? Icons.favorite : Icons.favorite_border;
    final Color favoriteIconColor =
        _isFavorite ? Colors.redAccent : Colors.grey; // Use grey for outline
    final String favoriteTooltip =
        _isFavorite ? 'Remove from Favorites' : 'Add to Favorites';

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, style: const TextStyle(fontSize: 18)),
        elevation: 1,
        actions: [
          // <<< --- ADD FAVORITE BUTTON HERE --- >>>
          if (!_isLoadingFavorite) // Only show when status is known
            IconButton(
              icon: Icon(favoriteIcon, color: favoriteIconColor),
              tooltip: favoriteTooltip,
              onPressed: _toggleFavorite, // Call the toggle function
            )
          else // Show a loading indicator while checking status
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section (Cover & Basic Info - unchanged) ---
            Row(
              /* ... Same ... */
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180,
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        book.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${book.author}',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoChip(
                        Icons.book_outlined,
                        '${book.pageCount ?? 'N/A'} Pages',
                      ),
                      const SizedBox(height: 6),
                      _buildInfoChip(Icons.language, book.language ?? 'N/A'),
                      const SizedBox(height: 6),
                      _buildInfoChip(
                        Icons.calendar_today_outlined,
                        'Published: $formattedPublishDate',
                      ),
                      const SizedBox(height: 6),
                      _buildInfoChip(
                        Icons.business_outlined,
                        book.publisher ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Download/Open Button (Uses logic defined above) ---
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon:
                      _isDownloading
                          ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              value: _downloadProgress,
                              color: colorScheme.onPrimary,
                            ),
                          )
                          : Icon(downloadButtonIcon),
                  label: Text(downloadButtonText),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: downloadButtonColor,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: downloadOnPressedAction,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Description, Tags, Details (unchanged) ---
            if (book.description != null && book.description!.isNotEmpty) ...[
              Text(
                'Description',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.description!,
                style: textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
            ],
            if (book.tags != null && book.tags!.isNotEmpty) ...[
              Text(
                'Tags',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children:
                    book.tags!
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: colorScheme.secondaryContainer
                                .withOpacity(0.5),
                            labelStyle: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Details',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('ISBN:', book.isbn ?? 'N/A'),
            _buildDetailRow(
              'Downloads:',
              book.downloadCount?.toString() ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets (unchanged) ---
  Widget _buildInfoChip(IconData icon, String text) {
    /* ... Same ... */
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[800], fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    /* ... Same ... */
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
} // End of _BookDetailsScreenState
