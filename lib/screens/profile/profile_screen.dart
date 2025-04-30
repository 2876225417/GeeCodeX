// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class profile_screen extends StatefulWidget {
  const profile_screen({Key? key}) : super(key: key);

  @override
  State<profile_screen> createState() => _profile_screen_state();
}

class _profile_screen_state extends State<profile_screen> {
  String _user_name = "";
  String? _user_email;
  String? _user_avatar_path;
  bool _is_dark_mode = false;
  final _user_name_controller = TextEditingController();
  final _user_email_controller = TextEditingController();

  int _books_read = 0;
  int _notes_count = 0;

  @override
  void initState() {
    super.initState();
    _load_user_data();
    _load_statistics();
  }

  @override
  void dispose() {
    _user_name_controller.dispose();
    _user_email_controller.dispose();
    super.dispose();
  }

  Future<void> _load_user_data() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _user_name = prefs.getString('user_name') ?? "User";
      _user_email = prefs.getString('user_email');
      _user_avatar_path = prefs.getString('user_avatar_path');
      _is_dark_mode = prefs.getBool('dark_mode') ?? false;

      _user_email_controller.text = _user_name;
      if (_user_email != null) _user_email_controller.text = _user_email!;
    });
  }

  Future<void> _save_user_data() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _user_name);
    if (_user_email != null) await prefs.setString('user_email', _user_email!);
    if (_user_avatar_path != null)
      await prefs.setString('user_avatar_path', _user_avatar_path!);
    await prefs.setBool('dark_mode', _is_dark_mode);
  }

  Future<void> _load_statistics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _books_read = prefs.getInt('books_read') ?? 0;
      _notes_count = prefs.getInt('notes_count') ?? 0;
    });
  }

  Future<void> _pick_avatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String path = '${directory.path}/user_avatar.jpg';

        await File(image.path).copy(path);

        setState(() {
          _user_avatar_path = path;
        });

        await _save_user_data();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _edit_username() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Name'),
            content: TextField(
              controller: _user_email_controller,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancle'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _user_name = _user_name_controller.text.trim();
                  });
                  await _save_user_data();
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _edit_email() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Email'),
            content: TextField(
              controller: _user_email_controller,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _user_email = _user_email_controller.text.trim();
                  });
                  await _save_user_data();
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _toggle_dark_mode(bool value) async {
    setState(() {
      _is_dark_mode = value;
    });
    await _save_user_data();
  }

  Future<void> _launch_url(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  @override
  Widget build(BuildContext build_ctx) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _build_user_header(),

            _build_statistics_section(),

            _build_settings_section(),

            _build_about_setion(),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Version 0.0.1',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build_user_header() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pick_avatar,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _user_avatar_path != null
                          ? FileImage(File(_user_avatar_path!))
                          : null,
                  child:
                      _user_avatar_path == null
                          ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.blue,
                          )
                          : null,
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade700, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _user_name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                onPressed: _edit_username,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 8),
              ),
            ],
          ),
          if (_user_email != null && _user_email!.isNotEmpty)
            Text(
              _user_email!,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            )
          else
            TextButton(
              onPressed: _edit_email,
              child: const Text(
                'Add email',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  Widget _build_statistics_section() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _build_stat_card(
                  icon: Icons.book,
                  title: 'Books Read',
                  value: _books_read.toString(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _build_stat_card(
                  icon: Icons.note,
                  title: 'Notes',
                  value: _notes_count.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build_stat_card({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build_settings_section() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _build_setting_item(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: _is_dark_mode,
              onChanged: _toggle_dark_mode,
              activeColor: Colors.blue.shade700,
            ),
          ),
          _build_setting_item(
            icon: Icons.notifications,
            title: 'Notifications',
            on_tap: () {},
          ),
          _build_setting_item(
            icon: Icons.language,
            title: 'Language',
            on_tap: () {},
          ),
          _build_setting_item(
            icon: Icons.security,
            title: "Privacy & Security",
            on_tap: () {},
          ),
          _build_setting_item(
            icon: Icons.help_outline,
            title: 'Help & Support',
            on_tap: () {},
          ),
        ],
      ),
    );
  }

  Widget _build_setting_item({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? on_tap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade700),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: EdgeInsets.zero,
      onTap: on_tap,
    );
  }

  Widget _build_about_setion() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _build_setting_item(
            icon: Icons.info_outline,
            title: 'About App',
            on_tap: () {
              _show_about_dialog();
            },
          ),
          _build_setting_item(
            icon: Icons.star_outline,
            title: 'Rate the App',
            on_tap: () {
              /* .Never Rate!!!!. */
            },
          ),
          _build_setting_item(
            icon: Icons.share,
            title: 'Share with Friends',
            on_tap: () {},
          ),
          _build_setting_item(
            icon: Icons.logout,
            title: 'Sign out',
            on_tap: () {
              _show_sign_out_dialog();
            },
          ),
        ],
      ),
    );
  }

  void _show_about_dialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('About PDF Reader'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balabala......', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  const Text(
                    'Powered by Flutter',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text('@ppQwQqq', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _show_sign_out_dialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Ready to sign out?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }
}
