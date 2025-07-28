import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class HangmanWords {
  final Map<String, List<String>> _wordsByDifficulty = {
    'Easy': [],
    'Normal': [],
    'Hard': [],
    'Extreme': [],
  };

  bool _loaded = false;

  Future<void> _loadWords() async {
    final fileData = await rootBundle.loadString('assets/hangman_words.txt');
    final lines = fileData.split('\n');

    String? currentDifficulty;

    for (final rawLine in lines) {
      final line = rawLine.trim();

      if (line.isEmpty) continue;

      // Parse section header like [EASY]
      if (line.startsWith('[') && line.endsWith(']')) {
        final header = line.substring(1, line.length - 1).toLowerCase();
        if (['easy', 'normal', 'hard', 'extreme'].contains(header)) {
          currentDifficulty = _capitalize(header);
        } else {
          currentDifficulty = null;
        }
      } else if (currentDifficulty != null &&
          _wordsByDifficulty.containsKey(currentDifficulty)) {
        _wordsByDifficulty[currentDifficulty]!.add(line.toLowerCase());
      }
    }

    _loaded = true;
  }

  Future<String?> getWord(String difficulty) async {
    if (!_loaded) await _loadWords();
    final words = _wordsByDifficulty[difficulty];
    if (words == null || words.isEmpty) return null;
    return words[Random().nextInt(words.length)];
  }

  int getWordListLength(String difficulty) {
    return _wordsByDifficulty[difficulty]?.length ?? 0;
  }

  String getHiddenWord(int length) {
    return '_' * length;
  }

  void reset() {
    _loaded = false;
    _wordsByDifficulty.forEach((key, list) => list.clear());
  }

  void resetWords() {
    reset();
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }
}
