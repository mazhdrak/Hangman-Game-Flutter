import 'package:flutter/material.dart';
import 'package:hangman/components/action_button.dart'; // Assuming this path is correct
import 'package:hangman/utilities/hangman_words.dart';  // Assuming this path is correct
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

import 'game_screen.dart';
import 'loading_screen.dart';
// Make sure you have created 'about_screen.dart'
// and added 'aboutPage' route in your main.dart

class HomeScreen extends StatefulWidget {
  final HangmanWords hangmanWords = HangmanWords();

  HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Android Test Banner Ad Unit ID
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner Ad Unit ID

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    widget.hangmanWords.readWords();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => debugPrint('BannerAd opened.'),
        onAdClosed: (Ad ad) => debugPrint('BannerAd closed.'),
        onAdImpression: (Ad ad) => debugPrint('BannerAd impression.'),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    // Calculate available height for content (excluding potential status bar, appbar, and banner ad height)
    // Approximate heights: AppBar ~56, BannerAd ~50, StatusBar ~24-48
    // This is a rough estimation; precise calculations might involve LayoutBuilder or MediaQuery.padding
    double availableHeight = screenHeight - (AppBar().preferredSize.height) - 50 - MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hangman'),
        backgroundColor: const Color(0xFF421b9b), // Match your theme's scaffold background
        elevation: 0, // Optional: remove shadow if you prefer a flatter look
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              Navigator.pushNamed(context, 'aboutPage');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding( // Added padding around the main content
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            children: <Widget>[
              // The large "HANGMAN" text from the body is REMOVED
              // as the AppBar now provides the title.

              // Spacer to push content down a bit from the AppBar
              const Spacer(flex: 2),

              Center(
                child: Image.asset(
                  'images/gallow.png',
                  // Adjust height based on available space, e.g., 40-50% of available height
                  height: availableHeight * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(flex: 1), // Spacer between image and buttons
              Center(
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        height: 60, // Adjusted height slightly
                        child: ActionButton(
                          buttonTitle: 'Start',
                          onPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameScreen(
                                  hangmanObject: widget.hangmanWords,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 20.0, // Adjusted spacing
                      ),
                      SizedBox(
                        height: 60, // Adjusted height slightly
                        child: ActionButton(
                          buttonTitle: 'High Scores',
                          onPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoadingScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3), // Spacer to push content towards center and above banner
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
          ? Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      )
          : const SizedBox.shrink(),
    );
  }
}