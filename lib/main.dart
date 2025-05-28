import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hangman/screens/home_screen.dart';
import 'package:hangman/screens/score_screen.dart';
import 'package:hangman/screens/about_screen.dart';
import 'package:hangman/utilities/constants.dart';
import 'package:hangman/utilities/ad_helper.dart';
import 'package:hangman/utilities/purchase_helper.dart'; // Import PurchaseHelper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();  // Initialize AdMob SDK
  await PurchaseHelper.init();            // Initialize In-App Purchase

  // Preload interstitial only if ads are not removed
  if (PurchaseHelper.shouldShowAds()) {
    AdHelper.loadInterstitialAd();
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Hide system UI and lock orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false, // <<< ADDED THIS LINE
      theme: ThemeData.dark().copyWith(
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: kTooltipColor, // Ensure kTooltipColor is defined in your constants.dart
            borderRadius: BorderRadius.circular(5.0),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20.0,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFF421b9b),
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'PatrickHand'),
      ),
      initialRoute: 'homePage',
      routes: {
        'homePage': (context) => HomeScreen(),
        'scorePage': (context) => const ScoreScreen(),
        'aboutPage': (context) => const AboutScreen(),
      },
    );
  }
}