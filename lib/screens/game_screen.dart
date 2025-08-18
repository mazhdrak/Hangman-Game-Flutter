// lib/screens/game_screen.dart
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
  int remainingHints = 1; // This is now unused but kept for score calculation logic
  int mistakes = 0;
  Alphabet englishAlphabet = Alphabet();
  String word = "";
  String hiddenWord = "";
  late List<bool> buttonStatus;
  int hangState = 0;
  int totalScore = 0;
  bool finishedGame = false;
  bool _isLoadingWord = true;

  @override
  void initState() {
    super.initState();
    setLivesAndHints(widget.difficulty);
    initWords();
    AdHelper.loadInterstitialAd();
    AdHelper.loadRewardedAd(); // Correctly pre-load the ad using the helper
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
    }
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
        int roundScore = calculateScore(widget.difficulty, mistakes, maxHints - remainingHints);
        totalScore += roundScore;
        showScoreBreakdown(roundScore);
      }
    });
  }

  int calculateScore(String difficulty, int mistakes, int hintsUsed) {
    int base = {'Easy': 10, 'Normal': 20, 'Hard': 35, 'Extreme': 50}[difficulty]!;
    int bonus = mistakes == 0 ? 10 : 0;
    int penalty = hintsUsed * 2;
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
                  // --- CORRECTED HINT BUTTON ---
                  IconButton(
                    tooltip: 'Get a hint by watching an ad',
                    iconSize: 34,
                    icon: Icon(MdiIcons.lightbulbOnOutline, color: Colors.yellow),
                    onPressed: finishedGame ? null : () {
                      // When the button is pressed, show a rewarded ad
                      AdHelper.showRewardedAd(
                        onUserEarnedReward: (RewardItem reward) {
                          // This code runs ONLY if the user finishes the ad
                          print("User earned reward of ${reward.amount}");
                          setState(() {
                            // --- Your original hint logic goes here ---
                            List<int> hiddenIndices = [];
                            for (int i = 0; i < hiddenWord.length; i++) {
                              if (hiddenWord[i] == '_') {
                                hiddenIndices.add(i);
                              }
                            }
                            if (hiddenIndices.isNotEmpty) {
                              final randomIndexInHidden = Random().nextInt(hiddenIndices.length);
                              final actualIndexInWord = hiddenIndices[randomIndexInHidden];
                              final letterToReveal = word[actualIndexInWord];
                              final buttonIndex = englishAlphabet.alphabet.indexOf(letterToReveal.toUpperCase());
                              if (buttonIndex != -1 && buttonStatus[buttonIndex]) {
                                handleLetterPress(buttonIndex);
                                // You might want to track hints used for scoring
                                // For example: hintsUsedForScoring++;
                              }
                            }
                            // ----------------------------------------
                          });
                        },
                        onAdFailedToShow: () {
                          // Optional: Show a message if the ad is not ready
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Hint not ready. Please try again in a moment.")),
                          );
                        },
                      );
                    },
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