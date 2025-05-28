// lib/screens/game_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Needed for RewardItem
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

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key, required this.hangmanObject}) : super(key: key);

  final HangmanWords hangmanObject;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final database = score_database.openDB();
  int lives = 5;
  Alphabet englishAlphabet = Alphabet();
  late String word = "";
  late String hiddenWord = "";
  List<String> wordList = [];
  List<int> hintLetters = [];
  late List<bool> buttonStatus;
  bool hintStatus = true; // True if free hint is available
  int hangState = 0;
  int wordCount = 0;
  bool finishedGame = false;
  bool resetGame = false;

  @override
  void initState() {
    super.initState();
    initWords();
    AdHelper.loadInterstitialAd();
    AdHelper.loadRewardedAd();   // Load rewarded ad when screen starts
  }

  void initWords() {
    finishedGame = false;
    resetGame = false;
    hintStatus = true;
    hangState = 0;
    buttonStatus = List.generate(26, (_) => true);
    wordList = [];
    hintLetters = [];

    if (widget.hangmanObject.getWordListLength() > 0) {
      String? potentialWord = widget.hangmanObject.getWord();
      word = potentialWord?.trim() ?? "";

      if (word.isEmpty && widget.hangmanObject.getWordListLength() > _getUsedWordCountSafely()) {
        potentialWord = widget.hangmanObject.getWord();
        word = potentialWord?.trim() ?? "";
      }
    } else {
      word = "";
    }

    if (word.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No more words available or error! Returning home."))
          );
          returnHomePage();
        }
      });
      return;
    }
    hiddenWord = widget.hangmanObject.getHiddenWord(word.length);

    for (int i = 0; i < word.length; i++) {
      wordList.add(word[i].toUpperCase());
      hintLetters.add(i);
    }
    // Attempt to load a rewarded ad for the new word/round
    AdHelper.loadRewardedAd();
  }

  int _getUsedWordCountSafely() {
    try {
      return widget.hangmanObject.wordCounter;
    } catch (e) {
      return widget.hangmanObject.getWordListLength();
    }
  }

  void newGame() {
    setState(() {
      widget.hangmanObject.resetWords();
      lives = 5;
      wordCount = 0;
      initWords();
    });
  }

  void returnHomePage() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
        ModalRoute.withName('homePage'),
      );
    }
  }

  void wordPress(int index) {
    if (lives <= 0 && !finishedGame) {
      WidgetsBinding.instance.addPostFrameCallback((_) => returnHomePage());
      return;
    }
    if (finishedGame) {
      setState(() => resetGame = true);
      return;
    }

    bool found = false;
    String letterPressed = englishAlphabet.alphabet[index].toUpperCase();

    setState(() {
      for (int i = 0; i < word.length; i++) {
        if (word[i].toUpperCase() == letterPressed && hiddenWord[i] == '_') {
          found = true;
          List<String> hiddenWordChars = hiddenWord.split('');
          hiddenWordChars[i] = word[i].toUpperCase();
          hiddenWord = hiddenWordChars.join('');
        }
      }

      if (!found) {
        hangState++;
        debugPrint('GameScreen: Incorrect guess. hangState is now $hangState. Lives: $lives');
      }

      hintLetters.removeWhere((letterIndex) => letterIndex < hiddenWord.length && hiddenWord[letterIndex] != '_');

      if (hangState >= 6) {
        lives--;
        finishedGame = true;
        debugPrint('GameScreen: hangState >= 6 condition met (hangState: $hangState). Attempting to show interstitial ad.');
        AdHelper.showInterstitialAd();
        if (lives < 1) {
          _showGameOver();
        } else {
          _showRoundOver();
        }
      }

      buttonStatus[index] = false;
      if (!hiddenWord.contains('_') && word.isNotEmpty) {
        finishedGame = true;
        _showWin();
      }
    });
  }

  void _showGameOver() {
    if (mounted && wordCount > 0) {
      score_database.manipulateDatabase(
        Score(id: 0, scoreDate: DateTime.now().toString(), userScore: wordCount),
        database,
      );
    }
    if (mounted) {
      Alert(
        style: kGameOverAlertStyle,
        context: context,
        title: 'Game Over!',
        desc: 'Your score is $wordCount',
        buttons: [
          DialogButton(
            color: kDialogButtonColor,
            child: Icon(MdiIcons.home, size: 30),
            onPressed: returnHomePage,
          ),
          DialogButton(
            color: kDialogButtonColor,
            child: Icon(MdiIcons.refresh, size: 30),
            onPressed: () {
              if (mounted) Navigator.pop(context);
              newGame();
            },
          ),
        ],
      ).show();
    }
  }

  void _showRoundOver() {
    if (mounted) {
      Alert(
        style: kFailedAlertStyle,
        context: context,
        type: AlertType.error,
        title: word,
        buttons: [
          DialogButton(
            radius: BorderRadius.circular(10),
            width: 127,
            color: kDialogButtonColor,
            child: Icon(MdiIcons.arrowRightThick, size: 30),
            onPressed: () {
              if (mounted) Navigator.pop(context);
              setState(initWords);
            },
          ),
        ],
      ).show();
    }
  }

  void _showWin() {
    if (mounted) {
      Alert(
        style: kSuccessAlertStyle,
        context: context,
        type: AlertType.success,
        title: word,
        buttons: [
          DialogButton(
            radius: BorderRadius.circular(10),
            width: 127,
            color: kDialogButtonColor,
            child: Icon(MdiIcons.arrowRightThick, size: 30),
            onPressed: () {
              if (mounted) Navigator.pop(context);
              setState(() {
                wordCount++;
                initWords();
              });
            },
          ),
        ],
      ).show();
    }
  }

  WordButton createButton(int index) {
    return WordButton(
      buttonTitle: englishAlphabet.alphabet[index].toUpperCase(),
      onPress: () {
        if (buttonStatus[index] && !finishedGame && lives > 0) {
          wordPress(index);
        }
      },
      buttonStatus: buttonStatus[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (resetGame && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            initWords();
          });
        }
      });
    }

    if (word.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: widget.hangmanObject.getWordListLength() == 0
                ? const Text("No words loaded. Check word list.", style: TextStyle(color: Colors.white))
                : const CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row( // Lives display
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(MdiIcons.heart, color: Colors.red, size: 39),
                            Text(
                              lives.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PatrickHand',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text('$wordCount', style: kWordCounterTextStyle), // Score
                    // Hint Section
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton( // Original Free Hint Button
                          tooltip: 'Hint',
                          iconSize: 39,
                          icon: Icon(MdiIcons.lightbulbOutline, color: hintStatus ? Colors.yellow : Colors.grey.shade700),
                          onPressed: (hintStatus && hintLetters.isNotEmpty && !finishedGame && lives > 0)
                              ? () {
                            debugPrint('--- FREE HINT BUTTON PRESSED ---');
                            if (hintLetters.isEmpty) {
                              debugPrint('Hint Error: hintLetters empty for free hint.');
                              return;
                            }
                            final randHintIndex = Random().nextInt(hintLetters.length);
                            final actualLetterIndexInWord = hintLetters[randHintIndex];
                            if (actualLetterIndexInWord < word.length) {
                              final letterToReveal = word[actualLetterIndexInWord].toUpperCase();
                              final buttonIndexInAlphabet = englishAlphabet.alphabet.indexOf(letterToReveal);
                              if (buttonIndexInAlphabet != -1 && buttonStatus[buttonIndexInAlphabet]) {
                                wordPress(buttonIndexInAlphabet);
                                setState(() => hintStatus = false);
                              }
                            }
                          }
                              : null,
                        ),
                        // "Watch Ad for Hint" Button
                        if (!hintStatus && !finishedGame && lives > 0)
                          IconButton(
                            tooltip: 'Get Hint (Watch Ad)',
                            iconSize: 39,
                            icon: Icon(MdiIcons.moviePlayOutline, color: Colors.amberAccent),
                            onPressed: () {
                              debugPrint("GameScreen: 'Watch Ad for Hint' button pressed.");
                              AdHelper.showRewardedAd(
                                onUserEarnedReward: (RewardItem reward) {
                                  debugPrint("GameScreen: User earned reward! Type: ${reward.type}, Amount: ${reward.amount}");
                                  setState(() {
                                    hintStatus = true; // Grant a new hint
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Hint granted! You can use the hint button again.')),
                                    );
                                  }
                                },
                                onAdDismissed: () {
                                  debugPrint("GameScreen: Rewarded ad was dismissed by user (no reward).");
                                },
                                onAdFailedToShow: () {
                                  debugPrint("GameScreen: Rewarded ad failed to show.");
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Hint ad not available right now. Please try again later.')),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.asset('images/$hangState.png', height: 1001, width: 991, gaplessPlayback: true),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Text(
                    hiddenWord.isNotEmpty ? hiddenWord.split('').join(' ') : "",
                    style: kWordTextStyle,
                    textScaler: TextScaler.linear(1.0),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 8, 10),
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  TableRow(children: List.generate(7, (i) => createButton(i))),
                  TableRow(children: List.generate(7, (i) => createButton(i + 7))),
                  TableRow(children: List.generate(7, (i) => createButton(i + 14))),
                  TableRow(children: List.generate(7, (i) => i < 5 ? createButton(i + 21) : const SizedBox.shrink())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}