// lib/screens/reading_heatmap/reading_heatmap_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:Geecodex/services/reading_time_service.dart';
import 'package:intl/intl.dart';

class ReadingHeatmapScreen extends StatefulWidget {
  const ReadingHeatmapScreen({Key? key}) : super(key: key);

  @override
  State<ReadingHeatmapScreen> createState() => _ReadingHeatmapScreenState();
}

class _ReadingHeatmapScreenState extends State<ReadingHeatmapScreen> {
  // Use intensity levels (e.g., 1-5) for the heatmap dataset
  Map<DateTime, int> _heatmapDatasets = {};
  // Store original seconds data separately for onClick display
  Map<DateTime, int> _originalSecondsData = {};

  bool _isLoading = true;
  DateTime? _endDate;
  DateTime? _startDate;

  // Define intensity thresholds (in seconds) - ADJUST THESE AS NEEDED
  final Map<int, int> _intensityThresholds = {
    // Level: Seconds Threshold (minimum seconds for this level)
    1: 1, // 1 second to 5 minutes
    2: 300, // 5 minutes to 15 minutes
    3: 900, // 15 minutes to 30 minutes
    4: 1800, // 30 minutes to 1 hour
    5: 3600, // 1 hour or more
  };

  @override
  void initState() {
    super.initState();
    // Set end date to today, start date ~6 months prior (start of that day)
    _endDate = DateTime.now();
    final approxStartDate = _endDate!.subtract(const Duration(days: 180));
    _startDate = DateTime(
      approxStartDate.year,
      approxStartDate.month,
      approxStartDate.day,
    );
    _loadHeatmapData();
  }

  // --- Data Loading and Processing ---
  Future<void> _loadHeatmapData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Fetch raw seconds data
      final rawData = await ReadingTimeService.getReadingDataForHeatmap();
      _originalSecondsData = rawData; // Store original data

      // Convert raw seconds to intensity levels for the heatmap
      final datasets = <DateTime, int>{};
      rawData.forEach((date, seconds) {
        datasets[date] = _secondsToIntensity(seconds);
      });

      if (mounted) {
        setState(() {
          _heatmapDatasets = datasets;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading heatmap data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reading data: $e')),
        );
      }
    }
  }

  // Convert seconds to an intensity level (1-5 based on thresholds)
  int _secondsToIntensity(int seconds) {
    if (seconds <= 0) return 0; // Level 0 for no reading
    int intensity = 0;
    // Iterate thresholds in descending order of level
    for (int level in _intensityThresholds.keys.toList().reversed) {
      if (seconds >= _intensityThresholds[level]!) {
        intensity = level;
        break; // Found the highest matching level
      }
    }
    // If seconds > 0 but below lowest threshold, assign level 1
    if (intensity == 0 && seconds > 0) {
      intensity = 1;
    }
    return intensity;
  }

  // Helper to format duration from seconds (keep as before)
  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return "No time";
    if (totalSeconds < 60) return "$totalSeconds sec";
    if (totalSeconds < 3600) return "${(totalSeconds / 60).floor()} min";
    final hours = (totalSeconds / 3600).floor();
    final minutes = ((totalSeconds % 3600) / 60).floor();
    return "${hours}h ${minutes}m";
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Define colorsets using theme colors and intensity levels
    // Use a more distinct color progression
    final Map<int, Color> colorsets = {
      1: colorScheme.primary.withOpacity(0.2), // Lightest
      2: colorScheme.primary.withOpacity(0.4),
      3: colorScheme.primary.withOpacity(0.6),
      4: colorScheme.primary.withOpacity(0.8),
      5: colorScheme.primary, // Darkest
    };

    // Define corresponding text labels for the color tip legend
    final List<Widget> colorTipHelper = [
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          "< 5m",
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          "5-15m",
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          "15-30m",
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          "30-60m",
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          "> 1h",
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Activity'),
        backgroundColor:
            colorScheme.surface, // Use surface for AppBar background
        foregroundColor: colorScheme.onSurface, // Ensure text/icons are visible
        elevation: 1, // Add subtle elevation
      ),
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        // Ensure content is within safe area
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _heatmapDatasets
                    .isEmpty // Check datasets, not original data
                ? _buildEmptyState(theme, colorScheme) // Pass theme data
                : _buildHeatmapContent(
                  theme,
                  colorScheme,
                  colorsets,
                  colorTipHelper,
                ), // Pass data
      ),
    );
  }

  // --- Build Helper Methods ---

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 70,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Reading Data Recorded Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Time spent reading PDFs will appear here as a heatmap.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapContent(
    ThemeData theme,
    ColorScheme colorScheme,
    Map<int, Color> colorsets,
    List<Widget> colorTipHelper,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Title and Date Range ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Reading Time',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              // if (_startDate != null && _endDate != null)
              //   Text(
              //     '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}',
              //     style: theme.textTheme.bodySmall?.copyWith(
              //       color: colorScheme.onSurfaceVariant,
              //     ),
              //   ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Heatmap Calendar ---
          // <<< WRAP the HeatMapCalendar with Center >>>
          Center(
            child: Container(
              // Keep the container for background/padding if desired
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: HeatMapCalendar(
                datasets: _heatmapDatasets,
                colorsets: colorsets,
                colorMode: ColorMode.color,
                defaultColor: colorScheme.surfaceContainerHighest,
                textColor: colorScheme.onSurfaceVariant,
                size: 38,
                margin: const EdgeInsets.all(3.5), // Use 'margin'
                borderRadius: 6,
                monthFontSize: 14,
                weekFontSize: 10,
                showColorTip: true,
                colorTipCount: 5,
                colorTipSize: 14,
                colorTipHelper: colorTipHelper,
                onClick: (date) {
                  /* ... onClick logic ... */
                  final seconds = _originalSecondsData[date] ?? 0;
                  final formattedDuration = _formatDuration(seconds);
                  final formattedDate = DateFormat.yMMMd().format(date);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$formattedDate: $formattedDuration read'),
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ),
          // <<< END WRAP >>>
          const SizedBox(height: 24),

          // --- Total Time Display ---
          FutureBuilder<Duration>(
            future: ReadingTimeService.getTotalReadingTime(
              _startDate!,
              _endDate!,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              } else if (snapshot.hasData) {
                final totalDuration = snapshot.data!;
                final formattedTotal = _formatDuration(totalDuration.inSeconds);
                return Center(
                  // Center the total time info
                  child: Text(
                    "Total in period: $formattedTotal",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink(); // Hide if error or no data
            },
          ),
        ],
      ),
    );
  }
}
