// lib/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = 'Loading...';

  // IMPORTANT: Replace with the copyright details from the ORIGINAL Hangman project you forked/cloned.
  // This is usually found in its LICENSE file.
  final String originalHangmanCopyright = "Copyright (c) 2025 Rumen Mazhdrakov";

   // IMPORTANT: Replace with your hosted privacy policy URL
  final String _privacyPolicyUrl = 'https://mazhdrak.github.io/Hangman-Game-Flutter/PRIVACY.MD'; // Ensure PRIVACY.MD casing is correct

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Version: ${info.version}'; // Changed to display only the version name
    });
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri uri = Uri.parse(_privacyPolicyUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) { // Check if widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $_privacyPolicyUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Hangman'),
        backgroundColor: const Color(0xFF421b9b),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // App Name & Version
            Text(
              'Hangman App', // You can make this dynamic too if you wish: PackageInfo.appName
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _appVersion, // Will now display e.g., "Version: 1.0.0"
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),

            // Privacy Policy Link
            Text(
              'Privacy Policy',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _launchPrivacyPolicy,
              child: Text(
                'Read our Privacy Policy',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Open Source Licenses
            Text(
              'Open Source Licenses',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'This app is based on an open-source Hangman game project.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Original Hangman Game License:',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              originalHangmanCopyright, // Ensure this is updated with the ORIGINAL project's copyright
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),

            // View All Licenses Button
            ElevatedButton(
              onPressed: () {
                PackageInfo.fromPlatform().then((info) {
                  // The applicationLegalese parameter is for YOUR app's primary license or copyright notice,
                  // not specifically for the original Hangman game's notice, though you can include it if you structure it well.
                  // Often, people put their own app's copyright here, or leave it null if the licenses speak for themselves.
                  // For simplicity, let's use your app name and a generic copyright for your own work.
                  showLicensePage(
                    context: context,
                    applicationName: info.appName, // Fetches app name from pubspec
                    applicationVersion: info.version, // Fetches version from pubspec
                    applicationLegalese: 'Copyright (c) ${DateTime.now().year} Rumen Mazhdrakov', // Your copyright for your additions
                    // applicationIcon: Image.asset('assets/icon/icon.png', width: 50), // Path to your app icon
                  );
                });
              },
              child: const Text('View All Licenses (including Flutter)'),
            ),
          ],
        ),
      ),
    );
  }
}