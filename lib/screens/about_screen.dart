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
  final String originalHangmanCopyright = 'Copyright (c) 2025 Rumen Mazhdrakov';
  final String mitLicenseText = '''
[Insert your full MIT License text here]
''';

  // IMPORTANT: Replace with your hosted privacy policy URL
  final String _privacyPolicyUrl = 'https://mazhdrak.github.io/Hangman-Game-Flutter/PRIVACY.md';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Version: ${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri uri = Uri.parse(_privacyPolicyUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $_privacyPolicyUrl')),
      );
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
              'Hangman App',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _appVersion,
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
              originalHangmanCopyright,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              mitLicenseText,
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
                  showLicensePage(
                    context: context,
                    applicationName: 'Hangman App',
                    applicationVersion:
                    '${info.version}+${info.buildNumber}',
                    applicationLegalese: originalHangmanCopyright,
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
