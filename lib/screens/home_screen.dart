// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hangman/utilities/ad_helper.dart';
import 'package:hangman/screens/game_screen.dart';
import 'package:hangman/utilities/hangman_words.dart';
import 'package:hangman/screens/score_screen.dart';
import 'package:hangman/utilities/score_db.dart' as score_database;
import 'package:hangman/utilities/user_scores.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedDifficulty = 'Normal';
  final hangmanWords = HangmanWords();

  @override
  void initState() {
    super.initState();
    // Load the banner ad when the screen is first created
    AdHelper.loadBannerAd();
  }

  @override
  void dispose() {
    // Dispose the banner ad when the screen is closed
    AdHelper.disposeBannerAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E1A47),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'HANGMAN',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'PatrickHand',
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Difficulty: $selectedDifficulty',
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontFamily: 'PatrickHand'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final selected = await showDialog<String>(
                        context: context,
                        builder: (_) => DifficultyDialog(selected: selectedDifficulty),
                      );
                      if (selected != null) {
                        setState(() {
                          selectedDifficulty = selected;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Select Difficulty', style: TextStyle(fontFamily: 'PatrickHand')),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play', style: TextStyle(fontSize: 22, fontFamily: 'PatrickHand')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        hangmanObject: hangmanWords,
                        difficulty: selectedDifficulty,
                      ),
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.leaderboard),
                label: const Text('High Scores', style: TextStyle(fontFamily: 'PatrickHand')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  var db = await score_database.openDB();
                  var highScores = await score_database.scores(db);
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScoreScreen(query: highScores),
                    ),
                  );
                },
              ),
              // --- BANNER AD WIDGET ADDED HERE ---
              // This will be an empty space until the ad loads successfully
              AdHelper.getBannerAdWidget() ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class DifficultyDialog extends StatelessWidget {
  final String selected;
  const DifficultyDialog({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final options = ['Easy', 'Normal', 'Hard', 'Extreme'];
    return AlertDialog(
      backgroundColor: const Color(0xFF2E1A47),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Center(
        child: Text(
          'Select Difficulty',
          style: TextStyle(fontSize: 22, color: Colors.white, fontFamily: 'PatrickHand'),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          return ListTile(
            title: Center(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'PatrickHand',
                  color: selected == option ? Colors.deepPurpleAccent : Colors.white,
                  fontWeight: selected == option ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            onTap: () => Navigator.pop(context, option),
          );
        }).toList(),
      ),
    );
  }
}