import 'dart:convert'; // For jsonEncode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For validation
  bool _isSubmitting = false;
  String? _submissionError; // To display specific errors

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // --- Feedback Submission Logic ---
  Future<void> _submitFeedback() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Don't submit if validation fails
    }

    if (_isSubmitting) return; // Prevent double submission

    setState(() {
      _isSubmitting = true;
      _submissionError = null; // Clear previous errors
    });

    final feedbackText = _feedbackController.text.trim();
    final url = Uri.parse(
      'https://jiaxing.website/geeccodex/user/feedback',
    ); // Use https

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{
          'feedback': feedbackText,
          // You might want to add more info like app version, user ID (if any)
          // 'app_version': '0.0.1', // Example
        }),
      );

      if (!mounted) return; // Check if widget is still in the tree

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success
        _feedbackController.clear(); // Clear the text field
        _showSuccessSnackBar('Feedback submitted successfully! Thank you.');
        // Optionally navigate back after a short delay
        // Future.delayed(const Duration(seconds: 1), () {
        //   if (mounted) Navigator.pop(context);
        // });
      } else {
        // Server error
        print('Feedback submission failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          _submissionError =
              'Failed to submit feedback (Error ${response.statusCode}). Please try again later.';
        });
        _showErrorSnackBar(_submissionError!);
      }
    } catch (e) {
      // Network or other errors
      print('Error submitting feedback: $e');
      if (!mounted) return;
      setState(() {
        _submissionError =
            'An error occurred. Please check your connection and try again.';
      });
      _showErrorSnackBar(_submissionError!);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // --- Utility Methods (Adapted from ProfileScreen) ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
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
        duration: const Duration(seconds: 3), // Slightly longer for success
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 1,
      ),
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          // Wrap content in a Form
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'We appreciate your feedback! Let us know what you think, report a bug, or suggest a feature.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _feedbackController,
                maxLines: 8,
                minLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Enter your feedback here...',
                  labelText: 'Feedback',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainer,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your feedback before submitting.';
                  }
                  if (value.length < 10) {
                    // Optional: minimum length
                    return 'Please provide a bit more detail (at least 10 characters).';
                  }
                  return null; // Return null if valid
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed:
                    _isSubmitting
                        ? null
                        : _submitFeedback, // Disable when submitting
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon:
                    _isSubmitting
                        ? SizedBox(
                          // Show progress indicator
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.onPrimary,
                          ),
                        )
                        : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Feedback',
                ),
              ),
              // Optionally display submission errors directly on the screen
              // if (_submissionError != null) ...[
              //   const SizedBox(height: 16),
              //   Text(
              //     _submissionError!,
              //     style: TextStyle(color: colorScheme.error),
              //     textAlign: TextAlign.center,
              //   ),
              // ]
            ],
          ),
        ),
      ),
    );
  }
}
