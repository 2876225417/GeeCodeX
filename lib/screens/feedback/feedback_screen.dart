import 'dart:convert'; // For jsonEncode
import 'dart:async'; // For Timeout
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package

// API 常量
const String _apiBaseUrl = 'https://jiaxing.website';
const String _feedbackApiEndpoint = '/geecodex/feedback'; // 更新后的路径

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackController = TextEditingController();
  final _nicknameController = TextEditingController(); // 用于昵称的 Controller
  final _formKey = GlobalKey<FormState>(); // For validation
  bool _isSubmitting = false;
  String? _submissionError; // To display specific errors

  @override
  void dispose() {
    _feedbackController.dispose();
    _nicknameController.dispose(); // 释放 nickname controller
    super.dispose();
  }

  // --- Feedback Submission Logic ---
  Future<void> _submitFeedback() async {
    FocusScope.of(context).unfocus(); // Hide keyboard

    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Don't submit if validation fails
    }

    if (_isSubmitting) return; // Prevent double submission

    setState(() {
      _isSubmitting = true;
      _submissionError = null; // Clear previous errors
    });

    final feedbackText = _feedbackController.text.trim();
    final nicknameText = _nicknameController.text.trim(); // 获取昵称文本
    final url = Uri.parse('$_apiBaseUrl$_feedbackApiEndpoint'); // 使用更新后的路径

    Map<String, String> requestBody = {'feedback': feedbackText};

    if (nicknameText.isNotEmpty) {
      requestBody['nickname'] = nicknameText;
    }

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(requestBody), // 发送包含可选昵称的请求体
          )
          .timeout(const Duration(seconds: 15)); // 添加超时

      if (!mounted) return; // Check if widget is still in the tree

      // 根据您的后端C++代码，成功时会返回 status 和 message
      final responseBody = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['status'] == 'success') {
          _feedbackController.clear(); // Clear the text field
          _nicknameController.clear(); // 清空昵称字段
          _showSuccessSnackBar(
            responseBody['message'] ??
                'Feedback submitted successfully! Thank you.',
          );
        } else {
          // 即便状态码是2xx，但业务逻辑上可能失败
          _submissionError =
              responseBody['message'] ??
              'Feedback submission failed. Please try again.';
          _showErrorSnackBar(_submissionError!);
        }
      } else {
        // Server error (非2xx状态码)
        _submissionError =
            responseBody['message'] ?? // 尝试从响应体中获取错误信息
            responseBody['error'] ??
            'Failed to submit feedback (Error ${response.statusCode}). Please try again later.';
        print('Feedback submission failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        _showErrorSnackBar(_submissionError!);
      }
    } catch (e) {
      // Network or other errors (e.g., timeout, json parsing error if server sends non-json error)
      print('Error submitting feedback: $e');
      if (!mounted) return;
      String errorMessage =
          'An error occurred. Please check your connection and try again.';
      if (e is TimeoutException) {
        errorMessage = 'Request timed out. Please try again.';
      }
      _submissionError = errorMessage;
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
      body: SingleChildScrollView(
        // 使用 SingleChildScrollView 防止内容溢出
        padding: const EdgeInsets.all(16.0),
        child: Form(
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
              const SizedBox(height: 24), // 增大了间距
              TextFormField(
                // 昵称输入框
                controller: _nicknameController,
                maxLength: 100, // 限制长度以匹配后端
                decoration: InputDecoration(
                  hintText: 'Your name or nickname (optional)',
                  labelText: 'Nickname (Optional)',
                  counterText: "", // 隐藏默认的字符计数器
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
                  labelText: 'Feedback *', // 标记为必填
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
                  if (value.trim().length < 10) {
                    return 'Please provide a bit more detail (at least 10 characters).';
                  }
                  return null; // Return null if valid
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
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
            ],
          ),
        ),
      ),
    );
  }
}
