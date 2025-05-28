// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hangman/components/action_button.dart';
import 'package:hangman/screens/loading_screen.dart';
import 'package:hangman/screens/game_screen.dart';
import 'package:hangman/utilities/hangman_words.dart';
import 'package:hangman/utilities/purchase_helper.dart';
import 'package:hangman/utilities/user_scores.dart';

class HomeScreen extends StatefulWidget {
  final HangmanWords hangmanWords;
  HomeScreen({Key? key})
      : hangmanWords = HangmanWords(),
        super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // VVVVVV  REPLACE WITH YOUR LIVE ADMOB BANNER AD UNIT ID FOR ANDROID VVVVVV
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-7816037574743099/6084765847' // <<< REPLACE THIS WITH YOUR LIVE ANDROID BANNER ID
      : 'ca-app-pub-3940256099942544/2934735716'; // Official iOS Banner Test ID (Replace if you have a live iOS ID)
  // ^^^^^^  REPLACE WITH YOUR LIVE ADMOB BANNER AD UNIT ID FOR ANDROID ^^^^^^

  @override
  void initState() {
    super.initState();
    widget.hangmanWords.readWords();
    if (PurchaseHelper.shouldShowAds()) _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isBannerAdLoaded = true),
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = _isBannerAdLoaded && _bannerAd != null ? _bannerAd!.size.height.toDouble() : 0;
    final appBarHeight = AppBar().preferredSize.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - appBarHeight - bannerHeight - topPadding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hangman'),
        backgroundColor: const Color(0xFF421b9b),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, 'aboutPage'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Center(
              child: Image.asset(
                'images/gallow.png',
                height: availableHeight * 0.5,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(flex: 1),
            Center(
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 60,
                      child: ActionButton(
                        buttonTitle: 'Start',
                        onPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameScreen(hangmanObject: widget.hangmanWords),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 60,
                      child: ActionButton(
                        buttonTitle: 'High Scores',
                        onPress: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoadingScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
      bottomNavigationBar: PurchaseHelper.shouldShowAds() && _isBannerAdLoaded && _bannerAd != null
          ? SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      )
          : const SizedBox.shrink(),
    );
  }
}