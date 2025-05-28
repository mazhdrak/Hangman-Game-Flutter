import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

class HangmanWords {
  int wordCounter = 0;
  List<int> _usedNumbers = [];
  List<String> _words = [];

  Future<void> readWords() async { // Good practice to type Future<void> if it doesn't return a specific value
    try {
      String fileText = await rootBundle.loadString('res/hangman_words.txt');
      // Filter out any empty strings that might result from split, especially if the file has trailing newlines
      _words = fileText.split('\n').where((word) => word.trim().isNotEmpty).toList();
      // Consider converting words to a consistent case, e.g., uppercase, if not already
      // _words = _words.map((word) => word.trim().toUpperCase()).toList();
    } catch (e) {
      // Handle potential errors during file reading, e.g., file not found
      print('Error reading words file: $e');
      _words = []; // Ensure words list is empty or has defaults if file fails
    }
  }

  void resetWords() {
    wordCounter = 0;
    _usedNumbers = [];
    // _words = []; // Usually you wouldn't clear the main word list on reset,
    // just the tracking of used words/numbers.
    // If readWords() is called again, it will repopulate.
  }

  // Added return type String? as it can return null implicitly or explicitly an empty string
  String? getWord() {
    wordCounter += 1; // Note: This increments even if no new word is returned or all words are used.
    // Consider if this counter should only increment when a valid new word is provided.

    if (_words.isEmpty) { // Check if words list is empty (e.g., after failed readWords)
      return null; // Or return an empty string, or handle error
    }

    // Check if all words have been used
    if (_usedNumbers.length >= _words.length) {
      // All words have been used
      return ''; // Return empty string to signify no more unique words
    }

    var rand = Random();
    int randNumber;
    bool notUnique = true;

    // Loop to find an unused word
    // Added a safety break to prevent infinite loop if logic is flawed or all numbers somehow get used
    // without _usedNumbers.length matching _words.length (shouldn't happen with correct logic)
    int attempts = 0;
    while (notUnique && attempts < _words.length * 2) { // Safety break
      randNumber = rand.nextInt(_words.length);
      if (!_usedNumbers.contains(randNumber)) {
        notUnique = false;
        _usedNumbers.add(randNumber);
        return _words[randNumber].trim(); // Return the unique word, trimmed
      }
      attempts++;
    }
    // If loop finishes without finding a unique word (e.g., due to safety break or all words used)
    return ''; // Or null, to indicate failure or no more words
  }

  String getHiddenWord(int wordLength) {
    if (wordLength <= 0) return ''; // Handle invalid length
    String hiddenWord = '';
    for (int i = 0; i < wordLength; i++) {
      hiddenWord += '_';
    }
    return hiddenWord;
  }

  // ========== ADDED THIS METHOD ==========
  int getWordListLength() {
    return _words.length;
  }
// =======================================
}