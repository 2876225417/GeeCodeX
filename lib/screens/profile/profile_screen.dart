import 'dart:convert'; // For jsonEncode/Decode
import 'dart:io'; // For Platform checks

import 'package:flutter/foundation.dart'; // for kDebugMode, kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For network requests
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:path/path.dart' as p; // Not used here currently
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Import the feedback screen
import '../feedback/index.dart';

// --- Constants ---
const String _prefDarkMode = 'profile_dark_mode';
const String _prefBooksRead = 'profile_books_read';
const String _prefNotesCount = 'profile_notes_count';
// Base URL for API calls (use https)
const String _apiBaseUrl = 'http://jiaxing.website';
// Fallback version (will be replaced by dynamic version)
const String _fallbackAppVersion = '0.0.1';

// --- Screen Widget ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- State Variables ---
  bool _isDarkMode = false;
  bool _isLoading = true; // Overall loading state
  bool _isCheckingUpdate = false; // State for update check spinner
  String _currentAppVersion = _fallbackAppVersion; // Holds the dynamic version

  // Statistics
  int _booksRead = 0;
  int _notesCount = 0;

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // dispose method is not strictly needed here unless managing controllers etc.
  // @override
  // void dispose() {
  //   super.dispose();
  // }

  // --- Data Loading ---
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    // Don't show loading indicator if already loading or just refreshing
    final bool showLoading =
        !_isLoading; // Use !isLoading to avoid flicker on refresh
    if (!showLoading) {
      // Only set isLoading true if not already loading
      setState(() => _isLoading = true);
    }

    // Load app version first as it's needed for display and checks
    await _loadAppVersion();
    // Run other loading tasks concurrently
    await Future.wait([_loadThemePreference(), _loadStatistics()]);

    if (mounted && !showLoading) {
      // Use !showLoading matching the initial check
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentAppVersion = packageInfo.version;
          // Append build number in debug mode for clarity - keep version clean for API
          // _currentAppVersion += "+${packageInfo.buildNumber}";
        });
      }
    } catch (e) {
      print("Error loading app version: $e");
      if (mounted) {
        setState(() {
          _currentAppVersion = _fallbackAppVersion; // Use fallback on error
        });
      }
    }
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        // Get system brightness only if no preference is saved
        bool systemIsDark =
            MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        _isDarkMode = prefs.getBool(_prefDarkMode) ?? systemIsDark;
      });
    } catch (e) {
      print("Error loading theme preference: $e");
      if (mounted) _showErrorSnackBar('Failed to load theme setting.');
    }
  }

  Future<void> _saveThemePreference(bool newDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefDarkMode, newDarkMode);
    } catch (e) {
      print("Error saving theme preference: $e");
      if (mounted) _showErrorSnackBar('Failed to save theme setting.');
    }
  }

  Future<void> _loadStatistics() async {
    // TODO: Replace with actual data fetching if needed
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _booksRead = prefs.getInt(_prefBooksRead) ?? 12; // Example defaults
          _notesCount = prefs.getInt(_prefNotesCount) ?? 153;
        });
      }
    } catch (e) {
      print("Error loading statistics: $e");
      if (mounted) _showErrorSnackBar('Failed to load reading statistics.');
    }
  }

  // --- Actions ---
  void _toggleDarkMode(bool value) async {
    // Implement your theme switching logic here (using Provider, Riverpod, etc.)
    // This example just updates local state and saves preference.
    // A real app would likely trigger a theme change via a state management solution.
    if (mounted) setState(() => _isDarkMode = value);
    await _saveThemePreference(value);
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        // Use external application for downloads or web pages
        // This is important for APK downloads on Android, etc.
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) _showErrorSnackBar('Could not launch $urlString');
      }
    } catch (e) {
      print("Error launching URL $urlString: $e");
      if (mounted) {
        _showErrorSnackBar(
          'Could not launch URL. Please check your connection or browser app.',
        );
      }
    }
  }

  void _showAboutDialog() {
    final theme = Theme.of(context);
    // Use dynamic version obtained earlier
    String displayVersion = _currentAppVersion;
    if (kDebugMode) {
      // In debug mode, maybe add build number back for display only
      // This requires getting packageInfo again or storing build number
      // For simplicity, just use the version number here.
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text('About Geecodex'),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'Your personal PDF reading companion.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Version: $displayVersion', // Use dynamic version
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Developed by: ppQwQqq',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  _buildLinkRow(
                    theme: theme,
                    icon: Icons.code,
                    text: 'View Source on GitHub',
                    url: 'https://github.com/2876225417/Geecodex',
                  ),
                  const SizedBox(height: 12),
                  _buildLinkRow(
                    theme: theme,
                    icon: Icons.privacy_tip_outlined,
                    text: 'Privacy Policy',
                    url: '$_apiBaseUrl/privacy', // Example Privacy URL
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  // --- Check for Updates Logic (MODIFIED) ---
  Future<void> _checkForUpdate() async {
    if (_isCheckingUpdate) return; // Prevent concurrent checks
    if (!mounted) return;

    setState(() => _isCheckingUpdate = true);
    _showPersistentSnackBar(
      'Checking for updates...',
    ); // Show immediate feedback

    // --- Determine Platform ---
    String platformString = 'unknown';
    try {
      if (kIsWeb) {
        platformString = 'web';
      } else if (Platform.isAndroid) {
        platformString = 'android';
      } else if (Platform.isIOS) {
        platformString = 'ios';
      } else if (Platform.isLinux) {
        platformString = 'linux';
      } else if (Platform.isMacOS) {
        platformString = 'macos';
      } else if (Platform.isWindows) {
        platformString = 'windows';
      }
    } catch (e) {
      print("Error getting platform: $e");
      // Keep platformString as 'unknown'
    }

    if (platformString == 'unknown') {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('Unsupported platform for update check.');
        setState(() => _isCheckingUpdate = false);
      }
      return;
    }

    // Use the version number without any build metadata (+...)
    final String currentVersionForApi = _currentAppVersion.split('+').first;
    final Uri url = Uri.parse(
      '$_apiBaseUrl/geecodex/app/update_check',
    ); // Correct API endpoint

    print(
      'Checking update for platform: $platformString, version: $currentVersionForApi',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(<String, String>{
              'platform': platformString,
              'current_version': currentVersionForApi,
            }),
          )
          .timeout(const Duration(seconds: 15)); // Slightly longer timeout

      if (!mounted) return; // Check mounted after await
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide "Checking..."

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final bool updateAvailable = data['update_available'] ?? false;

        if (updateAvailable) {
          print('Update found: ${data['latest_version']}');
          // Extract details for the dialog
          final String latestVersion = data['latest_version'] ?? 'N/A';
          final String releaseNotes = data['release_notes'] ?? '';
          final bool isMandatory = data['is_mandatory'] ?? false;
          // We construct the download URL later if user clicks download

          _showUpdateDialog(
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
            isMandatory: isMandatory,
            platform: platformString, // Pass platform for download URL
          );
        } else {
          print('No update available.');
          _showSuccessSnackBar('You have the latest version.');
        }
      } else {
        // Handle server-side errors (4xx, 5xx)
        print('Update check failed: Status Code ${response.statusCode}');
        print('Response body: ${response.body}');
        // Try to parse error message from server if available
        String serverErrorMsg = "Server error: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          serverErrorMsg = errorData['message'] ?? serverErrorMsg;
        } catch (_) {
          // Ignore if response body isn't valid JSON or doesn't have message
        }
        _showErrorSnackBar('Failed to check for updates ($serverErrorMsg).');
      }
    } catch (e) {
      // Handle network errors, timeouts, etc.
      print('Error checking for updates: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).hideCurrentSnackBar(); // Hide checking snackbar on error too
      _showErrorSnackBar('Failed to check for updates. Check connection.');
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  // --- Show Update Dialog (MODIFIED) ---
  void _showUpdateDialog({
    required String latestVersion,
    required String releaseNotes,
    required bool isMandatory,
    required String platform, // Needed to construct download URL
  }) {
    if (!mounted) return;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      // Prevent dismissing by tapping outside if mandatory
      barrierDismissible: !isMandatory,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text('Update Available'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'Version $latestVersion is available.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Release Notes:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Consider limiting height or using specific scroll view if notes are long
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(context).size.height *
                            0.3, // Limit height
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          releaseNotes,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                  if (isMandatory) ...[
                    const SizedBox(height: 16),
                    Text(
                      'This update is mandatory.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: <Widget>[
              // Only show "Later" button if update is NOT mandatory
              if (!isMandatory)
                TextButton(
                  child: const Text('Later'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              FilledButton(
                // Use FilledButton for primary action
                child: const Text('Download'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog first
                  // Construct the URL for the direct download endpoint
                  final downloadUrl =
                      '$_apiBaseUrl/geecodex/app/download/latest/$platform';
                  print('Launching download URL: $downloadUrl');
                  _launchUrl(downloadUrl);
                },
              ),
            ],
          ),
    );
  }

  // --- Utility Methods (Error/Success Snackbars - Unchanged) ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove previous
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Shows a snackbar that doesn't automatically dismiss (Unchanged)
  void _showPersistentSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(
          minutes: 1,
        ), // Long duration, will be hidden manually
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showFeatureNotImplemented() {
    if (!mounted) return;
    _showSuccessSnackBar(
      'Feature coming soon!',
    ); // Use success style for neutral info
  }

  // Helper for links in About dialog (Unchanged)
  Widget _buildLinkRow({
    required ThemeData theme,
    required IconData icon,
    required String text,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(text, style: TextStyle(color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }

  // --- Build Method (Unchanged) ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 1,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                // Added RefreshIndicator for pull-to-refresh
                onRefresh: _loadInitialData, // Refresh reloads everything
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHigh,
                child: CustomScrollView(
                  // Using CustomScrollView for better structure with sections
                  slivers: <Widget>[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // --- Statistics Section ---
                          _buildStatisticsSection(colorScheme, textTheme),
                          const SizedBox(height: 24),
                          // --- Settings Section ---
                          _buildSettingsSection(colorScheme, textTheme),
                          const SizedBox(height: 24),
                          // --- About Section (includes update check now) ---
                          _buildAboutSection(colorScheme, textTheme),
                          const SizedBox(height: 24),
                          // --- Version Info ---
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Text(
                              // Use dynamic version here too
                              'Geecodex v${_currentAppVersion.split('+').first}', // Display clean version
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // --- Build Helper Methods (Unchanged except _buildAboutSection updated below) ---

  Widget _buildSectionTitle(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 12.0),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textTheme.bodySmall?.color?.withOpacity(0.8), // Slightly muted
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Reading Stats', textTheme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatCard(
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    icon: Icons.menu_book_rounded,
                    title: 'Books Read',
                    value: _booksRead.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    icon: Icons.edit_note_rounded,
                    title: 'Notes Created',
                    value: _notesCount.toString(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Settings', textTheme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildSettingItem(
                  colorScheme: colorScheme,
                  icon:
                      _isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode, // Dynamic icon
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: _toggleDarkMode,
                    // activeColor: colorScheme.primary, // Use default theme switch colors
                  ),
                ),
                _buildDivider(indent: 56),
                _buildSettingItem(
                  colorScheme: colorScheme,
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  onTap: _showFeatureNotImplemented,
                ),
                _buildDivider(indent: 56),
                _buildSettingItem(
                  colorScheme: colorScheme,
                  icon: Icons.translate_rounded,
                  title: 'Language',
                  onTap: _showFeatureNotImplemented,
                ),
                _buildDivider(indent: 56),
                _buildSettingItem(
                  colorScheme: colorScheme,
                  icon: Icons.storage_outlined,
                  title: 'Storage & Data',
                  onTap: _showFeatureNotImplemented,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- About Section Widget (incorporates Update Check) ---
  Widget _buildAboutSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About & Support', textTheme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainer,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildSettingItem(
                  colorScheme: colorScheme,
                  icon: Icons.info_outline_rounded,
                  title: 'About Geecodex',
                  onTap: _showAboutDialog,
                ),
                _buildDivider(indent: 56),
                // --- Check for Updates Item ---
                _buildSettingItem(
                  colorScheme: colorScheme,
                  icon: Icons.system_update_alt_rounded,
                  title: 'Check for Updates',
                  // Show spinner if checking, otherwise show arrow (or nothing if disabled)
                  trailing:
                      _isCheckingUpdate
                          ? Container(
                            // Add padding around spinner
                            padding: const EdgeInsets.only(right: 12.0),
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                          : null, // Default arrow will be shown by _buildSettingItem
                  onTap:
                      _isCheckingUpdate
                          ? null
                          : _checkForUpdate, // Disable tap while checking
                  hideArrow:
                      _isCheckingUpdate, // Hide arrow when spinner is shown
                ),
                _buildDivider(indent: 56),
                _buildSettingItem(
                  colorScheme: colorScheme,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _launchUrl('$_apiBaseUrl/privacy'),
                ),
                _buildDivider(indent: 56),
                _buildSettingItem(
                  colorScheme: colorScheme,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Feedback',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeedbackScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider({double indent = 16.0}) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
    );
  }

  // Updated Setting Item to handle disabled state and hide arrow (Unchanged from before)
  Widget _buildSettingItem({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
    bool hideArrow = false,
  }) {
    bool isDisabled = onTap == null;

    return ListTile(
      leading: Icon(
        icon,
        color:
            isDisabled
                ? colorScheme.onSurface.withOpacity(0.38)
                : (iconColor ?? colorScheme.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              isDisabled
                  ? colorScheme.onSurface.withOpacity(0.38)
                  : (titleColor ?? colorScheme.onSurface),
        ),
      ),
      trailing:
          trailing ??
          (hideArrow || isDisabled
              ? null
              : Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              )),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 6.0,
      ),
      onTap: onTap,
      dense: false,
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Handled by Card
      enabled: !isDisabled,
    );
  }
} // End of _ProfileScreenState
