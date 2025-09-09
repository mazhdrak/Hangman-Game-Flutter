// lib/main.dart
import 'dart:async'; // for Completer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:hangman/screens/home_screen.dart';
import 'package:hangman/screens/score_screen.dart';
import 'package:hangman/screens/about_screen.dart';
import 'package:hangman/utilities/constants.dart';
import 'package:hangman/utilities/ad_helper.dart';
import 'package:hangman/utilities/purchase_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initSdkAndConsent(); // initialize + consent + maybe preload ads
  runApp(const MainApp());
}

Future<void> _initSdkAndConsent() async {
  await MobileAds.instance.initialize();
  await PurchaseHelper.init();

  // Request consent info update (EU/UK/CCPA handled by AdMob configuration)
  final params = ConsentRequestParameters();
  final completer = Completer<void>();

  ConsentInformation.instance.requestConsentInfoUpdate(
    params,
        () async {
      // Success
      final formAvailable = await ConsentInformation.instance.isConsentFormAvailable();
      if (formAvailable) {
        ConsentForm.loadConsentForm(
              (ConsentForm form) {
            // show() is callback-based and returns void — do NOT await
            form.show((FormError? formError) {
              if (formError != null) {
                debugPrint('Consent form error: $formError');
              }
              _maybePreloadAds();
              if (!completer.isCompleted) completer.complete();
            });
          },
              (FormError error) {
            debugPrint('Consent form load failed: $error');
            _maybePreloadAds();
            if (!completer.isCompleted) completer.complete();
          },
        );
      } else {
        _maybePreloadAds();
        if (!completer.isCompleted) completer.complete();
      }
    },
        (FormError error) {
      // Failure updating consent info – continue but log
      debugPrint('Consent info update failed: $error');
      _maybePreloadAds();
      if (!completer.isCompleted) completer.complete();
    },
  );

  await completer.future;
}

void _maybePreloadAds() {
  if (PurchaseHelper.shouldShowAds()) {
    AdHelper.loadInterstitialAd();
    AdHelper.loadRewardedAd();
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Hide system UI and lock to portrait
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: kTooltipColor,
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
        'homePage': (context) => const HomeScreen(),
        'scorePage': (context) => const ScoreScreen(),
        'aboutPage': (context) => const AboutScreen(),
      },
    );
  }
}
