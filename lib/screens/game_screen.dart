// lib/screens/game_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hangman/utilities/ad_helper.dart';
import 'package:hangman/components/word_button.dart';
import 'package:hangman/screens/home_screen.dart';
import 'package:hangman/utilities/alphabet.dart';
import 'package:hangman/utilities/constants.dart';
import 'package:hangman/utilities/hangman_words.dart';
import 'package:hangman/utilities/score_db.dart' as score_database;
import 'package:hangman/utilities/user_scores.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    Key? key,
    required this.hangmanObject,
    required this.difficulty,
  }) : super(key: key);

  final HangmanWords hangmanObject;
  final String difficulty;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final database = score_database.openDB();
  int lives = 5;
  int maxHints = 1;
  int remainingHints = 1; // kept for potential scoring; not decremented in current logic
  int mistakes = 0;
  Alphabet englishAlphabet = Alphabet();
  String word = "";
  String hiddenWord = "";
  late List<bool> buttonStatus;
  int hangState = 0;
  int totalScore = 0;
  bool finishedGame = false;
  bool _isLoadingWord = true;

  // Rewarded ad readiness + fallback tracking
  bool _rewardedReady = false;
  int _adFailCount = 0;
  int _freeHintsThisRound = 0;
  bool _freeHintEligible = false;
  static const int _adFailsBeforeFreeHint = 1;     // after 2 failed attempts we allow a free hint
  static const int _maxFreeHintsPerRound = 1;      // cap per round
  Timer? _rewardedWaitTimer;                       // fires if ad doesn't become ready in time
  static const Duration _waitForAd = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    setLivesAndHints(widget.difficulty);
    initWords();
    AdHelper.loadInterstitialAd();
    AdHelper.loadRewardedAd();

    // Listen to ad readiness
    AdHelper.rewardedReady.addListener(_onRewardedReadyChanged);
    _rewardedReady = AdHelper.rewardedReady.value;
  }

  void _onRewardedReadyChanged() {
    if (!mounted) return;
    setState(() {
      _rewardedReady = AdHelper.rewardedReady.value;
      // If an ad becomes ready, we can disable the free-hint eligibility timer
      if (_rewardedReady) _cancelRewardedWaitTimer();
    });
  }

  @override
  void dispose() {
    AdHelper.rewardedReady.removeListener(_onRewardedReadyChanged);
    _cancelRewardedWaitTimer();
    super.dispose();
  }

  void setLivesAndHints(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        lives = 8;
        maxHints = 3;
        break;
      case 'Normal':
        lives = 6;
        maxHints = 2;
        break;
      case 'Hard':
        lives = 5;
        maxHints = 1;
        break;
      case 'Extreme':
        lives = 4;
        maxHints = 0;
        break;
    }
    remainingHints = maxHints;
  }

  Future<void> initWords() async {
    setState(() {
      _isLoadingWord = true;
    });

    String? potentialWord = await widget.hangmanObject.getWord(widget.difficulty);
    if (!mounted) return;

    setState(() {
      if (potentialWord != null && potentialWord.isNotEmpty) {
        word = potentialWord.toUpperCase();
        hiddenWord = widget.hangmanObject.getHiddenWord(word.length);
        finishedGame = false;
        mistakes = 0;
        hangState = 0;
        buttonStatus = List.generate(26, (_) => true);
      } else {
        word = "";
      }
      _isLoadingWord = false;
    });

    if (word.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No more words available! Returning home.")),
          );
          Navigator.pop(context);
        }
      });
      return;
    }

    // Reset fallback counters/timer for the new round and (re)load rewarded
    _resetFreeHintStateForNewRound();
    AdHelper.loadRewardedAd();
  }

  void _resetFreeHintStateForNewRound() {
    _adFailCount = 0;
    _freeHintsThisRound = 0;
    _freeHintEligible = false;
    _cancelRewardedWaitTimer();
    _rewardedWaitTimer = Timer(_waitForAd, () {
      if (!mounted || finishedGame) return;
      if (!_rewardedReady) {
        // count as a failed availability attempt
        _adFailCount++;
        _updateFreeHintEligibility(reason: 'No ad available right now.');
      }
    });
  }

  void _cancelRewardedWaitTimer() {
    _rewardedWaitTimer?.cancel();
    _rewardedWaitTimer = null;
  }

  void handleLetterPress(int index) {
    if (finishedGame || lives <= 0) return;

    String guessedLetter = englishAlphabet.alphabet[index].toUpperCase();
    bool found = false;
    List<String> hiddenChars = hiddenWord.split('');

    setState(() {
      for (int i = 0; i < word.length; i++) {
        if (word[i] == guessedLetter && hiddenChars[i] == '_') {
          hiddenChars[i] = guessedLetter;
          found = true;
        }
      }

      if (!found) {
        mistakes++;
        hangState++;
        if (hangState >= 6) {
          lives--;
          finishedGame = true;
          _cancelRewardedWaitTimer();
          AdHelper.showInterstitialAd();
          if (lives <= 0) {
            showGameOver();
          } else {
            showRoundOver();
          }
        }
      }

      hiddenWord = hiddenChars.join();
      buttonStatus[index] = false;

      if (!hiddenWord.contains('_')) {
        finishedGame = true;
        _cancelRewardedWaitTimer();
        int roundScore = calculateScore(widget.difficulty, mistakes, maxHints - remainingHints);
        totalScore += roundScore;
        showScoreBreakdown(roundScore);
      }
    });
  }

  int calculateScore(String difficulty, int mistakes, int hintsUsed) {
    int base = {'Easy': 10, 'Normal': 20, 'Hard': 35, 'Extreme': 50}[difficulty]!;
    int bonus = mistakes == 0 ? 10 : 0;
    int penalty = hintsUsed * 2; // note: remainingHints isn't decremented currently
    return (base + bonus - penalty).clamp(0, 100);
  }

  void showScoreBreakdown(int roundScore) {
    if (!mounted) return;
    Alert(
      context: context,
      style: kSuccessAlertStyle,
      title: word,
      desc: "Score: $roundScore\n\nDifficulty: ${widget.difficulty}\nMistakes: $mistakes\nHints Used: ${maxHints - remainingHints}",
      buttons: [
        DialogButton(
          radius: BorderRadius.circular(10),
          width: 127,
          color: kDialogButtonColor,
          child: Icon(MdiIcons.arrowRightThick, size: 30),
          onPressed: () {
            if (mounted) Navigator.pop(context);
            initWords();
          },
        ),
      ],
    ).show();
  }

  void showGameOver() {
    if (!mounted) return;
    if (totalScore > 0) {
      score_database.manipulateDatabase(
        Score(id: 0, scoreDate: DateTime.now().toString(), userScore: totalScore),
        database,
      );
    }
    Alert(
      context: context,
      style: kGameOverAlertStyle,
      title: 'Game Over!',
      desc: 'Final Score: $totalScore',
      buttons: [
        DialogButton(
          child: Icon(MdiIcons.home, size: 30),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
        ),
        DialogButton(
          child: Icon(MdiIcons.refresh, size: 30),
          onPressed: () {
            if (mounted) Navigator.pop(context);
            setState(() {
              totalScore = 0;
              setLivesAndHints(widget.difficulty);
              initWords();
            });
          },
        ),
      ],
    ).show();
  }

  void showRoundOver() {
    Alert(
      context: context,
      style: kFailedAlertStyle,
      type: AlertType.error,
      title: word,
      buttons: [
        DialogButton(
          child: Icon(MdiIcons.arrowRightThick, size: 30),
          onPressed: () {
            if (mounted) Navigator.pop(context);
            initWords();
          },
        )
      ],
    ).show();
  }

  // Reveal one random hidden letter (used for both ad reward and free fallback)
  void _revealOneRandomLetter() {
    final hiddenIndices = <int>[];
    for (int i = 0; i < hiddenWord.length; i++) {
      if (hiddenWord[i] == '_') hiddenIndices.add(i);
    }
    if (hiddenIndices.isEmpty) return;
    final idx = hiddenIndices[Random().nextInt(hiddenIndices.length)];
    final ch = word[idx].toUpperCase();
    final btnIdx = englishAlphabet.alphabet.indexOf(ch);
    if (btnIdx != -1 && buttonStatus[btnIdx]) {
      handleLetterPress(btnIdx);
    }
  }

  // Make free hint available (manual button) if thresholds are met
  void _updateFreeHintEligibility({required String reason}) {
    if (finishedGame || _freeHintsThisRound >= _maxFreeHintsPerRound) return;
    if (_adFailCount >= _adFailsBeforeFreeHint && !_freeHintEligible) {
      setState(() {
        _freeHintEligible = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$reason Free hint is now available!')),
      );
    }
  }

  // When player taps the free hint button
  void _grantFreeHintManually() {
    if (!_freeHintEligible || _freeHintsThisRound >= _maxFreeHintsPerRound || finishedGame) return;
    _freeHintsThisRound++;
    _freeHintEligible = false; // consume availability
    _revealOneRandomLetter();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You used a free hint!')),
    );
    setState(() {}); // refresh button state
  }

  WordButton createButton(int index) {
    return WordButton(
      buttonTitle: englishAlphabet.alphabet[index].toUpperCase(),
      onPress: () {
        if (buttonStatus[index] && !finishedGame && lives > 0) {
          handleLetterPress(index);
        }
      },
      buttonStatus: buttonStatus[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingWord) {
      return Scaffold(
        backgroundColor: const Color(0xFF2E1A47),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2E1A47),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Hangman - ${widget.difficulty}"),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("❤️ $lives", style: kWordCounterTextStyle),
                  Text("Score: $totalScore", style: kWordCounterTextStyle),

                  // --- HINT ACTIONS (Ad + Free) ---
                  Row(
                    children: [
                      // Ad-based hint
                      IconButton(
                        tooltip: _rewardedReady ? 'Get a hint (watch ad)' : 'Loading hint…',
                        iconSize: 34,
                        onPressed: finishedGame || !_rewardedReady
                            ? null
                            : () {
                          AdHelper.showRewardedAd(
                            onUserEarnedReward: (RewardItem reward) {
                              setState(_revealOneRandomLetter);
                            },
                            onAdFailedToShow: () {
                              // Count as a failed ad attempt and possibly enable free hint.
                              _adFailCount++;
                              _updateFreeHintEligibility(reason: 'No ad available.');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Hint not ready. Please try again in a moment.')),
                              );
                            },
                          );
                        },
                        icon: _rewardedReady
                            ? const Icon(Icons.lightbulb_outline, color: Colors.yellow)
                            : const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Manual Free Hint (only appears/enables when eligible)
                      IconButton(
                        tooltip: _freeHintEligible
                            ? 'Free hint available'
                            : 'Free hint unavailable',
                        iconSize: 30,
                        onPressed: (!_freeHintEligible || finishedGame)
                            ? null
                            : _grantFreeHintManually,
                        icon: Icon(
                          MdiIcons.lightbulbOn10,
                          color: _freeHintEligible ? Colors.lightGreenAccent : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Flexible(
              flex: 5,
              child: FittedBox(
                child: Image.asset('images/$hangState.png', height: 900, width: 900, gaplessPlayback: true),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: FittedBox(
                child: Text(
                  hiddenWord.split('').join(' '),
                  style: kWordTextStyle,
                ),
              ),
            ),

            Flexible(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0, left: 8.0, right: 8.0),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(children: List.generate(7, (i) => createButton(i))),
                    TableRow(children: List.generate(7, (i) => createButton(i + 7))),
                    TableRow(children: List.generate(7, (i) => createButton(i + 14))),
                    TableRow(
                      children: List.generate(7, (i) {
                        int index = i + 21;
                        return index < 26 ? createButton(index) : const SizedBox.shrink();
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
